#!/bin/bash
if [[ -n  $(dpkg -l | grep -q mirimon) ]]
then 
    echo "Mirimon is not installed on the machine."
    exit 0
fi

monit stop all
while [[ -n $(monit summary | grep -i "Running") ]]
do
    sleep 1
done

apt-get -y purge mirimon-base
sleep 10
apt-get -y purge mirimon-dev-license-01
sleep 10
apt-get -y purge mirimon-python-pip-extra

if [[ -n $(dpkg -l | grep -q mirimon) ]]
then 
    dpkg -l | grep mirimon
    echo "Some Mirimon packages are still installed"
else 
    rm -f /etc/monit/conf.d/dvb-sim.monit
    rm -f /etc/monit/conf.d/hls-sim.monit
    rm -f /etc/monit/conf.d/iptv-sim.monit
    echo "Mirimon uninstallation has been completed"
fi

apt-get clean