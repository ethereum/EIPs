---
eip: xxxx
title: Batch Calls JSON Schema
description: Give the details of each call to the wallet
author: George (@JXRow)
discussions-to: https://ethereum-magicians.org/t/batch-calls-json-schema/13935
status: Draft
type: Standards Track
category: ERC
created: 2023-04-24
---


## Abstract

Batch Calls JSON Schema aims to define a JSON from apps to wallet.


## Motivation

Batch calls we use oftenly, like approve then swap, approve then transferFrom, user needs to confirm twice or more in wallet, we put the calls into a JSON, so that the wallet can deal the calls automatic in just one confirm.


### Use case

This JSON Schema is a suggetion to apps and wallet, it dosen't modify smart contracts or RPC-JSON. Just give the details of each call to the wallet.

- The total spend(that’s what user really care about) can be calculated before submit.
- It's much useful for Smart Contract Wallet (Account Abstraction), which can batch calls into one Tx.
- RPC info is given, user needn't to manual connect wallet or switch RPC, it can be automatic done by wallet.
- The data transfer is one direction, wallet needn't return data back to the apps, all user operations can be done in a QR code, scan and confirm.


## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

A simple Batch Calls JSON Schema is:

```solidity
{
    rpc: {
        name: 'Scroll_Alpha',
        url: 'https://alpha-rpc.scroll.io/l2',
        chainId: 534353
    },
    calls: [
        {
            to: '0x67aE69Fd63b4fc8809ADc224A9b82Be976039509',
            value: '0',
            abi: 'function transfer(address to, uint256 amount)',
            params: [
                '0xE44081Ee2D0D4cbaCd10b44e769A14Def065eD4D',
                '1000000'
            ]
        },
        {
            to: '0xE44081Ee2D0D4cbaCd10b44e769A14Def065eD4D',
            value: '1000000000000000',
            abi: '',
            params: []
        }
    ]
}
```

- `rpc` : REQUIRED
  - `name` : OPTIONAL, wallet SHALL use its stored RPC info instead.
  - `url` : OPTIONAL, wallet SHALL use its stored RPC info instead.
  - `chainId` : REQUIRED
- `calls` : REQUIRED, the calls array.
  - `to` : REQUIRED, smart contract address or wallet address
  - `value` : REQUIRED, ETH amount (wei)
  - `abi` : REQUIRED, The abi MAY be a JSON string or the parsed Object (using JSON.parse) which is emitted by the [Solidity compiler](https://solidity.readthedocs.io/en/v0.6.0/using-the-compiler.html#output-description) (or compatible languages).<br>
  The abi MAY also be a [Human-Readable](https://blog.ricmoo.com/human-readable-contract-abis-in-ethers-js-141902f4d917) Abi, which is a format the Ethers created to simplify manually typing the ABI into the source and so that a Contract ABI can also be referenced easily within the same source file.<br>
  The abi SHOULD be empty string if it's not a contract call.
  - `params` : REQUIRED, the params to this contract function call.
  The params SHOULD be empty array if it's not a contract call.


## Example

A complex example is:

```javascript
const { BigNumber, utils } = require('ethers')

let swapData = utils.defaultAbiCoder.encode(
    ['address', 'address', 'uint8'],
    [USDC_ADDRESS, WALLET_ADDRESS, 1] // tokenIn, to, withdraw mode
)

let json = {
    rpc: {
        name: 'Scroll_Alpha',
        url: 'https://alpha-rpc.scroll.io/l2',
        chainId: 534353
    },
    calls: [
        {
            to: USDC_ADDRESS,
            value: '0',
            abi: 'function approve(address spender, uint256 amount)',
            params: [
                ROUTER_ADDRESS, 
                '1000000'
            ]
        },
        {
            to: ROUTER_ADDRESS,
            value: '0',
            abi: 'function swap(tuple(tuple(address pool, bytes data, address callback, bytes callbackData)[] steps, address tokenIn, uint256 amountIn)[] paths, uint amountOutMin, uint deadline) returns (uint amountOut)',
            params: [
                [{
                    steps: [{
                        pool: POOL_ADDRESS,
                        data: swapData,
                        callback: ZERO_ADDRESS,
                        callbackData: '0x',
                    }],
                    tokenIn: USDC_ADDRESS,
                    amountIn: '1000000',
                }],    
                0,
                BigNumber.from(Math.floor(Date.now() / 1000)).add(1800)
            ]
        }
    ]
}
```

The encode function is:

```javascript
for (let call of json.calls) {
    if (call.abi != '') {
        let interface = new utils.Interface([call.abi])
        let funcName = call.abi.slice(9, call.abi.indexOf('('))
        let data = interface.encodeFunctionData(funcName, call.params)
    } else {
        let data = '0x'
    }
    //sign the data..
}
```


## Backwards Compatibility

This EIP is backward compatible with EOA Wallet and Smart Contract Wallet. 



## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
