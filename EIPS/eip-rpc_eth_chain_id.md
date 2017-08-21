## Preamble

    EIP: <to be assigned>
    Title: Create `eth_chainId` method for JSON-RPC
    Author: Isaac Ardis: isaac.ardis@gmail.com, Wei Tang: hi@that.world, [@tcz001](https://github.com/tcz001)
    Type: Standard Track
    Category: Interface
    Status: Draft
    Created: 2017-08-21


## Simple Summary
Include `eth_chainId` method in `eth_`-namespaced JSON-RPC methods.

## Abstract
The `eth_chainId` method should return a single STRING result
for an integer value in hexadecimal format, describing the
currently configured "Chain Id" value used for signing replay-protected transactions,
introduced via EIP-155.

## Motivation
Currently although we can use net_version RPC call to get the
current network ID, there's no RPC for querying the chain ID. This
makes it impossible to determine the current actual blockchain using
the RPC.

## Specification

----

### eth_chainId

Returns the currently configured chain id, a value used in replay-protected transaction
signing as introduced by EIP-155.

##### Parameters
none

##### Returns

`QUANTITY` - big integer of the current chain id. Defaults are mainnet=61, morden=62.

##### Example
```js
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

// Result
{
  "id":83,
  "jsonrpc": "2.0",
  "result": "0x3d" // 61
}
```

----

## Rationale
An ETH/ETC client can accidentally connect to an ETC/ETH RPC
endpoint without knowing it unless it tries to sign a transaction or
it fetch a transaction that is known to have signed with a chain
ID. This has since caused trouble for application developers, such as
MetaMask, to add multi-chain support.

Please note related links:

- [Parity PR](https://github.com/paritytech/parity/pull/6329)
- [Geth Classic PR (merged)](https://github.com/ethereumproject/go-ethereum/pull/336)


## Backwards Compatibility
Not relevant.

## Test Cases
Not currently implemented.

## Implementation
Would be good to have a test to confirm that expected==got.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
