#!/bin/bash

start_network () {
    echo "Starting local infra network..."
    docker compose up -d
    local ret=$?
    echo "Local infra network started with result: $ret"
    return $ret
}


stop_network () {
    echo "Stopping local infra network..."
    docker compose down --volumes
    local ret=$?
    echo "Local infra network stopped with result: $ret"
    return $ret
}


check_network_health () {
    # Check if all relevant containers are healthy
    # TODO: Add healcheck for sequencers, currenly only tce and polygon edge nodes are checked
    SERVICE_NAMES=$(docker compose config --dry-run --services | grep -e node)
    EXPECTED=$(docker compose ps -aq $SERVICE_NAMES | wc -l)
    COUNT=$(docker inspect --format "{{.State.Health.Status }}" $(docker compose ps -aq $SERVICE_NAMES) | grep "^healthy$"|wc -l)
    echo "Number of Healthy containers: $COUNT"
    if [[ $COUNT -eq $EXPECTED ]]; then
        echo "All expected containers healthy"
        return 0
    else
        echo "Unhealthy containers"
        docker compose -f tools/docker-compose.yml ps -a peer boot
        return 1
    fi
}

is_network_running() {
    SERVICE_NAMES=$(docker compose config --dry-run --services | grep -e node -e sequencer)
    COUNT=$(docker compose ps -aq $SERVICE_NAMES | wc -l) 
    if [[ $COUNT -eq 0 ]]; then
        echo "Network is not running"
        return 1
    else
        echo "Network is running"
        return 0
    fi
}


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
