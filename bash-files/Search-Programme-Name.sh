#!/bin/bash
# Author: Jinhua Huang
# Usage: Search-Programme.sh dbname

db=$1
user=$1_etl
outputDir=/tmp
fileName=$(basename $0 | cut -d'.' -f1)

loginDB="host=contentinsight.ck4ok8rfkx1j.us-west-2.redshift.amazonaws.com port=5439 dbname=$db user=$user password=fooBar8765A"
i=0

outputFile=$outputDir/$fileName-output

declare -a expectResults=("Move that body" "2")
echo "${expectResults[0]}, ${expectResults[1]}"

psql "$loginDB" -F , --no-align -o $outputFile -t -c \
"SELECT BTRIM(programme_label), programme_id FROM dim_programme WHERE programme_label ILIKE '%' || 'Move' || '%' \
GROUP BY programme_label, programme_id ORDER BY programme_label ASC;"

while read line || [[ -n $line ]] ;
do
    [[ $(echo $line | cut -d',' -f1) == ${expectResults[0]} ]] || ( echo "Test failed, the output is not \"Move that body\"."; i=1; break )
	[[ $(echo $line | cut -d',' -f2) == ${expectResults[1]} ]] || ( echo "Test failed, the output is not \"1\". "; i=2; break )
	
done < "$outputFile"
echo $i

if [[ $i -eq 0 ]]
then
    echo "Test $fileName was successful."
else
    echo "Test $fileName failed at column $i"
fi