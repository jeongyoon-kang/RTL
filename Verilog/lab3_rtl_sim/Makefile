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
TB_BASIC1 = basic1_tb
TB_BASIC2 = basic2_tb
TB_CASE1A = case1a_tb
TB_CASE1B = case1b_tb
TB_CASE2A = case2a_tb
TB_CASE2B = case2b_tb
TB_CASE3A = case3a_tb
TB_CASE3B = case3b_tb
TB_CASE4A = case4a_tb
TB_CASE4B = case4b_tb
TB_CASE4C = case4c_tb

# Snapshots
SNAP_BASIC1 = $(TB_BASIC1)_snapshot
SNAP_BASIC2 = $(TB_BASIC2)_snapshot
SNAP_CASE1A = $(TB_CASE1A)_snapshot
SNAP_CASE1B = $(TB_CASE1B)_snapshot
SNAP_CASE2A = $(TB_CASE2A)_snapshot
SNAP_CASE2B = $(TB_CASE2B)_snapshot
SNAP_CASE3A = $(TB_CASE3A)_snapshot
SNAP_CASE3B = $(TB_CASE3B)_snapshot
SNAP_CASE4A = $(TB_CASE4A)_snapshot
SNAP_CASE4B = $(TB_CASE4B)_snapshot
SNAP_CASE4C = $(TB_CASE4C)_snapshot

# WDB files
WDB_BASIC1 = $(WDB_DIR)/$(TB_BASIC1).wdb
WDB_BASIC2 = $(WDB_DIR)/$(TB_BASIC2).wdb
WDB_CASE1A = $(WDB_DIR)/$(TB_CASE1A).wdb
WDB_CASE1B = $(WDB_DIR)/$(TB_CASE1B).wdb
WDB_CASE2A = $(WDB_DIR)/$(TB_CASE2A).wdb
WDB_CASE2B = $(WDB_DIR)/$(TB_CASE2B).wdb
WDB_CASE3A = $(WDB_DIR)/$(TB_CASE3A).wdb
WDB_CASE3B = $(WDB_DIR)/$(TB_CASE3B).wdb
WDB_CASE4A = $(WDB_DIR)/$(TB_CASE4A).wdb
WDB_CASE4B = $(WDB_DIR)/$(TB_CASE4B).wdb
WDB_CASE4C = $(WDB_DIR)/$(TB_CASE4C).wdb

# Default target
.PHONY: all
all: background case1 case2 case3 case4

# Compile all sources
.PHONY: compile
compile:
	@echo "================================================================"
	@echo "Compiling RTL and Testbench files..."
	@echo "================================================================"
	$(XVLOG) $(XVLOG_FLAGS) $(DUT)
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_BASIC1).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_BASIC2).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE1A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE1B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE2A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE2B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE3A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE3B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE4A).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE4B).v
	$(XVLOG) $(XVLOG_FLAGS) $(TB_DIR)/$(TB_CASE4C).v
	@echo "Compilation successful"
	@echo ""

# Background: Understanding @(posedge clk) placement
.PHONY: background basic1 basic2
background: basic1 basic2

basic1: compile
	@echo "================================================================"
	@echo "Background Example 1: @(posedge clk) BEFORE assignment"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_BASIC1) -snapshot $(SNAP_BASIC1)
	@echo "add_wave {{/$(TB_BASIC1)/*}}" > basic1_sim.tcl
	@echo "add_wave {{/$(TB_BASIC1)/u_dut/*}}" >> basic1_sim.tcl
	@echo "run all" >> basic1_sim.tcl
	$(XSIM) $(SNAP_BASIC1) -gui -wdb $(WDB_BASIC1) -tclbatch basic1_sim.tcl -log basic1_simulate.log &

basic2: compile
	@echo "================================================================"
	@echo "Background Example 2: Assignment BEFORE @(posedge clk)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_BASIC2) -snapshot $(SNAP_BASIC2)
	@echo "add_wave {{/$(TB_BASIC2)/*}}" > basic2_sim.tcl
	@echo "add_wave {{/$(TB_BASIC2)/u_dut/*}}" >> basic2_sim.tcl
	@echo "run all" >> basic2_sim.tcl
	$(XSIM) $(SNAP_BASIC2) -gui -wdb $(WDB_BASIC2) -tclbatch basic2_sim.tcl -log basic2_simulate.log &

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

# Case 3: Inactive Region - Time delay effect
.PHONY: case3 case3a case3b
case3: case3a case3b

case3a: compile
	@echo "================================================================"
	@echo "Case 3A: Blocking without time delay (RACE CONDITION)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE3A) -snapshot $(SNAP_CASE3A)
	@echo "add_wave {{/$(TB_CASE3A)/*}}" > case3a_sim.tcl
	@echo "add_wave {{/$(TB_CASE3A)/u_dut/*}}" >> case3a_sim.tcl
	@echo "run all" >> case3a_sim.tcl
	$(XSIM) $(SNAP_CASE3A) -gui -wdb $(WDB_CASE3A) -tclbatch case3a_sim.tcl -log case3a_simulate.log &

case3b: compile
	@echo "================================================================"
	@echo "Case 3B: Blocking with #1 delay (RACE-FREE)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE3B) -snapshot $(SNAP_CASE3B)
	@echo "add_wave {{/$(TB_CASE3B)/*}}" > case3b_sim.tcl
	@echo "add_wave {{/$(TB_CASE3B)/u_dut/*}}" >> case3b_sim.tcl
	@echo "run all" >> case3b_sim.tcl
	$(XSIM) $(SNAP_CASE3B) -gui -wdb $(WDB_CASE3B) -tclbatch case3b_sim.tcl -log case3b_simulate.log &

# Case 4: Monitor Region - System task timing
.PHONY: case4 case4a case4b case4c
case4: case4a case4b case4c

case4a: compile
	@echo "================================================================"
	@echo "Case 4A: Using $display (Active Region)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4A) -snapshot $(SNAP_CASE4A)
	@echo "add_wave {{/$(TB_CASE4A)/*}}" > case4a_sim.tcl
	@echo "add_wave {{/$(TB_CASE4A)/u_dut/*}}" >> case4a_sim.tcl
	@echo "run all" >> case4a_sim.tcl
	$(XSIM) $(SNAP_CASE4A) -gui -wdb $(WDB_CASE4A) -tclbatch case4a_sim.tcl -log case4a_simulate.log &

case4b: compile
	@echo "================================================================"
	@echo "Case 4B: Using $strobe (Monitor Region)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4B) -snapshot $(SNAP_CASE4B)
	@echo "add_wave {{/$(TB_CASE4B)/*}}" > case4b_sim.tcl
	@echo "add_wave {{/$(TB_CASE4B)/u_dut/*}}" >> case4b_sim.tcl
	@echo "run all" >> case4b_sim.tcl
	$(XSIM) $(SNAP_CASE4B) -gui -wdb $(WDB_CASE4B) -tclbatch case4b_sim.tcl -log case4b_simulate.log &

case4c: compile
	@echo "================================================================"
	@echo "Case 4C: Using $monitor (Monitor Region, Automatic)"
	@echo "================================================================"
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4C) -snapshot $(SNAP_CASE4C)
	@echo "add_wave {{/$(TB_CASE4C)/*}}" > case4c_sim.tcl
	@echo "add_wave {{/$(TB_CASE4C)/u_dut/*}}" >> case4c_sim.tcl
	@echo "run all" >> case4c_sim.tcl
	$(XSIM) $(SNAP_CASE4C) -gui -wdb $(WDB_CASE4C) -tclbatch case4c_sim.tcl -log case4c_simulate.log &

# Batch mode simulations (without GUI)
.PHONY: batchbasic1 batchbasic2 batch1a batch1b batch2a batch2b batch3a batch3b batch4a batch4b batch4c

batchbasic1: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_BASIC1) -snapshot $(SNAP_BASIC1)
	$(XSIM) $(SNAP_BASIC1) -runall -log basic1_batch.log

batchbasic2: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_BASIC2) -snapshot $(SNAP_BASIC2)
	$(XSIM) $(SNAP_BASIC2) -runall -log basic2_batch.log

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

batch4c: compile
	@mkdir -p $(WDB_DIR)
	$(XELAB) $(XELAB_FLAGS) -top $(TB_CASE4C) -snapshot $(SNAP_CASE4C)
	$(XSIM) $(SNAP_CASE4C) -runall -log case4c_batch.log

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
	@echo "Lab3 RTL Simulation - Delta Cycles and Assignment Types"
	@echo "================================================================"
	@echo "Available targets:"
	@echo ""
	@echo "  all          - Run all case studies (background + case1-4)"
	@echo ""
	@echo "BACKGROUND: Understanding @(posedge clk) placement"
	@echo "  background   - Run basic1 and basic2"
	@echo "  basic1       - @(posedge clk) BEFORE assignment"
	@echo "  basic2       - Assignment BEFORE @(posedge clk)"
	@echo ""
	@echo "CASE 1: Active vs NBA Region (assignment after @(posedge clk))"
	@echo "  case1        - Run Case 1A and 1B"
	@echo "  case1a       - Blocking (RACE CONDITION)"
	@echo "  case1b       - Non-blocking (RACE-FREE)"
	@echo ""
	@echo "CASE 2: Assignment Location (assignment before @(posedge clk))"
	@echo "  case2        - Run Case 2A and 2B"
	@echo "  case2a       - Blocking (STILL RACE!)"
	@echo "  case2b       - Non-blocking (RACE-FREE)"
	@echo ""
	@echo "CASE 3: Inactive Region (time delay effect)"
	@echo "  case3        - Run Case 3A and 3B"
	@echo "  case3a       - Blocking without delay (RACE)"
	@echo "  case3b       - Blocking with #1 delay (RACE-FREE)"
	@echo ""
	@echo "CASE 4: Monitor Region (system task timing)"
	@echo "  case4        - Run Case 4A, 4B, and 4C"
	@echo "  case4a       - Using $display (Active Region)"
	@echo "  case4b       - Using $strobe (Monitor Region)"
	@echo "  case4c       - Using $monitor (Monitor Region, Auto)"
	@echo ""
	@echo "BATCH MODE: Run without GUI"
	@echo "  batch[X]     - Run case X in batch mode"
	@echo "                 (e.g., batchbasic1, batch1a, batch4c, etc.)"
	@echo ""
	@echo "OTHER:"
	@echo "  compile      - Compile all RTL and testbench files"
	@echo "  clean        - Remove generated files"
	@echo "  help         - Show this help message"
	@echo "================================================================"
	@echo ""
	@echo "Recommended workflow:"
	@echo "  1. make background  # Understand for-loop patterns first"
	@echo "  2. make case1       # See Active vs NBA region"
	@echo "  3. make case2       # See that code order doesn't matter"
	@echo "  4. make case3       # See time delay effect"
	@echo "  5. make case4       # See Monitor region system tasks"
	@echo "================================================================"
