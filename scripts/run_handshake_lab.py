"""Compile the public lab and check normal / deliberately faulty simulations.

Uses only Python's standard library. Faults are applied to temporary copies;
the checked-in SystemVerilog and the learner's original workspace stay intact.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError("Fault-injection anchor must occur exactly once")
    return text.replace(old, new, 1)


def sources_for(case, sender, receiver):
    if case == "sequence_mismatch":
        sender = replace_once(sender, "in_data = 8'h3C;", "in_data = 8'h3D;")
    elif case in ("valid_drop", "stalled_data_change"):
        fault = "in_valid = 1'b0;" if case == "valid_drop" else "in_data = 8'h3D;"
        sender = replace_once(
            sender,
            "// Hold 7E until an input handshake is accepted.",
            "// Deliberate protocol fault at 50 ns.\n"
            "        @(negedge clk);\n        " + fault,
        )
        # Isolate the stability checker so the sequence checker cannot terminate
        # simulation first on the same edge. Normal case keeps every check on.
        sender = replace_once(
            sender,
            "end else if (in_valid && in_ready) begin",
            "end else if (1'b0) begin",
        )
    elif case == "timeout":
        receiver = replace_once(
            receiver,
            "assign in_ready = rst_n && receiver_enabled;",
            "assign in_ready = 1'b0;",
        )
    return sender, receiver


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iverilog", default="iverilog")
    parser.add_argument("--vvp", default="vvp")
    args = parser.parse_args()
    for exe in (args.iverilog, args.vvp):
        if shutil.which(exe) is None:
            parser.error("Executable not found: " + exe)

    source_dir = ROOT / "examples" / "ready-valid"
    sender = (source_dir / "sender.sv").read_text(encoding="utf-8")
    receiver = (source_dir / "receiver_stub.sv").read_text(encoding="utf-8")
    build = ROOT / "build" / "handshake-lab"
    build.mkdir(parents=True, exist_ok=True)
    cases = {
        "normal": (0, "PASS: all 3 transfers match the expected sequence", "110000"),
        "sequence_mismatch": (1, "Transfer 1: expected=3c actual=3d", "Time: 65000"),
        "valid_drop": (1, "Protocol violation: valid dropped while stalled", "Time: 55000"),
        "stalled_data_change": (1, "Protocol violation: data changed while stalled", "Time: 55000"),
        "timeout": (1, "Simulation timeout: test did not finish within 200 ns", "Time: 200000"),
    }
    for name, (expected_status, message, time_marker) in cases.items():
        with tempfile.TemporaryDirectory(prefix="case-", dir=build) as directory:
            cwd = Path(directory)
            s, r = sources_for(name, sender, receiver)
            (cwd / "sender.sv").write_text(s, encoding="utf-8")
            (cwd / "receiver_stub.sv").write_text(r, encoding="utf-8")
            compiled = subprocess.run(
                [args.iverilog, "-g2012", "-Wall", "-s", "sender", "-o", "sim.out",
                 "sender.sv", "receiver_stub.sv"],
                cwd=cwd, capture_output=True, text=True, timeout=30,
            )
            if compiled.returncode != 0:
                print("FAIL " + name + ": compilation failed\n" + compiled.stdout + compiled.stderr)
                return 1
            run = subprocess.run([args.vvp, "sim.out"], cwd=cwd,
                                 capture_output=True, text=True, timeout=10)
            log = run.stdout + run.stderr
            (build / (name + ".log")).write_text(log, encoding="utf-8")
            if name == "normal":
                shutil.copyfile(cwd / "sender_receiver.vcd", build / "normal.vcd")
            correct_status = run.returncode == 0 if expected_status == 0 else run.returncode != 0
            correct_failure = "FATAL:" not in log if expected_status == 0 else "FATAL:" in log and "PASS:" not in log
            if not (correct_status and correct_failure and message in log and time_marker in log):
                print("FAIL " + name + ": unexpected simulation result\n" + log)
                return 1
            outcome = "PASS" if name == "normal" else "EXPECTED FAILURE detected"
            print("PASS " + name + ": " + outcome)
    print("SUMMARY: 5/5 scenarios matched their expected outcomes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
