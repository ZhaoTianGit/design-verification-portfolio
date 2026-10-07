# Ready/Valid Lab — Verification Results

Reviewed: 2026-10-08.

## Scope and method

Top module: `sender`. Receiver: `receiver_stub`. This is a simulation-only ready/valid example, not a FIFO implementation.

The clock period is 10 ns. Active-low reset is sampled on rising edges. Reset is released at 30 ns, stimulus starts at 40 ns, receiver readiness begins at 50 ns, and normal accepted inputs occur at 55, 65, and 75 ns. The expected sequence is initialized element-by-element for Icarus portability.

Reproduction command from the repository root:

```bash
python3 scripts/run_handshake_lab.py
```

The runner recompiles each scenario and validates process status, the expected diagnostic, and the expected simulation-time marker. It uses temporary source copies. Local logs and the normal waveform are written under ignored `build/handshake-lab/`.

## Observed results

| Scenario | Fault applied | Required observation | Result |
| --- | --- | --- | --- |
| `normal` | None | Sequence `7E, 3C, 12`; both counts equal 3; PASS and finish at 110 ns | Matched |
| `sequence_mismatch` | Second input changed from `3C` to `3D` | `Transfer 1: expected=3c actual=3d` at 65 ns | Matched |
| `valid_drop` | Valid withdrawn at 50 ns after the stall sampled at 45 ns | `valid dropped while stalled` at 55 ns | Matched |
| `stalled_data_change` | First input changed from `7E` to `3D` at 50 ns | `data changed while stalled` at 55 ns | Matched |
| `timeout` | Ready permanently forced low | Watchdog failure at 200 ns | Matched |

Five out of five expected outcomes were matched in both publication checks:

- Windows: Icarus `12.0 (devel) (s20150603-1539-g2693dd32b)`.
- Ubuntu 24.04 under WSL 2: Icarus `12.0 (stable)` and Python 3.12.3.

This is a scenario result, not a coverage percentage.

Earlier user-provided manual runs demonstrated the normal lab and the same failure mechanisms. The packaged runner was then executed separately on both platforms, rather than assuming those manual runs validated the new automation.

For valid-drop and stalled-data-change scenarios, the temporary copy disables the sequence checker to isolate the stall checker. Otherwise a simultaneous sequence failure could terminate simulation before the intended diagnostic. Every checker remains enabled in the normal scenario.

## Why acceptance can still be incorrect

`Accepted input` means the receiver sampled valid and ready high at the clock edge. It does not mean the value was correct. A fault can therefore produce both an acceptance message and a checker failure at the same simulation time. Parallel blocks need not print in a fixed order.

`Transfer 0` is the first accepted transfer; indices start at zero. A reported time of 55000 ps equals 55 ns. Unknown counter bits before the first reset edge and unknown last-accepted data before the first transfer are expected for this model.

## Evidence selection and privacy

Only `ready-valid-waveform.png` is published. It is the user-supplied waveform-only screenshot, not the earlier combined terminal/desktop screenshot. Visual inspection found no username, machine name, local path, or credentials. The PNG contains color/density metadata and no EXIF entries or textual metadata fields. The other supplied terminal images are omitted because their clipped borders retain fragments of terminal content.

The screenshot depicts a normal lab run, not FIFO behavior. Public source and the runner are the reproducibility evidence; the image is a visual aid.

## Known limits

- Fixed three-word stimulus, 8-bit data, and a scheduled initial stall; no randomized regression or coverage closure.
- No storage queue, output consumer, FIFO boundary tests, or implemented FIFO datapath.
- Stability checks compare rising-edge samples; between-edge glitches are not checked.
- No concurrent SystemVerilog Assertions, covergroups, formal proof, or UVM environment.
- Unknown-state behavior is not exhaustively checked; Verilator two-state simulation would not be an equivalent unknown-state test.
- Receiver readiness scheduling is a lab fixture, not a general backpressure controller.
- The deliberate unexpected-extra-transfer guard exists, but a separate extra-transfer scenario is not part of this five-case result.

## Reproducible progress boundary

Delivered: a self-checking ready/valid simulation lab and directed checks of sequence, sampled stall stability, and bounded completion.

Not delivered: a functioning synchronous FIFO. Its interface, internal-state declarations, status logic, and reset work are still under development and are not presented as verified RTL.
