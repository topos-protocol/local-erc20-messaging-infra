#!/bin/bash

network_started=0

# Start network if it is not running
$LOCAL_ERC20_HOME/tests/network.sh is_running
is_running=$?
if [ $is_running -eq 1 ]; then
    echo "Test network is not running, starting it now..."
    $LOCAL_ERC20_HOME/tests/network.sh start
    network_started=1
    sleep 5 # Warn up network
fi


# Perform test
echo "Executing block cert production test..."

# Get last block number created on the topos polygon edge node
last_block_topos=`docker compose logs topos-node-1 | grep -e topos::edge -e '"polygon.blockchain": "new block"' | \
grep -o 'number:[[:alnum:]]\{1,100\}' | awk -F ":" '{print $2}' | tail -1`
echo "Topos subnet last block: $last_block_topos"

# Check if certificate with this block number is produced on the topos sequencer
docker compose logs topos-sequencer | grep -e 'on_subnet_runtime_proxy_event : NewCertificate' | grep -e "block_number: $last_block_topos"
ret=$?
if [ $ret -eq 0 ]; then
    echo "Certificate for block $last_block_topos produced on topos sequencer"
else
    echo "Certificate for block $last_block_topos IS NOT produced on topos sequencer"
    exit 1
fi


# Stop network if started for this test
if [ $network_started -eq 1 ]; then
    echo "Shutting down network started for this test"
    $LOCAL_ERC20_HOME/tests/network.sh stop
fi
