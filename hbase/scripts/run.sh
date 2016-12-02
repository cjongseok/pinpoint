#!/usr/bin/env bash

# Author:   Jongseok Choi <cjongseok@gmail.com>
# Date:     2.12.2016
#
# Description:
#   Most parts are from Naver/Pinpoint Github.
#   I just made it work with my Docker image.   

this="${BASH_SOURCE-$0}"
while [ -h "$this" ]; do
  ls=`ls -ld "$this"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '.*/.*' > /dev/null; then
    this="$link"
  else
    this=`dirname "$this"`/"$link"
  fi
done

# convert relative path to absolute path
bin=`dirname "$this"`
script=`basename "$this"`
bin=`cd "$bin">/dev/null; pwd`
this="$bin/$script"

BASE_DIR=`dirname "$bin"`

. ${BASE_DIR}/scripts/start-hbase.sh
func_start_hbase

tail -f ${BASE_DIR}/hbase/hbase/bin/../logs/*.log
