<div id="top"></div>
<!-- PROJECT LOGO -->
<br />
<div align="center">

  <img src="./.github/assets/topos_logo.png#gh-light-mode-only" alt="Logo" width="200">
  <img src="./.github/assets/topos_logo_dark.png#gh-dark-mode-only" alt="Logo" width="200">

<br />

<p align="center">
Run the full Topos Messaging Protocol with docker compose 🐳
</p>

<br />

</div>

## Getting Started

**Install Docker**

https://docs.docker.com/get-docker/

## Stop

```sh
docker compose -f ./docker-compose.subnet.yml -f ./docker-compose.topos.yml down -v
```

## Run

If you have a partial or complete existing run, it's recommended to shut down the whole stack (see [Stop](#stop)) before re-running it.

To run the whole stack:

```sh
docker compose -f ./docker-compose.subnet.yml -f ./docker-compose.topos.yml up -d
```

## Env

A few environment variables are editable from the `.env` file found on the root of this repository.

- `TOPOSWARE_EDGE_VERSION`: `toposware/polygon-edge`'s version
- `TOPOS_VERSION`: `toposware/topos`'s version
- `TOPOS_MESSAGING_PROTOCOL_CONTRACTS_VERSION`: `toposware/topos-smart-contracts`'s version
- `TOPOS_CORE_CONTRACT_ADDRESS`: `ToposCore` contract's address

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
