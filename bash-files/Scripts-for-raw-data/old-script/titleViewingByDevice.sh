 #!/bin/bash
# Author: Jinhua Huang

#######################################################################################
#                                                                                     #
#     How to run the script:                                                          #
#     .../titlewatchedByDevice.sh "Title-Name" "2013-XX-XX" "Device ID"               #
#     e.g: .../titlewatchedByDevice.sh "Title-Name" "2013-10-10" 4307                 #
#     e.g: .../titlewatchedByDevice.sh "Title-Name" "2013-10" 4307                    #
#                                                                                     #
#######################################################################################

# Verify data correctness from raw data - a title watched by  one device
# Working directory is: /mnt/pipeline/p1_gen/work/s0_root/complete
WORKDIR=/mnt/pipeline/p1_gen/work/s0_root/complete
TESTTMP1=/tmp/test/test1
TESTTMP2=/tmp/test/test2
TESTTMP3=/tmp/test/test3

titleName=$1
DATE=$2
deviceID=$3

echo -e "Date: $DATE"

# Display hour, minute and second
function displayHHMMSS () {
if [[ $1 -gt 60 ]]
then
	h=$(($1/3600))
	m=$((($1/60)%60))
	s=$(($1%60))
	echo -e " ( $h hour $m min $s sec )\n"
fi
}

cd $WORKDIR

# Translate from a title name to title ID.
titleID=$(less vods-2014-03-* | grep -m 1 -a2 "$titleName" | sed  -n -r 's/(      <assetid>)([0-9]{1,4}).*/\2/p')
echo -e "Title Name: $titleName \nTitle ID: $titleID"
echo -e "Device ID: $3\n"

# Determine which raw files are used for data filtering
rawFiles="sig-event-long-term-2014-03"

# If only the month is given, then filter from whole month files. 
# awk command is to check how many fields are given. If 2, it is month. If 3, it is a day.
if [[ $( echo $DATE |  awk -F'-' '{print NF}') == 2 ]]
	then
		# Grep all events related to the title ID to test1 file
		less "$rawFiles"-*  | awk -F',' -v tleNum="$titleID" -v dID="$deviceID" '$2 ~ dID && $16 ~ tleNum ' > $TESTTMP1
	# If a date is given, filter events on the given day.
	else
		# Get the epoch start time and end time of "2013-10-10"
		START_TIME=$(date -d $2 +%s)
		END_TIME=$(date -d $2+"+1 day" +%s)
		# Get all events of the given day
		less "$rawFiles"-* | awk -F',' -v sTime="$START_TIME" -v eTime="$END_TIME" -v tleNum="$titleID" -v dID="$deviceID" '$2 ~ dID && $5 >= sTime && $5 < eTime && $16 ~ tleNum ' > $TESTTMP1
fi

while read line ;
do
	# Get the title start time of the device	
	if [[ $(echo "$line" | cut -d ',' -f4 ) == 254 ]]
	then
		dStart=$(echo "$line" | cut -d ',' -f5)
		dStartH=$(date -ud \@$dStart)
		echo ""
		echo "Start time: $dStart -- $dStartH"
	fi
	
	# Get channel stop time of the device
	if [[ $(echo "$line" | cut -d ',' -f4 ) == 252 ]]
	then
		dStop=$(echo "$line" | cut -d ',' -f5)
		dStopH=$(date -ud \@$dStop)	
		echo "Stop time: $dStop -- $dStopH"
	fi
	
	# Get duration 
	# if [[ $dStart != "" && $dStop == "" ]]
	# then 
		# echo -e "\ndevices$a: $i"	
		# echo "Start time is $dStart $dStartH, and stop time is $dStop"
	# fi
	if [[ $dStart != "" && $dStop -gt $dStart ]]
	then 
		duration=$(($dStop-$dStart))
		echo "Duration: $duration"
		displayHHMMSS $duration
		# if [[ $finalDuration == 0 || $finalDuration < $duration ]]
		# then 
			# finalDuration=$duration
		# fi
		
		dStart=""
		dStop=""
	fi
			
done < $TESTTMP1

echo "Complete!"
