<div id="top"></div>
<!-- PROJECT LOGO -->
<br />
<div align="center">

  <img src="./.github/assets/topos_logo.png#gh-light-mode-only" alt="Logo" width="200">
  <img src="./.github/assets/topos_logo_dark.png#gh-dark-mode-only" alt="Logo" width="200">

<br />

<p align="center">
Run the local ERC20 messaging infrastructure with docker compose 🐳
</p>

<br />

</div>

## Getting Started

**Install Docker**

https://docs.docker.com/get-docker/

## Stop

```sh
docker compose down -v
```

## Run

If you have a partial or complete existing run, it's recommended to shut down the whole stack (see [Stop](#stop)) before re-running it.

To run the whole stack:

```sh
docker compose up -d
```

### Run with the Executor Service

To additionally run an instance of the Executor Service (and a Redis server as dependency), you can use the `executor-service` profile:

```sh
docker compose --profile executor-service up -d
```

#### Notes

- You need to add the `--profile` flag to all commands, e.g. `docker compose --profile ... down`
- **Important**: The Executor Service must run on the `host` network. As detailed in docker's [documentation](https://docs.docker.com/network/host/), the `host` networking driver only works on Linux. This means Mac/Windows users cannot use this flag and must run the Executor Service natively on the host.

## Env

A few environment variables are editable from the `.env` file found on the root of this repository.

- `TOPOS_EDGE_VERSION`: `topos-network/polygon-edge`'s version
- `TOPOS_VERSION`: `toposware/topos`'s version
- `TOPOS_MESSAGING_PROTOCOL_CONTRACTS_VERSION`: `toposware/topos-smart-contracts`'s version
- `TOPOS_CORE_CONTRACT_ADDRESS`: `ToposCore` contract's address

Other (private) environment variables need be set in the environment (e.g., `~/.zshrc`, `~/.bashrc`):

- `PRIVATE_KEY`: ToposDeployer's private key (see [here](https://www.notion.so/Devnet-Info-8091660458cb4e2ebc5e1c8b79c8671e#5c5f0fc051244f4f8ebaaa1c57c0db24))—ToposDeployer is a account with funds on every subnet
- `TOKEN_DEPLOYER_SALT`: salt for TokenDeployer's deployment (see [here](https://www.notion.so/Devnet-Info-8091660458cb4e2ebc5e1c8b79c8671e#2a9173f7c2814c0fbbab97962dd1762c))
- `TOPOS_CORE_SALT`: salt for ToposCore's deployment (see [here](https://www.notion.so/Devnet-Info-8091660458cb4e2ebc5e1c8b79c8671e#2a9173f7c2814c0fbbab97962dd1762c))
- `TOPOS_CORE_PROXY_SALT`: salt for ToposCoreProxy's deployment (see [here](https://www.notion.so/Devnet-Info-8091660458cb4e2ebc5e1c8b79c8671e#2a9173f7c2814c0fbbab97962dd1762c))
- `SUBNET_REGISTRATOR_SALT`: salt for SubnetRegistrator's deployment (see [here](https://www.notion.so/Devnet-Info-8091660458cb4e2ebc5e1c8b79c8671e#2a9173f7c2814c0fbbab97962dd1762c))

### Important!

To find the right `ToposCore` contract address (to be passed as `TOPOS_CORE_CONTRACT_ADDRESS`), you can:

1. Run the whole stack once (see [Run](#run)) with any or no address
2. Run `docker logs -f contracts` and wait for `ToposCoreProxy` to be deployed
3. Set `ToposCoreProxy`'s address found in the logs above as `TOPOS_CORE_CONTRACT_ADDRESS`
4. [Stop](#stop) and [Run](#run) the whole stack again!

## Resources

- Website: https://toposware.com
- Technical Documentation: https://docs.toposware.com
- Medium: https://toposware.medium.com
- Whitepaper: [Topos: A Secure, Trustless, and Decentralized
  Interoperability Protocol](https://arxiv.org/pdf/2206.03481.pdf)

## License

This project is released under the terms of the MIT license.
