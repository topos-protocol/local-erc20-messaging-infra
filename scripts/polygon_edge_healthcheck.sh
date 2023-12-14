#!/bin/bash

set -e
block_number=$($1/polygon-edge status | grep 'Current Block Number (base 10) = .[0-9]*' | awk '{print $7}')

if [ $block_number -gt 0 ] 
then
    exit 0;
else 
    exit 1;
fi
