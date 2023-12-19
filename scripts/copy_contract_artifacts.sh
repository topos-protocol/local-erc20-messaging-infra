#!/bin/bash

set -e

contracts_list="ERC20Messaging BurnableMintableCappedERC20 ToposCore"

mkdir -p ./artifacts
for contract in $contracts_list
do
    echo "Copying $contract:"
    docker cp topos-sequencer:$(docker exec -t topos-sequencer find /contracts -name $contract.json | tr -d '\r') ./artifacts/
done
