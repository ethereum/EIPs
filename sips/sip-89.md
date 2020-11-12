---
sip: 89
title: Virtual Synths
status: Implemented
author: Justin J Moses (@justinjmoses)
discussions-to: https://research.synthetix.io/t/virtual-synths-sip/202

created: 2020-10-06
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Allow the proceeds of unsettled exchanges to be transferrable by tokenizing them into virtual synths.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

Create a virtual synth (vSynth) token representing a claim on an unsettled synth exchange. This vSynth will be represented by an ERC20 that represents a claim on the proceeds from the exchange. Once the exchange is settled, any holder of a vSynth can withdraw their portion of the proceeds and have the underlying synth transferred to them.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

Currently, when an exchange occurs between a `src` and `dest` synth, that `dest` synth is in an unsettled state for _N_ minutes ([`waitingPeriodSecs`](https://docs.synthetix.io/contracts/source/contracts/systemsettings/#waitingperiodsecs)) where it cannot be transferred (see [Fee Reclamation SIP-37](./sip-37.md)). This breaks composibility as a `IERC20.transfer()` on the `dest` synth cannot follow a `Synthetix.exchange()` in the same transaction.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview

<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

In order to alleviate this problem of composition, this SIP proposes the issuance of a new ERC20 token for every exchange that represents a claim on the `dest` synth. This contract, an instance of `VirtualSynth`, will receive the `destinationAmount` of `dest` synths and will issue that same number of vSynth tokens to the exchanger atomically following an exchange, which themselves are immediately transferable.

Once settlement is ready, anyone can invoke `settle()` on this ERC20 contract and the contract's `dest` synths will be transferrable. Then, any holder of the vSynth token can invoke `withdraw()` to have their vSynth tokens burned and their proportion of the `dest` synths sent to them.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

By creating a unique ERC20 contract instance for each exchange, we can ensure the reclaim risk of each exchange is separated from the others, yet still allows for fungibility within the size of the trade itself.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

Exchanging needs to be amended (or complemented) by the creation of a new ERC20 contract instance (`vSynth`). This contract will receive the `dest` synths in place of the user initiating the exchange, and the user will receive these vSynths instead.

```solidity
interface IVirtualSynth is IERC20 {

    // the synth token this virtual synth represents
    function synth() external view returns (IERC20);

    // show the balance of the underlying synth that the given address has, given
    // their proportion of totalSupply and
    function balanceOfUnderlying(address account) external view returns (uint);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function readyToSettle() external view returns (bool);

    // Perform settlement of the underlying exchange if required,
    // then burn the accounts vSynths and transfer them their owed balanceOfUnderlying
    function settle(address account) external;
}
```

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

TBD.

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implementation.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
