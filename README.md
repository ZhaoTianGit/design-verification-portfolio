# Synchronous FIFO — RTL Design and Verification

An independently developed verification project demonstrating specification-driven RTL development, self-checking verification, reproducible regressions, and structured debug.

> **Status:** implementation in progress. Results will be published only when they are reproducible from this repository.

## Engineering objective

Design and verify a parameterized synchronous FIFO whose behavior is explicit under reset, empty/full boundaries, pointer wraparound, simultaneous read/write, overflow attempts, and underflow attempts.

The project is evaluated as a verification deliverable—not merely as synthesizable RTL. The repository will provide enough evidence for a reviewer to understand what was verified, how failures are detected, and how the reported results can be reproduced.

## Delivered artifacts

The completed project will contain:

- A concise FIFO specification with unambiguous corner-case behavior
- Parameterized Verilog/SystemVerilog RTL
- A verification plan linking requirements to tests and checks
- A self-checking testbench with a queue-based reference model
- Directed boundary tests and reproducible randomized traffic
- Assertions for occupancy, ordering, overflow, underflow, and flag behavior
- Functional coverage for operations, boundaries, wraparound, and concurrency
- Automated regressions with seed capture and failure replay
- A bug journal showing injected defects, observed symptoms, root cause, and correction
- A results summary containing commands, tool versions, pass/fail counts, and known limitations

## Verification architecture

```text
Stimulus / transactions
         |
         v
   FIFO interface  --->  DUT
         |               |
         |               v
         +--------> Monitor
                         |
            +------------+-------------+
            |                          |
            v                          v
     Reference model               Assertions
            |
            v
        Scoreboard  --->  Results and failure diagnostics
```

## Verification intent

The testbench will demonstrate:

- Correct FIFO ordering across pointer wraparound
- Correct `full` and `empty` transitions at every boundary
- Defined behavior for simultaneous read and write operations
- No accepted write while full and no accepted read while empty
- Reset recovery from active and boundary states
- Parameter robustness across multiple data widths and depths
- Reproducibility of every randomized failure from its recorded seed

## Repository structure

```text
docs/       Public specification, verification plan, and final results
rtl/        FIFO RTL
tb/         Testbench, reference model, assertions, and coverage
scripts/    Build and regression automation
results/    Reproducible summaries and selected project-generated evidence
```

## Reproducing the results

Build and regression commands will be added with the first verified release. A claimed result will not be published unless it can be reproduced from a clean clone using the documented tool versions and commands.

## Independence and confidentiality

This repository contains only independently created personal work. It contains no employer code, specifications, test cases, logs, screenshots, signal names, architecture details, or other confidential material.
