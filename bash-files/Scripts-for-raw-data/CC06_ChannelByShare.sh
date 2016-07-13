#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "Channel by Share"

####################################################################################################################
#                                                                                                    			   #
#         FILE:  CC06_ChannelByShare.sh                                                                            #
#        USAGE:  CC06_ChannelByShare.sh "Channel-Name" "2013-XX-XX" "TotalSubscribers" "NumberOfDevices"           #
#      EXAMPLE:  CC06_ChannelByShare.sh "TEST CHANNEL" "2013-10-10" "54321" "200"                                  #
#  DESCRIPTION:  This is to test the query of "Channel by Share".                                                  #
#				 When a date is given, it will produce a result of the day.                                        #
#				 When a month is given, it will produce a result of the whole available data of the month.         #         
# 		OUTPUT:  Share of the channel in percentage                                                                #
#  SAIKU QUERY:  Columns - Channel (Select a channel)															   #
#                Rows - Share													                                   #
#                Filter - Day (Select a day) -- optional                                                           #
#      	  NOTE:  Parameter of NumberOfDevices is optional, the default is set to 200.                              #
#                "TotalSubscribers" varies, as it depends on other dimensions.                                     #
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

# Total subscribers - this can be obtained by using query "All Channels by Subscriber Reach"
totalSubscribers=$3

# Device number to investigate
deviceNumber=$4

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

	# Set a device counter to store the number of devices which contains more than 10 sec sessions.
	deviceCounter=0

	echo "The following devices watched "$channelName" more than 10 seconds:"
	echo "-----"
	
	# Grep the devices one by one from raw data
	for i in ${deviceIDs[@]};
	do 
		# Filter out all lines which contain all device IDs to tmp file test1
		getFileforChannelDuration "$givenDate" "$channelNumber" "$rawFiles" "$i" "$tmpFile"
		
		# Check whether the device contains one session (>=10 sec), then count it
		if [[ $(haveOneSessionTrueOrFalse "$tmpFile" "$givenDate") == "true" ]]
		then
			echo $i
			deviceCounter=$(($deviceCounter+1))
		fi
	done
	
	echo "-----"	
	echo "Total number of devices: $deviceCounter"
	
	# Calculate the share percentage using bc to control digital after decimal point. 
	# No round up possible in Bash.
	sharePercentage=$(echo "scale=2; (100*$deviceCounter/$totalSubscribers)" | bc )

echo "FINAL RESULT - \"$channelName\" by \"Share\" result: 0$sharePercentage%"
fi