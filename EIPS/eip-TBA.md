---
eip: <to be assigned>
title: Contract Ownership Governance
author: Soham Zemse (@zemse)
discussions-to: https://github.com/ethereum/EIPs/issues/2766
status: Draft
type: Standards Track
category: ERC
created: 2020-07-04
requires: 173, 191
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

A standard implementation for administratively decentralizing ownership of smart contracts.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

By standardizing the owner wallet of a smart contract based dApp as a Governance smart contract address instead of a private key wallet, we can enforce enough consensus for performing administrative tasks on decentralized applications. A smart contracts implementing this makes it more administratively decentralised. This implementation expects enough valid signatures to internally call the administrative method on the application smart contract. This implementation is backwards compatible, meaning existing EIP-173 can upgrade from centralised ownership by deploying a Governance smart contract for their organisation and transferring ownership to it.

## Motivation

<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Traditionally, many contracts that require that they be owned or controlled in some way use `EIP-173` which standardizes the use of ownership in the smart contracts. For example to withdraw funds or perform administrative actions.

```solidity
contract dApp {
  function doSomethingAdministrative() external onlyOwner {
    // admin logic that can be performed by a single wallet
  }
}
```

Often, such administrative rights for a single wallet are written for maintainance purpose, but it overpowers the owner wallet and users need to trust the owner. Rescue operations by owner wallet have raised questions on decentralised nature of the projects. Also, there is a possibility of compromise of owner's private key.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

A `dApp` smart contract considers address of another smart contract called `Governance` as it's owner (instead of a wallet address).

```solidity
contract Governance {
  function makeGovernedCall(
    uint256 nonce,
    address to,
    bytes memory data,
    bytes[] memory signatures
  ) external payable {
    // performs initial checks like enough signatures

    // once all checks are done, the governance makes
    //  a call to the application contract
    (bool success, ) = to.call{value: msg.value}(data);
  }
}
```

So to perform an administrative task, anyone can take initiative to prepare a transaction (`nonce`, `to`, `data`) to the dApp method and prepare a `EIP-191` signed data `0x19 66 <32 bytes governance domain seperator> <32 bytes nonce> <20 bytes to-address> <input data>` and get it signed with over 66% validators (wallets recognized by Governance contract). Once signatures are collected they need to be sorted by increasing address.

Once `signatures` are ready, the `makeGovernedCall` method on the `Governance` contract can be called by any wallet. If signatures are valid, it will make a call to the dApp contract. The dApp contract receives this transaction and checks in `EIP-173` fashion if `msg.sender` is governance contract address and the administrative tasks are performed.

The reference implementation is available [here](https://github.com/zemse/smart-contract-governance/blob/master/contracts/SimpleGovernance/Governance.sol).

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The goals of this effort have been the following:

- decentralise the powers of owner wallet to multiple wallets.
- enable existing `EIP-173` ownership smart contracts to become administratively decentralised.

A similar concept of multisig wallets have already been popularly used so that funds cannot be transferred without consensus. This implementation generalizes the concept to dApp administration.

## Backwards Compatibility

<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

The implementation is compatible with existing dApps implementing `EIP-173` Contract Ownership Standard.

## Test Cases

<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

Test cases include:

- calling dApp administrative method through governance with 66%+ sorted signatures
- calling dApp administrative method through governance with 66%+ unsorted signatures expecting revert
- calling dApp administrative method through governance with less than 66% sorted signatures expecting revert
- replaying a previously executed called dApp administrative method through governance expecting revert
- calling dApp administrative method through governance with repeated signatures expecting revert

Link to [reference test cases](https://github.com/zemse/contract-ownership-governance/blob/master/test/suites/SimpleGovernance.test.ts).

## Implementation

<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

This is a reference implementation. The relevant smart contract is available [here](https://github.com/zemse/smart-contract-governance/blob/master/contracts/SimpleGovernance/Governance.sol) in this [repository](https://github.com/zemse/contract-ownership-governance).

## Security Considerations

<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->

The format of signed data is a part which deserves great attention. As per recommendations of `EIP-191`:

```
0x19 66 <32 bytes domain seperator> <32 bytes nonce> <20 bytes to-address> <input data>.
```

The 1 byte version is choosen as `66` since no other EIP has registered it yet. The domain seperator is specific to the application. It can be as simple as hash of the unique identifier of the dapp followed by a salt for example `keccak256("NameOfDApp12345")`. The salt is used to prevent replay attacks from DApps with similar names. To prevent any incorrect interpretation in the signed data, every element excluding the last has fixed length. This helps the implementation to remain simple, i.e. without involving RLP.

To prevent repeated signatures in the `signatures` array, it is required that caller of `makeGovernedCall` should sort the signatures based on increasing addresses.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
