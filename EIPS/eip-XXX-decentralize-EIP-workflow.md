eip: <to be assigned>
title: Decentralize EIP workflow
author: Ethernian <dima@ethernian.com>
discussions-to: https://ethereum-magicians.org/t/decentralizing-eip-workflow/1525
status: Draft
type: Meta
created: 2018-10-03

## Abstract
This document proposes to decentralize an existing EIP classification process in order to increase its throughput and level of details possible. 

The proposed process is aimed to be "_eth-ish_": that means inclusive, decentralized on the global level, compatible with any organisation type on local level. 

It is based on the signaling paradigm as much as possible.

It is compatible with any existing EIP classification workflows EIP-1, EIP-4, [EIP-1100](https://github.com/ethereum/EIPs/pull/1100).

This proposal has many similarities with ["Strange Loop" by @danfinlay](https://ethereum-magicians.org/t/strange-loop-an-ethereum-governance-framework-proposal/268) (even unintentional). 

Special thanks to [@aogunwole](https://ethereum-magicians.org/u/aogunwole) for encouraging me to write this EIP and then giving me further ideas and clarifications.

## Motivation
Initially EIPs were mostly proposals for _CoreDev_ community to make change into ethereum protocol. _Editors_ are parts of _CoreDevs_ and their mission was to pick technically sound EIPs with enough support from community.

Things have changed. 

EIPs are not only about changes in ethereum protocol any more. Only few of EIPs require community consensus. Many of EIPs do not appeal to _CoreDev_ and do not need to be reviewed by whole community before being implemented. Most of new EIPs are targeting some specific ethereum sub-community and not the whole ethereum community or only _CoreDev's_.  

Now EIP is in effect [u] an unique identifier and a vehicle to collect enough community attention[/u] for review. This core change in the meaning of an EIP is cause for a change in the classification process.

Current EIP reviewing process has some problems:

1. ... it can't keep up with growing number of EIPs. Many EIPs are stuck in Draft status. And in the future, the number of application related EIPs will grow even more rapidly. This is because an ongoing ethereum adoption will create demand for standartisation and coordination on the application level.

1. ... it is designed with _CoreDevs_ needs in mind. It became insufficient: _Editors_ do not (and can not) categorize EIPs for other sub-community's needs. For example, _WalletDev_ community needs to review all new EIPs to find EIPs defining interfaces they should implement. Other communities have similar problems and they should read all EIPs with their needs in mind. This is an unnecessary repetition of _Editor's_ work.

1. ... there is no easy way to collect a feedback on some EIP from independent communities reviewing different aspects of it.

1. ... it demands you to propose a solution (the letter "P" in EIP). What if you target a problem, but you have no solution yet? It may be important to discuss the problem, even the solution is currently unknown. It is some kind of CTA (Call to Action), but there is no dedicated type for this kind of EIPs currently.

1. ... EIP reviewer (_Editor_) is a hard job. It should be better incentivized.   
  
Currently proposed solutions for the overstrained EIP review process are not sufficient:

1. ... EIP authors are advised to get a feedback from the community before publishing a new EIP. It moves the load from _Editors_ to communities, but at the same time EIP discussions become dispersed in different forums and disconnected from each other.

1. ... more _Editors_ will process more EIPs for _CoreDevs_, but it will not help other communities in their work.

## Basic Principles and Assumptions
* [u]_Communities are chat/forum based_:[/u]
The Ethereum community is naturally organized around chats and forums identified by URL. Those online communities may be focused on different aspects and be mentally quite disconnected from each other.

* [u]_Communities are focused on different knowledge domains:_[/u]
Communication in ethereum community is naturally organized around various knowledge domains.
There are _CoreDevs_, WalletDevs, Miners, Whales and so on. 
Communities should review EIPs in aspects they are focused on.

*  [u]_Tags should be meant as local to community_[/u] 
Any formalized terms (like statuses or tags) are defined and understood inside the community. They are just labels in some knowledge domain and may be quite unknown or misinterpreted outside of community. It means all terms should be meant as related to some community. Sharing terms between communities is possible, but needs additional efforts.

* [u]_Editor role becomes local to community_[/u]
The same person can be _Editor_ in many communities if trusted by them. Current _Editors_ will become  trusted by _CoreDevs_ and _Ethereum Users_ communities. Most probably they will work for other communities like _WalletDevs_ too.

* [u]_An advanced ethereum user is usually a member of many communities_:[/u]
Example: A member of _CoreDev_ community is naturally a member of Ethereum Users community too. This he has knows  terms and rules of both communities.
 
* [u]_Communities may be organized differently_:[/u]
A global EIP review process should be agnostic about the way how the particular community is organized. It can be centralized or anarchistic - it should not matter.

* [u]_Anyone and any community can make review, but nobody has to take it into account_:[/u]
Example: Anyone can express _his_ opinion setting a tag on particular EIP, but _CoreDevs_ are free to see and to follow only tags of their trusted _Editors_. 

* [u]_Anyone and any community are free to build its own and unenforced opinion about EIPs_:[/u]
_CoreDevs_ do not have a special place in EIP process any more, nor they have to follow EIP statuses set by others. _CoreDevs_ is now one of many ethereum communities (even very honored and reputable one).
Nevertheless Communities should make their trusted _Editors_ public in order to make their opinion public and official.

## Proposal Outlines

In order to achieve or goals we propose to improve the current EIP workflow as follows:

* [u]_Splitting EIP target audience:_[/u]
Currently, all EIPs are targeting the whole community. This creates huge overhead and is not necessary. EIPs should target an interested and responsible groups inside the ethereum community. Anyone outside target groups is primarily interested on the EIP status only.

* [u]_Ethereum Users community:_[/u]
Ethereum Users community is a default one for all ethereum users. It defines few status tags unambiguously understood by anyone. There could be like "OK", "NOT_OK", "IN_PROGRESS", "N/A". These few tags should be adopted by any other ethereum community in inter-community communication. 
EIPs changing global consensus should target Ethereum Users community to reflect their global impact.

*  [u]_Externally defined Tags can be reused by community_[/u]
Like common tags from Ethereum Users Community, it is possible to re-use tags from other community.

*  [u]_Community can ask an external _Editor_ to mark all new EIPs related to it:_[/u]
_Example:_ A _WalletDev_ community asks an external _Editor_ to mark any new EIPs that may be important for wallet development by using a tag "wallet". The _Editor_ is free to accept or reject request.

*  [u]_An Editor can ask a Community for review a particular aspect of EIP:_[/u]
_Example:_ An _Editor_ might be interested to initiate a discussion inside of Community of Miners about reducing a BlockReward, making his own decision depended on it.

## Community Examples
Here are some ideas for communities and their tags:
* [u]_Ethereum Users_[/u]
  Tags: 
        process: "OK", "NOT_OK", "IN_WORK", "N/A",
        state: "CLASH"
* [u]_Developers_[/u]
   Tags: DesignPattern, Standard
  * [u]_CoreDevs_[/u]
      Tags: HF (needs hard fork).
  * [u]_WalletDev_[/u]
  Tags: interface
  * [u]_Browser_[/u]
   Tags: browser, ENS, user_permissions
* [u]_Miners_[/u]
Tags: ASIC, BlockReward
* [u]_Whales_[/u]
Tags: Inflation
