#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "Channel by Duration band", display the duration band

###################################################################################################################
#                                                                                                    			  #
#         FILE:  CC03_ChannelByDurationBand.sh                                                                    #
#        USAGE:  CC03_ChannelByDurationBand.sh "Channel-Name" "2013-XX-XX" "NumberOfDevices"                      #
#      EXAMPLE:  CC03_ChannelByDurationBand.sh "TEST CHANNEL" "2013-10-10" "200"                                  #
#  DESCRIPTION:  This is to test the query of "Channel by Duration Band".                                         #
#				 When a date is given, it will produce a result of the day.                                       #
#				 When a month is given, it will produce a result of the whole available data of the month.        #
# 		OUTPUT:  Number of devices on each duration band                                                          #
#  SAIKU QUERY:  Columns - Channel (Select a channel)															  #
#                Rows - Duration Band																    		  #
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

# Count how many devices watched the channels.
if [[ $deviceIDs == "" ]]
then 
	echo "TEST STOPPED!!! --- Too many devices have been detected. Give a higher device number."
else
	# Display all device IDs which watched the channel.
	displayDeviceID $deviceIDs

	declare -a durationBandCount=(0 0 0 0 0 0 0 0) 
	declare -a durationBandTmp[8]
	declare -a durationBandName[8]
	durationBandName[0]="0 to 10 seconds"
	durationBandName[1]="Between 10 seconds and 1 minute"
	durationBandName[2]="Between 1 and 5 minutes"
	durationBandName[3]="Between 5 and 15 minutes"
	durationBandName[4]="Between 15 and 30 minutes"
	durationBandName[5]="Between 30 and 60 minutes"
	durationBandName[6]="Between 60 and 90 minutes"
	durationBandName[7]="Between 1.5 and 2.5 hours"
	
	# Grep the devices one by one from raw data
	for i in ${deviceIDs[@]};
	do 
		# Filter out all lines which contain all device IDs to tmp file test1
		getFileforChannelDuration "$givenDate" "$channelNumber" "$rawFiles" "$i" "$tmpFile"
		
		# Get each duration of the device and store into relevant band.
		durationBandTmp=$(getDeviceDurationBand $"$tmpFile" "$givenDate")
		
		# Count all device duration bands
		for d in ${durationBandTmp[@]};
		do
			case 1 in
				$(($d > 0 && $d <= 10 )) )	# 0-10 seconds
					durationBandCount[0]=$((${durationBandCount[0]}+1)) ;;
				$(($d >10 && $d <= 60 )) )	# 10sec to 1min
					durationBandCount[1]=$((${durationBandCount[1]}+1)) ;;
				$(($d > 60 && $d <= 300 )) )	# 1min to 5min
					durationBandCount[2]=$((${durationBandCount[2]}+1)) ;;
				$(($d > 300 && $d <= 900 )) )	# 5min to 15min
					durationBandCount[3]=$((${durationBandCount[3]}+1)) ;;
				$(($d > 900 && $d <= 1800 )) )	# 15min to 30min
					durationBandCount[4]=$((${durationBandCount[4]}+1)) ;;
				$(($d > 1800 && $d <= 3600 )) )	# 30min to 60min
					durationBandCount[5]=$((${durationBandCount[5]}+1)) ;;
				$(($d > 3600 && $d <= 5400 )) )	# 60min to 90min
					durationBandCount[6]=$((${durationBandCount[6]}+1)) ;;
				$(($d > 5400 )) )	# More than 90min
				durationBandCount[7]=$((${durationBandCount[7]}+1)) ;;
			esac
		done
	done
	
# Display viewing duration bands
a=0
echo -e "\nDisplay viewing duration bands"
echo "-----"
for i in ${durationBandCount[@]} ;
do 
	echo "${durationBandName[$a]}: $i"
	a=$(($a+1))
done
echo "-----"

fi
		







