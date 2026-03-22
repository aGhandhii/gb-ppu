# Conditional Compilation Rules
WAVES           =
SIM             = verilator

# Setup
PROJ            = Project
BUILD_DIR       = ./build
SIM_DIR         = ./sim
SV2V_DIR        = ./sv2v
VERILATOR_DIR   = ./obj_dir
TEST_BIN        = $(SIM_DIR)/$(TOP).vvp
TEST_WAVE       = $(SIM_DIR)/$(TOP).fst
TEST_LOG        = $(SIM_DIR)/$(TOP).log

# RTL Files
TOP             =
TESTBENCH       = ./test/$(TOP).sv
RTL_FILES       = $(shell find ./inc -name '*.sv') $(shell find ./src -name '*.sv')

# Synthesis Files
PCF             = icebreaker.pcf

.PHONY: synth timing prog sv2v test clean

synth: $(BUILD_DIR)/$(PROJ).asc $(BUILD_DIR)/$(PROJ).bin
	# Store build files separately
	mkdir -p $(BUILD_DIR)
	# Synthesis -> Yosys with slang for SystemVerilog
	yosys -m slang -f slang -p "synth_ice40 -top $(TOP) -blif $(BUILD_DIR)/$(PROJ).blif -json $(BUILD_DIR)/$(PROJ).json" $(RTL_FILES)
	# Place and Route -> NextPNR 
	nextpnr-ice40 --up5k --package sg48 --json build/$(PROJ).json --pcf $(PCF) --asc build/$(PROJ).asc
	# Convert to Bitstream -> IcePack
	icepack $(BUILD_DIR)/$(PROJ).asc $(BUILD_DIR)/$(PROJ).bin

timing: $(BUILD_DIR)/$(PROJ).asc
	icetime -d up5k $(BUILD_DIR)/$(PROJ).asc

prog: $(BUILD_DIR)/$(PROJ).bin
	iceprog $(BUILD_DIR)/$(PROJ).bin

sv2v:
ifeq ($(SIM), icarus)
	# Convert SystemVerilog to Verilog - needed for Icarus
	mkdir -p $(SV2V_DIR)
	sv2v --write=$(SV2V_DIR) --top=$(TOP) $(TESTBENCH) $(RTL_FILES)
endif

test: sv2v
	mkdir -p $(SIM_DIR)
ifeq ($(SIM), icarus)
	# Simulate the design with Icarus
	iverilog -o $(TEST_BIN) -s $(TOP) $(shell find ./sv2v -name '*.v')
	# Run simulation results
	vvp -l $(TEST_LOG) -n $(TEST_BIN) -fst
ifdef WAVES
	# Loading Waveform
	mv $(TOP).fst $(TEST_WAVE) &> /dev/null
endif
else ifeq ($(SIM), verilator)
	# Verilate the design
ifdef WAVES
	verilator -CFLAGS -fcoroutines --binary --timing --trace-structs --trace-params --trace-fst --assert --top-module $(TOP) $(RTL_FILES) $(TESTBENCH)
else
	verilator -CFLAGS -fcoroutines --binary --timing --assert --top-module $(TOP) $(RTL_FILES) $(TESTBENCH)
endif
	# Dump the simulation log
	$(VERILATOR_DIR)/V$(TOP) > $(TEST_LOG)
	cat $(TEST_LOG)
ifdef WAVES
	mv $(TOP).fst $(TEST_WAVE) &> /dev/null
endif
endif

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SIM_DIR)
	rm -rf $(SV2V_DIR)
	rm -rf $(VERILATOR_DIR)
