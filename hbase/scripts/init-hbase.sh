#!/usr/bin/env bash

# Author:   Jongseok Choi <cjongseok@gmail.com>
# Date:     2.12.2016
#
# Description:
#   Most parts are from Naver/Pinpoint Github.
#   I just made it work with my Docker image.   

quickstart_bin=`dirname "${BASH_SOURCE-$0}"`
quickstart_bin=`cd "$quickstart_bin">/dev/null; pwd`
quickstart_base=$quickstart_bin/..
quickstart_base=`cd "$quickstart_base">/dev/null; pwd`

"$quickstart_bin"/../hbase/hbase/bin/hbase shell $quickstart_base/conf/hbase/init-hbase.txt
