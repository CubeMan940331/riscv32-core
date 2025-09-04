#!/usr/bin/env bash
# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Compile testbench executable
if ! make; then
    echo -e "${RED}Build failed. Stopping.${RESET}"
    exit 1
fi

file_dir="./testing/"
test_list="00_test_list.txt"
result_list="00_test_result.txt"

# Grouping results
declare -A ext_results   # 1 = all pass, 0 = fail
declare -A ext_details   # failed case logs

printf '' > "$file_dir$result_list"

for target in $(tail -n +2 $file_dir$test_list); do
    test_name=$(basename "$target")
    mem_file="$file_dir$test_name.mem"

    # Extract extension (adjust regex if needed)
    if [[ $test_name =~ rv32u([a-z]) ]]; then
        ext=${BASH_REMATCH[1]}
        ext=${ext^^}
    else
        ext="Zicsr"
    fi

    stop_pc=$(grep '<write_tohost>:' "$file_dir$test_name.dump" | cut -c 2-8)
    if [ -n "$stop_pc" ]; then
        stop_pc=$(printf "%d" "0x$stop_pc")
    fi

    pass_pc=$(grep '<pass>:' "$file_dir$test_name.dump" | cut -c 2-8)
    if [ -n "$pass_pc" ]; then
        pass_pc=$(printf "%d" "0x$pass_pc")
    fi

    fail_pc=$(grep '<fail>:' "$file_dir$test_name.dump" | cut -c 2-8)
    if [ -n "$fail_pc" ]; then
        fail_pc=$(printf "%d" "0x$fail_pc")
    fi

    output=$(./obj_dir/VComputer "$mem_file" "$stop_pc" "$pass_pc" "$fail_pc")

    if [ -z "${ext_results[$ext]}" ]; then
        ext_results[$ext]=1  # assume pass until proven fail
    fi

    if [[ "$output" != "Yes" ]]; then
        ext_results[$ext]=0
        ext_details[$ext]+=$(printf "%-30s %-16s %s\n" "$test_name" "pass_pc=$pass_pc" "$output\n")
    fi
done

# Print summary per extension
supported_exts="RV32"
echo -e "\n${CYAN}===== TEST SUMMARY =====${RESET}"
for ext in $(printf "%s\n" "${!ext_results[@]}" | sort); do
    if [ "${ext_results[$ext]}" -eq 1 ]; then
        echo -e "${GREEN}✔ $ext-extension PASS${RESET}"
        supported_exts+="$ext"
    else
        echo -e "${RED}✘ $ext-extension FAIL${RESET}"
        echo -e "${YELLOW}Failed instructions for $ext-extension:${RESET}"
        echo -e "${ext_details[$ext]}"
    fi
done

# Print supported extensions
echo -e "\n${CYAN}Supported extensions:${RESET} ${GREEN}$supported_exts${RESET}"
