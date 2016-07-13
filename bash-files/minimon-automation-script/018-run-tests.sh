#!/bin/bash

# This script is to run the tests directly on the machine, no need through vagrant. 
# It will run all tests listed in "tests" array.

[[ -d /mnt/mirimon-regression-test ]] && rm -r /mnt/mirimon-regression-test/*

declare -a tests=( \
"provisioning" \
"content-tracking" \
"db-tools" \
"exporter" \
"geolookup" \
"login-string" \
"server-tools" \
"server" \
"dancer" \
"check-install" \
)

for test_pkg in ${tests[@]}
do 
    echo "Run test \"$test_pkg\""
    ./test-all.sh $test_pkg
done

./report_test_results.sh
