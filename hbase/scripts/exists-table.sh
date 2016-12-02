#!/bin/bash
HBASE_SHELL="${HBASE_DOCKER_HOME}/hbase/hbase/bin/hbase shell"
table_name=$1

result=$(echo "exists '$table_name'" | ${HBASE_SHELL} 2>&1 | grep "does exist")

if [ -z "$result" ]; then
	echo "false"
else
	echo "true"
fi
