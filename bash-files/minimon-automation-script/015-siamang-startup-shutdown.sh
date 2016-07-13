#!/bin/bash

# Check whether siamang is running. If not, start it.
monit summary | grep "siamang" | grep -q "Running"  || monit start "siamang"

count=0
while ! monit summary | grep "siamang" | grep -q "Running"
do
	sleep 1
	count=$(($count+1))
	if [[ $count -gt 60 ]]
	then
		echo "siamang still not running after 60 seconds. Test failed"
		monit summary
		exit 1
	fi
done

# Stop siamang
monit stop "siamang"

count=0
while ! monit summary | grep "siamang" | grep -q "Not monitored"
do
	sleep 1
	count=$(($count+1))
	if [[ $count -gt 60 ]]
	then
		echo "siamang still not stopped after 60 seconds. Test failed"
		monit summary
		exit 1
	fi
done

# Stop siamang again
monit start "siamang"

count=0
while ! monit summary | grep "siamang" | grep "Running"
do
	sleep 1
	count=$(($count+1))
	if [[ $count -gt 60 ]]
	then
		echo "siamang still not running after 60 seconds. Test failed"
		monit summary
		exit 1
	fi
done

echo "Test passed!"