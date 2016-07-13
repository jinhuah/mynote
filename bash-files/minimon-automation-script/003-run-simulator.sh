#!/bin/bash
# Use this script to assign seconds to run the simulator. 600sec = 10 mins
# Usage: 005-run-simulator.sh 600

if [[ $# = 0 ]]
then
    runTime=360
else
    runTime=$1
fi

if ( ! dpkg -l | grep -q "ii  mirimon-simulator" )
then
    echo "mirimon-simulator is not installed"
    exit 1
fi

monit summary

# Start simulator
monit start iptv-sim
monit start hls-sim
monit start dvb-sim

while true
do
    if ( monit summary  | grep -q "Process 'iptv-sim'                  Not monitored" )
    then
        sleep 1
    else
        if ( monit summary  | grep -q "Process 'hls-sim'                  Not monitored" )
        then
            sleep 1
        else 
            if ( monit summary  | grep -q "Process 'dvb-sim'                  Not monitored" )
            then
                sleep 1
            else
                break
            fi
        fi
    fi
done

monit summary

# Leave Mirimon simulator to run for 6 minutes
sleep $runTime

# Stop simulator
monit stop iptv-sim
monit stop hls-sim
monit stop dvb-sim

while true
do
    if ( monit summary  | grep -q "Process 'iptv-sim'                  Running" )
    then
        sleep 1
    else
        if ( monit summary  | grep -q "Process 'hls-sim'                  Running" )
        then
            sleep 1
        else 
            if ( monit summary  | grep -q "Process 'dvb-sim'                  Running" )
            then
                sleep 1
            else
                break
            fi
        fi
    fi
done

monit summary


