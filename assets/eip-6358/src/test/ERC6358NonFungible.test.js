const utils = require('./utils');
const BN = require('bn.js');
const secp256k1 = require('secp256k1');
const keccak256 = require('keccak256');
const Web3 = require('web3');
const providerUrl = 'http://localhost:8545';
const web3js = new Web3(providerUrl);
const assert = require('assert');

const CHAIN_ID = 0;
const TOKEN_ID = 1;
const TOKEN_SYMBOL = 'ERC6358NonFungible';
const COOL_DOWN = 2;

const TRANSFER = 0;
const MINT = 1;
const BURN = 2;

const NonFungible = artifacts.require('./ERC6358NonFungibleExample.sol');
const OmniverseProtocolHelper = artifacts.require('./OmniverseProtocolHelper.sol');
NonFungible.defaults({
    gas: 8000000,
});

NonFungible.numberFormat = 'String';

const owner = '0xe092b1fa25DF5786D151246E492Eed3d15EA4dAA';
const user1 = '0xc0d8F541Ab8B71F20c10261818F2F401e8194049';
const user2 = '0xf1F8Ef6b4D4Ba31079E2263eC85c03fD5a0802bF';

const ownerPk = '0xb0c4ae6f28a5579cbeddbf40b2209a5296baf7a4dc818f909e801729ecb5e663dce22598685e985a6ed1a557cf2145deba5290418b3cc00680a90accc9b93522';
const user1Pk = '0x99f5789b8b0d903a6e868c5fb9971eedde37da046e69d49c903a1b33167e0f76d1f1269628bfcff54e0581a0b019502394754e900dcbb69bf30010d51967d780';
const user2Pk = '0x25607735c05d91b504425c25567154aea2fd07e9a515b7872c7f783aa58333942b9d6ac3afacdccfe2585d1a4617f23a802a32bb6abafe13aaba2d386d44f52d';

const ownerSk = Buffer.from('0cc0c2de7e8c30525b4ca3b9e0b9703fb29569060d403261055481df7014f7fa', 'hex');
const user1Sk = Buffer.from('b97de1848f97378ee439b37e776ffe11a2fff415b2f93dc240b2d16e9c184ba9', 'hex');
const user2Sk = Buffer.from('42f3b9b31fcaaa03ca71cab7d194979d0d1bedf16f8f4e9414f0ed4df699dd10', 'hex');

let signData = (hash, sk) => {
    let signature = secp256k1.ecdsaSign(Uint8Array.from(hash), Uint8Array.from(sk));
    return '0x' + Buffer.from(signature.signature).toString('hex') + (signature.recid == 0 ? '1b' : '1c');
}

let getRawData = (txData, op, params) => {
    let bData;
    if (op == MINT) {
        bData = Buffer.concat([Buffer.from(new BN(op).toString('hex').padStart(2, '0'), 'hex'), Buffer.from(params[0].slice(2), 'hex'), Buffer.from(new BN(params[1]).toString('hex').padStart(32, '0'), 'hex')]);
    }
    else if (op == TRANSFER) {
        bData = Buffer.concat([Buffer.from(new BN(op).toString('hex').padStart(2, '0'), 'hex'), Buffer.from(params[0].slice(2), 'hex'), Buffer.from(new BN(params[1]).toString('hex').padStart(32, '0'), 'hex')]);
    }
    else if (op == BURN) {
        bData = Buffer.concat([Buffer.from(new BN(op).toString('hex').padStart(2, '0'), 'hex'), Buffer.from(params[0].slice(2), 'hex'), Buffer.from(new BN(params[1]).toString('hex').padStart(32, '0'), 'hex')]);
    }
    let ret = Buffer.concat([Buffer.from(new BN(txData.nonce).toString('hex').padStart(32, '0'), 'hex'), Buffer.from(new BN(txData.chainId).toString('hex').padStart(8, '0'), 'hex'),
        Buffer.from(txData.initiateSC.slice(2), 'hex'), Buffer.from(txData.from.slice(2), 'hex'), bData]);
    return ret;
}

let encodeMint = (from, toPk, tokenId, nonce) => {
    let txData = {
        nonce: nonce,
        chainId: CHAIN_ID,
        initiateSC: NonFungible.address,
        from: from.pk,
        payload: web3js.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [MINT, toPk, tokenId])
    }
    let bData = getRawData(txData, MINT, [toPk, tokenId]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, from.sk);
    return txData;
}

let encodeBurn = (from, toPk, tokenId, nonce) => {
    let txData = {
        nonce: nonce,
        chainId: CHAIN_ID,
        initiateSC: NonFungible.address,
        from: from.pk,
        payload: web3js.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [BURN, toPk, tokenId])
    }
    let bData = getRawData(txData, BURN, [toPk, tokenId]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, from.sk);
    return txData;
}

let encodeTransfer = (from, toPk, tokenId, nonce) => {
    let txData = {
        nonce: nonce,
        chainId: CHAIN_ID,
        initiateSC: NonFungible.address,
        from: from.pk,
        payload: web3js.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [TRANSFER, toPk, tokenId])
    }
    let bData = getRawData(txData, TRANSFER, [toPk, tokenId]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, from.sk);
    return txData;
}
    
contract('ERC6358NonFungible', function() {
    before(async function() {
        await initContract();
    });

    let nonFungible;

    let initContract = async function() {
        let protocol = await OmniverseProtocolHelper.new();
        NonFungible.link(protocol);
        nonFungible = await NonFungible.new(CHAIN_ID, TOKEN_SYMBOL, TOKEN_SYMBOL, {from: owner});
        NonFungible.address = nonFungible.address;
        await nonFungible.setMembers([[CHAIN_ID, NonFungible.address]]);
        await nonFungible.setCoolingDownTime(COOL_DOWN);
    }

    const mintToken = async function(from, toPk, tokenId) {
        let nonce = await nonFungible.getTransactionCount(from.pk);
        let txData = encodeMint(from, toPk, tokenId, nonce);
        await nonFungible.sendOmniverseTransaction(txData);
        await utils.sleep(COOL_DOWN);
        await utils.evmMine(1, web3js.currentProvider);
        let ret = await nonFungible.triggerExecution();
    }
    
    describe('Verify transaction', function() {
        before(async function() {
            await initContract();
        });

        describe('Signature error', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeTransfer({pk: user1Pk, sk: user1Sk}, user2Pk, TOKEN_ID, nonce);
                txData.signature = txData.signature.slice(0, -2);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'Signature error');
            });
        });

        describe('Sender not signer', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeTransfer({pk: user1Pk, sk: user1Sk}, user2Pk, TOKEN_ID, nonce);
                txData.from = ownerPk;
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'Signature error');
            });
        });

        describe('Nonce error', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk) + 20;
                let txData = encodeTransfer({pk: user1Pk, sk: user1Sk}, user2Pk, TOKEN_ID, nonce);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'Nonce error');
            });
        });

        describe('All conditions satisfied', function() {
            it('should succeed', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
                let ret = await nonFungible.sendOmniverseTransaction(txData);
                assert(ret.logs[0].event == 'TransactionSent');
                let count = await nonFungible.getTransactionCount(ownerPk);
                assert(count == 0, "The count should be zero");
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                ret = await nonFungible.triggerExecution();
                count = await nonFungible.getTransactionCount(ownerPk);
                assert(count == 1, "The count should be one");
            });
        });

        describe('Cooling down', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID + 1, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'Transaction cached');
            });
        });

        describe('Transaction duplicated', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk) - 1;
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
                let ret = await nonFungible.sendOmniverseTransaction(txData);
                assert(ret.logs[0].event == 'TransactionExecuted');
            });
        });

        describe('Cooled down', function() {
            it('should succeed', async () => {
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                ret = await nonFungible.triggerExecution();
                let count = await nonFungible.getTransactionCount(ownerPk);
                assert(count == 2);
            });
        });

        describe('Malicious', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk) - 1;
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID + 1, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                let malicious = await nonFungible.isMalicious(ownerPk);
                assert(malicious, "It should be malicious");
            });
        });
    });

    describe('Personal signing', function() {
        before(async function() {
            await initContract();
        });

        describe('All conditions satisfied', function() {
            it('should succeed', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
                let bData = getRawData(txData, MINT, [user2Pk, TOKEN_ID]);
                let hash = keccak256(Buffer.concat([Buffer.from('\x19Ethereum Signed Message:\n' + bData.length), bData]));
                txData.signature = signData(hash, ownerSk);
                let ret = await nonFungible.sendOmniverseTransaction(txData);
                assert(ret.logs[0].event == 'TransactionSent');
                let count = await nonFungible.getTransactionCount(ownerPk);
                assert(count == 0, "The count should be zero");
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                ret = await nonFungible.triggerExecution();
                count = await nonFungible.getTransactionCount(ownerPk);
                assert(count == 1, "The count should be one");
            });
        });
    });
    
    describe('Omniverse Transaction', function() {
        before(async function() {
            await initContract();
        });
    
        describe('Wrong initiate smart contract', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeTransfer({pk: user1Pk, sk: user1Sk}, user2Pk, TOKEN_ID, nonce);
                txData.initiateSC = user1;
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'Wrong initiateSC');
            });
        });
    
        describe('All conditions satisfied', function() {
            it('should succeed', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                let count = await nonFungible.getDelayedTxCount();
                assert(count == 1, 'The number of delayed txs should be one');
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                ret = await nonFungible.triggerExecution();
            });
        });
    
        describe('Malicious transaction', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk) - 1;
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                let count = await nonFungible.getDelayedTxCount();
                assert(count == 0, 'The number of delayed txs should be zero');
            });
        });
    
        describe('User is malicious', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'User malicious');
            });
        });
    });
    
    describe('Get executable delayed transaction', function() {
        before(async function() {
            await initContract();
            let nonce = await nonFungible.getTransactionCount(ownerPk);
            let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
            await nonFungible.sendOmniverseTransaction(txData);
        });

        describe('Cooling down', function() {
            it('should be none', async () => {
                let tx = await nonFungible.getExecutableDelayedTx();
                assert(tx.sender == '0x', 'There should be no transaction');
            });
        });

        describe('Cooled down', function() {
            it('should be one transaction', async () => {
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                let tx = await nonFungible.getExecutableDelayedTx();
                assert(tx.sender == ownerPk, 'There should be one transaction');
            });
        });
    });
    
    describe('Trigger execution', function() {
        before(async function() {
            await initContract();
        });

        describe('No delayed transaction', function() {
            it('should fail', async () => {
                await utils.expectThrow(nonFungible.triggerExecution(), 'No delayed tx');
            });
        });

        describe('Not executable', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user2Pk, TOKEN_ID, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                await utils.expectThrow(nonFungible.triggerExecution(), 'Not executable');
            });
        });
    });
    
    describe('Mint', function() {
        before(async function() {
            await initContract();
        });

        describe('Not owner', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeMint({pk: user2Pk, sk: user2Sk}, user1Pk, TOKEN_ID, nonce);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), "Not owner");
            });
        });

        describe('Is owner', function() {
            it('should succeed', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeMint({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                let ret = await nonFungible.triggerExecution();
                assert(ret.logs[0].event == 'OmniverseTokenTransfer');
                let tokenOwner = await nonFungible.omniverseOwnerOf(TOKEN_ID);
                assert(user1Pk == tokenOwner, 'Owner should be user1');
                let balance = await nonFungible.omniverseBalanceOf(user1Pk);
                assert(TOKEN_ID == balance, 'Balance should be one');
            });
        });
    });
    
    describe('Burn', function() {
        before(async function() {
            await initContract();
            await mintToken({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID);
        });

        describe('Not owner', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeBurn({pk: user2Pk, sk: user2Sk}, user1Pk, TOKEN_ID, nonce);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), "Not owner");
            });
        });

        describe('Token not exist', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeBurn({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID + 1, nonce);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), "Token not exist");
            });
        });

        describe('All conditions satisfied', function() {
            it('should succeed', async () => {
                let nonce = await nonFungible.getTransactionCount(ownerPk);
                let txData = encodeBurn({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                let ret = await nonFungible.triggerExecution();
                await utils.expectThrow(nonFungible.omniverseOwnerOf(TOKEN_ID), "Token not exist");
                assert(ret.logs[0].event == 'OmniverseTokenTransfer');
                let balance = await nonFungible.omniverseBalanceOf(user1Pk);
                assert(0 == balance, 'Balance should be zero');
            });
        });
    });
    
    describe('Transfer', function() {
        before(async function() {
            await initContract();
            await mintToken({pk: ownerPk, sk: ownerSk}, user1Pk, TOKEN_ID);
        });

        describe('Not token owner', function() {
            it('should fail', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeTransfer({pk: user2Pk, sk: user2Sk}, user2Pk, TOKEN_ID, nonce);
                await utils.expectThrow(nonFungible.sendOmniverseTransaction(txData), 'Not owner');
            });
        });

        describe('Balance enough', function() {
            it('should succeed', async () => {
                let nonce = await nonFungible.getTransactionCount(user1Pk);
                let txData = encodeTransfer({pk: user1Pk, sk: user1Sk}, user2Pk, TOKEN_ID, nonce);
                await nonFungible.sendOmniverseTransaction(txData);
                await utils.sleep(COOL_DOWN);
                await utils.evmMine(1, web3js.currentProvider);
                let ret = await nonFungible.triggerExecution();
                assert(ret.logs[0].event == 'OmniverseTokenTransfer');
                let tokenOwner = await nonFungible.omniverseOwnerOf(TOKEN_ID);
                assert(user2Pk == tokenOwner, 'Token owner should be user2');
                let balance = await nonFungible.omniverseBalanceOf(user1Pk);
                assert('0' == balance, 'Balance should be zero');
                balance = await nonFungible.omniverseBalanceOf(user2Pk);
                assert(TOKEN_ID == balance, 'Balance should be one');
            });
        });
    });
});