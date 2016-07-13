#!/bin/bash

# Install mirimon-exporter
if ( ! dpkg -l | grep -q mirimon-exporter )
then 
    apt-get -y install mirimon-exporter
fi

# Check the installation is successful.
if [[ $? -ne 0 ]]
then 
    echo "mirimon-exporter installation failed"
    exit 1
fi

# Make sure Exporter's processes are running
i=0 
while [[ -z $( monit summary | grep "Process 'push-output'               Running" ) || -z $(monit summary | grep "Process 'export-jobs'               Running" )  ]]
do 
sleep 1
i=$(($i+1))
if [[ $i -ge 30 ]]
then 
    echo "exporter process is not running"
    monit summary
    break
fi
done

# Start set/ reset the starting export point
[[  -f /var/lib/mirimon/exporter/last-increment-pos.txt ]] || su mirimon /usr/share/mirimon-exporter/bin/reset-increment-export-pos.sh

# Setup config file to point to local destinations
exported_dir="/mnt/mirimon-regression-test/$(basename $(pwd))"

pushd /etc/mirimon/destinations
if [[ ! -e  etl.conf ]]
then
touch etl.conf
    echo "type=etl" >> etl.conf
    echo "delivery_method=cp" >> etl.conf
    echo "hostname=localhost" >> etl.conf
    echo "username=mirimon" >> etl.conf
    echo "directory=$exported_dir/etl" >> etl.conf
    cat etl.conf
else
    cat etl.conf
fi
popd

[[ ! -e $exported_dir/etl/incoming ]] && mkdir -p $exported_dir/etl/incoming 
[[ ! -e $exported_dir/etl/ready ]] && mkdir -p $exported_dir/etl/ready && chown -R mirimon: $exported_dir/etl

# Grant permissions to "mirimon_admin"
# sqlGRANT="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, ALTER, EXECUTE ON * TO 'mirimon_admin'@'localhost';"

# mysql --user='root' --password='minime' --database='mirimon002' --execute="$sqlGRANT"

# mysql --user='root' --password='minime' --database='mirimon002' --execute='flush privileges;'

fileNum=$(ls $exported_dir/etl/ready | wc -l)
echo "file number: $fileNum"

su mirimon /usr/share/mirimon-exporter/bin/create-snapshot-export-job.sh > /dev/null
sleep 5
su mirimon /usr/share/mirimon-exporter/bin/create-increment-export-job.sh > /dev/null
sleep 30

cat /var/lib/mirimon/exporter/last-increment-pos.txt
[[ $(cat /var/log/mirimon/exporter.log | grep -i "error") ]] && echo "Some error in log - /var/log/mirimon/exporter.log"
[[ $(cat /var/log/mirimon/exporter.log | grep -i "fail") ]]  && echo "Some error in log - /var/log/mirimon/exporter.log"

# Check new files are generated in $exported_dir/etl/ready folder.
echo "file number:$(ls $exported_dir/etl/ready | wc -l)"
if [[  $(ls $exported_dir/etl/ready | wc -l) -ne $(($fileNum+3)) ]] 
then
    echo "Not enough files were exported in $exported_dir/etl/ready"
    echo "Test failed!"
    exit 1
fi

ls -alrst $exported_dir/etl/ready
echo "Test passed"  