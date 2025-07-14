.PHONY: main clean

main: clean
	verilator -Wall --Wno-UNUSEDSIGNAL --cc Computer.v --exe example_testbench.cpp --trace -j 0
	make -C obj_dir -f VComputer.mk VComputer
	./obj_dir/VComputer

clean:
	rm -rf obj_dir
	rm -f waveform.vcd
