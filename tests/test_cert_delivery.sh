#!/bin/bash
set -e

if [[ -z "${LOCAL_ERC20_HOME}" ]]; then
    echo "You need to setup the environment first. For local tests: source ./tests/environment.sh"
    exit 1
fi

source $LOCAL_ERC20_HOME/tests/utils.sh

function get_last_sequncer_generated_certificate () {
    # $1 - node name
    local last_certificate=`docker compose logs $1 | grep -e 'Submitting new certificate to the TCE network: ' | awk -F': ' '{print $3}' | tail -1` > /dev/null
    echo $last_certificate
}

function check_certificate_delivered () {
    # $1 - node name
    # $2 - certificate id
    docker compose logs $1 | grep -e "Certificate delivered $2" > /dev/null
    local certificate_delivered=$?
    echo $certificate_delivered
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
echo "Executing test to check if certificates are broadcasted and delivered..."
# Get last certificate generated by topos sequencer and incal sequencers
topos_certificate=$(get_last_sequncer_generated_certificate topos-sequencer)
incal_certificate=$(get_last_sequncer_generated_certificate incal-sequencer)
echo "Topos certificate: $topos_certificate, incal certificate $incal_certificate"

# Get TCE endpoints
TCE_NODES=$(docker compose config --services | grep -e topos-node)
NUMBER_OF_DELIVERIES=$(echo $TCE_NODES | wc -w)
NUMBER_OF_DELIVERIES=$(($NUMBER_OF_DELIVERIES*2)) # Each node receives 2 certificates (one topos, one incal certificate)

for i in {1..10};
do
    counter=0
    for node in $TCE_NODES
    do
        for test_certificate in $topos_certificate $incal_certificate
        do
            echo "Checking if certificate $test_certificate is delivered to $node"
            delivered=$(check_certificate_delivered $node $test_certificate)
            if [ $delivered -eq 0 ]; then
                echo "Certificate $test_certificate delivered to $node"
                counter=$((counter+1))
            else
                echo "Certificate $test_certificate IS NOT delivered to $node"
            fi
        done
    done
    if [ $counter -eq $NUMBER_OF_DELIVERIES ]; then
        echo "Certificates $topos_certificate and $incal_certificate  delivered to all TCE nodes"
        break
    else
        echo "Certificate $topos_certificate and $incal_certificate ARE NOT delivered to all TCE nodes"
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
