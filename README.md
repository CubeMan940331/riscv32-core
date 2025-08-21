# riscv32-core

run `make` to compile the testbench binary `./obj_dir/VComputer`
run it to simulate the CPU with `TEST_INSTRUCTIONS.txt` and produce `waveform.vcd`

## Testing

`./obj_dir/VComputer` can take four arguments, `mem_file`, `stop_pc`, `pass_pc`, and `fail_pc`
If `mem_file` is set, instructions will be load in inst mem.
If `stop_pc` is set, stop the simulation if it reachs it.
If `fail_pc` is set and reach it during the simulation, print `No`.
If `pass_pc` is set and reach it during the simulation, print `Yes`.
Print `Done` otherwise.

### prerequisites

- [**riscv-gnu-toolchain**](https://github.com/riscv-collab/riscv-gnu-toolchain)
for objcopy and objdump, or to generate binary for manual testcase
should be configured with `--enable-multilib` or `--with-arch=rv32imafc --with-abi=ilp32f`
- **spike**
a submodule of [**riscv-gnu-toolchain**](https://github.com/riscv-collab/riscv-gnu-toolchain)
- [**riscv-tests**](https://github.com/riscv-software-src/riscv-tests)

### riscv-tests

running `generate-test.sh` will generate the following files in `./testing`
according to `./testing/00_test_list.txt`,
auto generated with defaults if the file doesn't exist.

- .dump  
the same file in **riscv-tests** isa tests
- .log
produced by riscv isa sim **spike**, for comparison
- .mem
converted from the binary, for simulation

execute `run-tests.sh` compile `./obj_dir/VComputer` and
run the tests listed in `./testing/00_test_list.txt`
