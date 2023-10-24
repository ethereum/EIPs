---
eip: ?
title: Disclosure of a security flaw in ERC-20 transferring workflow
status: Draft
type: Informational
author: Dexaran (@Dexaran) <dexaran@ethereumclassic.org>, Vladimir Vencálek <vladimir@callisto.network>, Yuriy Kharytoshin (@yuriy77k) <yuriy@callisto.network>, Laurent Riche (@spatialiste) <tonton@callisto.network>
discussions-to: https://ethereum-magicians.org/t/disclosure-of-a-security-flaw-in-erc-20-transferring-workflow/16249
created: 2023-10-24
---

## Abstract

The following describes a security flaw in the transferring workflow of [ERC-20](./eip-20.md) token standard. It must be taken into account that all token standards that declare full backwards compatibility with [ERC-20](./eip-20.md) also inherit this security flaw, for example [ERC-1363](./eip-1363.md).

## Motivation

Security flaw disclosures are an important part of software development. Increasing awareness of the problem helps the development community to implement solutions and minimize the damage that a particular flaw can deal to the users.

## Specification

### [ERC-20](./eip-20.md) design overview

[ERC-20](./eip-20.md) standard declares two methods of transferring tokens: (1) `transfer`  function and (2) `approve` & `transferFrom` pattern. `approve` & `transferFrom` is supposed to be used to deposit tokens to contracts. The `transfer` function is supposed to be used for transfers between externally owned addresses however this is not directly written in the specification. If the tokens are sent to a contract address via the `transfer` function then the recipient contract will not recognize the depoist.

### Security flaw

**The `transfer` function does not notify the recipient of an incoming transaction which makes error handling impossible.** Error handling is an essential part of secure software development. If tokens are sent to any contract via the `transfer` function and the recipient contract does not support extraction of tokens (i.e. it doesn't implement any functions which would allow to send tokens out) then it is a clear case of user error that must be reverted. For example if a user would send plain ether to a contract that does not explicitly declare that it is intended to accept ether deposits then such transaction would be reverted automatically. In case of [ERC-20](./eip-20.md) tokens a user can push the token contract into incorrect state where a user no longer controls the tokens by picking a wrong function when performing a transaction.

**A burden of determining the method of transferring tokens is placed on the user in a situation where one option is obviously wrong and will result in a loss of funds.** Prompting a user to make a decision on the internal logic of the contract combined with the lack of an implementation of error handling for users actions is another security failure that can result in incorrect token contract behavior and a loss of funds for the end user.

### Token losses

As of 17.08.2023 $201,690,741 worth of [ERC-20](./eip-20.md) tokens were lost in top 50 (measured by transactions count) token contracts due to the described problem of the standard. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
