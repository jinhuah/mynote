#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Extract all devices info related to the given channel into a file for manual investigation

####################################################################################################################
#                                                                                                    	   		   #
#         FILE:  CC07_GenerateFileOfChannelWatchedByAllDevices.sh                                                  #
#        USAGE:  CC07_GenerateFileOfChannelWatchedByAllDevices.sh "Channel-Name" "2013-XX-XX" "NumberOfDevices"    #
#      EXAMPLE:  CC07_GenerateFileOfChannelWatchedByAllDevices.sh "TEST CHANNEL" "2013-10-10" "200"                #
#  DESCRIPTION:  This is to extract all devices info related to the given channel, then                            #
#                save to the specified file for manual investigation.                                              #
#				 When a date is given, it will produce a result of the day.                                        #
#				 When a month is given, it will produce a result of the whole available data of the month.         #
# 		OUTPUT:  A file is produced                                                                                #
#  SAIKU QUERY:  No relevant query														                           #
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

cd $workDir

channelNumber=$(getChannelNumber "$givenDate" "$channelName")
echo -e "Channel Name: $channelName \nChannel Number: $channelNumber"

getFileOfChannelWatchedByAllDevices $givenDate $channelNumber $rawFiles $tmpFile

echo "The output file is $tmpFile"