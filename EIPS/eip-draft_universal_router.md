---
eip: <to be assigned>
title: Universal Router Contract
description: Universal router contract designed for token allowance that eliminates all `approve`` transactions in the future.
author: Zergity (zergity@gmail.com)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-12-12
requires: EIP20, EIP721, EIP1155
---

## Abstract

A universal router contract that executes transactions with a sequence of the following steps:
  * (optional) call a calculation contract to get the `amountIn` value, and ensure that this `amountIn` is no larger than an input `amountInMax`
  * transfer `amountIn` of a token from `msg.sender` to a `recipient`
  * call a contract to execute an action
  * (optional) verify the returning amount of a token must be no less than an input `amountOutMin`

## Motivation

Most Dapp router contracts have the following pattern: approve/permit, (optional) calculation, transferFrom, action, and (optionally) verify the token output. This requires `n*m*k` `allow` (or `permit`) transactions, for `n` Dapps, `m` tokens and `k` user addresses. Even though user approves a contract to spend their tokens, it's the front-end code that they trust, not the contract itself. Anyone can create a front-end code and trick the users to sign a transaction to interact with the Uniswap Router contract and steal all their tokens that have been approved.

Universal Router separates token allowance logic from application logic, acts as a manifest for users when signing a transaction. It saves `(n-1)*m*k` approval transactions for old tokens and **ALL** approval transactions for new tokens. The Universal Router contract is designed to be simple and easy to verify and audit. It's counter-factually `CREATE2`'ed so any new token contracts can hardcode and skip the allowance check entirely.

## Specification

```
struct Action {
    bool output;    // true for output action, false for input action
    uint eip;       // token type: 0 for ETH, # for ERC#
    address token;  // token contract address
    uint id;        // token id for ERC-721 and ERC-1155
    uint amount;    // amountInMax for input action, amountOutMin for output action
    address recipient;
    address code;   // contract address
    bytes data;     // contract data
}
```

```
interface IUniversalRouter {
    function exec(Action[] calldata actions) external payable returns (uint[] memory results);
}
```

Universal Router contract is counter-factually `CREATE2`'ed at address <TBD> across all Ethererum networks.

### Input Action
Actions with `action.output == false` declare which and how many tokens are transferred from `msg.sender` to `action.recipient`.
1. If the `action.code` address is not `0x0`, the `amountIn` is returned by the contract call `action.code.call(action.data)`. This contract function must return a single `uint256` value. If this `amountIn` is greater than `action.amount`, reverts with "EXCESSIVE_INPUT_AMOUNT". If the `action.code` is `0x0`, `amountIn` is set to `action.amount`.
2. `action.eip` specifies the token standard, or `ETH` if it's `0`. If the token is `ETH` and the `recipient` is `0x0`, step #3 is skipped and no transfer is taken, the `amountIn` will be passed to the next output action as the transaction value.
3. Transfer `amountIn` of tokens from `msg.sender` to `action.recipient`.

### Output Action
Actions with `action.output == true` declare the main application action to call, and optionally verify the output token after all is done.
1. If the `action.amount` is not zero, the current token balance of `action.recipient` is recorded for later comparison.
2. Execute the `action.code.call{value: value}(action.data)`, where `value` can be zero or the `amountIn` of the last `ETH` input with an empty `recipient` (see Input Action #2).

### Output Token Verification
After all the actions are handled as above, every token balance tracked in Output Action #2 is queried again for comparison. The balance change must not be less than `action.amount` of each output action, otherwise reverts with "INSUFFICIENT_OUTPUT_AMOUNT".

## Rationale

The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

The `Permit` type signature is not supported since the purpose of Universal Router is to eliminate all `approve` signatures for new tokens, and *most* for old tokens.

Flashloan transactions are out of scope since it requires support from the application contracts themself.

## Backwards Compatibility

Old token contracts (ERC20, ERC721 and ERC1155) require approval for Universal Router once for each account.

New token contracts can pre-configure the Universal Router as a trusted spender, and no approval transaction is required.

## Test Cases

Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation

An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations

All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
