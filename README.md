# Ethereum Improvement Proposals (EIPs) [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

**Before you initiate a pull request**, please read the process document. Ideas should be thoroughly discussed on the [Ethereum Magicians forums](https://ethereum-magicians.org) first.

This repository tracks the ongoing status of EIPs. It contains:

- [Draft](https://eips.ethereum.org/all) proposals which intend to complete the EIP review process.

- [Last Calls](https://eips.ethereum.org/all) for proposals that may become final (see also [RSS feed](https://eips.ethereum.org/last-call.xml)).
- [Accepted](https://eips.ethereum.org/all) and [Deferred](https://eips.ethereum.org/all) proposals which are awaiting implementation or deployment by Ethereum client developers.
- [Final](https://eips.ethereum.org/all) and [Active](https://eips.ethereum.org/all) proposals that are recorded.
- The [EIP process](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-work-flow) that governs the EIP repository.

Achieving "Final" status in this repository only represents that a proposal has been reviewed for technical accuracy. It is solely the responsibilty of the implementer to decide if these proposals will be useful to you and if they represent best practice.

Browse all current and draft EIPs on [the official EIP site](http://eips.ethereum.org/).

## Project Goal

The Ethereum Improvement Proposals repository exists as a place to discuss concrete proposals with potential users of the proposal and the Ethereum community at large.

We promote high-quality, peer-reviewed proposals in two categories:

- [Consensus Changes](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-types) require people running an Ethereum client to update their software to implement the change. If enough people do not upgrade then an existing network will fork into two separate networks.
- [Other Proposals](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-types) do not require a change in client software and can be used by any interested party.

## Preferred Citation Format

The canonical URL for a EIP that has achieved draft status at any point is at https://eips.ethereum.org/. For example, the canonical URL for EIP-1 is https://eips.ethereum.org/EIPS/eip-1.

# Validation

EIPs must pass some validation tests.  The EIP repository ensures this by running tests using [html-proofer](https://rubygems.org/gems/html-proofer) and [eip_validator](https://rubygems.org/gems/eip_validator).

It is possible to run the EIP validator locally:
```
gem install eip_validator
eip_validator <INPUT_FILES>
```

# Automerger

The EIP repository contains an "auto merge" feature to ease the workload for EIP editors.  If a change is made via a PR to a draft EIP, then the authors of the EIP can Github approve the change to have it auto-merged by the [eip-automerger](https://github.com/eip-automerger/automerger) bot.
