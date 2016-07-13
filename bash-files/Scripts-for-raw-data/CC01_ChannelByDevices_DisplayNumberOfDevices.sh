#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "Channel by Devices", display "number of devices"

###################################################################################################################
#                                                                                                    			  #
#         FILE:  CC01_ChannelByDevices_DisplayNumberOfDevices.sh                                                  #
#        USAGE:  CC01_ChannelByDevices_DisplayNumberOfDevices.sh "Channel-Name" "2013-XX-XX" "NumberOfDevices"    #
#      EXAMPLE:  CC01_ChannelByDevices_DisplayNumberOfDevices.sh "TEST CHANNEL" "2013-10-10" "200"                #
#  DESCRIPTION:  This is to test the query of "Channel by Subscriber Reach".                                      #
#				 When a date is given, it will produce a result of the day.                                       #
#				 When a month is given, it will produce a result of the whole available data of the month.        #
# 		OUTPUT:  Number of Devices watched the channel                                                            #
#  SAIKU QUERY:  Columns - Channel (Select a channel)															  #
#                Rows - Subscriber Reach																		  #
#                Filter - Day (Select a day) -- optional                                                          #
#      	  NOTE:  Parameter of NumberOfDevices is optional, the default is set to 200                              #
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

echo "FINAL RESULT - \"$channelName\" watched by \"Subscriber Reach\": $a"
fi
		







