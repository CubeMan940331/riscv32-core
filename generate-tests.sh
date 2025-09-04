#!/usr/bin/env bash
riscv_toolchain="riscv32-unknown-elf-"
if [ $(riscv64-unknown-elf-gcc --print-multi-lib | grep rv32imaf) ];then
    riscv_toolchain="riscv64-unknown-elf-"
fi
if [ ! $(which "${riscv_toolchain}gcc") ];then
    echo "${riscv_toolchain}gcc not found"
    echo "check if riscv gnu toolchain is properly installed"
    exit 1
fi
echo "using ${riscv_toolchain}gcc"

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
    "${riscv_toolchain}objdump" -d -s -x $1 > "$file_dir$test_name.dump"
    
    # objcopy
    "${riscv_toolchain}objcopy" -O binary $1 "$file_dir$test_name.elfcopy"

    # generate .mem file
    # source binary is little endian
    # for little endian mem
    xxd -b -c 4 "$file_dir$test_name.elfcopy" | awk '{print $2 "\n" $3 "\n" $4 "\n" $5}' > "$file_dir$test_name.mem"
    # for big endian mem
    # xxd -b -c 4 "$file_dir$test_name.elfcopy" | awk '{print $5 "\n" $4 "\n" $3 "\n" $2}' > "$file_dir$test_name.mem"
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
