#!/bin/bash

output_dir="/mnt/mirimon-regression-test"
pass_list="$output_dir/test_pass_list.txt"
fail_list="$output_dir/test_fail_list.txt"

pass_count=$(cat $pass_list | wc -l)
fail_count=$(cat $fail_list | wc -l)

echo ""
echo "======================================"
echo "Total tests run: $(($pass_count+$fail_count))"
echo " Passes:     $pass_count "
echo " Failures:   $fail_count"
echo ""

if [[ $fail_count -eq 0 ]] 
then 
    echo -e "\e[32mTests Passed\e[0m"
	echo "======================================"
	exit 0
else
    echo -e "\e[31mTests Failed\e[0m"
	echo ""
	echo -e "\e[31mFailure tests below:\e[0m"
	cat "$fail_list"
	echo "======================================"
	exit 1
fi 