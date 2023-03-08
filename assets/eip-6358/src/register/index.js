const Web3 = require('web3');
const BN = require('bn.js');
const fs = require('fs');
const eccrypto = require('eccrypto');
const keccak256 = require('keccak256');
const secp256k1 = require('secp256k1');
const ethereum = require('./ethereum');
const { program } = require('commander');
const config = require('config');
const utils = require('./utils');

const TRANSFER = 0;
const MINT = 1;
const BURN = 2;

let web3;
let netConfig;
let chainId;
let skywalkerFungibleContract;

// Private key
let secret = JSON.parse(fs.readFileSync('./register/.secret').toString());
let testAccountPrivateKey = secret.sks[secret.index];
let privateKeyBuffer = Buffer.from(utils.toByteArray(testAccountPrivateKey));
let publicKeyBuffer = eccrypto.getPublic(privateKeyBuffer);
let publicKey = '0x' + publicKeyBuffer.toString('hex').slice(2);
// the first account pk: 0x878fc1c8fe074eec6999cd5677bf09a58076529c2e69272e1b751c2e6d9f9d13ed0165bc1edfe149e6640ea5dd1dc27f210de6cbe61426c988472e7c74f4cc29
// the first account address: 0xD6d27b2E732852D8f8409b1991d6Bf0cB94dd201
// the second account pk: 0x1c0ae2fe60e7b9e91b3690626318c8759147c6daf96147d886d37b4df8dd8829db901b1a4bbb9374b35322660503495597332b3944e49985fa2e827797634799
// the second account address: 0x30ad2981E83615001fe698b6fBa1bbCb52C19Dfa
// the second account pk: 0xcc643d259ada7570872ef9a4fd30b196f5b3a3bae0a6ffabd57fb6a3367fb6d3c5f45cb61994dbccd619bb6f11c522f71a5f636781a1f234fd79ec93bea579d3
// the second account address: 0x8408925fD39071270Ed1AcA5d618e1c79be08B27
// the third account pk: 0xfb73e1e37a4999060a9a9b1e38a12f8a7c24169caa39a2fb304dc3506dd2d797f8d7e4dcd28692ae02b7627c2aebafb443e9600e476b465da5c4dddbbc3f2782
// the third account address: 0x04e5d0f5478849C94F02850bFF91113d8F02864D

function _init(chainName) {
    let netConfig = config.get(chainName);
    if (!netConfig) {
        console.log('Config of chain (' + chainName + ') not exists');
        return [false];
    }

    let skywalkerFungibleAddress = netConfig.skywalkerFungibleAddress;
    // Load contract abi, and init contract object
    const skywalkerFungibleRawData = fs.readFileSync('./build/contracts/SkywalkerFungible.json');
    const skywalkerFungibleAbi = JSON.parse(skywalkerFungibleRawData).abi;

    let chainId = netConfig.omniverseChainId;
    let web3 = new Web3(netConfig.nodeAddress);
    web3.eth.handleRevert = true;
    let skywalkerFungibleContract = new web3.eth.Contract(skywalkerFungibleAbi, skywalkerFungibleAddress);

    return [true, web3, skywalkerFungibleContract, chainId, netConfig];
}

function init(chainName) {
    let ret = _init(chainName);

    if (ret[0]) {
        web3 = ret[1];
        skywalkerFungibleContract = ret[2];
        chainId = ret[3];
        netConfig = ret[4];
    }

    return ret[0];
}

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

async function initialize(members) {
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'setCooingDownTime',
        testAccountPrivateKey, [netConfig.coolingDown]);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'setMembers', testAccountPrivateKey, [members]);
}

async function mint(to, amount) {
    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [MINT, to, amount]),
    };
    console.log(txData);
    let bData = getRawData(txData, MINT, [to, amount]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function transfer(to, amount) {
    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [TRANSFER, to, amount]),
    };
    let bData = getRawData(txData, TRANSFER, [to, amount]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function burn(from, amount) {
    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [BURN, from, amount]),
    };
    let bData = getRawData(txData, BURN, [from, amount]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function withdraw(amount) {
    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [publicKey]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        initiateSC: netConfig.skywalkerFungibleAddress,
        from: publicKey,
        payload: web3.eth.abi.encodeParameters(['uint8', 'bytes', 'uint256'], [WITHDRAW, '0x', amount]),
    };
    let bData = getRawData(txData, DEPOSIT, [amount]);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'sendOmniverseTransaction', testAccountPrivateKey, [txData]);
}

async function getDepositRequest(index) {
    let ret = await ethereum.contractCall(skywalkerFungibleContract, 'getDepositRequest', [index]);
    console.log(ret);
}

async function sync(toChain, pk) {
    let toChainInfo = _init(toChain);
    if (!toChainInfo[0]) {
        console.log('error init', toChain);
        return;
    }

    let fromNonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [pk]);
    let toNonce = await ethereum.contractCall(toChainInfo[2], 'getTransactionCount', [pk]);
    console.log('nonce', toNonce, fromNonce);
    for (let n = parseInt(toNonce); n < parseInt(fromNonce); n++) {
        let message = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionData', [pk, n]);
        let ret = await ethereum.sendTransaction(toChainInfo[1], toChainInfo[5].chainId, toChainInfo[3], 'sendOmniverseTransaction',
        testAccountPrivateKey, [message.txData]);
        if (!ret) {
            console.log('Send message failed');
        }
    }
}

async function deposit(from, amount) {
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'requestDeposit', testAccountPrivateKey, [from, amount]);
}

async function getNonce(pk) {
    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [pk]);
    console.log(nonce);
}

async function approveDeposit(index) {
    let ret = await ethereum.contractCall(skywalkerFungibleContract, 'getDepositRequest', [index]);
    if (ret.receiver == '0x') {
        console.log('Request not valid');
        return;
    }

    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [publicKey]);
    let transferData = web3.eth.abi.encodeParameters(['bytes', 'uint256'], [ret.receiver, ret.amount]);
    let txData = {
        nonce: nonce,
        chainId: chainId,
        from: publicKey,
        to: TOKEN_ID,
        data: web3.eth.abi.encodeParameters(['uint8', 'bytes'], [DEPOSIT, transferData]),
    };
    let bData = getRawData(txData);
    let hash = keccak256(bData);
    txData.signature = signData(hash, privateKeyBuffer);
    await ethereum.sendTransaction(web3, netConfig.chainId, skywalkerFungibleContract, 'approveDeposit', testAccountPrivateKey, [index, nonce, txData.signature]);
}

async function omniverseBalanceOf(pk) {
    let nonce = await ethereum.contractCall(skywalkerFungibleContract, 'getTransactionCount', [pk]);
    let amount = await ethereum.contractCall(skywalkerFungibleContract, 'omniverseBalanceOf', [pk]);
    console.log('nonce', nonce);
    console.log('amount', amount);
}

async function balanceOf(address) {
    let amount = await ethereum.contractCall(skywalkerFungibleContract, 'balanceOf', [address]);
    console.log('amount', amount);
}

(async function () {
    function list(val) {
		return val.split(',')
	}

    program
        .version('0.1.0')
        .option('-i, --initialize <chain name>,<chain id>|<contract address>,...', 'Initialize omnioverse contracts', list)
        .option('-t, --transfer <chain name>,<pk>,<amount>', 'Transfer token', list)
        .option('-a, --withdraw <chain name>,<amount>', 'Withdraw token', list)
        .option('-ad, --approve_deposit <chain name>,<index>', 'Approve deposit', list)
        .option('-m, --mint <chain name>,<pk>,<amount>', 'Mint token', list)
        .option('-b, --burn <chain name>,<pk>,<amount>', 'Burn token', list)
        .option('-dr, --deposit_request <chain name>,<index>', 'Get deposit request', list)
        .option('-f, --deposit <chain name>,<fromPk>,<amount>', 'Transfer token from an account', list)
        .option('-p, --approval <chain name>,<address>,<address>', 'Approved token number', list)
        .option('-ob, --omniBalance <chain name>,<pk>', 'Query the balance of the omniverse token', list)
        .option('-ba, --balance <chain name>,<address>', 'Query the balance of the local token', list)
        .option('-tr, --trigger <chain name>', 'Trigger the execution of delayed transactions', list)
        .option('-d, --delayed <chain name>', 'Query an executable delayed transation', list)
        .option('-s, --switch <index>', 'Switch the index of private key to be used')
        .option('-sc, --sync <chain name>,<to chain>,<pk>', 'Sync messages from one to the other chain', list)
        .option('-n, --nonce <chain name>,<pk>', 'Nonce of a pk on a chain', list)
        .parse(process.argv);

    if (program.opts().initialize) {
        if (program.opts().initialize.length <= 1) {
            console.log('At least 2 arguments are needed');
            return;
        }
        
        if (!init(program.opts().initialize[0])) {
            return;
        }

        let members = [];
        let param = program.opts().initialize.slice(1);
        for (let i = 0; i < param.length; i++) {
            let m = param[i].split('|');
            members.push({
                chainId: m[0],
                contractAddr: m[1]
            });
        }
        await initialize(members);
    }
    else if (program.opts().withdraw) {
        if (program.opts().withdraw.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().withdraw.length + ' provided');
            return;
        }
        
        if (!init(program.opts().withdraw[0])) {
            return;
        }
        await withdraw(program.opts().withdraw[1]);
    }
    else if (program.opts().transfer) {
        if (program.opts().transfer.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().transfer.length + ' provided');
            return;
        }
        
        if (!init(program.opts().transfer[0])) {
            return;
        }
        await transfer(program.opts().transfer[1], program.opts().transfer[2]);
    }
    else if (program.opts().approve_deposit) {
        if (program.opts().approve_deposit.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().approve_deposit.length + ' provided');
            return;
        }
        
        if (!init(program.opts().approve_deposit[0])) {
            return;
        }
        await approveDeposit(program.opts().approve_deposit[1]);
    }
    else if (program.opts().deposit) {
        if (program.opts().deposit.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().deposit.length + ' provided');
            return;
        }
        
        if (!init(program.opts().deposit[0])) {
            return;
        }
        await deposit(program.opts().deposit[1], program.opts().deposit[2]);
    }
    else if (program.opts().deposit_request) {
        if (program.opts().deposit_request.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().deposit_request.length + ' provided');
            return;
        }
        
        if (!init(program.opts().deposit_request[0])) {
            return;
        }
        await getDepositRequest(program.opts().deposit_request[1]);
    }
    else if (program.opts().mint) {
        if (program.opts().mint.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().mint.length + ' provided');
            return;
        }
        
        if (!init(program.opts().mint[0])) {
            return;
        }
        await mint(program.opts().mint[1], program.opts().mint[2]);
    }
    else if (program.opts().burn) {
        if (program.opts().burn.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().burn.length + ' provided');
            return;
        }
        
        if (!init(program.opts().burn[0])) {
            return;
        }
        await burn(program.opts().burn[1], program.opts().burn[2]);
    }
    else if (program.opts().omniBalance) {
        if (program.opts().omniBalance.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().omniBalance.length + ' provided');
            return;
        }
        
        if (!init(program.opts().omniBalance[0])) {
            return;
        }
        await omniverseBalanceOf(program.opts().omniBalance[1]);
    }
    else if (program.opts().balance) {
        if (program.opts().balance.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().balance.length + ' provided');
            return;
        }
        
        if (!init(program.opts().balance[0])) {
            return;
        }
        await balanceOf(program.opts().balance[1]);
    }
    else if (program.opts().trigger) {
        if (program.opts().trigger.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().trigger.length + ' provided');
            return;
        }
        
        if (!init(program.opts().trigger[0])) {
            return;
        }
        await trigger();
    }
    else if (program.opts().delayed) {
        if (program.opts().delayed.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().delayed.length + ' provided');
            return;
        }
        
        if (!init(program.opts().delayed[0])) {
            return;
        }
        await getDelayedTx();
    }
    else if (program.opts().sync) {
        if (program.opts().sync.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().sync.length + ' provided');
            return;
        }
        
        if (!init(program.opts().sync[0])) {
            return;
        }
        await sync(program.opts().sync[1], program.opts().sync[2]);
    }
    else if (program.opts().nonce) {
        if (program.opts().nonce.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().nonce.length + ' provided');
            return;
        }
        
        if (!init(program.opts().nonce[0])) {
            return;
        }
        await getNonce(program.opts().nonce[1]);
    }
    else if (program.opts().approval) {
        if (program.opts().approval.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().approval.length + ' provided');
            return;
        }
        
        if (!init(program.opts().approval[0])) {
            return;
        }
        await getAllowance(program.opts().approval[1], program.opts().approval[2]);
    }
    else if (program.opts().switch) {
        secret.index = parseInt(program.opts().switch);
        fs.writeFileSync('./register/.secret', JSON.stringify(secret, null, '\t'));
    }
}());
