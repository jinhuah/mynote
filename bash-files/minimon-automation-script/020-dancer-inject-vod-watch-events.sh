#!/bin/bash

# two vod watching events, one has no error, one has errors
#  vod_start: 251
# video_started: 127
# audio_started: 128
# vod_started: 254
# av_video_underflow: 183
# vod_stop: 252

declare -a sig_event=(251 127 128 254)
declare -a sig_event_error=(251 127 128 254 183)

current_time=$(date +%s)

if [[ $@ -ne 0 ]]
then 
    vod_ext_ref=$1
else 
    vod_ext_ref=45008
fi

. /opt/mirimon/bin/miriserv_env.inc >/dev/null 
vod_hash=$(mmfnv $vod_ext_ref)
vod_hex=$(printf "%x" $vod_hash)

r0=FFFFFFFF
r1=$vod_hex

# Assign 3 devices ( from device 11 to device 18) watching vod without errors
for (( i=11; i<14; i++ ))
do
    for event in ${sig_event[@]}
    do
    curl -s -X POST "http://localhost/mirimon/cgi-bin/sigevent.pl" --data a=se --data m=$i --data di=$event --data df=50000 --data dt=$current_time --data dms=637 --data d0=00000008 \
        --data d1=00000001 --data d2=00000002 --data d3=08010200 --data r0=$r0 --data r1=$r1 --data r2=00000002 --data r3=00000019 >/dev/null
    done
done

# Assign 7 devices ( from device 19 to device 20) watching vod with errors
for (( i=14; i<=20; i++ ))
do
    for event in ${sig_event_error[@]}
    do
    curl -s -X POST "http://localhost/mirimon/cgi-bin/sigevent.pl" --data a=se --data m=$i --data di=$event--data df=50000 --data dt=$current_time --data dms=637 --data d0=00000008 \
        --data d1=00000001 --data d2=00000002 --data d3=08010200 --data r0=$r0 --data r1=$r1 --data r2=00000002 --data r3=00000019 >/dev/null
    done
done

sleep 30

# At the stage, the restful events are ready.
# Get the vod status and compare the expected results

expected_viewers_total="10"
expected_viewers_error="7"
json_output=$(curl -s -X GET "http://localhost:3000/vod-assets/status/$vod_hash")


# expected result should be similar to the below.
# {"status":[{"name":"Hollyoaks","tag":"2924382558","viewers_total":"10","viewers_error":"7"}]}

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