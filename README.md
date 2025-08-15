# riscv32-core

run `make` to compile the testbench binary `./obj_dir/VComputer`
run it to simulate the CPU with `TEST_INSTRUCTIONS.txt` and produce `waveform.vcd`

## Testing

`./obj_dir/VComputer` can take two arguments, mem_file and end_pc
If mem_file is set, instructions will be load in inst mem.
If end_pc is set, the program print "Yes" or "No" to indicate if it reach end_pc,
"Done" is always printed otherwise.

### riscv-tests
assume that **riscv-gnu-toolchain** and **riscv-tests** are installed in default location

running `generate-test.sh` will generate the following files in `./testing`
according to `./testing/00_test_list.txt`,
auto generated with defaults if file doesn't exist.

- .dump  
the same file in **riscv-tests** isa tests
- .log
produced by riscv isa sim **spike**, for comparison
- .mem
converted from the binary, for simulation
