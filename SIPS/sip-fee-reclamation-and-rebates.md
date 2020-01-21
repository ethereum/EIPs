---
sip: 37
title: Fee Reclamation and Rebate
status: WIP
author: Justin J Moses (@justinjmoses)
discussions-to: https://discord.gg/3uJ5rAy

created: 2020-01-20
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

Deduct profits or rebate losses occurred by exchanges made immediately prior to a market shift.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

In order to prevent front-running the standard latency of Ethereum block processing, ensure that all synth exchanges take into account any imminent changes to market prices. We can do this by settling the owed funds in successive exchanges of that target synth, as long as the exchange happens after a waiting period of _N_ minutes (configurable by SCCP).

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

In effect, users who `exchange` in Synthetix are actually converting debt from one form to another at the current market price on-chain. If a user trades to take advantage of latency between prices detectable in the off-chain market (the SPOT rate) and the on-chain one, then they make profit at the expense of the entire SNX stakers (as each staker hold a debt position - a percentage of the entire debt pool).

[SIP-12](./sip-12.md) was implemented as a mechanism to slow down any front-running, adding latency to their exchanges. However, while it prevents true front-running (anyone watching the Ethereum mempool for oracle updates and front-running the actual market prices being committed on-chain), it doesn't help much with oracle latency when the network congestion is low. Consider that oracles can't constantly push prices, at the very least they need to wait for any previous prices to be committed on-chain, and it would be incredibly expensive (and arguably a waste of resources) to try to get an oracle update in each and every block. If Ethereum network congestion is low (and thus gas prices are low), user exchanges can still get in quite quickly and the max gas limit doesn't help much. On top of that, the max gas limit can inhibit legitimate users who accidentally hit it when it adjusts down during regular adjustments.

By creating a short waiting period after exchanges in which exchanges or transfers out of that target synth are restricted, we can then settle the account automatically

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

When a user exchanges `src` synth for `dest` synth, the waiting period of _N_ minutes begins. Any `transfer` of `dest` synth will fail during this window, as will an `exchange` from `dest` synth to any other synth, or a burn of `sUSD` if it was the `dest` synth. If another exchange into the same `dest` synth is performed before _N_ minutes expires, the waiting period restarts with _N_ minutes remaining.

Once _N_ minutes has expired, the following `exchange` from the `dest` synth to any other, or a burn of `sUSD`, will invoke `settle` - calculating the difference between the exchanged prices and those at the end of the waiting perid. If the user made profit, it is taken to be front-run profit, and the profit is burned from the user's holding of the `dest` synth. If the user made a loss, this loss is issued to them from the `dest` synth. The `exchange` then continues as normal.

In the case of a user trying to `transfer` the `dest` synth after the waiting period has expired - this will always fail. The user has to first invoke `settle` before a synth can be transferred.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The goal is to reclaim any fees owing whilst not impacting usability and composability. Preventing `exchange`, `transfer` and `burn` of the `dest` synth during the waiting period is necessary to ensure the user has the synths to reclaim if need be.

Once the period is over, we invoke `settle` within `exchange` or `burn` of the `dest` synth to limit complexity for the user.

Whilst we can also invoke `settle` within `transfer` of the `dest` synth, there are concerns that this will break `ERC20` assumptions. When `transfer(amount)` is invoked, there are assumptions in the Ethereum ecosystem that `amount` will be received by the recipient. For instance, when Synthetix was Havven, there were issues integrating `sUSD` into DEXes as the previous `sUSD` transfer fees meant that these DEXes had to consider these in their accounting systems, which was often too complex for them. That being said, this

## Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Given the following preconditions:

- Jessica has a wallet which holds 100 sUSD and this wallet has never exchanged before,
- and the price of ETHUSD is 100:1, and BTCUSD is 10000:1
- and the waiting period (_M_) is set to _3_ minutes.

  ***

  When

  - she exchanges 100 sUSD into 1 sETH.

  Then

  - ✅ it succeeds as sETH has no reclamation fees for this wallet.

  ***

  When

  - she exchanges 100 sUSD into 1 sETH
  - and she immediately attempts to transfer 0.1 sETH

  Then

  - ❌ it fails as the waiting period has not expired

  ***

  When

  - she exchanges 100 sUSD into 1 sETH
  - and she immediately attempts to exchange 1 sETH for sBTC

  Then

  - ❌ it fails as the waiting period has not expired

  ***

  When

  - she exchanges 50 sUSD into 0.5 sETH.
  - and she immediately attempts to exchange 50 sUSD into 0.005 sBTC

  Then

  - ✅ it succeeds as sBTC has no reclamation fees for this wallet

  ***

  When

  - she exchanges 50 sUSD into 0.5 sETH.
  - and 1 minute she immediately attempts to exchange another 50 sUSD into 0.5 sETH

  Then

  - ✅ it succeeds, and the waiting period is reset to _3_ minutes

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and 2 minutes later the price of ETHUSD goes up to 100.25:1
  - ⏳ and another minute later she attempts to transfer this sETH

  Then

  - ✅ the transfer succeeds because the profit made from the oracle update is less than the fee she already paid

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and 1 minute later the price of ETHUSD goes up to 103:1
  - ⏳ and 2 more minutes later she attempts to transfer any of this sETH

  Then

  - ❌ the transfer fails because she profited 3% - 0.3% = 2.7%. She must invoke `settle` before being able to transfer the sETH

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and a minute later the price of ETHUSD goes up to 103:1
  - ⏳ and 2 more minutes later she invokes `settle` for sETH
  - and immediately transfers this sETH to another wallet

  Then

  - ✅ the transfer succeeds as the prior `settle` invocation burned 2.7% of her sETH holdings (0.027), and transfer detected no fees remaining.

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and a minute later the price of ETHUSD goes up to 103:1
  - ⏳ and 2 more minutes later she attempts to exchange 1 sETH for sBTC

  Then

  - ✅ the exchange succeeds, burning 2.7% of her exchange amount (0.027 sETH), and converting the rest into sBTC (minus the exchange fee).

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and a minute later the price of ETHUSD goes down to 95:1
  - ⏳ and 2 more minutes later she attempts to exchange 1 sETH for sBTC

  Then

  - ✅ the exchange succeeds, issuing her ~5.247% of her exchange amount (0.05247 sETH), and converting the entire amount into sBTC (minus the exchange fee).

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and no oracle update for ETHUSD occurs after 3 minutes
  - ⏳ once 3 minutes from exchange have elapsed she attempts to exchange

  Then

  - ✅ the exchange succeeds and no rebate or reclamation is required

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and no oracle update for ETHUSD occurs after 3 minutes
  - ⏳ once 3 minutes from exchange have elapsed she exchanges 1 sETH for sUSD (paying a further 30bps fee)
  - ⏳ and a minute later the price of ETHUSD goes down to 90:1
  - ⏳ she burns `50` sUSD

  Then

  - ❌ the burn fails as the waiting period for sUSD is still ongoing

  ***

  When

  - she exchanges 100 sUSD into 1 sETH (paying a 30bps fee)
  - ⏳ and no oracle update for ETHUSD occurs after 3 minutes
  - ⏳ once 3 minutes from exchange have elapsed she exchanges 1 sETH for sUSD (paying a further 30bps fee)
  - ⏳ and a minute later the price of ETHUSD goes down to 90:1
  - ⏳ and two minutes later 3 minutes have elapsed since her last exchange
  - ⏳ she burns `50` sUSD

  Then

  - ✅ `9.94009` sUSD is reclaimed from the user (`99.4009 - 89.46081`, which is the amount received in sUSD (`100 * 1/100 * 0.997 * 100 * 0.997`) minus the amount they should have received at the updated rate (`100 * 1/100 * 0.997 * 90 * 0.997`))
  - and `50` sUSD is burned.

## Implementation

<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

- `Synthetix.exchange()` invoked from synth `src` to `dest` by `user` for `amount`

  - _Are we currently within a waiting period for any exchange into `src`?_

    - Yes: ❌ Fail the transaction
    - No: ✅
      - Invoke `settle(src)`
      - Proceed with the `exchange` as per usual
      - Persist this exchange in the user queue for `dest` synth

- `Synthetix.settle(synth)` invoked with synth `synth` by `user`

  - _Are we currently within a waiting period for any exchange into `synth`?_

    - Yes: ❌ Fail the transaction
    - No: Sum the `owing` and `owed` amounts on all unsettled `synth` exchanges as `tally`
      - _Is the tally > 0_
        - Yes: ✅ Reclaim the `tally` of `synth` from the user by burning it
      - _Is the total < 0_
        - Yes: ✅ Rebate the absolute value `tally` of `synth` to the user by issuing it
      - Finally, remove all `synth` exchanges for the user

- `Synth.transfer()` invoked from synth `src` by `user` for `amount`

  - _Are we currently within a waiting period for any exchange into `src`?_
    - Yes: ❌ Fail the transaction
    - No: Sum the `owing` and `owed` amounts on all unsettled `synth` exchanges as `total`
      - _Is the total == 0_
        - Yes: ✅ Proceed with transfer as usual
        - No: ❌ Fail the transaction

- `Synth.burnSynths()` invoked by `user` for `amount`
  - _Are we currently within a waiting period for any exchange into `sUSD`?_
    - Yes: ❌ Fail the transaction
    - No: ✅
      - Invoke `settle(src)`
      - Proceed with the `burn` as per usual

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
