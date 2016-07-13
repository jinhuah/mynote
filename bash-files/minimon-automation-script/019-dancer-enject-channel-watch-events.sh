#!/bin/bash

# two channel watching events, one has no error, one has errors
# channel start:160
# video_started: 127
# audio_started: 128
# channel started: 161
# av_video_underflow: 183
# channel stop: 162

declare -a sig_event=(160 127 128 161 162)
declare -a sig_event_error=(160 127 128 161 183 162)

current_time=$(date +%s)

# Set channel external reference
if [[ $@ -ne 0 ]]
then 
    channel_ext_ref=$1
else 
    channel_ext_ref=1111
fi

. /opt/mirimon/bin/miriserv_env.inc >/dev/null 
channel_hash=$(mmfnv $channel_ext_ref)
channel_hex=$(printf "%x" $channel_hash)
r0=$channel_hex
r1=FFFFFFFF

# 8 devices watching channel without errors
for (( i=1; i<9; i++ ))
do
    for event in ${sig_event[@]}
    do
    curl -s -X POST "http://localhost/mirimon/cgi-bin/sigevent.pl" --data a=se --data m=$i --data di=$event --data df=50000 --data dt=$current_time --data dms=637 --data d0=00000008 \
        --data d1=00000001 --data d2=00000002 --data d3=08010200 --data r0=$r0 --data r1=$r1 --data r2=00000002 --data r3=00000019 >/dev/null
    done
done

# 2 devices watching channel with errors
for (( i=9; i<=10; i++ ))
do
    for event in ${sig_event_error[@]}
    do
    curl -s -X POST "http://localhost/mirimon/cgi-bin/sigevent.pl" --data a=se --data m=$i --data di=$event--data df=50000 --data dt=$current_time --data dms=637 --data d0=00000008 \
        --data d1=00000001 --data d2=00000002 --data d3=08010200 --data r0=$r0 --data r1=$r1 --data r2=00000002 --data r3=00000019 >/dev/null
    done
done

sleep 30

# At the stage, the restful events are ready.
# Get the channel ip status and compare the expected results

expected_viewers_total="10"
expected_viewers_error="2"
json_output=$(curl -s -X GET "http://localhost:3000/channels/ip/status/$channel_hash")


# expected result should be similar to the below.
# {"status":[{"name":"100NL","tag":"509","viewers_total":"10","viewers_error":"3"}]}

a=0
# Get actual "viewers_total" and compare
if [[ $(echo "$json_output" | cut -d":" -f5 | cut -d"\"" -f2) != $expected_viewers_total ]]
then
    echo "Viewers total does not match, expected $expected_viewers_total, \
    but $(echo "$json_output" | cut -d":" -f5 | cut -d"\"" -f2). Test failed."
    a=$(($a+1))
fi

# Get actual "viewers_error" and compare
if [[ $(echo "$json_output" | cut -d":" -f6 | cut -d"\"" -f2) != $expected_viewers_error ]]
then
  echo "Viewers error does not match, expected $expected_viewers_error, \
  but $(echo "$json_output" | cut -d":" -f6 | cut -d"\"" -f2). Test failed."
  a=$(($a+1))
fi  

# If one of the numbers does not match, the test failed.
[[ $a -eq 0 ]] || exit 1