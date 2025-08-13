# Makefile for Verilator FPU Simulation

# --- Tool Configuration ---
ifeq ($(VERILATOR_ROOT),)
VERILATOR_ROOT = /usr/local/share/verilator
endif

# --- Project Configuration ---
TOP_MODULE = FPU_Top
TB_CPP = tb_fpu.cpp
SIM_EXE = V$(TOP_MODULE)

# --- Verilog Source Files ---
VERILOG_SOURCES = \
    SP_Encoder.v DP_Encoder.v \
    SP_Decoder.v DP_Decoder.v \
    SP_Adder.v DP_Adder.v \
	SP_Compare.v DP_Compare.v \
	SP_Convert.v DP_Convert.v \
	SP_Multiplier.v DP_Multiplier.v \
	SP_Divider.v DP_Divider.v \
    ../FPU_Top.v

# --- Verilator Flags ---
VERILATOR_FLAGS = --cc --exe --trace -Wall -Wno-UNUSED -Wno-pinconnectempty

# --- 目標 ---
all: $(SIM_EXE)

$(SIM_EXE): obj_dir/V$(TOP_MODULE).mk
	@echo "Linking C++ model..."
	@make -C obj_dir -f V$(TOP_MODULE).mk

obj_dir/V$(TOP_MODULE).mk: $(VERILOG_SOURCES) $(TB_CPP)
	@echo "Verilating $(TOP_MODULE)..."
	@verilator $(VERILATOR_FLAGS) $(VERILOG_SOURCES) --top-module $(TOP_MODULE) --exe $(TB_CPP)

run: $(SIM_EXE)
	@echo "Running simulation..."
	@./obj_dir/$(SIM_EXE)

wave:
	@echo "Opening waveform..."
	@gtkwave waveform.vcd

clean:
	@echo "Cleaning up..."
	@rm -rf obj_dir
	@rm -f waveform.vcd
	@rm -f $(SIM_EXE)

clear:
	@make clean
	@clear
	@make run

.PHONY: all run wave clean clear
