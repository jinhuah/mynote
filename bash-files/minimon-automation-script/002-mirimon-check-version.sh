#!/bin/bash

red='\033[0;31m' # echo: colour red
NC='\033[0m' # echo: no Color

if [[ $# -eq 0 ]]
then 
    version="3.25.1~dev"
else
    version=$1
fi

# versionAlien=$(echo $version | tr -d "~" )

# Check mirimon version through dpkg list.
if [[  $(dpkg -l | grep -q mirimon) != "" ]]
then 
    echo "Mirimon is not installed on the machine."
    exit 1
fi

exported_dir="/mnt/mirimon-regression-test/$(basename $(pwd))"

[[ -d $exported_dir ]] || mkdir -p $exported_dir
mirimonPkgList="$exported_dir/mirimon_packages"
dpkg -l | grep mirimon > $mirimonPkgList

i=0
while read line || [[ -n $line ]] ;
do
    if [[ $(echo $line | cut -d' ' -f3) != $version ]]
    then 
        # Display line in red if the version does not match
        echo -e "${red}$line${NC}"
        i=$(($i+1))
    fi
    
done < $mirimonPkgList

if [[ i -ne 0 ]]
then 
    echo "$i Mirimon package versions are not correct."
    echo "Mirimon version is not $version. Test failed!"
    exit 1
fi

logFile="/mnt/regressionTest/$(ls /mnt/regressionTest/ | grep mirimon_install)"

#Check version in Mirimon installation log
if ( ! grep -inq "MiriMON $version Server Database Creation" $logFile ) 
then
    grep -in "Server Database Creation" $logFile
    echo "Test failed, Mirimon version in installation log is not $version!"
    exit 1
fi

echo "Test passed!"
