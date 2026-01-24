# Lab 2: Handshake Interface (Valid-Ready Protocol)

## Overview
This lab demonstrates the AXI-style valid-ready handshake protocol for data transfer between modules with backpressure support.

## Objective
- Understand valid-ready handshaking mechanism
- Implement pipeline stages with backpressure handling
- Learn proper ready signal propagation through pipeline stages
- Debug and verify handshake protocol behavior using testbenches

## Directory Structure
```
lab2_handshake/
├── rtl/              # RTL source files
│   └── basic.v       # Main design module with handshake
├── testbench/        # Testbench files
│   ├── basic_tb.v    # Testbench for basic module
│   └── ref/          # Reference test vectors
│       ├── test_vector.c  # C program to generate test data
│       ├── input.txt      # Input test vectors
│       └── output.txt     # Expected output vectors
├── filelist.f        # File list for compilation
├── Makefile          # Build automation
└── README.md         # This file
```

## Getting Started

### Prerequisites
- Xilinx Vivado (xvlog, xelab, xsim) or Icarus Verilog
- Basic understanding of Verilog
- Understanding of Lab 1 (valid interface)
- Make utility

### Quick Start
1. **Syntax Check**
   ```bash
   make compile
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
- **Generate test vectors**: Run `gcc test_vector.c && ./a.out` in `testbench/ref/`

## Design Details

### Module: power
- **Type**: Handshake interface example (AXI-style valid-ready)
- **Pipeline Stages**: 3 stages (Stage 0, 1, 2)
- **Functionality**: Computes 8th power of input data (x^8 = x^2 × x^2 × x^2)
- **Interface**: Valid-ready handshake with backpressure support

### Handshake Protocol

#### Signal Naming Convention
- **Slave Interface (Input)**:
  - `s_valid`: Input data is valid
  - `s_data`: Input data
  - `s_ready`: Module is ready to accept data (output from this module)

- **Master Interface (Output)**:
  - `m_valid`: Output data is valid (output from this module)
  - `m_data`: Output data
  - `m_ready`: Downstream module is ready (input to this module)

#### Handshake Rules
1. **Data Transfer**: Occurs when both `valid` and `ready` are HIGH on clock edge
2. **Valid Signal**: Once asserted, must remain HIGH until handshake completes
3. **Ready Signal**: Can change at any time (backpressure control)
4. **No Combinational Path**: `ready` must not combinationally depend on `valid` from same interface

### Ready Signal Logic
```verilog
assign s_ready = !m_valid | m_ready;
```
- Module accepts input when:
  - Output is not valid (`!m_valid`), OR
  - Downstream is ready to accept output (`m_ready`)

### Coding Structure
The RTL follows a structured template:
1. **Signal Declarations** - Organized by pipeline stage
   - Combinational signals (intermediate values)
   - Sequential signals (actual flip-flops)
2. **Combinational Logic** - Ready signal and arithmetic operations
3. **Sequential Logic** - Registered valid and data signals
4. **Output Assignment** - Final output connections

## Testbench Features

### Test Vector Generation
The `testbench/ref/test_vector.c` generates:
- 1000 random input values
- Corresponding expected output values (input^8)
- Files: `input.txt` and `output.txt`

### Testbench Capabilities
- **Input Stimulus**: Drives `s_valid` and `s_data` from test vectors
- **Backpressure Testing**: Controls `m_ready` to test pipeline stalling
- **Output Checking**: Verifies `m_data` against expected values
- **Statistics**: Reports number of inputs sent and outputs received
- **Handshake Monitoring**: Tracks valid-ready handshakes

### Key Test Scenarios
1. **Continuous Flow**: Both `s_valid` and `m_ready` always HIGH
2. **Input Stalling**: `s_valid` toggled to test input acceptance
3. **Output Backpressure**: `m_ready` toggled to test pipeline stalling
4. **Mixed Scenarios**: Random toggling of control signals

## Tips
- Always run `make clean` before starting fresh compilation
- Use `make check` frequently during development
- Review waveforms to verify handshake behavior
- Check that data transfers only occur when both valid and ready are HIGH
- Verify that pipeline correctly handles backpressure

## Common Issues
- **No Data Transfer**: Check if both `valid` and `ready` are HIGH simultaneously
- **Data Corruption**: Verify that valid signals propagate correctly through stages
- **Pipeline Stalling**: Ensure ready signal logic is correct
- **Race Conditions**: Use non-blocking assignments (`<=`) in testbench initial blocks

## Important Debugging Notes

### Testbench Assignment Types
**CRITICAL**: When driving DUT inputs in testbench, the choice between blocking (`=`) and non-blocking (`<=`) assignments affects timing:

```verilog
// WRONG - Can cause race conditions
initial begin
    @(posedge clk);
    s_valid = 1'b1;  // Blocking: updates in Active region
    s_data = value;  // May conflict with DUT's clock edge
end

// CORRECT - Avoids race conditions
initial begin
    @(posedge clk);
    s_valid <= 1'b1;  // Non-blocking: updates in NBA region
    s_data <= value;  // Deterministic timing with DUT
end
```

**Why this matters**:
- DUT uses non-blocking assignments in `always @(posedge clk)` blocks
- Testbench blocking assignments execute in the same delta cycle
- This can cause undefined behavior and race conditions
- **Always use non-blocking (`<=`) when driving inputs after `@(posedge clk)`**

For more details on delta cycles and timing, see **Lab 3: RTL Simulation Timing**.

## Notes
- Output signals should be registered (no combinational outputs)
- Ready signals may be combinational (output of pipeline stages)
- Follow the emoji coding convention:
  - 🟩: Stage markers
  - 🟧: Combinational logic
  - 🟦: Sequential logic

## Design Philosophy

### Pipeline with Backpressure
This design demonstrates:
- **Handshake Protocol**: Industry-standard valid-ready mechanism
- **Backpressure Handling**: Pipeline can stall when downstream is not ready
- **Data Integrity**: Valid signals track data through the pipeline
- **No Data Loss**: All stages respect handshake protocol

### From Lab 1 to Lab 2
**Lab 1** used simple valid signals (no backpressure):
- Data always flows through pipeline
- No way to stall or apply backpressure
- Simpler but less flexible

**Lab 2** adds ready signals (backpressure support):
- Downstream can signal "not ready"
- Pipeline stalls appropriately
- More complex but production-ready

### Future Enhancement
In later labs, we will explore:
- **Skid buffers**: Improve timing by breaking ready path
- **FIFO interfaces**: Queue-based data transfer
- **AXI/AXI-Stream**: Full industry-standard protocols

## Reference
- AXI Protocol Specification (ARM IHI 0022E)
- Valid-Ready Handshake Protocol
- Pipeline Design with Backpressure
