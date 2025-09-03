.PHONY: all clean verilate

TOP       := Computer
TB        := example_testbench.cpp
SRC_DIRS  := mul_div_modules fpu_modules bp_modules alu_modules lsu_modules mmu_modules
VERILATOR := verilator
VFLAGS    := -Wall --cc --trace -j 0 --default-language 1364-2001 -Wno-unused -Wno-pinconnectempty
VFLAGS    += $(addprefix -y ,$(SRC_DIRS))
OBJ_DIR   := obj_dir
CFLAGS    := -std=c++17

all: $(OBJ_DIR)/V$(TOP)

$(OBJ_DIR)/V$(TOP).mk: $(wildcard *.v) $(TB)
	$(VERILATOR) $(VFLAGS) $(TOP).v --exe $(TB) -CFLAGS $(CFLAGS)

verilate: $(OBJ_DIR)/V$(TOP).mk

$(OBJ_DIR)/V$(TOP): $(OBJ_DIR)/V$(TOP).mk
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP).mk

clean:
	rm -rf $(OBJ_DIR)