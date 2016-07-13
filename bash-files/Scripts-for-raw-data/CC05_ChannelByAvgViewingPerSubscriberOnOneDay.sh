#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "Channel by average daily viewing per subscriber on one day"

####################################################################################################################
#                                                                                                    			   #
#         FILE:  CC05_ChannelByAvgViewingPerSubscriberOnOneDay.sh                                                  #
#        USAGE:  CC05_ChannelByAvgViewingPerSubscriberOnOneDay.sh "Channel-Name" "2013-XX-XX" "NumberOfDevices"    #
#      EXAMPLE:  CC05_ChannelByAvgViewingPerSubscriberOnOneDay.sh "TEST CHANNEL" "2013-10-10" "200"                #
#  DESCRIPTION:  This is to test the query of "Channel by Average Daily Viewing per Subscriber".                   #
#				 The script is only working on a ONE day basis.                                                    #
# 		OUTPUT:  Average daily viewing per subscriber of the channel                                               #
#  SAIKU QUERY:  Columns - Channel (Select a channel)															   #
#                Rows - Average Daily Viewing per Subscriber													   #
#                Filter - Day (Select a day) -- compulsory                                                         #
#      	  NOTE:  Parameter of NumberOfDevices is optional, the default is set to 200.                              #
#					                                                                                               #
####################################################################################################################

source ./functions.sh
 
# Working directory is: /mnt/pipeline/p1_gen/work/s0_root/complete
workDir="/mnt/pipeline/p1_gen/work/s0_root/complete"
tmpFile="/tmp/test1"
rawFiles="sig-event-long-term-2013-10"

# Give a channel name and a date for investigate.
channelName=$1
# Date has to be the format of "2013-10-10"
givenDate=$2

# Device number to investigate
deviceNumber=$3

echo -e "Date: $givenDate"

cd $workDir

# Translate from a channel name to channel number
channelNumber=$(getChannelNumber "$givenDate" "$channelName")
echo -e "Channel Name: $channelName \nChannel Number: $channelNumber"

# Extract lines from raw files to save into /tmp/test1 for getting Device IDs
getFileforDeviceIDs "$givenDate" "$channelNumber" "$rawFiles" "$tmpFile"

# If no device number is given, set it to 200.
[[ $deviceNumber != "" ]] || deviceNumber=200

declare -a deviceIDs[$deviceNumber]

# Get device IDs from the tmp file
deviceIDs=$(getDeviceIDs $tmpFile $deviceNumber)

# Count how many devices which has a session more than 10 seconds.
if [[ $deviceIDs == "" ]]
then 
	echo "TEST STOPPED!!! --- Too many devices have been detected. Give a higher device number."
else
	# Display all device IDs which watched the channel.
	displayDeviceID $deviceIDs

	# Initialise duration and deviceCounter
	duration=0
	deviceCounter=0
	
	# Grep the devices one by one from raw data
	for i in ${deviceIDs[@]};
	do 
		# Filter out all lines which contain all device IDs to tmp file test1
		getFileforChannelDuration "$givenDate" "$channelNumber" "$rawFiles" "$i" "$tmpFile"
		
		# Get duration and a flag of whether device contains more than 10 sec session, and store to a tmp variable
		tmp=$(getSumOfDurationAndNumberOfDevices $tmpFile $givenDate $duration)
		
		# Get duration and flag values from tmp variable
		duration=$(echo $tmp | cut -d' ' -f1)
		gotOneSession=$(echo $tmp | cut -d' ' -f2)
		
		# Count device number if it contains more than 10 sec session
		if [[ $gotOneSession == "true" ]]
		then 
			deviceCounter=$(($deviceCounter+1))
			fi
	done
	
	# Calculate average viewing per subscriber
	if [[ $deviceCounter != 0 ]]
	then
		averageDailyViewingPerSubscriber=$(($duration/$deviceCounter))
	else
		echo "Number of devices is \"0\""
	fi	

	echo "FINAL RESULT - \"$channelName\" Average Daily Viewing per Subscriber is: $averageDailyViewingPerSubscriber seconds" 
	displayTimeHHMMSS $averageDailyViewingPerSubscriber
fi