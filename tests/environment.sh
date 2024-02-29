#!/bin/bash

# This script is used to set up the environment variables for the local test environment
# It reads the .env and .env.secrets files and sets the environment variables accordingly
# If the first argument is "unset", it will unset the environment variables instead of setting them

if test -f .env; then
    if [ "$1" = "unset" ]; then
        echo "Unsetting local test environment based on .env file"
        unset $(grep -v '^#' .env | sed -E 's/(.*)=.*/\1/' | xargs)
    else
        echo "Setting up local test environment based on .env file"
        export $(grep -v '^#' .env | xargs)
    fi
else
    echo ".env file doesn't exists, this command do nothing"
fi

if test -f .env.secrets; then
   if [ "$1" = "unset" ]; then
        echo "Unsetting local test environment based on .env.secrets file"
        unset $(grep -v '^#' .env.secrets | sed -E 's/(.*)=.*/\1/' | xargs)
    else
        echo "Setting up local test environment based on .env.secrets file"
        export $(grep -v '^#' .env.secrets | xargs)
    fi
fi
