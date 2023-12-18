import { AbiCoder, Contract, Wallet, isHexString, JsonRpcProvider, parseUnits } from 'ethers'

import erc20MessagingJSON from '../artifacts/ERC20Messaging.json'
import ERC20 from '../artifacts/BurnableMintableCappedERC20.json'

const TOKEN_NAME = 'Topos Token'
const TOKEN_SYMBOL = 'TOPX'
const MINT_CAP = 100_000_000
const DAILY_MINT_LIMIT = 100
const INITIAL_SUPPLY = 10_000_000

/// Usage:
/// ts-node ./scripts/send-token.ts <node endpoint> <sender private key> <receiver account> <amount>
const main = async function (...args: string[]) {
    const [providerEndpoint, senderPrivateKey, receiverAddress, amount] = args
    const provider = new JsonRpcProvider(providerEndpoint)
    const erc20MessagingAddress = sanitizeHexString(
        process.env.ERC20_MESSAGING_CONTRACT_ADDRESS || ''
    )
    if (!isHexString(erc20MessagingAddress, 20)) {
        console.error(
            'ERROR: Please set token deployer contract address ERC20_MESSAGING_CONTRACT_ADDRESS'
        )
        process.exit(1)
    }
    const targetSubnetId = sanitizeHexString(process.env.TARGET_SUBNET || '')
    if (!targetSubnetId) {
        console.error(
            'ERROR: Please set target subnet id TARGET_SUBNET'
        )
        process.exit(1)
    }

    const wallet = new Wallet(senderPrivateKey, provider)
    const erc20Messaging = new Contract(
        erc20MessagingAddress,
        erc20MessagingJSON.abi,
        wallet
    )

    // Check if token is already deployed. If not, deploy it
    let deploy = true
    let tokenAddress = ''
    const numberOfTokens = await erc20Messaging.getTokenCount()
    for (let index = 0; index < numberOfTokens; index++) {
        const tokenKey = await erc20Messaging.getTokenKeyAtIndex(index)
        const [token, address] = await erc20Messaging.tokens(tokenKey)
        if (token == TOKEN_SYMBOL) {
            deploy = false
            tokenAddress = address
        }
    }
    if (deploy) {
        const defaultToken = AbiCoder.defaultAbiCoder().encode(
            ['string', 'string', 'uint256', 'uint256', 'uint256'],
            [TOKEN_NAME, TOKEN_SYMBOL, MINT_CAP, DAILY_MINT_LIMIT, INITIAL_SUPPLY]
        )
        // Deploy token if not previously deployed
        await erc20Messaging.deployToken(defaultToken, {
            gasLimit: 5_000_000,
        })
        // get token address
        const token = await erc20Messaging.getTokenBySymbol(TOKEN_SYMBOL)
        tokenAddress = token.addr
    }

    // Approve token burn
    const erc20 = new Contract(tokenAddress, ERC20.abi, wallet)
    await erc20.approve(await erc20Messaging.getAddress(), amount)

    // Send token
    const sendTokenTx = await erc20Messaging.sendToken(
        targetSubnetId,
        TOKEN_SYMBOL,
        receiverAddress,
        amount,
        {
            gasLimit: 10_000_000,
            gasPrice: parseUnits('100', 'gwei')
        }
    );
    const receipt = await sendTokenTx.wait()

    // Print out block's receipt's root
    const rawBlock = await provider.send('eth_getBlockByHash', [
        receipt.blockHash,
        true,
    ])
    console.log(rawBlock.receiptsRoot)
}

const sanitizeHexString = function (hexString: string) {
    return hexString.startsWith('0x') ? hexString : `0x${hexString}`
}

const args = process.argv.slice(2)
main(...args)
