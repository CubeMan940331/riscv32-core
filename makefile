.PHONY: clean verilate

default: obj_dir/VComputer

obj_dir/VComputer.mk: *.v
# generate makefile for example_testbench.cpp
	verilator -Wall -Wno-unused -Wno-pinconnectempty --cc Computer.v --exe example_testbench.cpp --trace -j 0 -y mul_div_modules -y fpu_modules -y bp_modules -y alu_modules --default-language 1364-2001

verilate: obj_dir/VComputer.mk

obj_dir/VComputer: obj_dir/VComputer.mk example_testbench.cpp
# compile testbench
	make -C obj_dir -f VComputer.mk

clean:
	rm -rf obj_dir
