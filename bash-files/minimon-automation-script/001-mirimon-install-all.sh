#!/bin/bash

red='\033[0;31m' # echo: colour red
NC='\033[0m' # echo: no Color

# Make sure to use root user
if [[ $(whoami) != "root" ]] 
then 
    echo "You must be root to run the script."
    exit 1
fi

if [[ ! -f  ~/mirimon-install.conf ]]
then
    git clone https://geniusdigital-testbot:GeniusD1g1t4l@github.com/GeniusDigital/mirimon > /dev/null
    sleep 10
    cp mirimon/packaging/debian/sample-standalone-mirimon-install.conf ~/mirimon-install.conf
fi

# Check mirimon.conf file exists
if [[ ! -f  ~/mirimon-install.conf ]]
then 
    echo "mirimon.conf file does not exist, you need to make the manual installation."
    exit 1
fi

regressionHomeDir="/mnt/regressionTest"
logFile="$regressionHomeDir/mirimon_install_$(date +'%Y%m%d_%H%M').log"

# Display Ubuntu version.
lsb_release -a

mkdir $regressionHomeDir
touch $logFile
# Install mirimon
echo "Install Mirimon"
echo "Install Mirimon" >> $logFile
apt-get -y install mirimon >> $logFile 2>&1

if [[ $? != 0 ]]
then 
    echo "Mirimon installation failed, please check the log file $logFile"
    exit 1
else
    echo "Mirimon server has been installed successfully."
fi

grep -in 'error\|fail' $logFile | grep -v "In case this process fails" && echo "Some errors during the mirimon installation - $logFile"

count=$(cat $logFile | wc -l )

# Install mirimon dev license
echo "Install mirimon-dev-license-01"
echo "" >> $logFile
echo "Install mirimon-dev-license-01" >> $logFile
apt-get -y install mirimon-dev-license-01 >> $logFile 2>&1

if [[ $? != 0 ]]
then 
    echo "Mirimon license installation failed, please check the log file $logFile"
    exit 1
fi

tail -n +$count $logFile | grep -in 'error\|fail' && echo "Some errors during the mirimon license installation - $logFile"

# Make an array with mirimon packages, except mirimon and mirimon license
declare -a packages=("mirimon-geolookup" "mirimon-exporter" "mirimon-cts" "mirimon-wss" "mirimon-dancer" "mirimon-soap" "mirimon-simulator")

for package in ${packages[@]}
do

    count=$(cat $logFile | wc -l )
    
    echo "Install $package" 
    echo "" >> $logFile
    echo "Install $package" >> $logFile
    apt-get -y install $package >> $logFile 2>&1
    
    [[ $? == 0 ]] || echo -e "${red}Mirimon $package installation failed, please check the log file $logFile${NC}"
    tail -n +$count $logFile | grep -in 'error\|fail' && echo -e "${red}Some errors during the mirimon $package installation - $logFile${NC}"
    
    dpkg -l | grep -q "ii  $package"  || echo "$package is not installed"
    if [[ $package == "mirimon-geolookup"  ]]
    then 
        dpkg -l | grep -q "ii  mirimon-provisioning"  || echo "mirimon-provisioning is not installed"
        dpkg -l | grep -q "ii  mirimon-python-pip-extra" || echo "mirimon-python-pip-extra is not installed"
    fi
done

echo ""
echo "The installation have been completed." >> $logFile
echo "The installation have been completed."
dpkg -l | grep mirimon

if  [[ $(dpkg -l | grep mirimon | wc -l) -ne 13 ]]
then 
    echo "Test failed, number of packages do not match!!!"
    echo "Test failed, number of packages do not match!!!" >> $logFile
    echo "Only $(dpkg -l | grep mirimon | wc -l) packages are installed, expect 13." >> $logFile
fi

# Check processes are running/not running.
declare processes=( \
"siamang Running" \
"mmsubtraps Running" \
"mmregiontraps Running" \
"mmregionagent Running" \
"push-output Running" \
"export-jobs Running" \
"mirimon-dancer Running" \
"kloss Running" \
"iptv-sim Not monitored" \
"hoolock Running" \
"hls-sim Not monitored" \
"dvb-sim Not monitored" \
"concolor Running" \
"agile-default Running" )

IFS=""

echo "" >> $logFile
echo "Check processes running/not running" >> $logFile

for process in "${processes[@]}"
do

    if [[ -z $(monit summary | grep $(echo "$process" | cut -d" " -f1) | grep $(echo "$process" | cut -d" " -f2) ) ]]
    then
        echo "Expect: $process" >> $logFile
        if ( monit summary | grep $(echo "$process" | cut -d" " -f1) )
        then
            echo "But $(monit summary | grep $(echo "$process" | cut -d" " -f1))" >> $logFile
        else 
            echo "$(echo "$process" | cut -d" " -f1) does not exist" >> $logFile
        fi
    fi
done

# Create last-increment-pos.txt for exporter, if not exist. 
[[ -f /var/lib/mirimon/exporter/last-increment-pos.txt ]] || su mirimon /usr/share/mirimon-exporter/bin/reset-increment-export-pos.sh

if [[ $(cat $logFile | grep -in 'error\|fail') ]]
then 
    echo "Some error in Mirimon installation log" >> $logFile
    echo "Some error in Mirimon installation log"
else
    echo ""
    echo "Mirimon installation has completed successfully"
fi

