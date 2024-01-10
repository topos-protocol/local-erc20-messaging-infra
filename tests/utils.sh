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

function wait_network_healthy () {
    while true;
    do
        echo "Waiting for network to be healthy..."
        healthy=$(check_network_health)
        if [ $healthy -eq 0 ]; then
            echo "Network is healthy"
            break
        else
            echo "Network is not healthy yet, trying again in 5 seconds"
            sleep 5
            continue
        fi
    done
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


function graphql_get_tce_certificate () {
    # $1 - certificate id
    # $2 - tce graphql endpoint
    local query='{"query": "{certificate(certificateId: {value: \"'$1'\"})  \n { \n id \n stateRoot \n}}"}'
    TCE_CERT=$(curl -X POST -H "Content-Type: application/json" -d "$query" $2 | jq -r '.data.certificate.id')
    echo $TCE_CERT
}


function get_incal_subnet_id()
{
    echo $(docker compose logs incal-sequencer | grep "for subnet id 0x" | awk -F 'for subnet id ' '{print $2}')
}

function get_topos_subnet_id()
{
    echo $(docker compose logs topos-sequencer | grep "for subnet id 0x" | awk -F 'for subnet id ' '{print $2}')
}


function send_token_with_retry()
{
    # $1 - number of retries
    # $2 - target subnet id
    # $3 - host port of the edge node to send transaction from
    # $4 - return value type
    arbitrary_receiver_address="0xF472626faeb65277342e07962a8333A735934554"
    amount="1"
    for i in $(seq 1 $1);
    do
        result=$(npx ts-node $LOCAL_ERC20_HOME/scripts/send-token http://localhost:$3 $PRIVATE_KEY $2 $arbitrary_receiver_address $amount $4)
        if [ -z "$result" ]; then
            echo "Transaction failed, trying again in 5 seconds for $(($i+1)) time"
            if [ $i -eq $1 ]; then
                return 1
            fi        
            sleep 5
            continue
        fi
        echo "$result"
        break
    done
}

function check_artifacts()
{
    if [ ! -d $LOCAL_ERC20_HOME/artifacts ] || [ -z "$(ls -A $LOCAL_ERC20_HOME/artifacts)" ]; then
        $LOCAL_ERC20_HOME/scripts/copy_contract_artifacts.sh
    fi
}

function get_erc20_contract_address()
{
    echo $(docker compose logs contracts-topos | grep "ERC20_MESSAGING_CONTRACT_ADDRESS" | \
     awk -F 'ERC20_MESSAGING_CONTRACT_ADDRESS=' '{print $2}')
}

function get_topos_core_proxy_contract_address()
{
    echo $(docker compose logs contracts-topos | grep "TOPOS_CORE_PROXY_CONTRACT_ADDRESS" | \
     awk -F 'TOPOS_CORE_PROXY_CONTRACT_ADDRESS=' '{print $2}')
}

