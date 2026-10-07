// Simulation sender and harness. Receiver logic is in receiver_stub.sv.
module sender;
    timeunit 1ns;
    timeprecision 1ps;
    logic clk;
    logic rst_n;
    logic in_valid;
    logic [7:0] in_data;
    logic [7:0] expected_data [0:2];
    wire in_ready;
    wire integer accepted_enqueue_count;
    wire [7:0] last_accepted_data;
    logic stalled_last_cycle;
    logic [7:0] stalled_data;


    // Independent checker state
    int checked_transfer_count = 0;

    receiver_stub receiver (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_data(in_data),
        .in_ready(in_ready),
        .accepted_enqueue_count(accepted_enqueue_count),
        .last_accepted_data(last_accepted_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $timeformat(-9, 0, " ns", 8);
        $dumpfile("sender_receiver.vcd");
        $dumpvars(0, sender);
        $monitor("time=%0t valid=%b ready=%b data=%h count=%0d last_accepted_data=%h", $time, in_valid, in_ready, in_data, accepted_enqueue_count, last_accepted_data);
    end

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_data = '0;
        // Element-wise initialization is portable to Icarus Verilog 12.
        expected_data[0] = 8'h7E;
        expected_data[1] = 8'h3C;
        expected_data[2] = 8'h12;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);  // 40ns
        in_valid = 1'b1;
        in_data = 8'h7E;

        // Hold 7E until an input handshake is accepted.
        do begin
            @(posedge clk);
        end while (in_ready !== 1'b1);

        @(negedge clk);
        in_data = 8'h3C;
        // Wait for 3C to be accepted
        do begin
            @(posedge clk);
        end while (in_ready !== 1'b1);

        @(negedge clk);
        in_data = 8'h12;
        // Wait for 12 to be accepted
        do begin
            @(posedge clk);
        end while (in_ready !== 1'b1);

        @(negedge clk);
        in_valid = 1'b0;

        repeat (3) @(negedge clk); // Allow idle cycles before final checks.

        // Final acceptance criteria
        if (accepted_enqueue_count !== 3) begin
            $fatal(1, "Expected 3 accepted transfers");
        end

        if (checked_transfer_count !== 3) begin
            $fatal(1, "Expected 3 checked transfers");
        end

        $display("PASS: all 3 transfers match the expected sequence");
        $finish;
    end

    // Checker_1 - Data transfer count
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            checked_transfer_count = 0;
        end else if (in_valid && in_ready) begin
            if (checked_transfer_count >= 3) begin
                $fatal(1, "Unexpected extra transfer");
            end else begin
                // Failure detection - Data mismatch
                if (in_data !== expected_data[checked_transfer_count]) begin
                    $fatal(1, "Transfer %0d: expected=%h actual=%h",
                           checked_transfer_count,
                           expected_data[checked_transfer_count],
                           in_data);
                end

                checked_transfer_count = checked_transfer_count + 1;
            end
        end
    end

    // Checker_2 - Data stability under Backpressure
    always @(posedge clk) begin
    if (rst_n == 1'b0) begin
        stalled_last_cycle = 1'b0;
        stalled_data = '0;
    end else begin
        // Check the promise made at the previous rising edge.
        if (stalled_last_cycle) begin
            if (in_valid !== 1'b1) begin
                $fatal(1, "Protocol violation: valid dropped while stalled");
            end
            // 1: Check Previous State
            if (in_data !== stalled_data) begin
                $fatal(1, "Protocol violation: data changed while stalled");
            end
        end

        // 2: Record the current edge for the next check.
            // Stall when Sender has data BUT Receiver is NOT ready.
        stalled_last_cycle = in_valid && !in_ready;

        if (stalled_last_cycle) begin
            stalled_data = in_data;
        end
    end
end

    // Checker_3 - Failure detection - Simulation Timeout
    initial begin
        #200; // will shows in 200000ps = 200ns
        $fatal(1, "Simulation timeout: test did not finish within 200 ns");
    end
endmodule
