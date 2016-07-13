#!/bin/bash

# Check processes running/not running after installation
declare processes=( \
"siamang Running" \
"mmsubtraps Running" \
"mmregiontraps Running" \
"mmregionagent Running" \
"push-output Running" \
"export-jobs Running" \
"mirimon-dancer Running" \
"iptv-sim Not monitored" \
"hoolock Running" \
"hls-sim Not monitored" \
"dvb-sim Not monitored" \
"concolor Running" \
"agile-default Running" )

IFS=""
count=0

for process in "${processes[@]}"
do

    if [[ -z $(monit summary | grep $(echo "$process" | cut -d" " -f1) | grep $(echo "$process" | cut -d" " -f2) ) ]]
    then
        echo "Expect: $process"
        echo "But: $(monit summary | grep $(echo "$process" | cut -d" " -f1))"
        count=$(($count+1))
    fi
done

if [[ $count -ne 0 ]]
then 
    echo "Test failed! $count process status are not as expected"
	exit 1
fi

echo "Test passed"