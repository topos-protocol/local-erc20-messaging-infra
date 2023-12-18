import { Contract, Wallet, providers, utils } from 'ethers'

import toposCoreJson from '../artifacts/ToposCore.json'

/// Usage:
/// ts-node ./scripts/get-certificate.ts <node endpoint> <receipts root hash>
const main = async function (...args: string[]) {
    const [providerEndpoint, receiptsRoot] = args
    const provider = providers.getDefaultProvider(providerEndpoint)
    const toposDeployerPrivateKey = sanitizeHexString(
        process.env.PRIVATE_KEY || ''
    )
    if (!utils.isHexString(toposDeployerPrivateKey, 32)) {
        console.error(
            'ERROR: Please provide a valid toposDeployer private key! (PRIVATE_KEY)'
        )
        process.exit(1)
    }
    const toposCoreProxyAddress = sanitizeHexString(
        process.env.TOPOS_CORE_PROXY_CONTRACT_ADDRESS || ''
    )
    if (!utils.isHexString(toposCoreProxyAddress, 20)) {
        console.error(
            'ERROR: Please set topos core proxy contract address  TOPOS_CORE_PROXY_CONTRACT_ADDRESS'
        )
        process.exit(1)
    }

    const wallet = new Wallet(toposDeployerPrivateKey, provider)
    const toposCore = new Contract(
        toposCoreProxyAddress,
        toposCoreJson.abi,
        wallet
    )

    const certificateId = await toposCore.receiptRootToCertId(receiptsRoot)
    console.log(`${certificateId}`)
}

const sanitizeHexString = function (hexString: string) {
    return hexString.startsWith('0x') ? hexString : `0x${hexString}`
}

const args = process.argv.slice(2)
main(...args)
