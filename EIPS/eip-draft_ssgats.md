---
eip: <to be assigned>
title: Stupid Simple Gas Abstracted Transaction (SSGAT) Encoding Standard
author: Aakil Fernandes (@aakilfernandes) <aakilfernandes@gmail.com>
discussions-to: https://ethereum-magicians.org/t/eip-draft-stupid-simple-gas-abstracted-transaction-ssgat-encoding-standard/3729
status: Draft
type: Informational
category: N/A
created: 2019-10-28
requires: None
replaces: None
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
A transaction encoding standard that facilitates users paying mining fees with ERC20 tokens.


## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This EIP contains a standard for encoding gas abstracted transactions that is:
1. Stupid: Does not require "smart" contract wallets
2. Simple: Does not require relays, staking, chain monitoring, or VM upgrades

This EIP does not concern networking or transaction priority. This EIP is not designed for compatibility with the Ethereum Wire Protocol.


## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
This EIP allows users to pay for Ethereum transactions with ERC-20 tokens, as opposed to status quo where Ether is the only pragmatic option. This allows to use Ethereum without Ether.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
We use the acronym SSGAT for "Stupid Simple Gas Abstracted Transaction".

An SSGAT is an encoding of parameters which can be decoded and split into two Ethereum transactions:
1. `transaction_a` which contains an Ethereum transaction a user wishes to submit
2. `transaction_b` which contains an Ethereum transaction which pays the miner

The main "trick" of an SSGAT is that `transaction_a` and `transaction_b` have sequential nonces, such that `transaction_b` can only be mined if `transaction_a` is mined.

An SSGAT contains parameters
1. `transaction_a`:
  1. `nonce`
  2. `startgas`
  3. `from`
  4. `to`
  5. `value`
  6. `data`
  7. `v`
  8. `r`
  9. `s`
2. `transaction_b`:
  1. `startgas`
  3. `v`
  4. `r`
  5. `s`
3. `erc20`:
  1. `address`
  2. `handoffAddress`
  3. `amount`

All parameters are fixed length, with the exception of `transaction_a_data`. This allows us to push `transaction_a_data` to the end and use a simple concatenation for encoding.

>> ToDo: Specify parameter lengths and endianness

````
ssgat = concat([
  transaction_a_nonce,
  transaction_a_startgas,
  transaction_a_from,
  transaction_a_to,
  transaction_a_value,
  transaction_a_r,
  transaction_a_s,
  transaction_b_startgas,
  transaction_b_v,
  transaction_b_r,
  transaction_b_s,
  erc20_address,
  erc20_handoff,
  erc20_amount,
  transaction_a_data
])
````

The miner who receives an SSGAT **should** decode the SSGAT into `transaction_a`, `transaction_b`, with the following assumptions:

1. `transaction_b_nonce = transaction_a_nonce + 1`
2. `transaction_a_gasPrice` and `transaction_b_gasPrice` are 0
3. `transaction_b_value` is 0
4. `transaction_b` is a made using a solidity `transferFrom(address from, address to, uint256 amount)` where:
  1. `address from` is `transaction_a_from`
  2. `address to` is `erc20_handoff`
    1. `erc20_handoff` *should* be a contract deployed on the network which allows the current miner to drain all ERC20 balances
  3. `amount` is `erc20_amount`

The miner **should*** also generate `transaction_c` which pulls payment from `erc20_handoff`

The miner should include `transaction_a`, `transaction_b`, and `transaction_c` in direct sequence


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
### Lack of Ethereum Wire Protocol Compatibility
Since payments are made using ERC20 tokens, and the value of ERC20 tokens are in constant flux, there is no way for nodes to objectively prioritize SSGATs. Rather, a subjective judgement must be made based on the value of tokens to the miner. While an on-chain exchange *could* provide a means to objectively prioritize SSGATs, that strategy would necessitate guardrails around transaction volume and ignores that miners have subjective valuations for ERC20 tokens. For these reasons, we ignore DEVP2P compatibility concerns.

### `transaction_b` Assumptions
`transaction_b` contains strict assumptions about *how* a user pays the miner, specifically that a simple ERC20 `transferFrom(address,address,uint256)` is used. This is because it is necessary for `transaction_b` to be statically analyzed.

For traditional transactions, users incur a penalty in terms of a wasted transaction fee when they fail to include sufficient transaction fees. With `transaction_b`, that is no longer the case. The payment is made in an ERC20 transfer, which will fail if not enough gas is included.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
SSGATs are not designed for the Ethereum Wire Protocol. SSGATs can be decoded and marshalled into standard transactions that are backwards-compatible over the Ethereum Wire Protocol. How SSGATs get from a user to a miner, and how a miner prioritizes SSGATs is not in scope for this EIP.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
>> ToDo: Include test cases of SSGAT encoding

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
>> ToDo: Include SSGAT implementation

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
