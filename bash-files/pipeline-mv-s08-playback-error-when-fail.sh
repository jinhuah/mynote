#!/bin/bash

count=0
while true;
do #
    echo "$(date +%y-%m-%d-%H-%M_%S)"
    pipeline summary-active
    if pipeline summary-active | grep stopped
    then
        if pipeline summary-active | grep stopped | grep s08_ref_playback_error_event_bl
        then
            count=$(($count+1))        
            mv /mnt/pipeline/p2_bulk/work/s08_ref_playback_error_event_bl/working_set/* \
            /mnt/pipeline/p2_bulk/work/s08_ref_playback_error_event_bl/discard/
            pipeline start all
        else
            pipeline summary-active
            echo "$count files have been moved."
            break
        fi
    fi
    
    if pipeline summary-active | grep idle
    then
        echo "pipeline process completed!"
        echo "$count files have been moved."
        break
    fi
    
    sleep 30

done