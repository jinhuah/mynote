#!/bin/bash

exportedDir="/mnt/mirimon-regression-test/$(basename $(pwd))"

[[ -d $exportedDir ]] || mkdir -p $exportedDir

invalidIP1="10.1.146.234"
invalidIP2="192.168.128.80"
invalidIP3="172.16.23.54"

deviceID1=5
deviceID2=6
deviceID3=7

logFile_Geolookup="/var/log/mirimon/geolookup.log"
logFile_Provisioning="/var/log/mirimon/provisioning.log"

# Inject IP addresses into the database
. /usr/share/mirimon/bin/miriserv_env.inc > /dev/null
input-files/mmsetip --device $deviceID1 --ip_address $invalidIP1
input-files/mmsetip --device $deviceID2 --ip_address $invalidIP2
input-files/mmsetip --device $deviceID3 --ip_address $invalidIP3

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
where ip_address='$invalidIP1' or ip_address='$invalidIP2' or ip_address='$invalidIP3' \
into outfile '$actualFileTmp'  FIELDS TERMINATED BY ','"
mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysqlQuery"

mv $actualFileTmp $actualFile

# Do a file comparison
diff "$expectedFile" "$actualFile"  || exit 1
