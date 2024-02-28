#!/bin/bash

# This script is used to initialize a sequencer node in local-ERC20 tests
# It replaces the default topos command by this script manipulating resources
# and updating configurations.
#
# What it does:
# 1. Install net-tools package to use netstat command in the healthcheck
# 2. Copy consensus and libp2p directories from $DATA_FOLDER to $CONFIG_FOLDER
# 3. Copy genesis.json from $GENESIS_FOLDER to $SUBNET_FOLDER
# 4. Start the sequencer node using topos node up command

set -e

if [[ -z "${SUBNET}" ]]; then
    echo "SUBNET is not set"
    exit 1
fi

if [[ -z "${CONFIG_FOLDER}" ]]; then
    echo "CONFIG_FOLDER is not set"
    exit 1
fi

if [[ -z "${DATA_FOLDER}" ]]; then
    echo "DATA_FOLDER is not set"
    exit 1
fi

if [[ -z "${GENESIS_FOLDER}" ]]; then
    echo "GENESIS_FOLDER is not set"
    exit 1
fi

if [[ -z "${SUBNET_FOLDER}" ]]; then
    echo "SUBNET_FOLDER is not set"
    exit 1
fi

apt-get update
apt-get install -y net-tools
source /contracts/.env

mkdir -p $CONFIG_FOLDER/node/sequencer-$SUBNET/consensus -p $CONFIG_FOLDER/node/sequencer-$SUBNET/libp2p -p $SUBNET_FOLDER

cp -vr $DATA_FOLDER/consensus $CONFIG_FOLDER/node/sequencer-$SUBNET/
cp -vr $DATA_FOLDER/libp2p $CONFIG_FOLDER/node/sequencer-$SUBNET/
cp -vr $GENESIS_FOLDER/genesis.json $SUBNET_FOLDER/genesis.json

cp -f $CONFIG_FOLDER/node/sequencer-$SUBNET/config.toml $CONFIG_FOLDER/node/sequencer-$SUBNET/config.toml.new
sed -i -e '/subnet-contract-address =/ s/= .*/= "'$TOPOS_CORE_PROXY_CONTRACT_ADDRESS'"/' $CONFIG_FOLDER/node/sequencer-$SUBNET/config.toml.new
cp -f $CONFIG_FOLDER/node/sequencer-$SUBNET/config.toml.new $CONFIG_FOLDER/node/sequencer-$SUBNET/config.toml

echo "Topos Core contract address: $TOPOS_CORE_PROXY_CONTRACT_ADDRESS, set manually in config"

topos node up --name sequencer-$SUBNET --home $CONFIG_FOLDER --no-edge-process

