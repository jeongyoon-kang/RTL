# Makefile for Lab3 RTL Simulation Case Studies using Vivado Simulator
# Delta Cycles and Assignment Types

# Filelist
FILELIST = filelist.f

# Simulation directories and files
WORK_DIR = xsim.dir
WDB_DIR = wdb

# Vivado simulator commands
XVLOG = xvlog
XELAB = xelab
XSIM = xsim

# Compiler flags
XVLOG_FLAGS = -sv
XELAB_FLAGS = --debug typical --mt auto -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip

# Directories
RTL_DIR = rtl
TB_DIR = testbench

# RTL Files
DUT = $(RTL_DIR)/basic.v

# Testbench modules
TB_CASE1A = case1a_tb
TB_CASE1B = case1b_tb
TB_CASE2A = case2a_tb
TB_CASE2B = case2b_tb
TB_CASE3A = case3a_tb
TB_CASE3B = case3b_tb
TB_CASE4A = case4a_tb
TB_CASE4B = case4b_tb

# Snapshots
SNAP_CASE1A = $(TB_CASE1A)_snapshot
SNAP_CASE1B = $(TB_CASE1B)_snapshot
SNAP_CASE2A = $(TB_CASE2A)_snapshot
SNAP_CASE2B = $(TB_CASE2B)_snapshot
SNAP_CASE3A = $(TB_CASE3A)_snapshot
SNAP_CASE3B = $(TB_CASE3B)_snapshot
SNAP_CASE4A = $(TB_CASE4A)_snapshot
SNAP_CASE4B = $(TB_CASE4B)_snapshot

# WDB files
WDB_CASE1A = $(WDB_DIR)/$(TB_CASE1A).wdb
WDB_CASE1B = $(WDB_DIR)/$(TB_CASE1B).wdb
WDB_CASE2A = $(WDB_DIR)/$(TB_CASE2A).wdb
WDB_CASE2B = $(WDB_DIR)/$(TB_CASE2B).wdb
WDB_CASE3A = $(WDB_DIR)/$(TB_CASE3A).wdb
WDB_CASE3B = $(WDB_DIR)/$(TB_CASE3B).wdb
WDB_CASE4A = $(WDB_DIR)/$(TB_CASE4A).wdb
WDB_CASE4B = $(WDB_DIR)/$(TB_CASE4B).wdb

# Default target
.PHONY: all
all: case1 case2 case3 case4

# Compile all sources
.PHONY: compile
compile:
	@echo "================================================================"
	@echo "Compiling RTL and Testbench files..."
	@echo "================================================================"
	$(XVLOG) $(XVLOG_FLAGS) $(DUT)
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE1A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE1B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE2A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE2B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE3A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE3B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE4A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE4B).v
	@echo "Compilation successful"
	@echo ""

# Case 1: Assignment after clock edge
.PHONY: case1 case1a case1b
case1: case1a case1b

case1a: compile
	@echo "================================================================"
	@echo "Case 1A: Blocking assignment after @(posedge clk)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE1A) -snapshot $(SNAP_CASE1A)
	@echo "add_wave {{/$(TB_CASE1A)/*}}" > case1a_sim.tcl
	@echo "add_wave {{/$(TB_CASE1A)/u_dut/*}}" >> case1a_sim.tcl
	@echo "run all" >> case1a_sim.tcl
	$(XSIM) $(SNAP_CASE1A) -gui -wdb $(WDB_CASE1A) -tclbatch case1a_sim.tcl -log case1a_simulate.log &

case1b: compile
	@echo "================================================================"
	@echo "Case 1B: Non-blocking assignment after @(posedge clk)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE1B) -snapshot $(SNAP_CASE1B)
	@echo "add_wave {{/$(TB_CASE1B)/*}}" > case1b_sim.tcl
	@echo "add_wave {{/$(TB_CASE1B)/u_dut/*}}" >> case1b_sim.tcl
	@echo "run all" >> case1b_sim.tcl
	$(XSIM) $(SNAP_CASE1B) -gui -wdb $(WDB_CASE1B) -tclbatch case1b_sim.tcl -log case1b_simulate.log &

# Case 2: Assignment before clock edge
.PHONY: case2 case2a case2b
case2: case2a case2b

case2a: compile
	@echo "================================================================"
	@echo "Case 2A: Blocking assignment before @(posedge clk)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE2A) -snapshot $(SNAP_CASE2A)
	@echo "add_wave {{/$(TB_CASE2A)/*}}" > case2a_sim.tcl
	@echo "add_wave {{/$(TB_CASE2A)/u_dut/*}}" >> case2a_sim.tcl
	@echo "run all" >> case2a_sim.tcl
	$(XSIM) $(SNAP_CASE2A) -gui -wdb $(WDB_CASE2A) -tclbatch case2a_sim.tcl -log case2a_simulate.log &

case2b: compile
	@echo "================================================================"
	@echo "Case 2B: Non-blocking assignment before @(posedge clk)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE2B) -snapshot $(SNAP_CASE2B)
	@echo "add_wave {{/$(TB_CASE2B)/*}}" > case2b_sim.tcl
	@echo "add_wave {{/$(TB_CASE2B)/u_dut/*}}" >> case2b_sim.tcl
	@echo "run all" >> case2b_sim.tcl
	$(XSIM) $(SNAP_CASE2B) -gui -wdb $(WDB_CASE2B) -tclbatch case2b_sim.tcl -log case2b_simulate.log &

# Case 3: Initial block
.PHONY: case3 case3a case3b
case3: case3a case3b

case3a: compile
	@echo "================================================================"
	@echo "Case 3A: Blocking assignment in initial block"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE3A) -snapshot $(SNAP_CASE3A)
	@echo "add_wave {{/$(TB_CASE3A)/*}}" > case3a_sim.tcl
	@echo "add_wave {{/$(TB_CASE3A)/u_dut/*}}" >> case3a_sim.tcl
	@echo "run all" >> case3a_sim.tcl
	$(XSIM) $(SNAP_CASE3A) -gui -wdb $(WDB_CASE3A) -tclbatch case3a_sim.tcl -log case3a_simulate.log &

case3b: compile
	@echo "================================================================"
	@echo "Case 3B: Non-blocking assignment in initial block"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE3B) -snapshot $(SNAP_CASE3B)
	@echo "add_wave {{/$(TB_CASE3B)/*}}" > case3b_sim.tcl
	@echo "add_wave {{/$(TB_CASE3B)/u_dut/*}}" >> case3b_sim.tcl
	@echo "run all" >> case3b_sim.tcl
	$(XSIM) $(SNAP_CASE3B) -gui -wdb $(WDB_CASE3B) -tclbatch case3b_sim.tcl -log case3b_simulate.log &

# Case 4: Clocked always block
.PHONY: case4 case4a case4b
case4: case4a case4b

case4a: compile
	@echo "================================================================"
	@echo "Case 4A: Blocking in always @(posedge clk) - RACE CONDITION"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4A) -snapshot $(SNAP_CASE4A)
	@echo "add_wave {{/$(TB_CASE4A)/*}}" > case4a_sim.tcl
	@echo "add_wave {{/$(TB_CASE4A)/u_dut/*}}" >> case4a_sim.tcl
	@echo "run all" >> case4a_sim.tcl
	$(XSIM) $(SNAP_CASE4A) -gui -wdb $(WDB_CASE4A) -tclbatch case4a_sim.tcl -log case4a_simulate.log &

case4b: compile
	@echo "================================================================"
	@echo "Case 4B: Non-blocking in always @(posedge clk) - CORRECT"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4B) -snapshot $(SNAP_CASE4B)
	@echo "add_wave {{/$(TB_CASE4B)/*}}" > case4b_sim.tcl
	@echo "add_wave {{/$(TB_CASE4B)/u_dut/*}}" >> case4b_sim.tcl
	@echo "run all" >> case4b_sim.tcl
	$(XSIM) $(SNAP_CASE4B) -gui -wdb $(WDB_CASE4B) -tclbatch case4b_sim.tcl -log case4b_simulate.log &

# Batch mode simulations (without GUI)
.PHONY: batch1a batch1b batch2a batch2b batch3a batch3b batch4a batch4b
batch1a: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE1A) -snapshot $(SNAP_CASE1A)
	$(XSIM) $(SNAP_CASE1A) -runall -log case1a_batch.log

batch1b: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE1B) -snapshot $(SNAP_CASE1B)
	$(XSIM) $(SNAP_CASE1B) -runall -log case1b_batch.log

batch2a: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE2A) -snapshot $(SNAP_CASE2A)
	$(XSIM) $(SNAP_CASE2A) -runall -log case2a_batch.log

batch2b: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE2B) -snapshot $(SNAP_CASE2B)
	$(XSIM) $(SNAP_CASE2B) -runall -log case2b_batch.log

batch3a: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE3A) -snapshot $(SNAP_CASE3A)
	$(XSIM) $(SNAP_CASE3A) -runall -log case3a_batch.log

batch3b: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE3B) -snapshot $(SNAP_CASE3B)
	$(XSIM) $(SNAP_CASE3B) -runall -log case3b_batch.log

batch4a: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4A) -snapshot $(SNAP_CASE4A)
	$(XSIM) $(SNAP_CASE4A) -runall -log case4a_batch.log

batch4b: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4B) -snapshot $(SNAP_CASE4B)
	$(XSIM) $(SNAP_CASE4B) -runall -log case4b_batch.log

# Clean
.PHONY: clean
clean:
	@echo "Cleaning up generated files..."
	rm -rf $(WORK_DIR)
	rm -rf $(WDB_DIR)
	rm -rf *.jou *.log *.pb *.wdb *.tcl
	rm -rf .Xil
	rm -rf webtalk*
	@echo "Clean complete"

# Help
.PHONY: help
help:
	@echo "================================================================"
	@echo "Lab3 RTL Simulation - Makefile Help"
	@echo "================================================================"
	@echo "Available targets:"
	@echo ""
	@echo "  all          - Run all case studies (opens multiple GUIs)"
	@echo ""
	@echo "  case1        - Run Case 1A and 1B (assignment after clock edge)"
	@echo "  case1a       - Run Case 1A (blocking) with GUI"
	@echo "  case1b       - Run Case 1B (non-blocking) with GUI"
	@echo ""
	@echo "  case2        - Run Case 2A and 2B (assignment before clock edge)"
	@echo "  case2a       - Run Case 2A (blocking) with GUI"
	@echo "  case2b       - Run Case 2B (non-blocking) with GUI"
	@echo ""
	@echo "  case3        - Run Case 3A and 3B (initial block)"
	@echo "  case3a       - Run Case 3A (blocking) with GUI"
	@echo "  case3b       - Run Case 3B (non-blocking) with GUI"
	@echo ""
	@echo "  case4        - Run Case 4A and 4B (clocked always block)"
	@echo "  case4a       - Run Case 4A (blocking - RACE CONDITION) with GUI"
	@echo "  case4b       - Run Case 4B (non-blocking - CORRECT) with GUI"
	@echo ""
	@echo "  batch[X]     - Run case X in batch mode without GUI"
	@echo "                 (e.g., batch1a, batch1b, batch2a, etc.)"
	@echo ""
	@echo "  compile      - Compile all RTL and testbench files"
	@echo "  clean        - Remove generated files"
	@echo "  help         - Show this help message"
	@echo "================================================================"
	@echo ""
	@echo "Typical workflow:"
	@echo "  1. make case1a      # Run Case 1A with waveform GUI"
	@echo "  2. make case1b      # Compare with Case 1B"
	@echo "  3. Analyze waveforms to observe timing differences"
	@echo "================================================================"
