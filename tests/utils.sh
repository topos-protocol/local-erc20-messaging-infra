#!/bin/bash
set -e

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
    SERVICE_NAMES=$(docker compose config --dry-run --services | grep -e node -e sequencer)
    EXPECTED=$(docker compose ps -aq $SERVICE_NAMES | wc -l)
    COUNT=$(docker inspect --format "{{.State.Health.Status }}" $(docker compose ps -aq $SERVICE_NAMES) | grep "^healthy$"|wc -l)
    if [[ $COUNT -eq $EXPECTED ]]; then
        echo 0
    else
        echo 1
    fi
}

is_network_running() {
    SERVICE_NAMES=$(docker compose config --dry-run --services | grep -e node -e sequencer)
    COUNT=$(docker compose ps -aq $SERVICE_NAMES | wc -l) 
    if [[ $COUNT -eq 0 ]]; then
        echo 1
    else
        echo 0
    fi
}
