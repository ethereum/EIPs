---
title: Interface of Confidential Transactions Supported Token Contract
description: General interface for confidential transaction supported token contract with allowance and approve functionality.
author: Siyuan Zheng (@andrewcoder666) <zhengsiyuan.zsy@antgroup.com>, Xiaoyu Liu (@elizabethxiaoyu) <jiushi.lxy@antgroup.com>, Wenwei Ma (@madyinglight) <huiwei.mww@antgroup.com>, Jun Meng Tan (@chadxeth) <junmeng.t@antgroup.com>, Yuxiang Fu (@tmac4096) <kunfu.fyx@antgroup.com>, Kecheng Gao (@thanks-v-me-50) <gaokecheng.gkc@antgroup.com>, Alwin Ng Jun Wei (@alwinngjw) <alwin.ng@antgroup.com>, Chenxin Wang (@3235773541) <wcx465603@antgroup.com>, Xiang Gao (@GaoYiRu) <gaoxiang.gao@antgroup.com>, yuanshanhshan (@xunayuan) <yuanshanshan.yss@antgroup.com>, Hao Zou (@BruceZH0915) <situ.zh@antgroup.com>, Yanyi Liang <eason.lyy@antgroup.com>, Yuehua Zhang (@astroyhzcc) <ruoying.zyh@antgroup.com>
discussions-to: https://ethereum-magicians.org/t/interface-of-confidential-transactions-supported-token-contract/23586
status: Draft
type: Standards Track
category: ERC
created: 2025-05-09
requires: 20
---

## Abstract

This proposal draws up a standard interface of confidential transaction supported token contracts, by providing basic functionality without loss of generality. Contracts following the standard can provide confidentiality for users’ balances and token transfer value.

## Motivation

A standard interface allows confidential transactions of tokens on Ethereum (and/or other EVM-compatible blockchains) to be applied by certain parties which are sensitive to transfer amount, or by privacy-preserving applications.


## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.


### Contract Interface

#### Methods

##### name

Returns the name of the token - e.g. `"MyConfidentialToken"` .

OPTIONAL - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.

```
function name() public view returns (string)
```

##### symbol

Returns the symbol of the token. e.g. `"cHIX"` .

OPTIONAL - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.

```
function symbol() public view returns (string)
```

##### decimals

Returns the number of decimals the token uses - e.g. `8` , means to divide the token amount by `100000000` to get its user representation.

OPTIONAL - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.

```
function decimals() public view returns (uint8)
```

##### confidentialBalanceOf

Returns the account confidential balance of another account with address `owner` .

```
function confidentialBalanceOf(address owner) 
public view returns (bytes memory confidentialBalance)
```

##### confidentialTransfer

Transfers `value` amount of tokens (behind `_confidentialTransferValue` ) to address `_to` , and MUST fire the `ConfidentialTransfer` event. The function SHOULD `throw` if the message caller’s `_proof` of this transfer fails to be verified.

Note:

* Callers MUST handle `false` from returns (bool success). Callers MUST NOT assume that `false` is never returned!
* Implementations can fully customize the proof system, (de)serialization strategies of `bytes` and/or the business workflow. For example, when implementing "Zether" (see https://doi.org/10.1007/978-3-030-51280-4_23 ) confidential token contracts, the `_confidentialTransferValue` and accounts' confidential balances will be encrypted homomorphically under ElGamal public keys, and `_proof` will consist 3 parts to check:

  * `_confidentialTransferValue` is well encrypted under both caller's public key and `_to` 's;
  * The plaintext `value` behind `_confidentialTransferValue` is non-negative;
  * The caller's confidential balance is actually enough to pay the plaintext `value` behind `_confidentialTransferValue` .

```
function confidentialTransfer(
  address _to,
  bytes memory _confidentialTransferValue, 
  bytes memory _proof
) public returns (bool success)
```

##### confidentialTransferFrom

Transfers `value` amount of tokens (behind `_confidentialTransferValue` ) from address `_from` to address `_to` , and MUST fire the `ConfidentialTransfer` event.

The `confidentialTransferFrom` method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD `throw` unless the `_from` account has deliberately authorized the sender of the message via some mechanism, and SHOULD `throw` if the message caller’s `_proof` of this transfer fails to be verified.

Note:

* Callers MUST handle `false` from returns (bool success). Callers MUST NOT assume that `false` is never returned!
* Implementations can fully customize the proof system, (de)serialization strategies of `bytes` and/or the business workflow. For example, when implementing "Zether" confidential token contracts, the `_confidentialTransferValue` and accounts' confidential balances will be encrypted homomorphically under ElGamal public keys, and `_proof` will consist 3 parts to check:

  * `_confidentialTransferValue` is well encrypted under public keys of `_from` 's, `_to` 's and caller's;
  * The plaintext `value` behind `_confidentialTransferValue` is non-negative;
  * The caller's confidential allowance is actually enough to pay the plaintext `value` behind `_confidentialTransferValue` .

```
function confidentialTransferFrom(
  address _from,
  address _to,
  bytes memory _confidentialTransferValue, 
  bytes memory _proof
) public returns (bool success)
  
```

##### confidentialApprove

Allows `_spender` to withdraw from caller's split part of balances multiple times, up to the amount (allowance value) behind `_confidentialValue` to 0. This function SHOULD `throw` if the message caller’s `_proof` of this transfer fails to be verified.

Caution:

This function behaves much **different from** `approve(address,uint256)` in [ERC20](./eip-20.md).

Calling `confidentialApprove` splits the confidential balance of caller's account into *allowance part* and *the left part*.

The values behind two parts above after calling `confidentialApprove` , and the value behind the original confidential balance of caller's account before calling `confidentialApprove` satisfy the equation:

 <img src="../assets/eip-draft-N/value_equation.png" width=690 height=27>



* The allowance part of confidential balance allows `_spender` to withdraw multiple times through calling `confidentialTransferFrom` until `_spender` does not call it any more or the value behind this part is 0.

  * Every time the `_spender` calls `confidentialTransferFrom` , the value behind this part will be decreased by the value behind `_confidentialTransferValue` .

* The left part remains as the new confidential balance of caller's account.

If this function is called again it,

* merges existing allowance part into the confidential balance of caller's account; and then
* overwrites the current allowance part with `_confidentialValue` .

Note:

* Callers MUST handle `false` from returns (bool success). Callers MUST NOT assume that `false` is never returned!
* Implementations can fully customize the proof system, (de)serialization strategies of `bytes` and/or the business workflow. For example, when implementing "Zether" confidential token contracts, the `_confidentialValue` and accounts' confidential balances will be encrypted homomorphically under ElGamal public keys, and `_proof` will consist 3 parts to check:

  * `_confidentialValue` is well encrypted under public keys of caller's and `_spender` 's;
  * The plaintext `value` behind `_confidentialValue` is non-negative;
  * The caller's confidential balance is actually enough to pay the plaintext `value` behind `_confidentialValue` .

```
function confidentialApprove(
  address _spender,
  bytes memory _confidentialValue, 
  bytes memory _proof
) public returns (bool success)
```

##### confidentialAllowance

Returns the allowance part which `_spender` is still allowed to withdraw from `_owner` .

```
functinon confidentialAllowance(address _owner, address _spender)
public view returns (bytes memory _confidentialValue)
```

#### Events

##### ConfidentialTransfer

MUST trigger when tokens are transferred.

Specifically, if tokens are transffered through function `confidentialTransferFrom` , `_spender` address MUST be set to caller's; otherwise, it SHOULD be set to `0x0` .

A confidential token contract,

* which creates new tokens SHOULD trigger a `ConfidentialTransfer` with the `_from` address set to `0x0` when tokens are minted;
* which destroys existent tokens SHOULD trigger a `ConfidentialTransfer` with the `_to` address set to `0x0` when tokens are burnt.

```
event ConfidentialTransfer(
  address indexed _spender,
  address indexed _from, 
  address indexed _to, 
  bytes _confidentialTransferValue
)
```

##### ConfidentialApproval

MUST trigger on any successful call to `confidentialApprove(address,bytes,bytes)` .

```
event ConfidentialApproval(
  address indexed _owner,
  address indexed _spender,
  bytes _currentAllowancePart,
  bytes _allowancePart
)
```

## Rationale


Confidential transactions have been implemented in many blockchains, either natively through blockchain protocols like Monero and Zcash, or through smart contracts like Zether (see https://doi.org/10.1007/978-3-030-51280-4_23 ) without modifying blockchain protocol.

However, when it comes to the latter way, actually no standards are proposed yet to illustrate such contracts. Users and applications cannot easily detect whether a token contract supports confidential transactions or not, and so hardly can they make transfers without revealing the actual amount.

Consequently, this proposal is to standardize the confidential transaction supported token contracts, meanwhile without loss of generality, by only specifying core methods and events.


### Optional Accessor of "Confidential Total Supply"

Confidentiality of transfer amount makes it hard to support such field like `totalSupply()` in [ERC20](./eip-20.md). Because when it comes to the token "mint" or "burn", if every user in this contract can access `totalSupply()` as well as decrypt it, these users will know the actual token value to be minted or burnt by comparing the `totalSupply()` before and after such operations, which means that confidentiality no longer exists.

Contract implementation can optionally support `confidentialTotalSupply()` by evaluating if anti-money laundry (see next part) and audit are required. That would be much more plausible by making a small group of parties can know the plaintext total supply behind `confidentialTotalSupply()`.

```
function confidentialTotalSupply() public view returns (bytes memory)
```

### Anti-money Laundry and Audit

To support audit of confidential transactions and total supply, especially such token issuers are banks or other financial institutes supervised by governments or monetary authorities, confidential transactions can be implemented without changing `confidentialTransfer` method signature, by encoding more info into parameters.

For example in Zether-like implementation (see https://doi.org/10.1007/978-3-030-58951-6_29), if token transfers are required to be audited, `confidentialTransfer` caller encrypts transfer `value` redundantly under public keys of caller's, `to`'s, a group of auditors', which makes it possible that related parties can exactly know the real `value` behind. So does `confidentialTotalSupply()`.

### Fat Token

Confidential transactions supported token can also implement [ERC20](./eip-20.md) at the same time.

Token accounts in such tokens can hold 2 kinds of balances. Such token contracts can optionally provide methods to hind [ERC20](./eip-20.md) plaintext balances into confidential balances, and vice versa, to reveal confidential balances back to [ERC20](./eip-20.md) plaintext balances.

[ERC20](./eip-20.md) interfaces will bring much more usability and utilities to confidential transaction supported tokens, realizing general confidentiality meantime.

## Backwards Compatibility

No backward compatibility issues found.


## Security Considerations

To realize full confidentiality, contracts implementing this presented interface SHOULD NOT create (mints) or destroy (burns) tokens with plaintext value parameters. For implementation, following the same encryption strategies in `confidentialTransfer(address,bytes,bytes)` is RECOMMENDED.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
