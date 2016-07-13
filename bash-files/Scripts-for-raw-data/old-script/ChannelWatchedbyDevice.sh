#!/bin/bash
# Author: Jinhua Huang
# Synopsis: Calculate "a channel watched by devices"
############################################################################
#                                                                          #
#     How to run the script:                                               #
#     .../ChannelWatchedbyDevice-script.sh "Channel-Name" "2013-XX-XX"     #
#     e.g: .../ChannelWatchedByDevice.sh "TEST CHANNEL" "2013-10-10"       #
#                                                                          #
############################################################################

# Working directory is: /mnt/pipeline/p1_gen/work/s0_root/complete
WORKDIR=/mnt/pipeline/p1_gen/work/s0_root/complete
TESTTMP1=/tmp/test1
TESTTMP2=/tmp/test2
TESTTMP3=/tmp/test3

# Give a channel name and a date for inestigate
channelName=$1
# Date has to be the format of "2013-10-10"
DATE=$2

echo -e "Date: $DATE"

cd $WORKDIR

# Translate from a channel name to channel number
channelNumber=$(less channels-2013-10-* | grep -m 1 -a2 "$channelName" | sed  -n -r 's/(  <digits>)([0-9]{1,3}).*/\2/p')
echo -e "Channel Name: $channelName \nChannel Number: $channelNumber"

# Determine which raw files are used for data filtering
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
	less "$rawFiles"-* | awk -F',' -v sTime="$START_TIME" -v eTime="$END_TIME" -v chlNum="$channelNumber" '$5 >= sTime && $5 < eTime && $15 ~ chlNum && $4 ~/16[1,2]/ ' > $TESTTMP1
fi

# Grep all lines which has the channel number on column 15 to test2 file
#awk -F',' -v chlNum="$channelNumber" '$15 ~ chlNum && $4 ~/16[1,2]/ ' $TESTTMP1 > $TESTTMP2

# Use devices array to store device id, maximan 50 devices.
dn=50
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
	echo "More than 50 devices to be found"
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

# Grep the devices one by one from raw data
for i in ${devices[@]};
	do 
	let a=a+1
	
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
			
			# Get duration 
			# if [[ $dStart != "" && $dStop == "" ]]
			# then 
				# echo -e "\ndevices$a: $i"	
				# echo "Start time is $dStart $dStartH, and stop time is $dStop"
			# fi
			if [[ $dStart != "" && $dStop -gt $dStart ]]
			then 
				let duration=dStop-dStart
				
				if [[ $duration -ge 10 ]]
				then
					echo -e "\ndevices$a: $i"
					echo "Device $i - Start time: $dStart  - $dStartH"
					echo "Device $i - Stop time: $dStop - $dStopH"					
					echo "Watch duration$b: $duration sec"
				
					if [[ $duration -gt 60 ]]
					then
						h=$(($duration/3600))
						m=$((($duration/60)%60))
						s=$(($duration%60))
						echo "( $h hour $m min $s sec )" 
					fi
				fi	
			fi
					
		done < $TESTTMP2
		
		fi
	done
