#!/bin/bash

# Get siamang pid
pid=$(ps -ef | pgrep "siamang")

# Kill siamang process
kill -9 $pid

count=0
while ! monit summary | grep "siamang" | grep -q "Does not exist"
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

# Siamang should be recover after a few second
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

echo "siamang started after $count seconds."
echo "Test passed!"