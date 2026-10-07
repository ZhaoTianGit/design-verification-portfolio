// Simulation-only receiver stub: no FIFO storage or dequeue behavior.
module receiver_stub #(
    parameter bit STALL_FIRST_TRANSFER = 1'b1
) (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    input logic [7:0] in_data,
    output wire in_ready,
    output integer accepted_enqueue_count,
    output logic [7:0] last_accepted_data
);
    timeunit 1ns;
    timeprecision 1ps;

    logic receiver_enabled;
    assign in_ready = rst_n && receiver_enabled;
    //assign in_ready = 1'b0; // Temporarily block all handshakes for simulation timeout

    initial begin
        receiver_enabled = 1'b1;
        if (STALL_FIRST_TRANSFER) begin
            receiver_enabled = 1'b0;
            // Teaching schedule: ready at 50 ns with the current 10 ns clock.
            // This is tied to this lab's timing, not a general stall controller.
            // Skip the time-zero X-to-0 clock initialization transition.
            @(posedge clk);
            repeat (5) @(negedge clk);
            receiver_enabled = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            accepted_enqueue_count <= 0;
        end else if (in_valid && in_ready) begin
            accepted_enqueue_count <= accepted_enqueue_count + 1;
            last_accepted_data <= in_data;
            $display("Accepted input at %0t: data=%h, count=%0d",
                     $time, in_data, accepted_enqueue_count + 1);
        end
    end
endmodule
