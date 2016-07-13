#!/bin/bash

# channel stop: 162
# vod_stop: 252
# dvb_channel_stop: 361

if [[ $@ -ne 0 ]]
then
    channel_ext_ref=$1
    vod_ext_ref=$2
    dvb_channel_ext_ref=$3
else
    channel_ext_ref=1111
    vod_ext_ref=45008
    dvb_channel_ext_ref=509
fi
i=1

. /opt/mirimon/bin/miriserv_env.inc >/dev/null 

while true
do 
    # Stop device1-10 to watch channel
    if [[ $i -le 10 ]]
    then
        se=162
        hash=$(mmfnv $channel_ext_ref)
        hex=$(printf "%x" $hash)
        r0=$hex
        r1=FFFFFFFF    
    else
        # Stop device11-20 to watch vod
        if [[ $i -gt 10 && $i -le 20 ]]
        then 
            se=252
            hash=$(mmfnv $vod_ext_ref)
            hex=$(printf "%x" $hash)
            r0=FFFFFFFF
            r1=$hex
        else
            # Stop device21-30 to watch dvb channel
            if [[ $i -gt 20 && $i -le 30 ]]
            then 
                se=361
                hash=$(mmfnv $dvb_channel_ext_ref)
                hex=$(printf "%x" $hash)
                r0=$hex
                r1=FFFFFFFF
            else
                break
            fi
        fi
    fi
  
    curl -s -X POST "http://localhost/mirimon/cgi-bin/sigevent.pl" --data a=se --data m=$i --data di=$se --data df=50000 --data dt=$(date +%s) --data dms=637 --data d0=00000008 \
        --data d1=00000001 --data d2=00000002 --data d3=08010200 --data r0=$r0 --data r1=$r1 --data r2=00000002 --data r3=00000019 >/dev/null
        
    i=$(($i+1))
        
done

