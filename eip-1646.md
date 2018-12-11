---
eip: <to be assigned>
title: Decentralized Autonomous Zero-identity Protocol
author:Derek Zhou(周朝晖, zhous1998@gmail.com) (@zhous); Clinton Tong(21239506@qq.com); Yuefei Tan(whtyfhas@gmail.com)</a>; 
discussions-to: https://github.com/ethereum/EIPs/issues/1649
status: Draft
type: Standards Track (ERC)
category (*only required for Standard Track): ERC
created: 2018-11-06
requires (*optional): https://eips.ethereum.org/EIPS/eip-191
replaces (*optional): EIP 1646
---

## Simple Summary
A public autonomous zero-identity protocol which can greatly enhance smart contract based application's security ,for itself and for the participants, and can be a core protocol to the decentralized autonomous civilization. 

## Abstract
This protocol allows a user to register ,backup and update his/her zero-identity(zero-identities) by running smart contracts. The protocol defines methods to register with a zero-identity, query or update a zero-identity. Especially this protocol allows a user to replace his/her current zero-identity with a backup zero-identity and generates one or more backup identities.This protocol is a fundamental protocol for the blockchain‘s decentralized autonomous civilization.

## Motivation
We intend to develop a zero-identity interface which can be used by smart contracts. In Ethereum any smart contract takes an Ethereum address as a user's zero-identity. Quite often a user will lose access to his/her crypto assets when his/her private key associated with his ETH address is lost or stolen, or after he/she has transferred some tokens to a malicious or buggy smart contract. We are motivated to design a mechanism to help a user minimize his/her loss when these occassions happen.

The key to true autonomy is that only the owner of a zero-identity rather than any thirty party has full access control over his/her zero-identity unless the owner has his/her guardian or the owner authorizes a thirty party the highest permission. 

This is a fundamental protocol which an ideal public autonomous blockchain zero-identity framework is based on. It is a key proposal for building blockchain decentralized autonomous ecosystems, such as decentralized autonomous organization (DAO).

## Definitions
* **Zero-identity**: Briefly speaking a Zero-Identity is a user's Ethereum address which represents his/her effective identity and interacts with any smart contract in Ethereum. Compared to existing identity related proposals the Zero-Identity has three core advantages. Firstly it is based on decentralized autonomy, meaning basically it is managed by the owner of an Ethereum address. Secondly, It can interact with a smart contract and can deliver the active Ethereum address (not always itself) to the smart contract, thus it can bring the security of the smart contract's application to a high level. Thirdly, it can protect the anonymity of a Zero-Identity's owner, thus concerns about privacy disclosure would be naturally removed from Blockchain and all blockchain data could be transparent and publicly accessed. This will bring a profound change to the blockchain world.

* **Active Zero-Identity and Backup Zero-Identity**: An Active Zero-Identity is the only effective Zero-Identity (or the only effective Ethereum address) for the smart contract(s) of an involved party. Any party who has participated in a smart contract or has developed a smart contract has a unique Active Zero-Identity. A Backup Zero-Identity can be either a Seed or a deployment of multiple signatures. When an Active Zero-Identity is compromised or lost, a Backup Zero-Identity could be activated to an Active Zero-Identity and the previous Active Zero-Identity will be abolished by the Autonomous Zero-Identity Smart Contract (which simultaneously generates another Backup Zero-identity or helps with a deployment of mutiple signatures).  

* **Zero-Identity Registry**: When interacting with a smart contract, self-registration is the basic and the best way for a user to record his/her Ethereum address as his/her active Zero-identity on Ethereum.

* **Backup Zero-identity**: When a user signs up with a smart contract based application a seed will be automatically generated for the use. And this seed is a private key of an Ethereum address, marked as a Backup Zero-Identity and publicly recorded with an active Zero-Identity (his/her Ethereum address of the account he/she is using for the registration) simultaneously. The user needs to keep this seed safe and secure otherwise his/her zero-identity would be exposed to risks. For a minor or person who needs a guardian this framework allows an authorized thirty part to be either an assistant or a master of the backup zero-identity with a multiple-signature based mechanism. An assistant of a backup zero-identity means the access rights of this backup zero-identity are inferior to the access rights of any following new seed/backup zero-identity. A master of a backup zero-identity means the access rights of this backup zero-identity are superior to the access rights of any following new seed/backup zero-identity. A multiple-signature based mechanism can be developed flexibly according to an application's requirements.

## Specification
Our proposed decentralized autonomous zero-identity protocol allows a user to register and manage his/her zero-identity and generate a backup zero-identity when he/she interacts with a smart contract. The user has full access control over his/her zero-identity. And this protocol also allows the access control over his/her zero-identity to be transferred to an authorized third party no matter whom that party is. It implements an ideal identity management mechanism in a decentralized autonomous world. 

When a user registers a zero-identity, the Decentralized Autonomous Zero-Identity Smart Contract generates a seed as a backup zero-identity automatically. And the user can authorize a thirty party to be either an assistant or a master of the backup zero-identities with a multiple-signature mechanism. The user can designate either any of the possible following new seeds( as a backup zero-identity) or the authorized third party to have the full access control over his/her Acitive Zero-identity. When his/her Active Zero-identity is abolished his/her designated seed or by third party's control, another Ethereum address will be set as a new active zero-identity by the Decentralized Autonomous Zero-Identity Smart Contract.

When the third party management is asked with a lag time, the parties that manage the multiple signatures in the aforementioned multiple-signature mechanism have no access control over the user's zero-identity without authorization of the user's backup zero-identity no matter what access rights this backup zero-identity has.

## Rationale
Although blockchain based decentralized autonomy is still in its early stages it has assumed unprededented achievements. This leads us to a strong belief that decentralized autonomy will not only be blockchain's core value but also be a fundamental force that drives blockchain's development and growth.

To achieve decentralized autonomy, a solution to building an identity based on trustlessness and autonomy is needed. This solution may have no similarities with any existing identity management systems in our society. Bitcoin proposes such a solution by introducing a zero-knowledge proof based mechanism which implements identity anonymity by representing an identity in terms of three elements: a private key, a public key and an address. This mechanism gives full access control over an identity uniquely to its owner. This tells that zero-identity based autonomy can effectively protect a user from privacy disclosure. And only this kind of mechanism can achieve de-privacy in blockchain, then it will make blockchain data publicly accessed without concerns about privacy disclosure therefore make blockchain data a public big data system worldwide.

A user himself/herself is the owner of his/her zero-identity. The user can revoke his/her authorization to an authorized third party. However for a minor or person who needs a guardian since he/she may not be competent to fulfill a responsibility, full access control over his/her zero-identity may be given to a third party e.g. his/her guardian while he/she may only be a user of his/her zero-identity. When he/she becomes an adult or a person that no longer needs a guardian full access control over his/her zero-identity will be transferred  to him/her with smart contracts.  

## Backwards Compatibility
There is no backwards compatibility issue. 

## Implementation
The reference implementation for ERC-1484 may be found in [Silkroad-Framework/eip](https://github.com/Silkroad-Framework/eip).
* **NewZidReg** To register a new zero-identity and generates a new backup zero-identity.
* **ZidReclaimed** Claims loss of an active zero-identity or change of an active zero-identity. When a user's private key is lost or compromised he/she can call this function for the claim to abolish the zero-identity associated with the lost private key and activate a backup zero-identity as his/her new zero-identity and generate a new backup zero-identity as well. This function specifies which zero-identity will be abolished, which zero-identity will be used as an active zero-identity and what new backup zero-identity generated. In addition this function can trace all addresses of all the smart contracts the abolished zero-identity has participated.   
* **getActiveZid** Queries whether or not an Ethereum address is an active zero-identity.
* **getCurrentCandidate** Queries the backup zero-identity (or zero-identities) for a zero-identity no matter whether or not this zero-identity is active or abolished. 
* **Implementation** for a user with multiple zero-identities a doubly linked list can be used to link all of them. Let the first generated zero-identity be denoted as A, its backup zero-identity be denoted as B and address(0) be denoted as nil. We doubly link A, B and nil by calling main2Candidate to do A -> B -> nil and calling candidate2Main to do B -> A -> nil. When A is abandoned, B is set as the new zero-identity and C is set as the new backup zero-identity we  will call main2Candidate to do A -> B -> C -> nil and call candidate2Main to do C -> B -> A -> nil. When D is set as the new backup zero-identity we will call main2Candidate to do A -> B -> C -> -> D -> nil and call candidate2Main to do D -> C -> B -> A -> nil. An enquery of any node in this doubly linked list returns the node's status, e.g. whether or not this node is an active zero-identity or whether or not this node is a backup zero-identity etc. By adopting this mechanism we can prevent smart contracts to tranfer tokents to an abolished zero-identity, thus minimize a user's loss.
getZidType queries a zero-identity's type
* **ZidVerifyDone** verifies a query of zero-identity is completed.
* **SmartContractExecuted** Accomplished smart contract lists.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
