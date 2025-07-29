#!/bin/bash
riscv_test_dir="/opt/riscv/target/share/riscv-tests"
file_dir="./testing/"

if [ ! -d $file_dir ]; then
    mkdir $file_dir
fi

gen_test(){
    file_name=$(basename $1)    
    echo $file_name
    
    cat "$1.dump" > "$file_dir$file_name.dump"
    
    # objcopy
    riscv32-unknown-elf-objcopy -O binary $1 "$file_dir$file_name.elfcopy"

    # get inst. count
    section_size=$(riscv32-unknown-elf-readelf -S $1 | grep ".text.init" | awk '{print $7}')
    section_size=$(printf "%d" "0x$section_size")
    inst_cnt=$(printf "%d" $(("$section_size/4")))

    # generate .mem file
    xxd -b -c 4 "$file_dir$file_name.elfcopy" | head -n $inst_cnt | awk '{print $5 "\n" $4 "\n" $3 "\n" $2}' > "$file_dir$file_name.mem"
    rm "$file_dir$file_name.elfcopy"

    # generate spike log
    spike -l --log="$file_dir$file_name.log" --isa=rv32i --misaligned --priv=mu $1
}

# get test list
for target in $(ls $riscv_test_dir/isa/rv32[um]*-p-* | grep -v '\.dump$'); do
    gen_test $target
done
