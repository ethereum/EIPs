---
eip: <to be assigned>
title: Ethereum Network Upgrade Windows
author: Danno Ferrin (@shemnon)
discussions-to: <URL>
status: Draft
type: Meta
created: 2018-03-25 <date created on, in ISO 8601 (yyyy-mm-dd) format>
---

## Simple Summary

A proposal to define a limited number of annual time windows in which network upgrades (aka hard forks) should be performed within.  Policies for scheduling network upgrades outside these windows are also described.


## Abstract

Four different weeks, spaced roughly evenly throughout the year, are targeted for network upgrades to be launched.  Regular network upgrades should announce their intention to use that window at least four weeks prior and choose a block number expected to occur within that window.  If a network upgrade is cancelled then it would be rescheduled for the next window.  Not all windows will be used.  Priority upgrades outside the roadmap may be scheduled in the thrid week of any month, but such use is discouraged.  Critical upgrades are scheduled as needed.  

## Motivation

The aim of this EIP is to provide some level of regularity and predictability to the Ethereum network upgrade/hard fork process.  This will allow service providers such as exchanges and node operators a predictable framework to schedule activities around.  This also provides a framework to regularize the delivery of network upgrades.


## Specification

Scheduling is defined for three categories of network upgrades.  First are `Roadmap` network upgrades that include deliberate protocol improvements.  Next are `Priority` network updates, where there are technical reasons that necessitate a prompt protocol change but these reasons do not present a systemic risk to the protocol or the ecosystem.  Finally, `Critical` network upgrades are to address issues that present a systemic risk to the protocol or the ecosystem.

### Roadmap Network Upgrades

Roadmap network upgrades are network upgrages that are deliberate and measured to improve the protocol and ecosystem.  Historical examples are Homestead, Byzantium, and Contantinople.

Roadmap network upgrades should be scheduled in one of four windows: the third week of January, the third week fo April, the third week of July or the third week of October.  A block number for the network upgrade should be chosen four to six weeks prior to the network upgrade window.  Scheduling details such as whether this choice is made prior to or after testnet deployment are out of scope of this EIP.

> **Note to reviewers:** The months and week chosen are to provide an initial recommendation and are easily modifiable prior to final call.  They thread the needle between many third quarter and fourth quarter holidays.

A roadmap upgrade typically should not occur in ajacent upgrade windows.  Hence if a roadmap upgrade occured in April then the July window would not be used for network upgrades.

If a planned roadmap upgrade needs to be rescheduled then strong consideration should be given to rescheduling the upgrade for the next window in three months time.

Not every upgrade window must be used.

Network upgrades have historically been given single word names.  The first three network upgrades were Frontier, Homestead, and Metropolis.  Metropolis was split into two upgrades, Byzantium and Contantinople.  As of the writing of this EIP the next network upgrade will be called Istanbul.

### Priority Network Upgrades

Priority network upgrads are reserved for upgrades that require more urgency than a roadmap network upgrade yet do not present a systemic risk to the network or the ecosystem.  To date there have been no examples of a priority upgrade.  Possible examples may include roadmap upgrades that need to occur in multiple upgrades or for security risks that have a existing mitigration in place that would be better served by a network upgrade.  Another possible reason may be to defuse the difficulty bomb due to posponed roadmap upgrades.

Priority network upgrades are best launched in unused roadmap launch windows, namely the third week of January, April, July, and October.  If necessary they may be launched in the third week of any month, but strong consideration and preference should be given to unused roadmap launch windows.

Priority network upgrades should be announced and a block chosen far enough in advance so major clients implementors can release software with the needed block number in a timely fashion.  It is expected that two to four weeks would be sufficient.

Priority network upgrades should be given two word names, this will easily distinguish them from planned roadmap network upgrades.

### Critical Network Upgrades

Critical network upgrades are network upgrades that are designed to address systemic risks to the protocol or to the ecosystem.  Historical examples include Dao Fork, Tangerine Whistle, and Spurious Dragon.

This EIP provides neither guidance nor restrictions to the development and deployment of these emergency hard forks.  These upgrades are typically launched promptly after a solution to the systemic risk is agreed upon between the client implementors.

Historically the names of such hard forks have been two word phrases.  Sometimes the name applies to the issue at hand, sometimes it do not.

### Network Upgrade Block Number Choice

Network upgrade activation block numbers for mainnet deployment should chose a number whose base 10 representation ends with three or more zeros.  

For testnet deployments network operators are encounraged to choose a block activation number that is a palindrome in base 10.

To date all Mainnet activation blocks have ended in three or more zeros, including Critical Network Upgrades.  Ropsten and Kovan initially started with three zeros but switched to palindromatic numbers.  Rinkeby has always had palindromati activation blocks.  Goerli has yet to perform a network upgrade.

## Rationale

The rationale for defining launch windows is to give business running Ethereum infrastructure a predictable schedule for when upgrades may or may not occur.  Knowing when a upgrade is not going to occur gives the businesses a clear timeframe within which to perform interal upgrades free from external changes.  It also provides a timetable for developers and IT professionals to schedule time off against.

## Backwards Compatibility

Except for the specific launch windows the previous network upgrades would have complied with these policies.  Homestead, Byzantium, and Constantinople would have been Roadmap Network Upgrades.  There were no Priorty Network Upgrades, although Suprious Dragon would have been a good candiate.  Dao Fork was a Critical Network Upgrade in response to TheDao.  Tangerine Whistle and Spurious Dragon were critical upgrages in response to the Shanghai Spam Attacks.  Constantinople Fix (as it is termed in the reference tests) was in response to the EIP-1283 security issues.

If this policy were in place prior to Constantinople then the initial 2018 launch would likely have been bumped to the next window after the Ropsten testnet consensus failures.  The EIP-1283 issues likey would have resulted in an out of window upgrade because of the impact of the difficulty bomb. 


<!-- ## Test Cases -->
<!-- no test cases are relevant for this EIP -->

<!-- ## Implementation -->
<!-- This is a process EIP, no implementations are relevant -->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).