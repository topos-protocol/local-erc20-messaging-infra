#!/bin/bash
set -e

source $LOCAL_ERC20_HOME/tests/utils.sh


network_started=0

# Start network if it is not running
is_running=$(is_network_running)
if [ $is_running -eq 1 ]; then
    echo "Test network is not running, starting it now..."
    start_network
    network_started=1
    sleep 5 # Warm up network
fi


# Perform test
echo "Executing network health check test..."
# Check if all relevant containers are healthy
for i in {1..10};
do
    network_healthy=$(check_network_health)
    if [ $network_healthy -eq 0 ]; then
        echo "Network is healthy"
        break
    else
        echo "Network is NOT healthy"
        if [[ "$i" != '10' ]]; then
            echo "Trying again in 5 seconds for $(($i+1)) time"
            sleep 5
            continue
        fi
        if [ $network_started -eq 1 ]; then
            echo "Test failed, shutting down network started for this test"
            stop_network
        fi        
        exit 1
    fi
done



# Stop network if started for this test
if [ $network_started -eq 1 ]; then
    echo "Shutting down network started for this test"
    stop_network
fi
