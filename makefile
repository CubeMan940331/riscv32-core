.PHONY: main clean

main: clean
	verilator -Wall -Wno-UNUSEDSIGNAL --cc PipelineCPU.v --exe example_testbench.cpp --trace
	make -C obj_dir -f VPipelineCPU.mk VPipelineCPU
	./obj_dir/VPipelineCPU

clean:
	rm -rf obj_dir
	rm -f waveform.vcd

