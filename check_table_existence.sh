#!/bin/bash

# $1: table list file

set -u
TRUE="true"
FALSE="false"

usage="$0 <TABLE_LIST_FILE>"

table_list_file=${1:-hbase_tables.list}
tmp_file=.hbase_out.tmp
#HBASE=../hbase/hbase/bin/hbase
HBASE=${HBASE_HOME}/bin/hbase

#HBASE_SCRIPT=list.hbase
HBASE_SCRIPT=list-tables.hbase

table_list=()

# TODO: generalize it for common hbase scripts
function func_list_tables(){
    ${HBASE} shell $HBASE_SCRIPT > $tmp_file
    local line_num=$(cat $tmp_file | wc -l)
    local border_line=$(cat -n $tmp_file | grep seconds | awk '{print $1}')

    local tables=$(cat $tmp_file | sed -e '1d' -e ''"$border_line"','"$line_num"'d')
    if [ ! -z tables ]; then
        local table
        for table in $tables; do
            table_list+=(''"$table"'')
        done
    fi
    rm $tmp_file
}

# $1: target item
function func_contains(){
    local array=${table_list[@]}
    local target=$1
    local item

    for item in ${array[@]}; do
        if [[ $item == $target ]]; then
            echo $TRUE
            return
        fi
    done
    echo $FALSE
}

# Check arguments
if [ ! -f $table_list_file ] || [ $# -gt 1 ]; then
    echo $usage
    exit 255
fi

# Get table list from Hbase
func_list_tables

if [ ${#table_list[@]} -lt 1 ]; then
    echo $FALSE
    exit 255
fi

# Compare table lists
while read -r line; do
    #    echo "line=$line >>> $(func_contains $line)"
    if [[ $(func_contains $line) == $FALSE ]]; then
        echo $FALSE 
        exit
    fi
done <<< "$(cat $table_list_file)"
echo $TRUE
