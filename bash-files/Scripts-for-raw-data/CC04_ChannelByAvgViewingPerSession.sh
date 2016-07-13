#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "Channel by average viewing per session"

###################################################################################################################
#                                                                                                    			  #
#         FILE:  CC04_ChannelByAvgViewingPerSession.sh                                                            #
#        USAGE:  CC04_ChannelByAvgViewingPerSession.sh "Channel-Name" "2013-XX-XX" "NumberOfDevices"              #
#      EXAMPLE:  CC04_ChannelByAvgViewingPerSession.sh "TEST CHANNEL" "2013-10-10" "200"                          #
#  DESCRIPTION:  This is to test the query of "Channel by Average Viewing per Session".                           #
#				 When a date is given, it will produce a result of the day.                                       #
#				 When a month is given, it will produce a result of the whole available data of the month.        #
# 		OUTPUT:  Average viewing per session of the channel                                                       #
#  SAIKU QUERY:  Columns - Channel (Select a channel)															  #
#                Rows - Average Viewing per Session																  #
#                Filter - Day (Select a day) -- optional                                                          #
#      	  NOTE:  Parameter of NumberOfDevices is optional, the default is set to 200.                             #
#					                                                                                              #
###################################################################################################################

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

	duration=0
	numberOfsessions=0
	
	# Grep the devices one by one from raw data
	for i in ${deviceIDs[@]};
	do 
		# Filter out all lines which contain all device IDs to tmp file test1
		getFileforChannelDuration "$givenDate" "$channelNumber" "$rawFiles" "$i" "$tmpFile"
		
		# Get duration and number of sessions from each device and store to a tmp variable
		tmp=$(getSumOfDurationAndNumberOfSessions $tmpFile $givenDate $duration $numberOfSessions)
		
		# Get duration and numberOfSession from tmp variable
		duration=$(echo $tmp | cut -d' ' -f1)
		numberOfSessions=$(echo $tmp | cut -d' ' -f2)
	done
	
	# Calculate average viewing per session
	if [[ $numberOfSessions != 0 ]]
	then
		avgViewingPerSession=$(($duration/$numberOfSessions))
	else
		echo "Number of sessions is \"0\""
	fi	

	echo "FINAL RESULT - \"$channelName\" Average Viewing per Session is: $avgViewingPerSession seconds" 
	displayTimeHHMMSS $avgViewingPerSession
fi