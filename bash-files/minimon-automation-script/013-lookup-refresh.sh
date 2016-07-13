#!/bin/bash

user="root"
password="minime"
database="mirimon002"

function run_geolookup() {

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
su mirimon /usr/share/mirimon-geolookup/import.sh > /dev/null

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
su mirimon /usr/share/mirimon-provisioning/import.sh > /dev/null
if [[ $? -ne 0 ]]
then
    echo "Provisioning failed to import file. Please check the log file - $logFile_Provisioning"
	tail -n +$countP $logFile_Provisioning
	exit 1
fi

}

declare -a IPs=("107.143.47.30" "108.192.78.156" "109.158.229.39")
declare -a deviceIDs=(8 9 10)

declare -a output1[3]
declare -a output1_location[3]

declare -a output2[3]
declare -a output2_location[3]

declare -a output3[3]
declare -a output3_location[3]

declare -a output4[3]
declare -a output4_location[3]

declare -a output5[3]
declare -a output5_location[3]


logFile_Geolookup="/var/log/mirimon/geolookup.log"
logFile_Provisioning="/var/log/mirimon/provisioning.log"

# 1) Inject IP addresses into the database
. /usr/share/mirimon/bin/miriserv_env.inc > /dev/null

for (( i=0; i<3; i++ ))
do
    input-files/mmsetip --device ${deviceIDs[$i]} --ip_address ${IPs[$i]}
done

# 2) New IP addresses should been injected into geo_ip_list table
for (( i=0; i<3; i++ ))
do
    mysql_query="select lastlookup from geo_ip_list where ipv4='${IPs[$i]}'"
	output1[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query")
	if [[ $? -ne 0 && ${output1[$i]} != "" ]]
	then
	    echo "mmsetip did not function correctly"
		exit 1
	fi
done

# 3) As geo_loopup has not run yet, goe_lookup should have no data associated with the above IP addresses.
mysql_query="select * from geo_lookup where ip_address='${IPs[0]}' or ip_address='${IPs[1]}' or ip_address='${IPs[2]}'"
[[ $(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query") == "" ]] || echo "The IP address has been looked up before."

# 4) Call run_geolookup function to lookup the IP addresses
run_geolookup

# New IP addresses should been looked up and "lastlookup" date should be updated
for (( i=0; i<3; i++ ))
do
    mysql_query1="select lastlookup from geo_ip_list where ipv4='${IPs[$i]}'"
	output2[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query1")
	if [[ $? -ne 0 && ${output2[$i]} == "" ]]
	then
	    echo "geo-lookup did not update \"lastlookup\" date"
		exit 1
	fi
	
	mysql_query2="select ip_address, valid, geo_city, geo_region, geo_country, isp, asn, geo_lat, geo_long from geo_lookup where ip_address='${IPs[$i]}'"
	output2_location[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query2")
	if [[ $? != 0 || ${output2_location[$i]} == "" ]]
	then
	    echo "Test failed, geo-looup not provide location. IP address is ${IPs[$i]}"
		exit 1
	fi
done

for (( i=0; i<3; i++ ))
do
	# Modify the goe_city to null
	mysql_query="update geo_lookup set geo_city = '' where ip_address='${IPs[i]}'"
	mysql --user="$user" --password="$password" --database="$database" --execute="$mysql_query"
	mysql_query="select ip_address, valid, geo_city, geo_region, geo_country, isp, asn, geo_lat, geo_long from geo_lookup where ip_address='${IPs[$i]}'"
	output2_location[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query")
done

# 5) run_geolookup again. Although geo_city has been changed manually, geolookup should not update it as it does not excess the expired date.
run_geolookup

for (( i=0; i<3; i++ ))
do
    mysql_query="select lastlookup from geo_ip_list where ipv4='${IPs[$i]}'"
	output3[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query")
	if [[ ${output2[$i]} != ${output3[$i]} ]]
	then
	    echo "Output should not be changed. Test failed!"
        echo "previous update time$i is: ${output1[$i]}"
		echo "current update time$i is: ${output2[$i]}"
	    exit 1
	fi
	mysql_query="select ip_address, valid, geo_city, geo_region, geo_country, isp, asn, geo_lat, geo_long from geo_lookup where ip_address='${IPs[$i]}'"
	output3_location[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query")
    if [[ $? != 0 || ${output3_location[$i]} != ${output2_location[$i]} ]]
	then
	    echo "Test failed, geo-looup should not update the location. IP address is ${IPs[$i]}"
		exit 1
	fi	
	
done

# 5) Modify the geo-lookup date in database to make geo-lookup exceed expired days. Default expired day is 7.

mysql_query="select lookup_time from geo_lookup where ip_address='${IPs[0]}'"
lookup_date=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query")

# Get the epoch time
echo "current date: $lookup_date"
lookup_epoch_date=$(date --date="$lookup_date" +%s)
# the epoch time - 8 days (Default expired day is 7 days(604800). Give 8 days(691200) to make sure it works.)
old_epoch_date=$(($lookup_epoch_date- 691200 | bc ))
# Convert to human readable time
old_date=$(date -d @$old_epoch_date "+%y-%m-%d %H:%M:%S")
echo "Set to old date: $old_date"

# Update table geo_lookup with old date
for (( i=0; i<3; i++ ))
do
    mysql_query="update geo_lookup set lookup_time='$old_date' where ip_address='${IPs[i]}'"
    mysql --user="$user" --password="$password" --database="$database" --execute="$mysql_query"
	
	mysql_query1="select lookup_time from geo_lookup where ip_address='${IPs[i]}'"
    output4[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query1")
	mysql_query2="select geo_city from geo_lookup where ip_address='${IPs[i]}'"
    output4_location[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query2")
done

# 5) Run geolookup again
echo "geo-lookup refreshes the data"
run_geolookup

# 6) Verify whether the "lastlookup" has been updated, and geo_city has been updated
for (( i=0; i<3; i++ ))
do
    mysql_query1="select lookup_time from geo_lookup where ip_address='${IPs[i]}'"
    output5[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query1")
	mysql_query2="select geo_city from geo_lookup where ip_address='${IPs[i]}'"
    output5_location[$i]=$(mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query2")
	if [[ ${output5[$i]} == ${output4[$i]} || ${output5_location[$i]} == "" ]]
	then 
	    echo "Test failed, the database not updated after expired. IP address is ${IPs[$i]}"
		exit 1
	fi
done 

echo "Test passed!"