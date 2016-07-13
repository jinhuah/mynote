#!/bin/bash

# Install git and puppet if not exist
apt-get update
which git > /dev/null || apt-get -y install git
which puppet > /dev/null || apt-get -y install puppet-common

# Download insight-douc
cd ~
git clone https://geniusdigital-testbot:GeniusD1g1t4l@github.com/GeniusDigital/insight-douc.git > /dev/null

mkdir /mnt/regressionTest
logFile="/mnt/regressionTest/upgrade-setup.log"

echo "Upgrade setup starts now" > $logFile

# install bootstrap
echo "install_bootstrap.sh local"
echo "install_bootstrap.sh local" >> $logFile
~/insight-douc/puppet/bootstrap/install_bootstrap.sh local >> $logFile 2>&1
if [[ $? -eq 1 ]]
then 
    echo "bootstrap failed!!!"
    exit 1
fi

# Update custom.yaml
cp ~/insight-douc/puppet/hiera/example-custom-mirimon.yaml ~/insight-douc/puppet/hiera/custom.yaml
sed -i "s/mirimon::mysql::install                                       : 'true'/mirimon::mysql::install                                       : 'false'/g" ~/insight-douc/puppet/hiera/custom.yaml

# puppet apply gd-install.pp
pushd ~/insight-douc/puppet/
echo "" >> $logFile
echo "puppet apply --verbose --debug gd-install.pp"
echo "puppet apply --verbose --debug gd-install.pp" >> $logFile

puppet apply --verbose --debug gd-install.pp >> $logFile  2>&1
if [[ $? -eq 1 ]]
then 
    echo "puppet apply failed!!!"
    exit 1
fi
popd

# Update repository
echo "apt-get update"
apt-get update

# Get mirimon-install.conf from mirimon repository
if [[ ! -d ~/mirimon ]]
then
    git clone https://geniusdigital-testbot:GeniusD1g1t4l@github.com/GeniusDigital/mirimon > /dev/null
    sleep 10
    cp mirimon/packaging/debian/sample-standalone-mirimon-install.conf ~/mirimon-install.conf
fi

# change to "Upgrade DB" in mirimon-install.conf
sed -i "s/Install DB/Upgrade DB/g" ~/mirimon-install.conf

# Uninstall mirimon packages if not uninstalled by puppet
if ( dpkg -l | grep mirimon)
then
    apt-get -y purge mirimon-base
    apt-get -y purge mirimon-dev-license-01
fi

apt-get -y purge libdigest-fnv-pureperl-perl

echo "Mirimon upgrade setup is done."