---
eip: X
title: Address and ERC20-compliant transfer rules
author: Cyril Lapinte <cyril.lapinte@mtpelerin.com>, Laurent Aapro <laurent.aapro@mtpelerin.com>
type: Standards Track
category: ERC
status: Draft
created: 2018-11-09
---

## Simple Summary

We propose a standard and an interface to define transfer rules, in the context of ERC20 tokens and possibly beyond.


A rule can act based on sender, destination and amount, and is triggered (and rejects the transfer) according to any required business logic.


To ease rule reusability and composition, we also propose an interface and base implementation for a rule engine.

## Abstract

This standard proposal should answer the following challenges:
- Enable integration of rules with interacting platforms such as exchanges, decentralized wallets and DApps.
- Externale code and storage, improve altogether reusability, gas costs and contracts' memory footprint.
- Highlight contract behavior and its evolution, in order to ease user interaction with such contract. 


If these challenges are answered, this proposal will provide a unified basis for transfer rules and hopefully address the transfer restriction needs of other EIPs as well, e.g. 
[EIP-902](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-902.md), 
[EIP-1066](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1066.md)
and [EIP-1175](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1175.md).

This document proposes specifications for a standard of **transfer rules** and interfaces to both the rules and the rule engine, which was made to be inherited by a token, but may have a much broader scope in the authors' opinion.

The last section of this document illustrates the proposal with a rule template and links to rule implementations.

## Motivation

ERC20 was designed as a standard interface allowing any token on Ethereum to be handled by other applications: from wallets to decentralized exchanges. This has been extremely powerful, but future developments in the industry of tokenization are bringing new challenges. For example it is already hard to know exactly why an ERC20 transfer failed, and it will become even harder when many tokens add their own transfer rules to the mix; we propose that it should be trivial to determine before a tx is sent, whether the transfer should turn out valid or invalid, and why (unless conditions change in the meantime obviously). On the other hand, if the rules were changed, it should also be easily detected, so that the interacting party knows it must adjust its expectations or model.

## Specification

We define below an interface for a rule. Rules are meant to be as simple as possible, to limit gas expenditure, since that logic will be executed on every transfer. Another reason for keeping rules simple and short, and strive for atomicity, is to facilitate both composition and interpretation of rejected transfers. By knowing which rule was triggered, we obtain a clear picture of the reason for rejection.

The engine we propose executes all the rules defined by its owner, on every transfer and it is easy to add and remove rules individually, although we have chosen to use quite a raw rule update method, to save on deployment costs, which are often tight when it comes to token smart contracts.

Rules are deployed on the blockchain as individual smart contracts, and called upon by the rule engine they were attached to. But any third party, for example an exchange preparing a cashout for a customer, can very cheaply query the rule engine of the token, or a single rule directly, to verify the validity of a transfer before execution, so as to never get a rejected transaction.

## Rule interface

`IRule` interface should provide a way to validate if an address or a transfer is valid.

If one of these two methods is not applicable, it can simply be made to return true systematically.
If any parameter of `isTransferValid` is not needed, its name should be commented out with `/* */`.

```js
pragma solidity ^0.4.25;

interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}
```

## WithRules interface

`WithRules` interface describes the integration of rules to a rule engine.
Developers may choose to not implement this interface if their code will only deal with one rule, or if it is not desirable to update the rules.

The rules ordering must be thought through carefully.
Rules which are cheaper to validate or have a higher chance to break should be put first to reduce global gas expenditure, then business logic should guide the ordering of rules. That is why rules for a given context should be defined as a whole and not individually.

```js
pragma solidity ^0.4.25;

import "./IRule.sol";

interface IWithRules {
  function ruleLength() public view returns (uint256);
  function rule(uint256 _ruleId) public view returns (IRule);
  function validateAddress(address _address) public view returns (bool);
  function validateTransfer(address _from, address _to, uint256 _amount)
    public view returns (bool);

  function defineRules(IRule[] _rules) public;

  event RulesDefined(uint256 count);
}
```

## WithRules implementation

We also propose a simple implementation of the rule engine, available [here](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/rule/WithRules.sol). It has been kept minimal both to save on gas costs on each transfer, and to reduce the deployment cost overhead for the derived smart contract.


On top of implementing the interface above, this engine also defines two modifiers (`whenAddressRulesAreValid`and  `whenTransferRulesAreValid`), which can be used throughout the token contract to restrict `transfer()`, `transferFrom` and any other function that needs to respect either a simple whitelist or complex transfer rules.


## Integration

To use rules within a token is as easy as having the token inherit from WithRules, then writing rules according to the IRule interface and deploying each rule individually. The token owner can then use `defineRules()` to attach all rules in the chosen order, within a single transaction.

Below is a template for a rule.

```
import "../interface/IRule.sol";

contract TemplateRule is IRule {
  
  // state vars for business logic

  constructor(/* arguments for init */) public {

    // initializations

  }

  function isAddressValid(address _from) public view returns (bool) {
    boolean isValid;

    // business logic 

    return isValid;
  }

  function isTransferValid(
    address _from,
    address _to,
    uint256 _amount)
    public view returns (bool)
  {
    boolean isValid;

    // business logic 

    return isValid;
  }
}
```

*** Notes ***
The MPS (Mt Pelerin's Share) token is the current live implementation of this standard.
Other implementations may be written with different trade-offs: from gas savings to improved security.

#### Example of rules implementations

- [YesNo rule](https://github.com/MtPelerin/MtPelerin-protocol/tree/master/contracts/rule/YesNoRule.sol): Trivial rule used to demonstrate both a rule and the rule engine.

- [Freeze rule](https://github.com/MtPelerin/MtPelerin-protocol/tree/master/contracts/rule/FreezeRule.sol): This rule allows to prevent any transfer of tokens to or from chosen addresses. A smart blacklist.

- [Lock rule](https://github.com/MtPelerin/MtPelerin-protocol/tree/master/contracts/rule/LockRule.sol): Define a global transfer policy preventing either sending or receiving tokens within a period of time. Exceptions may be granted to some addresses by the token admin. A smart whitelist.

- [User Kyc Rule](https://github.com/MtPelerin/MtPelerin-protocol/tree/master/contracts/rule/UserKycRule.sol): Rule example relying on an existing whitelist to assert transfer and addresses validity. It is a good example of a rule that completely externalizes it's tasks.

#### Example implementations are available at
- [Mt Pelerin Bridge protocol rules implementation](https://github.com/MtPelerin/MtPelerin-protocol/tree/master/contracts/rule)
- [Mt Pelerin Token with rules](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/token/component/TokenWithRules.sol)

## History

Historical links related to this standard:

- The first regulated tokenized share issued by Mt Pelerin (MPS token) is using an early version of this proposal: https://www.mtpelerin.com/blog/world-first-tokenized-shares
The rule engine was updated several times, after the token issuance and during the tokensale, to match changing business and legal requirements, showcasing the solidity and flexibility of the rule engine.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
External references outside this repository will have their own specific copyrights.
