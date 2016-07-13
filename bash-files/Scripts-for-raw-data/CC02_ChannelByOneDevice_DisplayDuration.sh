#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "One Channel by One Devices", display all >=10 sec durations 

###################################################################################################################
#                                                                                                    			  #
#         FILE:  CC02_ChannelByOneDevice_DisplayDuration.sh                                                       #
#        USAGE:  CC02_ChannelByOneDevice_DisplayDuration.sh "Channel-Name" "2013-XX-XX" "Device ID"               #
#      EXAMPLE:  CC02_ChannelByOneDevice_DisplayDuration.sh "TEST CHANNEL" "2013-10-10"  "2345"                   #
#  DESCRIPTION:  This is to test a channel watched by one single device.                                          #
#				 When a date is given, it will produce a result of the day.                                       #
#				 When a month is given, it will produce a result of the whole available data of the month.        #
# 		OUTPUT:  All session durations (except <10 sec) of the device will be displayed.                          #
#  SAIKU QUERY:  No relevant query															                      #
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
deviceID=$3

echo -e "Date: $givenDate"

cd $workDir

# Translate from a channel name to channel number
channelNumber=$(getChannelNumber "$givenDate" "$channelName")
echo -e "Channel Name: $channelName \nChannel Number: $channelNumber"

# Filter out all lines which contain the device to test1 file
getFileforChannelDuration "$givenDate" "$channelNumber" "$rawFiles" "$deviceID" "$tmpFile"

# Display all session duration which is more than 10 seconds.
displayMoreThan10SecSessionDuration "$tmpFile" "$givenDate"