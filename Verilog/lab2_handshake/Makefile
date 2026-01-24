# Makefile for Verilog simulation using Vivado simulator
# Usage:
#   make compile  - Compile Verilog files (syntax check)
#   make elab     - Elaborate design (check module hierarchy)
#   make sim      - Run simulation with GUI
#   make clean    - Clean generated files
#   make all      - Run all steps (compile, elaborate, simulate)

# Filelist - Edit filelist.f to add/remove source files
FILELIST = filelist.f
TOP_MODULE = basic_tb

# Simulation directories and files
WORK_DIR = xsim.dir
SNAPSHOT = $(TOP_MODULE)_snapshot
WDB_FILE = $(TOP_MODULE).wdb

# Vivado simulator commands
XVLOG = xvlog
XELAB = xelab
XSIM = xsim

# Compiler flags
XVLOG_FLAGS = -sv
XELAB_FLAGS = --debug typical --mt auto -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip
XSIM_FLAGS = --gui --wdb $(WDB_FILE)

# Default target
.PHONY: all
all: compile elab sim

# Step 1: Compile - Check syntax errors
.PHONY: compile
compile:
	@echo "========================================="
	@echo "Step 1: Compiling Verilog files..."
	@echo "========================================="
	$(XVLOG) $(XVLOG_FLAGS) -f $(FILELIST)
	@echo ""
	@echo "Compilation successful - No syntax errors"
	@echo ""

# Step 2: Elaborate - Check module hierarchy and connections
.PHONY: elab
elab: compile
	@echo "========================================="
	@echo "Step 2: Elaborating design..."
	@echo "========================================="
	$(XELAB) $(XELAB_FLAGS) -top $(TOP_MODULE) -snapshot $(SNAPSHOT)
	@echo ""
	@echo "Elaboration successful - Module hierarchy is correct"
	@echo ""

# Step 3: Simulate - Run simulation with waveform GUI (auto-run)
.PHONY: sim
sim: elab
	@echo "========================================="
	@echo "Step 3: Running simulation with GUI..."
	@echo "========================================="
	@echo "add_wave {{/basic_tb/*}}" > sim.tcl
	@echo "run all" >> sim.tcl
	$(XSIM) $(SNAPSHOT) -gui -wdb $(WDB_FILE) -tclbatch sim.tcl -log simulate.log &

# Run simulation in batch mode without GUI (optional)
.PHONY: sim-batch
sim-batch: elab
	@echo "========================================="
	@echo "Running simulation in batch mode..."
	@echo "========================================="
	$(XSIM) $(SNAPSHOT) -runall

# Quick syntax check only
.PHONY: check
check: compile
	@echo "Syntax check completed"

# Clean up generated files
.PHONY: clean
clean:
	@echo "Cleaning up generated files..."
	rm -rf $(WORK_DIR)
	rm -rf *.jou *.log *.pb *.wdb *.tcl
	rm -rf .Xil
	rm -rf webtalk*
	@echo "Clean complete"

# Help
.PHONY: help
help:
	@echo "Verilog Simulation Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make compile    - Compile Verilog files (syntax check)"
	@echo "  make elab       - Elaborate design (check module connections)"
	@echo "  make sim        - Run simulation with waveform GUI"
	@echo "  make sim-batch  - Run simulation without GUI"
	@echo "  make check      - Quick syntax check only"
	@echo "  make all        - Run complete flow (compile + elab + sim)"
	@echo "  make clean      - Remove all generated files"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "File management:"
	@echo "  Edit 'filelist.f' to add or remove source files"
	@echo ""
	@echo "Typical workflow:"
	@echo "  1. make check      # Quick syntax verification"
	@echo "  2. make elab       # Verify module hierarchy"
	@echo "  3. make sim        # Run simulation and view waveforms"
