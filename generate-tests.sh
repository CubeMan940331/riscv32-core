#!/bin/bash
riscv_test_dir="/opt/riscv/target/share/riscv-tests"
file_dir="./testing/"
test_list="00_test_list.txt"

if [ ! -d $file_dir ]; then
    mkdir $file_dir
fi

# all rv32 with different extension tests
# rv32mi: machine-level
# rv32ua: atomic
# rv32uc: compressed
# rv32ud: double-precision floating-point
# rv32uf: single-precision floating-point
# rv32ui: base integer
# rv32um: integer multiplication and division
# rv32uzba: B address generation
# rv32uzbb: B basic bit-manipulation
# rv32uzbc: B carry-less multiplication
# rv32uzbs: B single-bit manipulation
# rv32uzfh: half-precision floating-point

# spike setting
isa_setting="rv32imf"
priv_setting="mu"

# generate 00_test_list.txt if it does not exist
if [ ! -e "$file_dir$test_list" ]; then
    echo "$isa_setting $priv_setting" > "$file_dir$test_list"
    for target in $(ls $riscv_test_dir/isa/rv32[um][imf]-p-* | grep -v '\.dump$'); do
        echo $target >> "$file_dir$test_list"
    done
fi

gen_test(){
    test_name=$(basename $1)
    echo $test_name
    
    # objdump
    riscv32-unknown-elf-objdump -d -s -x $1 > "$file_dir$test_name.dump"
    
    # objcopy
    riscv32-unknown-elf-objcopy -O binary $1 "$file_dir$test_name.elfcopy"

    # get inst. count
    section_size=$(riscv32-unknown-elf-readelf -S $1 | grep ".text.init" | awk '{print $7}')
    section_size=$(printf "%d" "0x$section_size")
    inst_cnt=$(printf "%d" $(("$section_size/4")))

    # generate .mem file
    xxd -b -c 4 "$file_dir$test_name.elfcopy" | head -n $inst_cnt | awk '{print $5 "\n" $4 "\n" $3 "\n" $2}' > "$file_dir$test_name.mem"
    rm "$file_dir$test_name.elfcopy"

    # generate spike log
    spike -l --log="$file_dir$test_name.log" --isa="$isa_setting" --misaligned --priv="$priv_setting" $1
}

# load 00_test_list.txt
spike_setting=$(head -n 1 "$file_dir$test_list")
echo $spike_setting
isa_setting=$(echo $spike_setting | cut -d ' ' -f 1)
priv_setting=$(echo $spike_setting | cut -d ' ' -f 2)

for target in $(tail -n +2 $file_dir$test_list); do
    gen_test $target
done
