#!/bin/bash

# Usage1: ./install_insight.sh
# Usage2: ./install_insight.sh 'installname' 'Region/City'
# Example: ./install_insight.sh 'test_jinhua' 'Europe/London'

# Update and install git
[[ $(whoami) == "root" ]] || sudo -s

apt-get update
apt-get -y install git

# Download dev build
[[ $(git clone https://geniusdigital-testbot:GeniusD1g1t4l@github.com/GeniusDigital/insight-douc) ]] || exit 1

# Install local bootstrap
insight-douc/puppet/bootstrap/install_bootstrap.sh local

# Modify custom.yaml file
cd insight-douc/puppet
cp hiera/example-custom.yaml hiera/custom.yaml

dateStamp="$(date +%Y%m%d%H)"
instanceName="test_daily_$dateStamp"
timeZone="Europe/London"

if [[ $# -gt 0 ]]
then
	instanceName=$1
	[[ $2 == "" ]] || timeZone=$2
fi

# Change instance name
sed -i "s/tph_dev_test5/$instanceName/g" hiera/custom.yaml

# Change Timezone
sed -i "s/Europe\/Amsterdam/$(echo $timeZone | cut -d'/' -f1)\/$(echo $timeZone | cut -d'/' -f2)/g" hiera/custom.yaml

# Change load balance
sed -i "s/insight2::pipeline::dim_device_load_balance                   : '4'/insight2::pipeline::dim_device_load_balance                   : '1'/" hiera/custom.yaml
sed -i "s/insight2::pipeline::ref_linear_session_live_load_balance      : '4'/insight2::pipeline::ref_linear_session_live_load_balance      : '1'/" hiera/custom.yaml

# Remove the log file if it exists
if [[ -f /tmp/insight_install.log ]]
then 
    rm -f /tmp/insight_install.log
fi

# Check whether puppet is installed. If not, install it.
puppet > /dev/null
result=$?

[[ $result == 127 ]] && apt-get -y install puppet

clear
echo "#############################################"
echo "#                                           #"
echo "#     The installation will take a while.   #"
echo "#     Please wait ......                    #"
echo "#                                           #"
echo "#############################################"
echo ""

# Install Insight build
puppet apply --verbose --debug gd-install.pp > /tmp/insight_install.log 2>&1

if [[ $? != 0 ]]
then 
    echo "Insight installation failed, please check the log file /tmp/insight_install.log"
	exit 1
else
    echo "Insight platform has been installed successfully."
fi

# Inject data into pipeline
cd /home/insight/app/insight-entellus
bin/pipeline_apply_data /mnt/pipeline data/default-set


