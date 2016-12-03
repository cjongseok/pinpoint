#!/bin/bash
HBASE_SHELL="${HBASE_DOCKER_HOME}/hbase/hbase/bin/hbase shell"
table_name=$1

while true; do
    result=
    result=$(echo "exists '$table_name'" | ${HBASE_SHELL} 2>&1 | grep "does exist")

    if ! [ -z "$result" ]; then
        break
    else
        echo "Waiting for the table ${table_name}..."
    fi
    sleep 1
done
echo "exists"
