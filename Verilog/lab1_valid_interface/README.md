# Lab 1: Valid Interface

## Overview
This lab demonstrates the basic valid interface protocol for data transfer between modules.

## Objective
- Understand valid-based handshaking
- Implement pipeline stages with proper signal propagation
- Learn RTL coding structure and organization

## Directory Structure
```
lab1_valid_interface/
├── rtl/              # RTL source files
│   └── basic.v       # Main design module
├── testbench/        # Testbench files
│   └── basic_tb.v    # Testbench for basic module
├── filelist.f        # File list for compilation
├── Makefile          # Build automation
└── README.md         # This file
```

## Getting Started

### Prerequisites
- Xilinx Vivado (xvlog, xelab, xsim)
- Basic understanding of Verilog
- Make utility

### Quick Start
1. **Syntax Check**
   ```bash
   make complie
   ```
   Quickly verifies Verilog syntax without elaboration.

2. **Elaboration**
   ```bash
   make elab
   ```
   Checks module hierarchy and port connections.

3. **Run Simulation**
   ```bash
   make sim
   ```
   Launches GUI for waveform analysis.

### Make Targets
| Target       | Description                           |
|--------------|---------------------------------------|
| `compile`    | Compile Verilog files (syntax check)  |
| `elab`       | Elaborate design (check hierarchy)    |
| `sim`        | Run simulation with GUI               |
| `sim-batch`  | Run simulation without GUI            |
| `check`      | Quick syntax verification             |
| `all`        | Complete flow (compile + elab + sim)  |
| `clean`      | Remove generated files                |
| `help`       | Show available commands               |

## File Management
- **Add RTL files**: Edit `rtl/` directory and update `filelist.f`
- **Add testbenches**: Edit `testbench/` directory and update `filelist.f`
- **Modify filelist**: Edit `filelist.f` to add/remove source files

## Design Details

### Module: basic
- **Type**: Valid interface example
- **Pipeline Stages**: 3 stages (Stage 0, 1, 2)
- **Interface**: Clock, reset, valid signals with data

### Coding Structure
The RTL follows a structured template:
1. **Signal Declarations** - Organized by pipeline stage
   - Combinational signals (intermediate values)
   - Sequential signals (actual flip-flops)
2. **Combinational Logic** - Use `always @(*)` or `assign` statements
3. **Sequential Logic** - Use `always @(posedge clk)` for registers
4. **Output Assignment** - Final output connections

## Tips
- Always run `make clean` before starting fresh compilation
- Use `make check` frequently during development
- Review waveforms in GUI to verify functionality

## Common Issues
- **Compilation Error**: Check file paths in `filelist.f`
- **Elaboration Error**: Verify module hierarchy and port connections
- **Simulation Issues**: Ensure testbench is properly written

## Notes
- Output signals should be registered (no combinational outputs)
- Follow the emoji coding convention:
  - 🟩: Stage markers
  - 🟧: Combinational logic
  - 🟦: Sequential logic

## Design Philosophy

### Explicit Pipeline Stage Separation
This template uses an **explicit, verbose structure** to clearly separate each pipeline stage. While this could be simplified with more compact code, we deliberately choose this approach for the following reasons:

**Why explicit separation?**
- **Clarity**: Each pipeline stage is clearly visible and easy to understand
- **Maintainability**: Easy to modify individual stages without affecting others
- **Learning**: Helps beginners understand pipeline structure and data flow
- **Debugging**: Simplifies identifying which stage has issues

**Future Enhancement**
In later labs, we will introduce **`generate` blocks** to simplify repetitive pipeline stages. This will demonstrate:
- How to write parameterized, scalable pipeline code
- Using generate loops for cleaner, more maintainable designs
- Balancing between verbosity and elegance

For now, focus on understanding the fundamentals through explicit stage-by-stage coding.
