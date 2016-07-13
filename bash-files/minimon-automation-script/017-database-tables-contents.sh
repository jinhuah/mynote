#!/bin/bash

exported_dir="/mnt/mirimon-regression-test/$(basename $(pwd))/tables"

if [[ ! -d $exported_dir ]] 
then
    mkdir -p $exported_dir
	chown -R mysql: $exported_dir
fi

# Function to run myssql query
function run_mysql_query() {

user="root"
password="minime"
database="mirimon002"

mysql_query=$1
mysql -sN --user="$user" --password="$password" --database="$database" --execute="$mysql_query"
}

# Get all tables names
exported_table_list="$exported_dir/00_table_list.csv"
tmp_file="/tmp/00_table_list.csv"
get_all_tables_query="SELECT table_name FROM information_schema.tables WHERE table_schema = 'mirimon002' INTO OUTFILE '$tmp_file' FIELDS TERMINATED BY ','"

run_mysql_query "$get_all_tables_query"

mv $tmp_file $exported_table_list

# Get the description of each table into files
while read line
do 
    describe_table_query="select * from $line;"
	table_to_file="$exported_dir/$line.csv"
	run_mysql_query "$describe_table_query" | sed 's/\t/,/g' > "$table_to_file"
done < $exported_table_list

## Compare tables
#expected_dir="$(dirname $0)/expected/tables"
#expected_table_list="$expected_dir/00_table_list.csv"
#
#count=0
#while read line
#do
#    if [[ -f $expected_dir/$line.csv ]]
#	then
#		diff $exported_dir/$line.csv $expected_dir/$line.csv > /dev/null
#		if [[ $? -ne 0 ]]
#		then 
#			echo "Table \"$line\" has been changed!"
#			diff -y $exported_dir/$line.csv $expected_dir/$line.csv
#			echo ""
#			count=$(($count+1))
#		fi
#	else
#	    echo "Table \"$line\" does not exist before."
#	fi
#done < $exported_table_list
#
## Compare number of tables. If not match, test failed.
#if ! diff -q "$expected_table_list" "$exported_table_list" > /dev/null
#then
#	echo "Number of tables does not match. Expect $(cat $expected_table_list | wc -l) tables, but actually $(cat $exported_table_list | wc -l )".
#	echo "-------------------"
#    diff "$expected_table_list" "$exported_table_list"
#	echo "-------------------"
#	echo "Test failed!"
#	exit 1
#else
#	# If table descriptions are different, test failed.
#	if [[ $count -ne 0 ]]
#	then
#		echo "Test failed!"
#		exit 1
#	fi
#fi
#
#echo "Test passed!"