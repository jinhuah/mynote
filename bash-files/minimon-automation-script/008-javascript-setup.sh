#!/bin/bash

# Get the machine IP address. If it is aws internal IP address, get the public IP address.
tmpIP=$(hostname -i)
if [[ $(echo $tmpIP | cut -d'.' -f1 ) -eq 10 ]]
then 
    serverIP=$(GET http://169.254.169.254/latest/meta-data/public-ipv4)
else
    serverIP="$tmpIP"
fi

# Install sshpass if not exists
which sshpass || apt-get install sshpass

# javascript is stored at x101poc.staging.geniusdigital.tv
javascriptFileServer="134.213.24.23"
javascriptFile="MMJS-SDK-2.3.1.zip"

# Add the fileServer into "known_hosts" file
ssh-keygen -R $javascriptFileServer
ssh-keyscan -H $javascriptFileServer >> /root/.ssh/known_hosts

# Copy javascript files
cd /var/www/
sshpass -p "GeniusD1g1t4l" scp root@$javascriptFileServer:$javascriptFile . 
#sshpass -p "GeniusD1g1t4l" scp root@$javascriptFileServer:MMJS-SDK-2.3.zip .
# tar xzvf js.tgz

pushd mmp-javascript/

# Update the server address
sed -i "s/mm.geniusdigital.tv/$serverIP/g" SDK/mmweb.js
sed -i "s/mm.geniusdigital.tv/$serverIP/g" SDK/mmweb_min.js
sed -i "s/192.168.128.134/$serverIP/g" Demo/sample.js

popd

chown -R www-data: /var/www

# Copy mobile_config file and place it into Mirimon
sshpass -p "GeniusD1g1t4l" scp root@$javascriptFileServer:mobile_config.xml .
sed -i "s/192.168.128.134/$serverIP/g" mobile_config.xml
cp mobile_config.xml /usr/share/mirimon/www/me/config/

# Set mobile_config file as default config
source /opt/mirimon/bin/miriserv_env.inc
mmme config resync
configID=$(mmme config list | grep mobile_config.xml | cut -d":" -f1 | tr -d ' ')
echo -e "y\n\r>&1 " | "mmme config default "$configID"

# Copy cts files
sshpass -p "GeniusD1g1t4l" scp root@$javascriptFileServer:cts.tgz .
tar -zxvf cts.tgz -C / > /dev/null

# Update cts_apache.conf with more options
sed -i "s/<LimitExcept GET OPTIONS>/<LimitExcept GET DELETE PUT POST CONNECT PUSH OPTIONS>/g" /usr/share/mirimon-cts/install/cts_apache.conf

echo "Javascript setup is done. You should be able to play vedio through a web browser now."
echo "$serverIP/mmp-javascript/Demo/index2.html"