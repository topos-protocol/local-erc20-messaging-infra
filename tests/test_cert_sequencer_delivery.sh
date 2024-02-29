#!/bin/bash
set -e

if [[ -z "${LOCAL_ERC20_HOME}" ]]; then
    echo "You need to setup the environment first. For local tests: source ./tests/environment.sh"
    exit 1
fi

source $LOCAL_ERC20_HOME/tests/utils.sh


function receipts_root_in_delivered_certificate()
{
    echo $(docker logs topos-sequencer 2>&1 | grep -e "Received certificate from TCE " | \
     awk -F 'receipts_root_hash: "' '{print $2}' | awk -F '\",' '{print $1}' | tail -1)
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
export ERC20_MESSAGING_CONTRACT_ADDRESS=$(get_erc20_contract_address)
export TOPOS_CORE_PROXY_CONTRACT_ADDRESS=$(get_topos_core_proxy_contract_address)

wait_network_healthy
# Make token transaction on incal network targeting topos network
# In should be delivered to target topos sequencer
echo "Executing test of certificate delivery to target topos sequencer..."
check_artifacts
topos_subnet_id=$(get_topos_subnet_id)
receipts_root_hash=$(send_token_with_retry 3 $topos_subnet_id $INCAL_HOST_PORT)
transaction_valid=$?
echo "Transaction send token result: $transaction_valid, receipts root hash: $receipts_root_hash"
if [ $transaction_valid -eq 1 ]; then
    echo "Transaction send token failed"
    if [ $network_started -eq 1 ]; then
        echo "Shutting down network started for this test"
        stop_network
    fi
    exit 1
fi


# Check if transaction is delivered to target topos sequncer
# Wait multiple times to give time to target sequencer to catch up
# Check receipts root in delivered certificate
for i in {1..10};
do
    delivered_receipts_root_hash=$(receipts_root_in_delivered_certificate)
    echo "Receipts root hash in delivered certificate: $delivered_receipts_root_hash"
    if [ "$delivered_receipts_root_hash" == "$receipts_root_hash" ]; then
        echo "Transaction with correct receipt root hash is delivered to target sequencer"
        break
    else
        echo "Transaction is not delivered to target sequencer"
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
