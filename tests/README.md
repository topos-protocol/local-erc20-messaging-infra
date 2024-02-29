## Description

These tests are designed to be executed locally against a running instance of the Local ERC20 messaging infrastructure (Docker Compose setup). The tests are written as bash scripts, with each test being a separate file that can be run individually. Each test checks if the infrastructure is running and, if not, starts it. The tests then run and report the results. After the tests have been completed, if the infrastructure is started by a particular script, it is stopped in the same way, so there is no need to stop it manually. If local ERC20 messaging infrastructure is started prior to the test script's execution, tests do not start or stop the Docker Compose network.

## Prerequisites

In addition to the prerequisites for the Local ERC20 messaging infrastructure, the following are required to run the tests:

- [Node.js](https://nodejs.org/en/)

## Running the tests

While being in the root of the repository, install the dependencies:

```sh
$ npm install
```

Then, edit the `.env` file to your liking. The default values should work for most cases. Then, source the `.env` file:

```sh
$ source ./tests/environment.sh
```

To run the tests, execute the tests from the root of the repository:

```sh
$ ./tests/<NAME_OF_TEST>.sh
# e.g. ./tests/test_network_health.sh
```

After your tests if you want to unset the environment variables:

```sh
source ./tests/environment.sh unset
```
### Notes

- The tests use TypeScript scripts to interact with the infrastructure. These scripts can be found in the `./scripts` directory. Currently, there are two main scripts available:

    - `get-certificate.ts`: Retrieves the certificate from the `ToposCore.sol` contract of a subnet.
    - `send-token.ts`: Performs a token transfer transaction using the Topos Messaging Protocol, from one subnet to another, using the `ERC20Messaging.sol` contract.

- The smart contract artifacts are copied from the `topos-sequencer` container to the `./artifacts` directory. These artifacts are then used by the TypeScript scripts to interact with the infrastructure. There is no need to copy them manually, as the tests will take care of that automatically using a helper script, `./scripts/copy_contract_artifacts.sh`.
