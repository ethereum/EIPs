## Preamble

    EIP: <to be assigned>
    Title: EIP Community Veto
    Author: Sam Griffin (sam.griffin@gmail.com)
    Type: Meta
    Status: Draft
    Created: 2018-02-24
    Modifies: EIP-1

## Simple Summary
The greater Ethereum community should be able to veto EIPs they don't like. Also, the process by which EIPs become part of the Ethereum standard should be clarified. 

## Abstract
Some EIPs have contentious moral/ethical/legal/philosophical rammifications. The process of drafting the EIP where the author comes up with what they think is the best form of their idea should be free from interference, but the community should have a voice to prevent unpopular EIPs becoming part of the standard. 

## Motivation
The community currently has no official procedure for indicating their dislike of certain EIPs. This leads to brigading of GitHub pull requests that make it more difficult for EIP editors and draft writers. Additionally, EIP draft writers do not have specific data on how controversial their EIP is. Controversial hard forks should be avoided whenever possible, and if compromise can happen in the EIP drafting stage, this could avoid community splits. The current role of the AllCoreDevs group is also not detailed in EIP-1, and this should be made explicit.

## Specification
I propose two new phases to the EIP process: "Staging" and "Implementing"
Once an EIP champion has polished their draft to their satisfaction, it will go to the "Staging" phase. At this point a carbon vote shall be set up and the draft shall be sent to the AllCoreDevs group. The community shall be given a period of a week to register their carbon votes. If the majority of the carbon vote is against the EIP in its current form, it shall be sent back to the "Draft" phase.
If the majority of the carbon vote is for the EIP and the AllCoreDevs group is satisfied with the current form, the EIP shall enter the "Implementing" phase. If any implementation details necessitate changes to the EIP, it shall be sent back to the "Draft" phase. If 3 "viable" (what is viable?) Ethereum clients successfully implement the EIP, it shall move to the "Final" phase and be codified in the Ethereum standard.

## Rationale
The contention around EIP-867 made it clear that there was no good way for the community to make its voice heard, and it was unclear if dissent was the result of a few passionate, loud voices, brigading from other cryptocurrencies, or a major community backlash.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
