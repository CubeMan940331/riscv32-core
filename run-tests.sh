#!/bin/bash
# compile testbench executable
make

riscv_test_dir="/opt/riscv/target/share/riscv-tests"
file_dir="./testing/"

for target in $(ls $riscv_test_dir/isa/rv32ui-p-* | grep -v '\.dump$'); do
    target=$(basename $target)
    echo $target

    pass_pc=$(cat "$file_dir$target.dump" | grep '<pass>:' | cut -c 2-8)
    pass_pc=$(printf "%d" "0x$pass_pc")
    
    ./obj_dir/VComputer "$file_dir$target.mem" &
done
