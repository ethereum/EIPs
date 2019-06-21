---
sip: 3
title: Purgeable Synths
status: Approved
author: Clinton Ennis (@hav_noms)
discussions-to: https://discord.gg/CDTvjHY

created: 2019-06-12
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

This SIP proposes to introduce a "Purgeable Synth" in order to exchange the remaining balances of unpopular or frozen Inverse Synths to their holders in sUSD and remove the deprecated Synth from the system which in turn saves gas or reconfigure the frozen Inverse Synth.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Since rolling out the 15 Fx Synths 6 have shown to have zero to dust balances. These are sBRL, sCAD, sNZD, sPLN, sRUB, sSGD. The Synthetix contract has a requirement that a Synth can only be removed if its totalSupply is zero. Most low cap Synths hold dust from "testers" that block these useless Synths from being removed from the System.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

The more Synths in the Synthetix system the more Mint and Burn functions cost in gas as Synthetix needs to do cross contract calls to query each Synth for its totalSupply.
The ability to remove unused Synths would save unnecessary gas spend and allow the reconfiguring of Inverse Synths with a much faster turnaround as the Inverse Synths are blocked until all holders exchange out of them. e.g. iBTC -> sUSD.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

### Solidity

By utilizing the Synthetix's upgradable contract mechanism we propose a new PurgeableSynth contract which subclasses the existing Synth contract which only the deprecated and Inverse Synths would be upgraded to PurgeableSynth and have purge called by the foundation owner.

```
contract PurgeableSynth is Synth {}
```

An owneronly function allowing the foundation to pass in all holders of that Synth which it will internally look up their balance and exchanging for them into sUSD sent to their wallet.

No deprecated Synth holder will lose their value.

```/**
     * @notice Function that allows owner to exchange any number of holders back to sUSD (for frozen or deprecated synths)
     * @param addresses The list of holders to purge
     */
    function purge(address[] addresses)
        external
        optionalProxy_onlyOwner
    {
        uint maxSupplyToPurge = getMaxSupplyToPurge();

        // Only allow purge when total supply is lte the max or the rate is frozen in ExchangeRates
        require(
            totalSupply <= maxSupplyToPurge || exchangeRates.rateIsFrozen(currencyKey),
            "Cannot purge as total supply is above threshold and rate is not frozen."
        );

        for (uint8 i = 0; i < addresses.length; i++) {
            address holder = addresses[i];

            uint amountHeld = balanceOf(holder);

            if (amountHeld > 0) {
                synthetix.synthInitiatedExchange(holder, currencyKey, amountHeld, "sUSD", holder);
                emitPurged(holder, amountHeld);
            }

        }

    }
```

### Maximum Supply to Purge 
For Inverse Synths any amount is purgable if the Inverse Synth is frozen doing the check.
```
|| exchangeRates.rateIsFrozen(currencyKey)
```
This proposal specifies a hard cap value of any upgraded FX, synth to be purgeable at a value less than or equal to \$10,000 USD. This may be found to be too much for some Fx / Crypto Synths or perhaps should be atleast configrable. RFC below.

```
// The maximum allowed amount of tokenSupply in equivalent sUSD value for this synth to permit purging
    uint public maxSupplyToPurgeInUSD = 10000 * SafeDecimalMath.unit(); // 10,000
```

A Synth must have a totalSupply of zero to be able to pass this requirement to be removed.

```
require(synths[currencyKey].totalSupply() == 0, "Synth supply exists");
```

The last step to remove a Synth from the Synthetix system is to have the foundation owner call [removeSynth()](https://github.com/Synthetixio/synthetix/blob/master/contracts/Synthetix.sol#L212).

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

All Synths sit behind their own Proxy contract so they are upgradeable. Subclassing Synth allows the flexibility to upgrade a Synth to a PurgeableSynth and not deploy all Synths as PurgeableSynth by default. It is only required for low cap and frozen Synths. i.e. It is foreseen sUSD will never be upgraded to a PurgeableSynth.

By passing in the list of addresses only the PurgeableSynth looks up the balance itself protecting the user from loss of funds from incorrect amount input.

A Synth cannot be removed from the Synthetix system until its totalSupply == 0. So the foundation will send the correct list of addresses of holders to purge all balances and allow the Deprecated Synth to be removed from the system.

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

https://github.com/Synthetixio/synthetix/blob/HBN-892/test/PurgeableSynth.js

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

https://github.com/Synthetixio/synthetix/blob/HBN-892/contracts/PurgeableSynth.sol

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
