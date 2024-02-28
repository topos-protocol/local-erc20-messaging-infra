#!/bin/bash
set -e

if [[ -z "${LOCAL_ERC20_HOME}" ]]; then
    echo "You need to setup the environment first. For local tests: source ./tests/environment.sh"
    exit 1
fi

source $LOCAL_ERC20_HOME/tests/utils.sh


function get_last_block () {
    local last_block=`docker compose logs $1 | grep -e 'polygon.blockchain' | grep -e 'new block' | \
    grep -o 'number[=:][[:alnum:]]\{1,100\}' | awk -F'[:=]' '{print $2}' | tail -1` > /dev/null
    echo $last_block
}

function check_certificate_produced () {
    docker compose logs $1 | grep -e 'on_subnet_runtime_proxy_event : NewCertificate' | \
     grep -e "block_number: $2" > /dev/null
    local certificate_produced=$?
    echo $certificate_produced
}

network_started=0

# Start network if it is not running
is_running=$(is_network_running)
if [ $is_running -eq 1 ]; then
    echo "Test network is not running, starting it now..."
    start_network
    network_started=1
    sleep 5 # Warm up network
fi

wait_network_healthy
# Perform test
echo "Executing block cert production test..."
# Get last block number created on the topos polygon edge node
last_block_topos=$(get_last_block topos-node-1)
echo "Topos subnet last block: $last_block_topos"
# Check if certificate with this block number is produced on the topos sequencer
# Try multiple times to give time to sequencer to sync/catch up
for i in {1..10};
do
    certificate_produced=$(check_certificate_produced topos-sequencer $last_block_topos)
    if [ $certificate_produced -eq 0 ]; then
        echo "Certificate for block $last_block_topos produced on topos sequencer"
        break
    else
        echo "Certificate for block $last_block_topos IS NOT produced on topos sequencer"
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


# Get last block number created on the incal polygon edge node
last_block_incal=$(get_last_block incal-node-1)
echo "Incal subnet last block: $last_block_incal"
# Check if certificate with this block number is produced on the incal sequencer
for i in {1..10};
do
    certificate_produced=$(check_certificate_produced incal-sequencer $last_block_incal)
    if [ $certificate_produced -eq 0 ]; then
        echo "Certificate for block $last_block_incal produced on incal sequencer"
        break
    else
        echo "Certificate for block $last_block_incal IS NOT produced on incal sequencer"
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
