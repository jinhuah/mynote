#!/bin/bash

# restful file: /usr/share/mirimon-dancer/dancer-rest-service.pl

if [[ $# -eq 0 ]]
then 
    server="localhost"
else
    server=$1
fi

which jsonlint > /dev/null || apt-get -y install python-demjson >/dev/null

outputDir="/mnt/mirimon-regression-test/$(basename $(pwd))/restful-$(date +%Y%m%d_%H%M)"
[[ -d $outputDir ]] || mkdir -p $outputDir

currentTime=$(date +%s)
previousTime=$(($currentTime - 3600))

# Simulator has to be running at the time of the test
if ( ! dpkg -l | grep -q "ii  mirimon-simulator" )
then
    echo "mirimon-simulator is not installed"
    exit 1
fi

monit summary | grep -q "Process 'iptv-sim'                  Not monitored" && monit start iptv-sim
monit summary | grep -q "Process 'hls-sim'                   Not monitored" && monit start hls-sim
monit summary | grep -q "Process 'dvb-sim'                   Not monitored" && monit start dvb-sim

while ( monit summary | grep sim | grep -q "Not monitored" )
do
    # If simulator not running before, give a bit time to run. 
    # So more data will be injected to the database.
    sleep 10
done

sleep 60
monit summary

# Place all restful api into an array.  
# "channels/ip/status/2083305497" - 2083305497 is channel_number from content_channel table.
# The channel number based on the channel.xml which provisioning to the database.

declare -a restfulAll=( \
"channels/broadcast/list" \
"channels/broadcast/popularity" \
"channels/broadcast/status/882421979" \
"channels/ip/list" \
"channels/ip/popularity" \  
"channels/ip/status/2083305497" \
"cos/list" \
"cos/status/0" \
"devices/Simulator1/broadcast/av-qos" \
"devices/Simulator1/configuration" \
"devices/Simulator1/cpu-load" \
"devices/Simulator1/cpu-load?max_results=2" \
"devices/Simulator1/cpu-load?start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/events" \
"devices/Simulator1/events?event_type=82" \
"devices/Simulator1/events?max_result=20" \
"devices/Simulator1/events?max_result=3" \
"devices/Simulator1/events?severity=5" \
"devices/Simulator1/events?severity=5&start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/events?severity=7" \
"devices/Simulator1/events?start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/events?start_epoch=$previousTime&end_epoch=$currentTime&severity=5&max_result=1" \
"devices/Simulator1/events?start_epoch=$previousTime&end_epoch=$currentTime&severity=5&max_result=1&type=82" \
"devices/Simulator1/information" \
"devices/Simulator1/installation" \
"devices/Simulator1/ip/av-qos" \
"devices/Simulator1/ip/network/qos" \
"devices/Simulator1/ip-channel-start-up-time" \
"devices/Simulator1/ip-channel-start-up-time?start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/memory-use" \
"devices/Simulator1/memory-use?max_results=3" \
"devices/Simulator1/memory-use?start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/net-traffic-ip" \
"devices/Simulator1/net-traffic-ip?max_results=4" \
"devices/Simulator1/net-traffic-ip?start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/service-faults" \
"devices/Simulator1/service-faults?max_results=5" \
"devices/Simulator1/service-faults?start_epoch=$previousTime&end_epoch=$currentTime" \
"devices/Simulator1/stats" \
"devices/Simulator2/vod/av-qos" \
"devices/Simulator2/vod-start-up-time" \
"devices/Simulator2/vod-start-up-time?max_results=6" \
"devices/Simulator2/vod-start-up-time?start_epoch=$previousTime&end_epoch=$currentTime" \
"kpis/broadcast/av-qos" \
"kpis/broadcast/timings" \
"kpis/devices/counts" \
"kpis/ip/av-qos" \
"kpis/ip/network-qos" \
"kpis/ip/timings" \
"kpis/rates/status" \
"kpis/vod/av-qos" \
"kpis/vod/timings" \
"network-elements/list/mds" \
"network-elements/type-list" \
"subscribers/list-all" \
"subscribers/search?subscriber_id=Simulator12" \
"subscribers/search?device_uid=Simulator12" \
"subscribers/search?ip_address=0.0.0.0" \
"system-alarms" \
"txmux/list" \
"vod-assets/list" \
"vod-assets/popularity" \
"vod-assets/status/2924382558" \
"vod-servers/list" \
"vod-servers/status/10.0.0.1" \
)

# Install jsonlint if not exists
which jsonlint > /dev/null || apt-get install jsonlint

i=0
touch $outputDir/faillist.txt
for rest in ${restfulAll[@]}
do
    tmpName=$(echo $rest | tr "\/|\?|\=|\&" -).json
    curl -s -X GET "http://$server:3000/$rest" > $outputDir/$tmpName
    jsonlint $outputDir/$tmpName
    if [[ $? -ne 0 ]]
    then 
        i=$(($i+1))
        echo "Fail$i: $rest ---------------- $outputDir/$tmpName"
        echo "$i: $rest   ------   $tmpName" >> $outputDir/faillist.txt
    fi
done

monit stop iptv-sim
monit stop hls-sim
monit stop dvb-sim

if [[ $i -ne 0 ]]
then 
    echo "json validataion failed."
	exit 1
else
    echo "Test passed."
fi
