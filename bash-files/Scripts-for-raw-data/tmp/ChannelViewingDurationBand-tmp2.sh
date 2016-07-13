#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "Channel by Duration band"
############################################################################
#                                                                          #
#     How to run the script:                                               #
#     .../ChannelViewingDurationBand "Channel-Name" "2013-XX-XX"     #
#     e.g: .../ChannelWatchedByDevice.sh "TEST CHANNEL" "2013-10-10"       #
#                                                                          #
############################################################################

# Working directory is: /mnt/pipeline/p1_gen/work/s0_root/complete
WORKDIR=/mnt/pipeline/p1_gen/work/s0_root/complete
TESTTMP1=/tmp/test1
TESTTMP2=/tmp/test2
TESTTMP3=/tmp/test3

# Give a channel name and a date for investigate.
channelName=$1
# Date has to be the format of "2013-10-10"
DATE=$2

echo -e "Date: $DATE"

cd $WORKDIR

# Translate from a channel name to channel number
channelNumber=$(less channels-2013-10-* | grep -m 1 -a2 "$channelName" | sed  -n -r 's/(  <digits>)([0-9]{1,3}).*/\2/p')
echo -e "Channel Name: $channelName \nChannel Number: $channelNumber"

# Give the raw data file location
rawFiles="sig-event-long-term-2013-10"

# If only the month is given, then filter from whole month files. 
# awk command is to check how many fields are given. If 2, it is month. If 3, it is a day.
if [[ $( echo $DATE |  awk -F'-' '{print NF}') == 2 ]]
then
	# Grep all events related to the channel number to test1 file
	less "$rawFiles"-*  | awk -F',' -v chlNum="$channelNumber" '$15 ~ chlNum && $4 ~/16[1,2]/ ' > $TESTTMP1
# If a date is given, filter events on the given day.
else
	# Get the epoch start time and end time of "2013-10-10"
	START_TIME=$(date -d $2 +%s)
	END_TIME=$(date -d $2+"+1 day" +%s)
	# Get all events of the given day
	less "$rawFiles"-* | awk -F',' -v sTime="$START_TIME" -v eTime="$END_TIME" -v chlNum="$channelNumber" '$5 >= sTime && $5 <= eTime && $15 ~ chlNum && $4 ~/16[1,2]/ ' > $TESTTMP1
fi

# Grep all lines which has the channel number on column 15 to test2 file
#awk -F',' -v chlNum="$channelNumber" '$15 ~ chlNum && $4 ~/16[1,2]/ ' $TESTTMP1 > $TESTTMP2

# Use devices array to store device id, maximan 50 devices.
dn=200
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
	echo "More than $dn devices to be found"
	break
	fi
done < $TESTTMP1

# Display all device IDs
a=0
echo -e "\nDisplay all device IDs"
echo "-----"
for i in ${devices[@]} ;
do 
	if [[ $i != "" ]] ;
    then 
	echo $i
	let a=a+1
	fi
done
echo -e "-----"
echo -e "Total $a devices\n"

a=0
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


# Grep the devices one by one from raw data
for i in ${devices[@]};
do 
	let a=a+1
	declare -a durationBandTmp=(0 0 0 0 0 0 0 0)

	if [[ $i != "" ]]
	then
	
	# Filter out all lines which contain all device IDs from test1 to test2 file
	awk -F',' -v dID="$i" '$2 ~ dID && $3 ~ dID ' $TESTTMP1 > $TESTTMP2
	
	# Set start time and stop time to none.
	dStart=""
	dStop=""
	
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
		
		# If a date is given, get channel stop time if it follows on next day.
		if [[ $( echo $DATE |  awk -F'-' '{print NF}') == 3 && $dStart != "" && $dStop == "" ]]
		then 
			echo -e "\ndevices$a: $i"

			# Search raw files to get the first 161 after last channel start time.
			dStop=$(less "$rawFiles"-* | awk -F',' -v chlNum="$channelNumber" -v dID="$i" -v dStartT="$dStart" '$2 ~ dID && $4 ~/161/ && $5 >= $dStartT && $15 ~ chlNum {print $5; exit;}')
			
			# Search raw files to get the first 161 after end time.
			dStartTmp=$(less "$rawFiles"-* | awk -F',' -v chlNum="$channelNumber" -v dID="$i" -v eTime="$END_TIME" '$2 ~ dID && $4 ~/162/ && $5 >= eTime && $15 ~ chlNum {print $5; exit;}')
			
			# Check the stop time(161) appear before start time (162). If not, assign dStop to null. 
			echo "$dStop, $dStartTmp, $END_TIME"
			[[ $dStop < $dStartTmp ]] && [[ $dStop > $END_TIME ]] || dStop=""
		fi
		
		if [[ $dStart != "" && $dStop -gt $dStart ]]
		then 
			duration=$(($dStop-$dStart))
					
			# Record one device in different duration band. If it is in one band many time, it is only recorded once.
			case 1 in
				$(($duration > 0 && $duration <= 10 && ${durationBandTmp[0]} == 0 )) )	# 0-10 seconds
					durationBandTmp[0]=$duration;;
				$(($duration >10 && $duration <= 60 && ${durationBandTmp[1]} == 0  )) )	# 10sec to 1min
					durationBandTmp[1]=$duration;;
				$(($duration > 60 && $duration <= 300  && ${durationBandTmp[2]} == 0 )) )	# 1min to 5min
					durationBandTmp[2]=$duration;;
				$(($duration > 300 && $duration <= 900 && ${durationBandTmp[3]} == 0  )) )	# 5min to 15min
					durationBandTmp[3]=$duration;;
				$(($duration > 900 && $duration <= 1800 && ${durationBandTmp[4]} == 0 )) )	# 15min to 30min
					durationBandTmp[4]=$duration;;
				$(($duration > 1800 && $duration <= 3600 && ${durationBandTmp[5]} == 0 )) )	# 30min to 60min
					echo "30min to 60min: device ID $i"
					echo -e "Start time: $dStart $dStartH \nEnd time: $dStop $dStopH"
					echo -e "Duration: $duration\n"
					durationBandTmp[5]=$duration;;
				$(($duration > 3600 && $duration <= 5400 && ${durationBandTmp[6]} == 0 )) )	# 60min to 90min
				    echo "60min to 90min: device ID $i"
					echo -e "Start time: $dStart $dStartH \nEnd time: $dStop $dStopH"
					echo -e "Duration: $duration\n"
					durationBandTmp[6]=$duration;;
				$(($duration > 5400 && ${durationBandTmp[7]} == 0 )) )	# More than 90min
					echo "More than 90min: device ID $i"
					echo -e "Start time: $dStart $dStartH \nEnd time: $dStop $dStopH"
					echo -e "Duration: $duration\n"
					durationBandTmp[7]=$duration;;
			esac
			
			# Reset start time and stop time after duration is calculated.
			dStart=""
			dStop=""
			
			# Stop read line when all durationBandTmp items are assigned.
			[[ ${durationBandTmp[0]} == 0 || ${durationBandTmp[1]} == 0 || ${durationBandTmp[2]} == 0 ||  ${durationBandTmp[3]} == 0 || ${durationBandTmp[4]} == 0 || ${durationBandTmp[5]} == 0 || ${durationBandTmp[6]} == 0 || ${durationBandTmp[7]} == 0 ]] || break

		fi
				
	done < $TESTTMP2
	fi
	
	# echo "finalDuration: $finalDuration"
	
# Display duration tmp
# a=0
# echo -e "\nDisplay duration tmp"
# echo "-----"
	# for m in ${durationBandTmp[@]} ;
	# do 
		# echo "${durationBandName[$a]}: $m"
		# let a=a+1
	# done
		
	# Count devices in viewing duration bands
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
	let a=a+1
done
echo "-----"
