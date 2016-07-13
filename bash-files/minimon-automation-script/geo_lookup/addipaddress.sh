#!/bin/bash

# This file is to inject WAN ip addresses into Mirimon database in batch. 
# By giving a start position and an end position in ipaddresses.txt,the addresses between the positions will be injected into Mirimon database.
# Usage: ./addipaddress.sh x y
# Example: ./addipaddress.sh 10 30

# File with WAN ip addresses
fileName=ipaddresses.txt

# Set the positions in the file
if [[ $# -eq 0 ]]
then
    i=1  # Start position in ip address file
    j=10 # End position in ip address file
else
    i=$1
	j=$2
fi
    
a=0
source /usr/share/mirimon/bin/miriserv_env.inc

# Start to inject ip addresses 
while read line || [[ -n $line ]] ;
do

a=$(($a+1))
if  [[ $a -ge $i &&  $a -le $j ]]
then
    ./mmsetip --device $a --ip_address $line
fi

if [[ $a -gt $j ]]
then
    break;
fi

done < $fileName
