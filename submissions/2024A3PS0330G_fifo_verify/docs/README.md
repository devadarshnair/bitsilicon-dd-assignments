# Assignment 2 — Synchronous FIFO Verification

This repository contains the RTL and verification environment for **Assignment 2: Synchronous FIFO & Verilog Testbench Techniques**. The design implements a **synchronous FIFO** with configurable data width and depth, along with a **self-checking Verilog testbench** that uses a **golden reference model**, **scoreboard**, and **manual coverage counters**.

This README is intended to document the design, explain the verification approach, and show how to run the simulation.

Assignment reference: fileciteturn0file0

---

## 1. Objective

The goal of this assignment is to:

- Design a **synchronous FIFO** in synthesizable Verilog.
- Implement FIFO control using:
  - memory array
  - write pointer
  - read pointer
  - occupancy counter
  - full/empty status flags
- Verify the FIFO using a **self-checking testbench**.
- Validate correctness using:
  - a **golden model**
  - a **scoreboard**
  - **directed testcases**
  - **manual coverage counters**

The FIFO preserves **First-In First-Out** ordering, meaning the first value written is the first value read.

---

## 2. Files in this Submission

```text
.
├── rtl/
│   ├── sync_fifo.v
│   └── sync_fifo_top.v
├── tb/
│   └── tb_sync_fifo.v
└── docs/
    └── README.md
```

### File descriptions

#### `rtl/sync_fifo.v`
Contains the internal FIFO logic, including:
- memory array
- write pointer
- read pointer
- occupancy counter
- synchronous reset logic
- write/read handling
- full/empty flag generation

#### `rtl/sync_fifo_top.v`
Top-level wrapper around the FIFO module.
It instantiates `sync_fifo` and exposes the complete DUT interface.

#### `tb/tb_sync_fifo.v`
Self-checking testbench that:
- instantiates the DUT
- implements an independent golden model
- compares DUT outputs against expected outputs every cycle
- runs directed verification tests
- tracks manual coverage counters

#### `docs/README.md`
Documentation for the implementation and verification flow.

---

## 3. FIFO Specification

### Parameters

- `DATA_WIDTH = 8`
- `DEPTH = 16`
- `ADDR_WIDTH = $clog2(DEPTH)`

### Interface Signals

| Signal | Direction | Description |
|---|---|---|
| `clk` | input | System clock |
| `rst_n` | input | Active-low synchronous reset |
| `wr_en` | input | Write enable |
| `wr_data` | input | Data to be written into FIFO |
| `wr_full` | output | FIFO full flag |
| `rd_en` | input | Read enable |
| `rd_data` | output | Data read from FIFO |
| `rd_empty` | output | FIFO empty flag |
| `count` | output | Number of elements currently stored |

---

## 4. FIFO Design Overview

The FIFO is implemented using the following internal hardware elements:

- `mem[0:DEPTH-1]` — storage array
- `wr_ptr` — points to next write location
- `rd_ptr` — points to next read location
- `oc` / `count` — occupancy counter

### Reset behavior
When `rst_n = 0` on a rising clock edge:
- memory is cleared
- write pointer resets to `0`
- read pointer resets to `0`
- occupancy counter resets to `0`
- `rd_data` resets to `0`

### Write behavior
When `wr_en = 1` and FIFO is **not full**:
- `wr_data` is written into `mem[wr_ptr]`
- `wr_ptr` increments
- occupancy counter increments

### Read behavior
When `rd_en = 1` and FIFO is **not empty**:
- data from `mem[rd_ptr]` is placed on `rd_data`
- `rd_ptr` increments
- occupancy counter decrements

### Simultaneous read/write
When both `wr_en` and `rd_en` are asserted and the operation is valid:
- both pointers increment
- one element is written and one element is read in the same cycle
- net `count` remains unchanged

### Status flags
The flags are derived from the occupancy counter:

- `rd_empty = (count == 0)`
- `wr_full  = (count == DEPTH)`

---

## 5. Verification Methodology

The verification environment is designed to automatically detect mismatches without relying on manual waveform inspection.

### 5.1 Golden Reference Model
The testbench contains an independent behavioral FIFO model using:

- `model_mem`
- `model_wr_ptr`
- `model_rd_ptr`
- `model_count`
- `model_rd_data`

This model updates on the same clock edge as the DUT and computes the expected FIFO behavior independently.

### 5.2 Scoreboard
A scoreboard compares DUT outputs with golden model outputs.
The following checks are performed:

- `count` vs `model_count`
- `wr_full` vs `(model_count == DEPTH)`
- `rd_empty` vs `(model_count == 0)`
- `rd_data` vs `model_rd_data` during valid reads

If any mismatch is detected, the testbench prints detailed diagnostics including:
- simulation time
- cycle number
- expected vs actual values
- current input signals

Simulation terminates immediately on failure.

### 5.3 Manual Coverage Counters
The testbench also tracks whether important corner cases were exercised:

- `cov_full`
- `cov_empty`
- `cov_wrap`
- `cov_simul`
- `cov_overflow`
- `cov_underflow`

A coverage summary is printed at the end of simulation.

---

## 6. Directed Testcases Implemented

The following required directed tests are implemented in the testbench:

1. **Reset Test**
   - verifies reset state
   - checks empty/full behavior after reset

2. **Single Write / Read Test**
   - writes one known data value
   - reads it back
   - checks data integrity and count updates

3. **Fill Test**
   - writes until FIFO becomes full
   - checks `wr_full` assertion

4. **Overflow Attempt Test**
   - attempts a write when FIFO is already full
   - checks that state does not change incorrectly

5. **Drain Test**
   - reads until FIFO becomes empty
   - checks ordering and `rd_empty`

6. **Underflow Attempt Test**
   - attempts a read from an empty FIFO
   - verifies no illegal state change

7. **Simultaneous Read/Write Test**
   - performs concurrent valid read and write
   - checks pointer and count behavior

8. **Pointer Wrap-Around Test**
   - repeatedly performs operations to force pointer wrap-around
   - checks data integrity across boundary conditions

---

## 7. How to Run

### Using Icarus Verilog

From the project root, compile with:

```bash
iverilog -g2012 -o fifo_sim rtl/sync_fifo.v rtl/sync_fifo_top.v tb/tb_sync_fifo.v
```

Run the simulation with:

```bash
vvp fifo_sim
```

### Optional waveform dump
If waveform viewing is desired, a VCD dump can be added to the testbench using:

```verilog
initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, tb_sync_fifo);
end
```
```

Then open the waveform using GTKWave:

```bash
gtkwave fifo.vcd
```

Note: waveform inspection is optional; the primary verification is done by the self-checking scoreboard, as required by the assignment. fileciteturn0file0

---

## 8. Expected Simulation Output

On a successful run, the testbench should print messages similar to:

```text
Starting FIFO Automated Verification...
PASS: Reset Test
PASS: Single Write / Read Test
PASS: Fill Test (FIFO is now full)
PASS: Overflow Attempt Test
PASS: Drain Test (FIFO is now empty)
PASS: Underflow Attempt Test
PASS: Simultaneous Read/Write Test
PASS: Pointer Wrap-Around Test
SIMULATION COMPLETE: ALL TESTS PASSED
Coverage Summary:
...
```

If an error occurs, the scoreboard prints a detailed failure report and stops simulation immediately.

---

## 9. Notes on the Current Implementation

- The FIFO is implemented as a **single-clock synchronous FIFO**.
- Reset is **active-low synchronous reset**.
- The top module uses `ADDR_WIDTH = $clog2(DEPTH)`.
- The testbench is **self-checking**, which satisfies the assignment requirement that manual waveform inspection must not be the primary validation method. fileciteturn0file0

---

## 10. Conclusion

This assignment demonstrates the complete RTL-to-verification flow for a synchronous FIFO:

- synthesizable FIFO RTL
- top-level DUT integration
- independent golden model
- automatic scoreboarding
- directed verification
- manual coverage tracking

The submission is structured to match the expected assignment deliverables and provides a reusable framework for validating similar FIFO-based hardware blocks.

---

## 11. Reference

Assignment brief: **Assignment 2: Synchronous FIFO & Verilog Testbench Techniques** fileciteturn0file0
