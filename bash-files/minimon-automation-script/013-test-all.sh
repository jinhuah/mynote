#!/bin/bash

# Run all tests in this directory

test_pkg=$1
script_dir=$(cd $(dirname $0)/../$test_pkg && pwd)
output_dir="/mnt/mirimon-regression-test"
pass_list="$output_dir/test_pass_list.txt"
fail_list="$output_dir/test_fail_list.txt"

[[ -d $output_dir ]] || mkdir -p $output_dir
[[ -f $pass_list ]] || touch $pass_list
[[ -f $fail_list ]] || touch $fail_list

test_count=0
pass_count=0
fail_count=0

failed_test=""
passed_test=""

pushd $script_dir

for test_file in $(find . -mindepth 1 -maxdepth 1 -type f | cut -d"/" -f2 | sort )
do
    sudo ./$test_file

    if [ $? -eq 0 ]; then
        echo -e "\e[32mtest '$test_file' passed\e[0m"
        let "pass_count++"
		passed_tests="$passed_tests $test_file"
		echo $test_file >> $pass_list
    else
        echo -e "\e[31mtest '$test_file' failed\e[0m"
        let "fail_count++"
        failed_tests="$failed_tests $test_file"
		echo $test_file >> $fail_list
    fi

    let "test_count++"
done

popd 

echo ""
echo "Summary:"
echo " tests  $test_count"
echo " passed $pass_count"
echo " failed $fail_count"
echo ""

if [ $fail_count -ne 0 ]; then
    echo -e "\e[31mTests Failed\e[0m"
    for test in $failed_tests
    do
        echo -e "\e[31m $test\e[0m"
    done
else
    echo -e "\e[32mTests Passed\e[0m"
fi 