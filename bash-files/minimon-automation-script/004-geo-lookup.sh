#!/bin/bash

red='\033[0;31m' # echo: colour red
NC='\033[0m' # echo: no Color

updatedb

# Check geo-lookup files have been placed into the test server.
if ( ! locate addipaddress.sh )
then 
    echo "geo-lookup files have not been placed into the machine."
    exit 1
fi

dir=$(dirname "$(locate addipaddress.sh)")
echo "directory is: $dir"

# Inject WAN IP addresses into the database
pushd $dir
bash addipaddress.sh 1 20
popd

logFile_Geolookup="/var/log/mirimon/geolookup.log"
logFile_Provisioning="/var/log/mirimon/provisioning.log"

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
fi
    
tail -n +$countG $logFile_Geolookup | grep -in 'error\|fail' && echo -e "${red}Some errors in $logFile_Geolookup${NC}"

# If the directory is empty, fail the test.
if [[ ! $(ls -A /var/lib/mirimon/provisioning/ready/) ]]
then 
    echo "No geo-lookup file generated into /var/lib/mirimon/provisioning/ready/ folder."
    exit 1
fi

su mirimon /usr/share/mirimon-provisioning/import.sh
if [[ $? -ne 0 ]]
then 
    echo "Provisioning failed to import file. Please check the log file - $logFile_Provisioning"
fi

tail -n +$countP $logFile_Provisioning | grep -in 'error\|fail' && echo -e "${red}Some errors in $logFile_Provisioning${NC}"

echo "The WAN IP addresses have been looked up. You can check the database now."
    