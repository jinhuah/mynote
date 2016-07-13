#!/bin/bash
# Author: Jinhua Huang

############################################################################
#                                                                          #
#         FILE:  CC00_functions.sh                                         #
#  DESCRIPTION:  This file contains all frequently used functions,         #  
#                which will be called by all other scripts.                #
#                It is a foundation of all scripts.                        #
#                                                                          #
############################################################################

# All function names are listed below
#
# getChannelNumber
# getDeviceIDs
# displayDeviceIDs
# getFileforDeviceIDs
# getFileforChannelDuration
# getStopTimeAcrossMidnight
# getChannelStartAndStopTime
# haveOneSessionTrueOrFalse
# getDeviceDurationBand
# displayTimeHHMMSS
# displayMoreThan10SecSessionDuration
# getFileOfChannelWatchedByAllDevices
# getSumOfDurationAndNumberOfSessions
# getSumOfDurationAndNumberOfDevices



# When a channel name is given, it will return the channel number
# Usage: getDeviceNumber "givenDate" "channelName"
function getChannelNumber(){
givenDate=$1
channelName=$2
if [[ -f channels-$givenDate-* ]]
then
	channelNumber=$(cat channels-$givenDate-* | grep -i -m 1 -a2 "$channelName" | sed  -n -r 's/(  <digits>)([0-9]{1,4}).*/\2/p')
else 
	channelNumber=$(cat channels-2013-* | grep -i -m 1 -a2 "$channelName" | sed  -n -r 's/(  <digits>)([0-9]{1,4}).*/\2/p')
fi

echo $channelNumber
}

# Get device IDs from a file
# Usage: getDeviceID  "file name" "array size"
# e.g. getDeviceID "/tmp/test1" 100
function getDeviceIDs(){
fileName=$1
dn=$2

declare -a devices[$dn]

while read line ;
do 
	deviceTmp=$(echo "$line" | cut -d ',' -f2)

	if [[ ${devices[$(($dn-1))]} == "" ]]
	then
	
		for (( i=0; i <= "$(($dn-1))" ; i++ ))
			do 
				if [[ ${devices[$i]} = $deviceTmp ]] 
				then 
					break
				else
					if [[ ${devices[$i]} == "" ]] 
					then
					devices[$i]=$deviceTmp
					break
					fi
				fi
			done
			
	else
		# Pass an empty string to array to indicate too many devices have been detected
		echo ""
		break
	fi
done < $fileName

echo ${devices[@]}
}

# Display device IDs
function displayDeviceID(){
# Display all device IDs
devices=("$@")

a=0
echo -e "\nDisplay all device IDs"
echo "-----"
echo ${devices[@]}

for i in ${devices[@]} ;
do 
	let a=a+1
done

echo -e "-----"
echo -e "Total $a devices\n"
}

# Generate a file for using to get device IDs
# Usage: getFileforDeviceIDs "givenDate" "channelNumber" "rawFiles" "outputFile"
# Example: getFileforDeviceIDs 2013-10-10 CCTV4 sig-event-long-term-2013-10 /tmp/test1
function getFileforDeviceIDs(){
givenDate=$1
channelNumber=$2
rawFiles=$3
outputFile=$4

# If only the month is given, then filter from whole month files, otherwise from the day.
# awk command is to check how many fields are given. If 2, it is month. If 3, it is a day.
if [[ $( echo $givenDate |  awk -F'-' '{print NF}') == 2 ]]
then
	# Grep all events related to the channel number to test1 file
	zcat "$rawFiles"-*  | awk -F',' -v chlNum="$channelNumber" '$15 == chlNum && $4 ~/16[1,2]/ ' > $outputFile
# If a date is given, filter events on the given day.
else
	# Get the epoch start time and end time of "2013-10-10"
	start_time=$(date -d $givenDate +%s)
	end_time=$(date -d $givenDate+"+1 day" +%s)
	# Get all events of the given day
	zcat "$rawFiles"-* | awk -F',' -v sTime="$start_time" -v eTime="$end_time" -v chlNum="$channelNumber" \
	'$5 >= sTime && $5 <= eTime && $15 == chlNum && $4 ~/16[1,2]/ ' > $outputFile
fi
}

# Generate a file which only contains deviceID and channel number from raw data.
# Usage: getFileforChannelDuration "givenDate" "channelNumber" "rawFiles" "deviceID" "outputFile"
# Example: getFileforChannelDuration "2013-10" 199 "sig-event-long-term-2013-10" 237 "/tmp/test22
function getFileforChannelDuration(){
givenDate=$1
channelNumber=$2
rawFiles=$3
deviceID=$4
outputFile=$5

# If only the month is given, then filter from whole month files, otherwise from the day.
# awk command is to check how many fields are given. If 2, it is month. If 3, it is a day.
if [[ $( echo $givenDate |  awk -F'-' '{print NF}') == 2 ]]
then
	# Grep all events related to the channel number and device to test1 file
	zcat "$rawFiles"-*  | awk -F',' -v chlNum="$channelNumber" -v dID="$deviceID" \
	'$2 == dID && $15 == chlNum && $17 ~ /1/' > $outputFile
	
# If a date is given, filter events on the given day.
else
	# Get the epoch start time and end time of "2013-10-10"
	start_time=$(date -d $givenDate +%s)
	end_time=$(date -d $givenDate+"+1 day" +%s)
	# Get all events related to the channel number and device to test1 file on the given day
	zcat "$rawFiles"-* | awk -F',' -v sTime="$start_time" -v eTime="$end_time" -v chlNum="$channelNumber" -v dID="$deviceID" \
	'$2 == dID && $5 >= sTime && $5 <= eTime && $15 ~ chlNum && $17 ~ /1/' >  $outputFile
fi
}

# Get channel stop time from the following day
# Usage: getStopTimeAcrossMidnight "start time"
# Example: getStopTimeAcrossMidnight 1381429195
function getStopTimeAcrossMidnight(){
channelStart=$1

# Search raw files to get the first line which is not 82 after last channel start time.
channelStop=$(zcat "$rawFiles"-* | awk -F',' -v chlNum="$channelNumber" -v dID="$i" -v cStartT="$channelStart" \
		'$2 == dID && $4 !/82/ && $5 >= cStartT && $15 == chlNum {print $5; exit;}')
event=$(zcat "$rawFiles"-* | awk -F',' -v chlNum="$channelNumber" -v dID="$i" -v cStartT="$channelStart" \
		'$2 == dID && $4 !/82/ && $5 >= cStartT && $15 == chlNum {print $4; exit;}')

if [[ $event != 161 ]]
then
# Search raw files to get the last 82 after start time and before stop tmp time, then get the stop time
	channelStop=$(zcat "$rawFiles"-* | awk -F',' -v chlNum="$channelNumber" -v dID="$i" -v cStartT="$channelStart" -v cStop_tmp="$channelStop" \
	'$2 == dID && $4 ~/82/ && $5 > cStartT && $5 < cStop_tmp && $15 == chlNum { f = $5 } END { print f }')
fi
echo $channelStop
}

# Get a channel start time and stop time from a line of a file. 
# Usage: getChannelStartAndStopTime "line" "file name" "given date"
# Output: $channelStart $channelStop
function getChannelStartAndStopTime() {
line=$1
fileName=$2
givenDate=$3
channelStart=$4
channelStop=$5

start_time=$(date -d $givenDate +%s)

local event=$(echo "$line" | cut -d ',' -f4 )
	
# Detect the event ID from line and get channel start time and stop time
case $event in
	162 ) channelStart=$(echo "$line" | cut -d ',' -f5) ;;			# Get channel start time of the device
	82  ) 															# Get the device heart beat time
		if [[ $channelStart == ""  && $heartbeat_first == "" ]] ; 								
		then 
			heartbeat_first=$(echo "$line" | cut -d ',' -f5)		# Keep first heart beat time if channel start time is empty
		else
			heartbeat_last=$(echo "$line" | cut -d ',' -f5)			# Get the last heart beat time
		fi ;;	
	161 ) channelStop=$(echo "$line" | cut -d ',' -f5) ;;			# Get channel stop time of the device
	*   ) channelStop=$heartbeat_last ;;							# Get the time of the device if the event is not in 162,161,82
esac

# Sign first heartbeat time to channelStart if heartbeat_first is within the first 10 minutes of the day start time 
# and channel stop time is not empty.
# This is to eliminate a channel start time in previous day.
if [[ $channelStart == ""  && $heartbeat_first > $(($start_time + 600)) && $channelStop != "" ]]
then 
	channelStart=$heartbeat_first
fi

# If it reaches the last line, a date is given and the start time is not empty, then get channel stop time from the following day.
if [[ $line == $(tail -1 $fileName) && $( echo $givenDate |  awk -F'-' '{print NF}') == 3 && $channelStart != "" && $channelStop == "" ]]
then 
	channelStop=$(getStopTimeAcrossMidnight $channelStart)
fi
echo "$channelStart $channelStop"
}

# Get one session of a device which is more than 10 sec, return "true" or "false"
# Usage: getOneSession "fileName" "givenDate"
function haveOneSessionTrueOrFalse(){
fileName=$1
givenDate=$2

# Set start time and stop time to none.
channelStart=""
channelStop=""

# Read lines one by one from test2 file and get start time and stop time
while read line || [[ -n $line ]] ;
do
	# Call the function getChannelStartAndStopTime to get the start and stop times
	channelStart=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f1)
	channelStop=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f2)
	
	# Compare the start and stop time and determine whether there is a session more than 10 sec. If is, break the loop.
	if [[ $channelStart != "" && $channelStop -gt $channelStart ]]
	then 
		if [[ $(($channelStop-$channelStart)) -ge 10 ]] 
		then
			channelStart=""
			channelStop=""
			heartbeat_last=""
			gotOneSession="true"
			break
		fi
	fi
	
done < $fileName
if [[ $gotOneSession == "true" ]] 
then 
	echo "true"
else
	echo "false"
fi
}

# Get a device sessions and assign first available session into correspond band
# Usage@ getDurationBand fileName givenDate
function getDeviceDurationBand(){
fileName=$1
givenDate=$2

declare -a durationBand=(0 0 0 0 0 0 0 0) 

# Set start time and stop time to empty
channelStart=""
channelStop=""

# Read lines one by one from test2 file and get start time and stop time
while read line || [[ -n $line ]] ;
do
	# Call the function getChannelStartAndStopTime to get the start and stop times
	channelStart=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f1)
	channelStop=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f2)
	
	# Get the duration and assign to each band.
	if [[ $channelStart != "" && $channelStop -gt $channelStart ]]
	then 
		duration=$(($channelStop-$channelStart))
				
		# Record one device in different duration band. If it is in one band many time, it is only recorded once.
		case 1 in
			$(($duration > 0 && $duration <= 10 && ${durationBand[0]} == 0 )) )	# 0-10 seconds
				durationBand[0]=$duration;;
			$(($duration >10 && $duration <= 60 && ${durationBand[1]} == 0  )) )	# 10sec to 1min
				durationBand[1]=$duration;;
			$(($duration > 60 && $duration <= 300  && ${durationBand[2]} == 0 )) )	# 1min to 5min
				durationBand[2]=$duration;;
			$(($duration > 300 && $duration <= 900 && ${durationBand[3]} == 0  )) )	# 5min to 15min
				durationBand[3]=$duration;;
			$(($duration > 900 && $duration <= 1800 && ${durationBand[4]} == 0 )) )	# 15min to 30min
				durationBand[4]=$duration;;
			$(($duration > 1800 && $duration <= 3600 && ${durationBand[5]} == 0 )) )	# 30min to 60min
				durationBand[5]=$duration;;
			$(($duration > 3600 && $duration <= 5400 && ${durationBand[6]} == 0 )) )	# 60min to 90min
				durationBand[6]=$duration;;
			$(($duration > 5400 && ${durationBand[7]} == 0 )) )	# More than 90min
				durationBand[7]=$duration;;
		esac
		
		# Reset start time and stop time after duration is calculated.
		dStart=""
		dStop=""
		
		# Stop read line when all durationBandTmp items are assigned.
		[[ ${durationBand[0]} == 0 || ${durationBand[1]} == 0 || ${durationBand[2]} == 0 ||  ${durationBand[3]} == 0 \
		|| ${durationBand[4]} == 0 || ${durationBand[5]} == 0 || ${durationBand[6]} == 0 || ${durationBand[7]} == 0 ]] \
		|| break
	fi
done < $fileName

echo ${durationBand[@]}
}

# Display time in hour, minute and second format
# Usage: displayTimeHHMMSS "time"
# Example: displayTimeHHMMSS 1381407574
function displayTimeHHMMSS() {
duration=$1

if [[ $duration -gt 60 ]]
then
	h=$(($duration/3600))
	m=$((($duration/60)%60))
	s=$(($duration%60))
	echo -e " ( $h hour $m min $s sec )\n"
fi
}

# Display all sessions of a device which is more than 10 sec.
# Usage: displaySessionDuration "fileName" "givenDate"
function displayMoreThan10SecSessionDuration(){
fileName=$1
givenDate=$2

# Set start time and stop time to none.
channelStart=""
channelStop=""

a=0
# Read lines one by one from test2 file and get start time and stop time
while read line || [[ -n $line ]] ;
do
	# Call the function getChannelStartAndStopTime to get the start and stop times
	channelStart=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f1)
	channelStop=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f2)
	
	# Compare the start and stop time and determine whether there is a session more than 10 sec. If is, break the loop.
	if [[ $channelStart != "" && $channelStop -gt $channelStart ]]
	then 
		if [[ $(($channelStop-$channelStart)) -ge 10 ]] 
		then
			duration=$(($channelStop-$channelStart))
			a=$(($a+1))
			echo -e "\nDuration $a:"
			echo "Start time: $channelStart - $(date -ud \@$channelStart) "
			echo "Stop time: $channelStop - $(date -ud \@$channelStop)"					
			echo "Watch duration: $duration sec"
			displayTimeHHMMSS $duration
			
			# Reset all timers
			channelStart=""
			channelStop=""
			heartbeat_last=""
		fi
	fi
	
done < $fileName
echo "Total number of >=10 seconds durations: $a"
}

# Generate a file which contains all devices watch a channel
# Usage: getFileOfChannelWatchedByAllDevices givenDate channelNumber rawFiles outputFile
function getFileOfChannelWatchedByAllDevices(){
givenDate=$1
channelNumber=$2
rawFiles=$3
outputFile=$4

# If only the month is given, then filter from whole month files, otherwise from the day.
# awk command is to check how many fields are given. If 2, it is month. If 3, it is a day.
if [[ $( echo $givenDate |  awk -F'-' '{print NF}') == 2 ]]
then
	# Grep all events related to the channel number to test1 file
	zcat "$rawFiles"-*  | awk -F',' -v chlNum="$channelNumber" '$15 == chlNum && ($4 ~/16[1,2]/ || $4 ~/82/)' > $outputFile
# If a date is given, filter events on the given day.
else
	# Get the epoch start time and end time of "2013-10-10"
	start_time=$(date -d $givenDate +%s)
	end_time=$(date -d $givenDate+"+1 day" +%s)
	# Get all events of the given day
	zcat "$rawFiles"-* | awk -F',' -v sTime="$start_time" -v eTime="$end_time" -v chlNum="$channelNumber" \
	'$5 >= sTime && $5 <= eTime && $15 == chlNum && ($4 ~/16[1,2]/ || $4 ~/82/)' > $outputFile
fi
}

# Sum all durations and count number of sessions
# Usage: getSumOfDurationAndNumberOfSessions fileName givenDate duration numberOfSessions
function getSumOfDurationAndNumberOfSessions(){
fileName=$1
givenDate=$2
duration=$3
numberOfSessions=$4

# Set start time and stop time to none.
channelStart=""
channelStop=""

# Read lines one by one from test2 file and get start time and stop time
while read line || [[ -n $line ]] ;
do
	# Call the function getChannelStartAndStopTime to get the start and stop times
	channelStart=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f1)
	channelStop=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f2)
	
	# Compare the start and stop time and determine whether there is a session more than 10 sec. If is, break the loop.
	if [[ $channelStart != "" && $channelStop -gt $channelStart ]]
	then 
		if [[ $(($channelStop-$channelStart)) -ge 10 ]] 
		then
			# Sum the durations
			if [[ $(($channelStop-$channelStart)) -le 9000 ]]	# If a duration > 2.5 hours, it is cut off to 2.5 hours
			then
				duration=$(($duration+$channelStop-$channelStart))
			else 
				duration=$(($duration+9000))
			fi
			
			# Count the sessions
			numberOfSessions=$(($numberOfSessions+1))

			# Reset all timers
			channelStart=""
			channelStop=""
			heartbeat_last=""
		fi
	fi
	
done < $fileName
echo "$duration $numberOfSessions"
}

# Sum all durations
# Usage: getSumOfDurationAndNumberOfDevices fileName givenDate duration
function getSumOfDurationAndNumberOfDevices(){
fileName=$1
givenDate=$2
duration=$3

# Set start time and stop time to none.
channelStart=""
channelStop=""

# Set a flag for counting number of devices
gotOneSession="false"

# Read lines one by one from test2 file and get start time and stop time
while read line || [[ -n $line ]] ;
do
	# Call the function getChannelStartAndStopTime to get the start and stop times
	channelStart=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f1)
	channelStop=$(echo $(getChannelStartAndStopTime $line $fileName $givenDate $channelStart $channelStop) | cut -d' ' -f2)
	
	# Compare the start and stop time and determine whether there is a session more than 10 sec. If is, break the loop.
	if [[ $channelStart != "" && $channelStop -gt $channelStart ]]
	then 
		if [[ $(($channelStop-$channelStart)) -ge 10 ]] 
		then
			# Set a flag to true
			gotOneSession="true"
			
			# Sum the durations
			if [[ $(($channelStop-$channelStart)) -le 9000 ]]	# If a duration > 2.5 hours, it is cut off to 2.5 hours
			then
				duration=$(($duration+$channelStop-$channelStart))
			else 
				duration=$(($duration+9000))
			fi
			
			# Reset all timers
			channelStart=""
			channelStop=""
			heartbeat_last=""
		fi
	fi
	
done < $fileName
echo "$duration $gotOneSession"
}