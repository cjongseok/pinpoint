#!/bin/bash

# Author:   Jongseok Choi <cjongseok@gmail.com>
# Date:     2.12.2016
#
# Description:
#   Most parts are from Naver/Pinpoint Github.
#   I just made it work with my Docker image.   

#set -e
#set -x

SCRIPT_DIR=$(dirname $(readlink -e $0))

## Required env variables ##################################################
# Pinpoint Params
PINPOINT_VERSION=${PINPOINT_VERSION:-1.5.2}
PINPOINT_HOME=${PINPOINT_HOME:-/opt/pinpoint-${PINPOINT_VERSION}}
PINPOINT_AGENT_HOME=${PINPOINT_AGENT_HOME:-${PINPOINT_HOME}/agent}
PINPOINT_APP_HOME=${PINPOINT_APP_HOME:-${PINPOINT_HOME}/app}

# Pinpoint App Params
APP_NAME=${APP_NAME:-PinpointApp}
APP_PATH=${APP_PATH:-${PINPOINT_APP_HOME}/${APP_NAME}}
AGENT_ID=${AGENT_ID:-${APP_NAME}$(date +%s)}

# Agent config Params
AGENT_CONFIG=${PINPOINT_AGENT_HOME}/pinpoint.config
COLLECTOR_IP=${COLLECTOR_IP:-127.0.0.1}
COLLECTOR_TCP_PORT=${COLLECTOR_TCP_PORT:-9994}
COLLECTOR_UDP_STAT_LISTEN_PORT=${COLLECTOR_UDP_STAT_LISTEN_PORT:-9995}
COLLECTOR_UDP_SPAN_LISTEN_PORT=${COLLECTOR_UDP_SPAN_LISTEN_PORT:-9996}
DISABLE_DEBUG=${DISABLE_DEBUG:-true}
############################################################################

# Java params
PINPOINT_JAVA_AGENT=${PINPOINT_AGENT_HOME}/pinpoint-bootstrap-${PINPOINT_VERSION}.jar
PINPOINT_JAVA_OPT="-javaagent:${PINPOINT_JAVA_AGENT} -Dpinpoint.agentId=${AGENT_ID} -Dpinpoint.applicationName=${APP_NAME}"

CONFIGURED=${PINPOINT_HOME}/Configured
LOGS_DIR=${PINPOINT_HOME}/logs
LOG_FILE=${APP_NAME}.log
PID_DIR=${PINPOINT_HOME}/logs/pid
PID_FILE=${APP_NAME}.pid

function func_configure(){
    echo "Start Agent Configuration..."
    sed -i "s/profiler.collector.ip=127.0.0.1/profiler.collector.ip=${COLLECTOR_IP}/g" ${AGENT_CONFIG}
    sed -i "s/profiler.collector.tcp.port=9994/profiler.collector.tcp.port=${COLLECTOR_TCP_PORT}/g" ${AGENT_CONFIG}
    sed -i "s/profiler.collector.stat.port=9995/profiler.collector.stat.port=${COLLECTOR_UDP_STAT_LISTEN_PORT}/g" ${AGENT_CONFIG}
    sed -i "s/profiler.collector.span.port=9996/profiler.collector.span.port=${COLLECTOR_UDP_SPAN_LISTEN_PORT}/g" ${AGENT_CONFIG}

    if [ "$DISABLE_DEBUG" == "true" ]; then
        sed -i 's/level value="DEBUG"/level value="INFO"/' ${PINPOINT_AGENT_HOME}/lib/log4j.xml
    fi
    echo "Agent Configuration DONE."
    echo "true" > $CONFIGURED
}


function func_usage(){
    echo "launcher <ACTION>"
    echo ""
    echo "ACTIONS"
    echo " start"
    echo " stop"
}

function func_init(){
    if [ ! -d $LOGS_DIR ]; then
        mkdir -p $LOGS_DIR
    fi

    if [ ! -d $PID_DIR ]; then
        mkdir -p $PID_DIR
    fi

    if [ -f $CONFIGURED ] && [[ $(cat $CONFIGURED) == "true" ]]; then
        echo "Agent is already configured."
    else
        func_configure
    fi
}

function func_parse_args(){
    local argn=$#
    local argp=0
    local argv=($@)
    local unset action

    while true; do
        #    echo "argv=${argv[argp]}"
        if [[ ${argv[argp]} == "start" ]]; then
            action="start"           
        elif [[ ${argv[argp]} == "stop" ]]; then
            action="stop"
        fi
        break
    done

    echo $action
}

function func_start_app_with_pinpoint(){

    # Run thru Maven
    #export MAVEN_OPTS=$maven_opt
    #MAVEN_GOAL_LAUNCH=spring-boot:run
    #local pid=`nohup mvn -f $APP_HOME/pom.xml $MAVEN_GOAL_LAUNCH -D${AGENT_ID} -Dmaven.pinpoint.version=${PINPOINT_VERSION} >> $LOGS_DIR/$LOG_FILE 2>&1 & echo $!`
    #echo "nohup mvn -f $APP_HOME/pom.xml clean package $MAVEN_GOAL_LAUNCH -D${AGENT_ID} -Dmaven.pinpoint.version=${PINPOINT_VERSION} >> $LOGS_DIR/$LOG_FILE 2>&1 & echo $!"

    # Run with jar
    local pid=`nohup java $PINPOINT_JAVA_OPT -jar $APP_PATH >> $LOGS_DIR/$LOG_FILE 2>&1 & echo $!`
    echo "pid=nohup java $PINPOINT_JAVA_OPT -jar $APP_PATH >> $LOGS_DIR/$LOG_FILE 2>&1 & echo $!"
    echo $pid > $PID_DIR/$PID_FILE
}

function func_kill_app(){
    local pid=`cat $PID_DIR/$PID_FILE`
    echo "stop process $pid"
    kill -9 $pid
}

function func_run_action(){
    local action=$1
    case "$action" in
        start)
            func_run_action "stop"
            func_start_app_with_pinpoint
            tail -f $LOGS_DIR/$LOG_FILE
            ;;
        stop)
            func_kill_app
            ;;
        *)
            func_usage
            ;;
    esac
}

func_init
#argv=($@)
#action=$(func_parse_args $argv)
#func_run_action $action
func_run_action "start"
