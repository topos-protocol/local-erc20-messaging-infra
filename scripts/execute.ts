import { Contract, getDefaultProvider, AbstractProvider, isHexString, Wallet, Block, hexlify, TransactionResponse, toUtf8String } from 'ethers'
import { RLP } from '@ethereumjs/rlp'
import { Trie } from '@ethereumjs/trie'

import erc20MessagingJSON from '../artifacts/ERC20Messaging.json'

const main = async function (...args: string[]) {
    const [sourceProviderEndpoint, targetProviderEndpoint, senderPrivateKey, txHash, indexes] = args
    const targetProvider = getDefaultProvider(targetProviderEndpoint)
    const sourceProvider = getDefaultProvider(sourceProviderEndpoint)
    const erc20MessagingAddress = sanitizeHexString(
        process.env.ERC20_MESSAGING_CONTRACT_ADDRESS || ''
    )
    if (!isHexString(erc20MessagingAddress, 20)) {
        console.error(
            'ERROR: Please set token deployer contract address ERC20_MESSAGING_CONTRACT_ADDRESS'
        )
        process.exit(1)
    }

    const targetWallet = new Wallet(senderPrivateKey, targetProvider)
    const erc20Messaging = new Contract(
        erc20MessagingAddress,
        erc20MessagingJSON.abi,
        targetWallet
    )
    const { proofBlob, receiptsRoot } = await getReceiptMptProof(
        txHash,
        sourceProvider
    )
    console.log(`Proof blob: ${proofBlob}`)
    console.log(`Receipts root: ${receiptsRoot}`)
    
    console.log(
        `Executing transaction ${txHash} with indexes ${indexes}...`
    )
    const numArray: number[] = [Number(indexes)];

    const executeTx = await erc20Messaging.execute(numArray, proofBlob, receiptsRoot as string, {
            gasLimit: 5_000_000
    });
    try {
        const receipt = await executeTx.wait();
        if (receipt.status === 1) {
            console.log(`Transaction executed successfully!`, `Transaction hash: ${executeTx.hash}`);
        }
    } catch {
        const tx = await targetProvider.getTransaction(executeTx.hash);
        if (tx === null) {
            throw new Error(`Transaction with hash ${txHash} not found.`);
        }
        try {
            await targetProvider.call(tx);
        } catch (error: any) {
            if (error.data) {
                const decodedError = erc20Messaging.interface.parseError(error.data);
                console.error(`Transaction failed with custom error: ${decodedError!.name}`);
            } else {
                console.error(error);
            }
        }
    }
}

const sanitizeHexString = function (hexString: string) {
    return hexString.startsWith('0x') ? hexString : `0x${hexString}`
}

async function getReceiptMptProof(
    txHash: string,
    provider: AbstractProvider
) {
    const tx: TransactionResponse | null = await provider.getTransaction(txHash);
    if (tx === null) {
        throw new Error(`Transaction with hash ${txHash} not found.`);
    }
    const prefetchTxs = true
    const block = await provider.getBlock(tx.blockHash!, prefetchTxs)
    const rawBlock = await (provider as any).send('eth_getBlockByHash', [
        tx.blockHash,
        prefetchTxs,
    ])

    const receiptsRoot = rawBlock.receiptsRoot
    const trie = await createTrie(block!)
    const trieRoot = trie.root()
    if ('0x' + trieRoot.toString('hex') !== receiptsRoot) {
        throw new Error(
            'Receipts root does not match trie root' +
            '\n' +
            'trieRoot: ' +
            '0x' +
            trieRoot.toString('hex') +
            '\n' +
            'receiptsRoot: ' +
            receiptsRoot
        )
    }

    const indexOfTx = block!.prefetchedTransactions.findIndex(
        (_tx) => _tx.hash === tx.hash
    )
    const key = Buffer.from(RLP.encode(indexOfTx))

    const { stack: _stack } = await trie.findPath(key)
    const stack = _stack.map((node) => node.raw())
    const proofBlob = hexlify(RLP.encode([1, indexOfTx, stack]))
    return { proofBlob, receiptsRoot }
}

async function createTrie(block: Block) {
    const trie = new Trie()
    await Promise.all(
        block.prefetchedTransactions.map(async (tx, index) => {
            const receipt = await tx.wait()
            const { cumulativeGasUsed, logs, logsBloom, status } = receipt!

            return trie.put(
                Buffer.from(RLP.encode(index)),
                Buffer.from(
                    RLP.encode([
                        status,
                        Number(cumulativeGasUsed),
                        logsBloom,
                        logs.map((l) => [l.address, l.topics as string[], l.data]),
                    ])
                )
            )
        })
    )
    return trie
}

const args = process.argv.slice(2)
try {
    main(...args)
} catch (error) {
    console.error(error)
    process.exit(1)
}
