#!/bin/bash

exportedDir="/mnt/mirimon-regression-test/$(basename $(pwd))"

[[ -d $exportedDir ]] || mkdir -p $exportedDir

validIP1="1.46.110.122"
validIP2="101.36.72.55"
validIP3="104.11.208.196"
validIP4="193.63.64.49"

deviceID1=1
deviceID2=2
deviceID3=3
deviceID4=4

logFile_Geolookup="/var/log/mirimon/geolookup.log"
logFile_Provisioning="/var/log/mirimon/provisioning.log"

# Inject IP addresses into the database
. /usr/share/mirimon/bin/miriserv_env.inc > /dev/null
input-files/mmsetip --device $deviceID1 --ip_address $validIP1
input-files/mmsetip --device $deviceID2 --ip_address $validIP2
input-files/mmsetip --device $deviceID3 --ip_address $validIP3
input-files/mmsetip --device $deviceID4 --ip_address $validIP4

# If the directory is not empty, remove the files.
[[ $(ls -A /var/lib/mirimon/provisioning/ready/) ]] && rm -f /var/lib/mirimon/provisioning/ready/*

if [[ -f $logFile_Geolookup ]]
then
    countG=$(cat $logFile_Geolookup | wc -l )
else
    countG=1
fi

if [[ -f $logFile_Provisioning ]]
then
    countP=$(cat $logFile_Provisioning | wc -l )
else
    countP=1
fi

# Use geo-lookup function to translate WAN IP address to geo-location.
su mirimon /usr/share/mirimon-geolookup/import.sh 

if [[ $? -ne 0 ]]
then
    echo "Geo-lookup generating file failed. Please check the log file - $logFile_Geolookup"
	tail -n +$countG $logFile_Geolookup
	exit 1
fi

# If the directory is empty, fail the test.
if [[ ! $(ls -A /var/lib/mirimon/provisioning/ready/) ]]
then
    echo "No geo-lookup file generated into /var/lib/mirimon/provisioning/ready/ folder."
    exit 1
fi

# Use Provisioning to import the file
su mirimon /usr/share/mirimon-provisioning/import.sh 
if [[ $? -ne 0 ]]
then
    echo "Provisioning failed to import file. Please check the log file - $logFile_Provisioning"
	tail -n +$countP $logFile_Provisioning
	exit 1
fi

user="root"
password="minime"
database="mirimon002"
actualFileTmp="/tmp/$(basename $0 .sh).csv"
expectedDir="$(dirname $0)/expected"
expectedFile="$expectedDir/$(basename $0 .sh).csv"
actualFile="$exportedDir/$(basename $0 .sh).csv"

mysqlQuery="select ip_address, valid, geo_city, geo_region, geo_country, isp, asn, geo_lat, geo_long from geo_lookup \
where ip_address='$validIP1' or ip_address='$validIP2' or ip_address='$validIP3' or ip_address='$validIP4' \
into outfile '$actualFileTmp'  FIELDS TERMINATED BY ','"
mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysqlQuery"

mv $actualFileTmp $actualFile

# Do a file comparison
diff "$expectedFile" "$actualFile"  || exit 1