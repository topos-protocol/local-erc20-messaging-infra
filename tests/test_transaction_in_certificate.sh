#!/bin/bash
set -e

source $LOCAL_ERC20_HOME/tests/utils.sh


function get_transaction_in_certificate()
{
    echo $(docker compose logs incal-sequencer | grep "CrossSubnetMessageSentFilter" | \
     awk -F 'transaction_hash: ' '{print $2}' | awk -F ',' '{print $1'} | tail -1)
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


# Make token transaction
echo "Executing test of transaction inclusion in certificate..."
check_artifacts
topos_subnet_id=$(get_topos_subnet_id)
tx_hash=$(send_token_with_retry 3 $topos_subnet_id $INCAL_HOST_PORT "txhash")
transaction_valid=$?
echo "Transaction send token result: $transaction_valid, tx hash: $tx_hash"
if [ $transaction_valid -eq 1 ]; then
    echo "Transaction send token failed"
    if [ $network_started -eq 1 ]; then
        echo "Shutting down network started for this test"
        stop_network
    fi
    exit 1
fi

# Check if transaction is registered by the sequencer
# Wait multiple times to give time to sequencer to catch up/create the certificates
for i in {1..10};
do
    transaction_in_certificate=$(get_transaction_in_certificate)
    echo "Last transaction registered by sequencer: $transaction_in_certificate"
    if [ "$transaction_in_certificate" == "$tx_hash" ]; then
        echo "Transaction is registered by the sequencer"
        break
    else
        echo "Transaction is not registered by the sequncer"
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
