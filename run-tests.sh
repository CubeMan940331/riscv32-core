#!/bin/bash
# compile testbench executable
make

riscv_test_dir="/opt/riscv/target/share/riscv-tests"
file_dir="./testing/"
result_list="00_test_result.txt"

printf '' > "$file_dir$result_list"

for mem_file in $(ls $file_dir*.mem); do
    test_name=$(basename $mem_file)
    test_name=${test_name%.*}

    pass_pc=$(cat "$file_dir$test_name.dump" | grep '<pass>:' | cut -c 2-8)
    if [ ! -z $pass_pc ]; then
        pass_pc=$(printf "%d" "0x$pass_pc")
    fi
    
    printf "%-30s" "$test_name"
    printf "%-16s" "pass_pc=$pass_pc"
    ./obj_dir/VComputer "$mem_file" "$pass_pc"

done
