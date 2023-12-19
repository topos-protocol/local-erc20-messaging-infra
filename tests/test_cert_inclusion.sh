#!/bin/bash
set -e

source $LOCAL_ERC20_HOME/tests/utils.sh

export ERC20_MESSAGING_CONTRACT_ADDRESS=$(get_erc20_contract_address)
export TOPOS_CORE_PROXY_CONTRACT_ADDRESS=$(get_topos_core_proxy_contract_address)

function check_certificate_inclusion_with_retry()
{
    # $1 - number of retries
    # $2 - receipts root hash
    for i in $(seq 1 $1);
    do
        certificate=$(npx ts-node $LOCAL_ERC20_HOME/scripts/get-certificate http://localhost:$INCAL_HOST_PORT $2)
        if [ -z "$certificate" ]; then
            "$(($i+1))"
            sleep 5
            continue
        fi
        echo 0
        break
    done
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


# Perform test
echo "Executing certificate inclusion test..."
incal_subnet_id=$(get_incal_subnet_id)
receipts_root=$(send_token_with_retry 3 $incal_subnet_id $TOPOS_HOST_PORT)
echo "Receipts root hash: $receipts_root"
is_certificate_present=$(check_certificate_inclusion_with_retry 3 $receipts_root)
if [ $is_certificate_present -eq 0 ]; then
    echo "Certificate is present"
    exit 0
else
    echo "Certificate is NOT present"
    exit 1
fi



# Stop network if started for this test
if [ $network_started -eq 1 ]; then
    echo "Shutting down network started for this test"
    stop_network
fi
