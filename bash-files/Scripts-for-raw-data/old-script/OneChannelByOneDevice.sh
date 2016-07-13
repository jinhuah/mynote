#!/bin/bash
# Author: Jinhua Huang

#######################################################################################
#                                                                                     #
#     How to run the script:                                                          #
#     .../ChannelWatchedbyDevice-script.sh "Channel-Name" "2013-XX-XX" "Device ID"    #
#     e.g: .../ChannelWatchedByDevice.sh "TEST CHANNEL" "2013-10-10" 4307             #
#                                                                                     #
#######################################################################################

# Verify data correctness from raw data - a channel watched by  one device
# Working directory is: /mnt/pipeline/p1_gen/work/s0_root/complete
WORKDIR=/mnt/pipeline/p1_gen/work/s0_root/complete
TESTTMP1=/tmp/test1
TESTTMP2=/tmp/test2
TESTTMP3=/tmp/test3

channelName=$1
DATE=$2
deviceID=$3

echo -e "Date: $DATE"

# Display hour, minute and second
function displayHHMMSS () {
if [[ $1 -gt 60 ]]
then
	h=$(($1/3600))
	m=$((($1/60)%60))
	s=$(($1%60))
	echo -e " ( $h hour $m min $s sec )\n"
fi
}

cd $WORKDIR

# Translate from a channel name to channel number
channelNumber=$(less channels-2013-10-* | grep -m 1 -a2 "$channelName" | sed  -n -r 's/(  <digits>)([0-9]{1,3}).*/\2/p')
echo -e "Channel Name: $channelName \nChannel Number: $channelNumber"
echo -e "Device ID: $3\n"

# Determine which raw files are used for data filtering
rawFiles="sig-event-long-term-2013-10"

# If only the month is given, then filter from whole month files. 
# awk command is to check how many fields are given. If 2, it is month. If 3, it is a day.
if [[ $( echo $DATE |  awk -F'-' '{print NF}') == 2 ]]
	then
		# Grep all events related to the channel number to test1 file
		less "$rawFiles"-*  | awk -F',' -v chlNum="$channelNumber" -v dID="$deviceID" '$2 ~ dID && $15 ~ chlNum ' > $TESTTMP1
	# If a date is given, filter events on the given day.
	else
		# Get the epoch start time and end time of "2013-10-10"
		START_TIME=$(date -d $2 +%s)
		END_TIME=$(date -d $2+"+1 day" +%s)
		# Get all events of the given day
		less "$rawFiles"-* | awk -F',' -v sTime="$START_TIME" -v eTime="$END_TIME" -v chlNum="$channelNumber" -v dID="$deviceID" '$2 ~ dID && $5 >= sTime && $5 < eTime && $15 ~ chlNum ' > $TESTTMP1
fi

declare -a durationBandCount=(0 0 0 0 0 0 0 0)
declare -a durationBandName[8]
durationBandName[0]="0 to 10 seconds"
durationBandName[1]="Between 10 seconds and 1 minute"
durationBandName[2]="Between 1 and 5 minutes"
durationBandName[3]="Between 5 and 15 minutes"
durationBandName[4]="Between 15 and 30 minutes"
durationBandName[5]="Between 30 and 60 minutes"
durationBandName[6]="Between 60 and 90 minutes" 
durationBandName[7]="Between 1.5 and 2.5 hours"

# Read lines one by one from test2 file and get start time and stop time
while read line ;
do
	# Get channel start time of the device	
	if [[ $(echo "$line" | cut -d ',' -f4 ) == "162" ]]
	then
		dStart=$(echo "$line" | cut -d ',' -f5)
		dStartH=$(date -ud \@$dStart)
	fi
	
	# Get channel stop time of the device
	if [[ $(echo "$line" | cut -d ',' -f4 ) == "161" ]]
	then
		dStop=$(echo "$line" | cut -d ',' -f5)
		dStopH=$(date -ud \@$dStop)			
	fi
	
	# Get duration 
	# if [[ $dStart != "" && $dStop == "" ]]
	# then 
		# echo -e "\ndevices$a: $i"	
		# echo "Start time is $dStart $dStartH, and stop time is $dStop"
	# fi
	if [[ $dStart != "" && $dStop -gt $dStart ]]
	then 
		duration=$(($dStop-$dStart))
		
		# if [[ $finalDuration == 0 || $finalDuration < $duration ]]
		# then 
			# finalDuration=$duration
		# fi
		
		# Record one device in different duration band. If it is in one band many time, it is only recorded once.
		case 1 in
			$(($duration > 0 && $duration < 10 )) )	# 0-10 seconds
				durationBandCount[0]=$((${durationBandCount[0]}+1));;
			$(($duration >=10 && $duration < 60 )) )	# 10sec to 1min
				durationBandCount[1]=$((${durationBandCount[1]}+1));;
			$(($duration >= 60 && $duration < 300  )) )	# 1min to 5min
				durationBandCount[2]=$((${durationBandCount[2]}+1));;
			$(($duration >= 300 && $duration < 900  )) )	# 5min to 15min
				durationBandCount[3]=$((${durationBandCount[3]}+1));;
			$(($duration >= 900 && $duration < 1800 )) )	# 15min to 30min
				durationBandCount[4]=$((${durationBandCount[4]}+1));;
			$(($duration >= 1800 && $duration < 3600 )) )	# 30min to 60min
				echo "30min to 60min"
				echo -e "Start time: $dStart $dStartH \nEnd time: $dStop $dStopH"
				echo -ne "Duration: $duration"
				displayHHMMSS $duration
				durationBandCount[5]=$((${durationBandCount[5]}+1));;
			$(($duration >= 3600 && $duration < 5400 )) )	# 60min to 90min
				echo "60min to 90min"
				echo -e "Start time: $dStart $dStartH \nEnd time: $dStop $dStopH"
				echo -ne "Duration: $duration" 
				displayHHMMSS $duration
				durationBandCount[6]=$((${durationBandCount[6]}+1));;
			$(($duration >= 5400 )) )	# More than 90min
				echo "More than 90min"
				echo -e "Start time: $dStart $dStartH \nEnd time: $dStop $dStopH"
				echo -ne "Duration: $duration"
				displayHHMMSS $duration
				durationBandCount[7]=$((${durationBandCount[7]}+1));;

		esac
		
		dStart=""
		dStop=""

	fi
			
done < $TESTTMP1

a=0
for i in ${durationBandCount[@]}
do 
	echo "${durationBandName[$a]}: $i"
	a=$(($a+1))
done


