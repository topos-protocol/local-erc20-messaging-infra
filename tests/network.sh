#!/bin/bash
set -e

source $LOCAL_ERC20_HOME/tests/utils.sh

if [ $1 = 'start' ]; then
    start_network
    exit $?
elif [ $1 = 'stop' ]; then
    stop_network
    exit $?
elif [ $1 = 'check' ]; then
    check_network_health
    exit $?
elif [ $1 = 'is_running' ]; then
    is_network_running
    exit $?        
else
    echo "Invalid argument"
    exit 1
fi