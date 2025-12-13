# RTL Design Labs

A collection of hands-on laboratory exercises for learning RTL (Register Transfer Level) design using Verilog and SystemVerilog.

## Overview

This repository provides structured lab exercises to learn digital design concepts through practical implementation. Each lab focuses on specific design patterns, coding practices, and verification techniques commonly used in modern RTL design.

## Repository Structure

```
RTL/
├── Verilog/              # Verilog-based labs
│   ├── lab1_valid_interface/
│   ├── lab2_handshake/
│   └── ...
├── SystemVerilog/        # SystemVerilog-based labs
│   └── ...
├── template_verilog.v    # RTL coding template
└── README.md             # This file
```

## Lab Organization

Each lab follows a consistent structure:

```
labN_topic_name/
├── rtl/              # RTL source files
├── testbench/        # Testbench files
├── filelist.f        # Compilation file list
├── Makefile          # Build automation
└── README.md         # Lab-specific documentation
```

## Prerequisites

### Tools
- **Xilinx Vivado** (for xvlog, xelab, xsim)
- **Make** utility
- Text editor or IDE

### Knowledge
- Basic digital logic concepts
- Verilog/SystemVerilog syntax fundamentals
- Understanding of clocks, resets, and sequential logic

## Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd RTL
```

### 2. Navigate to a Lab
```bash
cd Verilog/lab1_valid_interface
```

### 3. Read the Lab README
Each lab has its own README with specific objectives and instructions.

### 4. Run Simulation
```bash
make complie    # Quick syntax check
make elab     # Elaborate and check hierarchy
make sim      # Run simulation with GUI
make clean    # Clean generated files
```

## Verilog Labs

### Lab 1: Valid Interface
- **Topic**: Basic valid-based handshaking
- **Focus**: Pipeline stages, signal propagation
- **Difficulty**: Beginner

### Lab 2: Handshake Interface
- **Topic**: Ready/Valid handshaking protocol
- **Focus**: Backpressure handling, flow control
- **Difficulty**: Intermediate

## SystemVerilog Labs

*Coming soon*

## Coding Standards

### RTL Template
All RTL designs follow a structured template (`template_verilog.v`) that includes:
- **Header**: File information, author, version history
- **Signal Declarations**: Organized by pipeline stage
  - Combinational signals (intermediate values)
  - Sequential signals (actual flip-flops)
- **Combinational Logic**: Using `always @(*)` or `assign`
- **Sequential Logic**: Using `always @(posedge clk)`
- **Output Assignment**: Registered outputs only

### Coding Conventions
- 🟩 **Stage markers**: Identify pipeline stages
- 🟧 **Combinational logic**: Non-registered signals
- 🟦 **Sequential logic**: Registered signals (flip-flops)

### Design Philosophy
Labs intentionally use **explicit, verbose code** to:
- Clearly separate each pipeline stage
- Make data flow easy to understand
- Simplify debugging and maintenance
- Help beginners learn fundamental concepts

Advanced techniques (like `generate` blocks) will be introduced in later labs.

## Common Make Targets

All labs support these standard targets:

| Target       | Description                              |
|--------------|------------------------------------------|
| `compile`    | Compile Verilog files (syntax check)     |
| `elab`       | Elaborate design (check hierarchy)       |
| `sim`        | Run simulation with waveform GUI         |
| `sim-batch`  | Run simulation without GUI               |
| `check`      | Quick syntax verification                |
| `all`        | Complete flow (compile + elab + sim)     |
| `clean`      | Remove all generated files               |
| `help`       | Show available commands                  |

## Tips for Success

1. **Start Simple**: Begin with lab1 and progress sequentially
2. **Read Documentation**: Each lab's README contains important details
3. **Check Syntax Often**: Use `make check` during development
4. **Understand Before Coding**: Review the lab objectives first
5. **Analyze Waveforms**: Always verify your design in simulation
6. **Follow the Template**: Use the provided structure for consistency

## Contributing

Contributions are welcome! Please:
- Follow the existing lab structure
- Include comprehensive README for new labs
- Test all code before submitting
- Use the standard RTL template

## License

See [LICENSE](LICENSE) file for details.

## Resources

- [Verilog HDL Quick Reference](https://www.verilog.com/)
- [SystemVerilog LRM](https://standards.ieee.org/)
- [Vivado Simulator Documentation](https://www.xilinx.com/support/documentation/)

## Contact

For questions or suggestions, please open an issue in the repository.

---

**Happy Coding!** 🚀
