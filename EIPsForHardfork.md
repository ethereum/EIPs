---
eip: 1929
title: Selection of EIPs for network upgrade
author: Pooja Ranjan (@poojaranjan), James Hancock (@MadeofTin)
discussions-to: https://ethereum-magicians.org/t/proposal-of-a-formal-process-of-selection-of-eips-for-hardforks-meta-eip/3115
status: Draft
type: Meta 
created: 2019-04-09
requires : 233
---
## Simple summary

To describe a formal process of selection of EIPs for upcoming network upgrades (hardfork).

## Abstract

This proposal will help decouple the EIP process and the network upgrade process by following a new process of EIP selection for the upcoming upgrade in the Eth1.0-spec repository.

## Motivation

This meta EIP provides a general outline process to propose, discuss, and track the progress of EIPs for upcoming hardfork and clearly state the selection of proposal for a network upgrade. Whereas, in the present process, for a core EIP,  it is difficult to draw a line between the end of an EIP process (final state) and the beginning of the formal selection of proposals for a network upgrade.

## Specification

A Meta EIP should be created and merged following the process mentioned in [EIP-233](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-233.md).

###  EIP selection process for for CFI

#### Preconditions to be proposed for consideration
* Type of EIP -  Core 
* Status of EIP - Any status between Draft to Final (ref: EIP-1)
    
#### Proposing an EIP
* If you're an author, and still vetting the idea, please follow the guidelines mentioned in [EIP - 1](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-work-flow) to formalize your idea into an EIP.
* Once an EIP/Pull request (at EIP GitHub) is created, open a new issue at [Eth1.0-specs repository](https://github.com/ethereum/eth1.0-specs) referring "EIP# to be considered for CFI". This can be created at any stage of the EIP process.
* It will be then picked up by the Hardfork coordinators and added as Proposed EIP for CFI in the [project board](https://github.com/ethereum/eth1.0-specs/projects/1).
* The author/proposer then adds it to the agenda of the next AllCoreDev meeting. 

#### Socializing an EIP
* Open a discussion thread, preferably at EthMagician. Share it in the Ethereum [allcoredevs Discord](https://discord.gg/PqxkpE), Reddit, and twitter (if need be).
* Show up in the All core dev meetings for EIP to be introduced to the client teams. 
* Show up in an episode of '[Peep an EIP](https://github.com/ethereum-cat-herders/PM/projects/2)' to share the importance, need, and application of the proposal in simple terms for community understanding. (Optional).
    
#### Reviewing an EIP
The author or champion may reach out to [EIP Editors](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-editors) or Hardfork coordinator for help in review the EIP, if not already reviewed. HF coordinator may coordinate with EIP Editors based on the interest/availability.

#### Network upgrade process tracker
The tracker is created at [Eth1.0-spec Projects](https://github.com/ethereum/eth1.0-specs).

| № | CFI applied  | CFI approved |CI devnet waiting room | CI devnet active| Testing green light | Public testnet| Mainnet |
|---| -----|-------------|-----------| ------- | ------- | --------| -------|
| 1 |
| 2 |
| 3 |

### Network upgrade stages
    
(Conditions for change in EFI stages)
#### CFI applied 
* EIP status - Draft-Final
* An [issue](https://github.com/ethereum/eth1.0-specs/issues) created at Eth1.0-spec repo
#### CFI approved
* EIP status - Draft-Final
* The decision to include in EFI in ACD meeting with the approval of at least 3 clients
#### CI devnet waiting room
* EIP status - Draft-Final
* ACD agrees to include the EIP on the developers testnet 
* Implementation in clients participating in the developer's testnet
#### CI devnet active
* EIP status - Draft-Final
* At any time only one version of the devnet will be active.
#### Testing green light
* EIP status - Review-Final
* EIPs on the latest version of the devnet 
* Final list of EIPs for next upgrade
* Add to the hard fork Meta EIP
### Public testnet
* EIP status - Last call-Final
* Deploy on public testnet  
#### Mainnet accepted
* EIP status - Final
* Deployed in a hardfork
    

## Rationale

The network upgrade process tracker for coordinating the network upgrade should help in the visibility and traceability of the scope of changes to the upcoming hardfork.

## Implementation

The proposed process is being followed for the upcoming 'Berlin upgrade' and the tracker is available at [Eth1.0-spec Projects](https://github.com/ethereum/eth1.0-specs/projects/1).

## Security consideration 
This is a change in process and not affecting any core protocol. No security concern has been observed so far.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
