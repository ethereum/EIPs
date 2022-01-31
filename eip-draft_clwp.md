---
eip: <to be assigned>
title: Consensus Layer Withdrawal Protection
description: Provides additional security in the "change withdrawal address" operation when a consensus layer mnemonic may be compromised, without changing consensus
author: Benjamin Chodroff (@benjaminchodroff), Jim McDonald (@mcdee)
discussions-to: https://ethereum-magicians.org/t/consensus-layer-withdrawal-protection/8161
status: Draft
type: Standards Track
category (*only required for Standards Track): Interface
created: 2022-01-30
requires (*optional): <EIP number(s)>
---

## Abstract
If a consensus layer mnemonic phrase is compromised, it is impossible for the consensus layer network to differentiate the "legitimate" holder of the key from an "illegitimate" holder. However, there are signals that can be considered in a wider sense without changing core Ethereum consensus. This proposal outlines ways in which the execution layer deposit address, a consensus layer rebroadcast delay, and list of signed messages could create a social consensus that would significantly favor but not guarantee legitimate mnemonic holders would win a race condition against an attacker, while not changing core Ethereum consensus. 

## Motivation
The consensus layer change withdrawal credentials proposal is secure for a single user who has certainty their keys and mnemonic have not been compromised. However, as validator withdrawals on the consensus layer are not yet possible, no user can have absolute certainty that their keys are not compromised until the change withdrawal address is on chain, and by then too late to change. All legitimate mnemonic phrase holders were originally in control of the execution layer deposit address. Beacon node clients and node operators may optionally load a list of verifiable deposit addresses, a list of verifiable change withdrawal address messages to broadcasts, and specify a rebroadcast delay that may create a social consensus for legitimate holders to successfully win a race condition against an attacker. If attackers compromise a significant number of consensus layer nodes, it would pose risks to the entire Ethereum community.

Setting a withdrawal address to an execution layer address was not supported by the eth2.0-deposit-cli until v1.1.1 on March 23, 2021, leaving early adopters wishing they could force change their execution layer address earlier. Forcing this change is not something that can be enforced in-protocol, partly due to lack of information on the beacon chain about the execution layer deposit address and partly due to the fact that this was never listed as a requirement. It is also possible that the execution layer deposit address is no longer under the control of the legitimate holder of the withdrawal private key. 

However, it is possible for individual nodes to locally restrict the changes they wish to include in blocks they propose, and which they propagate around the network, in a way that does not change consensus. It is also possible for client nodes to help broadcast signed change withdrawal address requests to ensure as many nodes witness this change as soon as possible in a fair manner. Further, such change withdrawal address signed messages can be preloaded into clients in advance to further help nodes filter attacking requests.
	
This proposal provides purely optional additional protection. It aims to request nodes set a priority on withdrawal credential claims that favour a verifiable execution layer deposit address in the event of two conflicting change withdrawal credentials. It also establishes a list of change withdrawal address signed messages to help broadcast "as soon as possible" when the network supports it, and encourage client teams to help use these lists to honour filter and prioritize accepting requests by REST and transmitting them via P2P. This will not change consensus, but may help prevent propagating an attack where a withdrawal key has been knowingly or unknowingly compromised. 
	
It is critical to understand that this proposal is not a consensus change. Nothing in this proposal restricts the validity of withdrawal credential change operations within the protocol. It is a voluntary change by client teams to build this functionality in to their beacon nodes, and a voluntary change by node operators to accept any or all of the restrictions and broadcasting capabilities suggested by end users.

Because of the above, even if fully implemented, it will be down to chance as to which validators propose blocks, and which voluntary restrictions those validators’ beacon nodes are running. Node operators can do what they will to help the community prevent attacks on any compromised consensus layer keys, but there are no guarantees of success this will prevent a successful attack. 

## Specification
The Consensus Layer change withdrawal credentials operation is [not yet fully specified](https://github.com/ethereum/consensus-specs/pull/2759), but MUST have at least the following fields:
* Validator index
* Current withdrawal public key
* Proposed execution layer withdrawal address
* Signature by withdrawal private key over the prior fields
	
This proposal describes three OPTIONAL and RECOMMENDED mechanisms which a client beacon node MAY implement, and end users are RECOMMENDED to use in their beacon node operation.

### 1. Change Withdrawal Address Acceptance File
Beacon node clients MAY support an OPTIONAL file in the format "withdrawal credentials, execution layer address" which, if implemented and if provided, SHALL allow clients to load, or RECOMMENDED packaged by default, a verifiable list matching the consensus layer withdrawal credentials and the original execution layer deposit address. While any withdrawal credential and execution layer address found in the file SHALL be supported, this list MAY be used to help enforce a deposit address is given preference in rebroadcasting, even if other clients do not support or have not loaded an OPTIONAL "Change Withdrawal Address Broadcast" file. 

### 2. Change Withdrawal Address Broadcast File
Beacon node clients MAY support an OPTIONAL file of lines specifying "validator index,current withdrawal public key,proposed execution layer withdrawal address,consensus layer signature" which, if implemented and if provided, SHALL instruct nodes to automatically submit a one-time change withdrawal address broadcast message for each valid line at the block height the network supports a "change withdrawal address" operation. This file SHALL give all node operators an OPTIONAL opportunity to ensure any valid change withdrawal address messages are broadcast, heard, and shared by nodes during the first epoch supporting the change withdrawal address operation. This OPTIONAL file SHALL also instruct nodes to perpetually prefer accepting and repeating signatures matching the signature in the file, and SHALL reject accepting or rebroadcasting messages which do not match a signature for a given withdrawal credential. 
	
### 3. Change Withdrawal Address Rebroadcast Delay
Beacon node clients MAY implement an OPTIONAL time measurement parameter "change withdrawal address rebroadcast delay" that, if implemented and if provided, SHALL create a delay in rebroadcasting change withdrawal addresses (RECOMMENDED to default to 2000 seconds (>5 epochs), or OPTIONAL set to 0 seconds for no delay, or MAY set to -1 to strictly only rebroadcast requests matching a "Change Withdrawal Address Broadcast File" signature or "Change Withdrawal Address Acceptance File" entry). This setting SHALL allow change withdrawal address requests time for peer replication of client accepted valid requests that are preferred by the community. This MAY prevent a "first to arrive" critical race condition for a conflicting change withdraw address.

### Change Withdrawal Address Handling
Beacon node clients are RECOMMENDED to first rely on a "Change Withdrawal Address Broadcast" file of verifiable signatures, then MAY fallback to a "Change Withdrawal Address Acceptance" file intended to be loaded with all validator original deposit address information, and then MAY fallback to accept a "first request" but delay in rebroadcasting it via P2P. All of this proposal is OPTIONAL for beacon nodes to implement or use, but all client teams are RECOMMENDED to include a copy or link to the uncontested verification file and RECOMMENDED enable it by default to protect the entire Ethereum community. This OPTIONAL protection will prove the user was both in control of the consensus layer and execution layer address, while making sure their intended change withdrawal address message is ready to broadcast as soon as the network supports it. 

If a node is presented with a change withdrawal address operation via the REST API or P2P, they are RECOMMENDED to follow this process:

A) Withdrawal credential found in "Change Withdrawal Address Broadcast" file:
  1. Signature Match: If a valid change withdrawal request signature is received for a withdrawal credential that matches the first signature found in the "Change Withdrawal Address Broadcast" file, accept it via REST API, rebroadcast it via P2P, and drop any pending “first preferred” if existing. 
  2. Signature Mismatch: If a valid change withdrawal request is received for a withdrawal credential that does not match the first signature found in the "Change Withdrawal Address Broadcast" file, reject it via REST API, and drop it to prevent rebroadcasting it via P2P.

B) Withdrawal credential not found in or no "Change Withdrawal Address Broadcast" file provided, or capability not implemented in the client:
1. Matching withdraw credential and withdraw address in "Change Withdrawal Address Acceptance" file: If a valid change withdrawal address request is received for a withdrawal credential that matches the first found withdrawal address provided in the "Change Withdrawal Address Acceptance" file, accept it via REST API, rebroadcast it via P2P, and drop any pending “first preferred” if existing. 
2. Mismatching withdraw credential and withdraw address in "Change Withdrawal Address Acceptance" file: If a valid change withdrawal request is received for a withdrawal credential that does not match the first found withdrawal address provided in the "withdrawal address" file, reject it via REST API, and drop it to prevent rebroadcasting it via P2P.
3. Missing withdraw address in or no "Change Withdrawal Address Acceptance" file: 

    i. First Preferred: If first valid change withdrawal request is received for a not finalized withdrawal credential that does not have any listed withdrawal credential entry in the "Change Withdrawal Address Acceptance" file, accept it via REST API, but do not yet rebroadcast it via P2P (“grace period”). Once the client “Change Withdrawal Address Grace Period” has expired and no other messages have invalidated this message, rebroadcast the request via P2P. 
  
    ii. Subsequent Rejected: If an existing valid "First Preferred" request exists for a not finalized withdrawal credential, reject it via REST API, and drop it to prevent rebroadcasting via P2P. 

Note that these restrictions SHALL NOT apply to withdrawal credential change operations found in blocks. If any operation has been included on-chain, it MUST by definition be valid regardless of its contents or protective mechanisms described above. 

## Rationale
This proposal is intended to protect legitimate mnemonic phrase holders where the phrase was knowingly or unknowingly compromised. As there is no safe way to transfer ownership of a validator without exiting, it can safely be assumed that all current validator holders intend to change to a withdrawal address they specify. Using the deposit address in the execution layer to determine the legitimate holder is not possible to consider in consensus as it may be far back in history and place an overwhelming burden to maintain such a list. As such, this proposal outlines optional mechanism which protect legitimate original mnemonic holders and does so in a way that does not place any mandatory burden on client node software or operators. 

## Backwards Compatibility
As there is currently no existing "change withdrawal address" operation in existence, there is no documented backwards compatibility. As all of the proposal is OPTIONAL in both implementation and operation, it is expected that client beacon nodes that do not implement this functionality would still remain fully backwards compatible with any or all clients that do implement part or all of the functionality described in this proposal. Additionally, while users are RECOMMENDED to enable these OPTIONAL features, if they decide to either disable or ignore some or all of the features, or even purposefully load content contrary to the intended purpose, the beacon node client will continue to execute fully compatible with the rest of the network as none of the proposal will change core Ethereum consensus. 

## Test Cases
This proposal does not change consensus. However, beacon node client test cases will be added here once the proposal is formalized.

## Reference Implementation
### Change Withdrawal Address Acceptance File
A file intended to be preloaded with all consensus layer withdrawal credentials and verifiable execution layer deposit addresses. This file will be generated by a script and able to be independently verified by community members using the consensus and execution layers, and intended to be included by all clients, enabled by default. Client nodes are encouraged to enable packaging this independently verifiable list with the client software, and enable it by default to help further protect the community from unsuspected attacks. 

depositAddress.csv format (both fields required):
```withdrawal credential, withdrawal address```

Example depositAddress.csv:
```
000092c20062cee70389f1cb4fa566a2be5e2319ff43965db26dbaa3ce90b9df99,01c34eb7e3f34e54646d7cd140bb7c20a466b3e852
0000d66cf353931500a54cbd0bc59cbaac6690cb0932f42dc8afeddc88feeaad6f,01c34eb7e3f34e54646d7cd140bb7c20a466b3e852
0000d6b91fbbce0146739afb0f541d6c21e8c41e92b97874828f402597bf530ce4,01c34eb7e3f34e54646d7cd140bb7c20a466b3e852
000037ca9a1cf2223d8b9f81a14d4937fef94890ae4fcdfbba928a4dc2ff7fcf3b,01c34eb7e3f34e54646d7cd140bb7c20a466b3e852
0000344b6c73f71b11c56aba0d01b7d8ad83559f209d0a4101a515f6ad54c89771,01f19b1c91faacf8071bd4bb5ab99db0193809068e
```

### Change Withdrawal Address Broadcast File - Claim
A community collected and independently verifiable list of "Change Withdrawal Address Broadcasts" containing verifiable claims will be collected. Client teams and node operators may verify these claims independently and are suggested to include "Uncontested and Verified" claims enabled by default in their package. 

To make a verifiable claim, users must upload using their GitHub ID with the following contents to the [CLWP repository](https://github.com/benjaminchodroff/ConsensusLayerWithdrawalProtection) in a text file "claims/validatorIndex-gitHubUser.txt" such as "123456-myGitHubID.txt"

123456-myGitHubID.txt:
```
current_withdrawal_public_key=b03c5ea17b017cffd22b6031575c4453f20a4737393de16a626fb0a8b0655fe66472765720abed97e8022680204d3868
proposed_withdrawal_address=0108f2e9Ce74d5e787428d261E01b437dC579a5164
consensus_layer_withdrawal_signature=
execution_layer_deposit_signature=
execution_layer_withdrawal_signature=
email=noreply@ethereum.org
```

| Key | Value | 
| ----| ------|
| **current_withdrawal_public_key** | (Required) The "pubkey" field found in deposit_data json file matching the validator index| Required | Necessary for verification |
| **proposed_withdrawal_address** | (Required) The address in Ethereum you wish to authorize withdrawals to, prefaced by "01" without any "0x", such that an address "0x08f2e9Ce74d5e787428d261E01b437dC579a5164" turns into "0108f2e9Ce74d5e787428d261E01b437dC579a5164 |
| **consensus_layer_withdrawal_signature** | (Required) The verifiable signature generated by signing "validator_index,current_withdrawal_public_key,proposed_withdrawal_address" using the consensus layer private key | 
| execution_layer_deposit_signature | (Optional) The verifiable signature generated by signing "validator_index,current_withdrawal_public_key,proposed_withdrawal_address" using the execution layer deposit address private key | 
| execution_layer_withdrawal_signature | (Optional) The verifiable signature generated by signing "validator_index,current_withdrawal_public_key,proposed_withdrawal_address" using the execution layer proposed withdrawal address private key. This may be the same result as the "execution_layer_deposit_signature" if the user intends to withdraw to the same execution layer deposit address. |
| email | (Optional) Any actively monitored email address to notify if contested | 

#### Claim Acceptance
In order for a submission to be merged into CLWP GitHub repository, the submission must have:
1. Valid filename in the format validatorIndex-githubUsername.txt
2. Valid validator index which is deposited, pending, or active on the consensus layer 
3. Matching GitHub username in file name to the user submitting the request
4. Verifiable consensus_layer_withdrawal_signature, and a verifiable execution_layer_deposit_signature and execution_layer_withdrawal_signature if included
5. All required fields in the file with no other content present

All merge requests that fail will be provided a reason from above which must be addressed prior to merge. Any future verifiable amendments to accepted claims must be proposed by the same GitHub user, or it will be treated as a contention.

#### Change Withdrawal Address Broadcast
Anyone in the community will be able to generate the following verifiable files from the claims provided:
	A. UncontestedVerified - Community collected list of all verifiable uncontested change withdrawal address final requests (no conflicting withdrawal credentials allowed from different GitHub users)
	B. ContestedVerified - Community collected list of all contested verifiable change withdrawal address requests (will contain only verifiable but conflicting withdrawal credentials from different GitHub users)

A claim will be considered contested if a claim arrives where the verifiable consensus layer signatures differ between two or more GitHub submissions, where neither party has proven ownership of the execution layer deposit address. If a contested but verified "Change Withdrawal Address Broadcast" request arrives to the GitHub community, all parties will be notified via GitHub, forced into the ContestedVerified list, and may try to convince the wider community by providing any off chain evidence supporting their claim to then include their claim in nodes. All node operators are encouraged to load the UncontestedVerified signatures file as enabled, and optionally append only ContestedVerified signatures that they have been convinced are the rightful owner in a manner to further strengthen the community. 

The uncontested lists will be of the format:

UncontestedVerified-datetime.txt:
```
validator_index,current_withdrawal_public_key,proposed_withdrawal_address,consensus_layer_withdrawal_signature
```

The contested list will be of the format:

ContestedVerified-datetime.txt
```
validator_index,current_withdrawal_public_key,proposed_withdrawal_address,consensus_layer_withdrawal_signature,email
```

## Security Considerations

### 1: Attacker lacks EL deposit key, uncontested claim
- User A: Controls the CL keys and the EL key used for the deposit
- User B: Controls the CL keys, but does not control the EL key for the deposit

User A signs and submits a claim to the CLWP repository, clients load User A message into the "Change Withdrawal Address Broadcast" file. At the time of the first epoch support Change Withdrawal Address, many (not all) nodes begin to broadcast the message. User B also tries to submit a different but valid Change Withdrawal Address to an address that does not match the signature in the claim. This message is successfully received via REST API, but some (not all) nodes begin to silently drop this message as the signature does not match the signature in the "Change Withdrawal Address Broadcast" file. As such, these nodes do not replicate this message via P2P. The nodes which do not have a Change Withdrawal Address Broadcast file loaded may still impose a "Change Withdrawal Address Rebroadcast Delay" to keep listening (for about 5 epochs) to see if there are any conflicts to this message. This delay may give User A an advantage in beating User B to consensus, but there is no certainty as it will depend on chance which validator and nodes are involved. 

### 2: Attacker has both EL deposit key and CL keys, uncontested claim
- User A: Controls the CL key/mnemonic and the EL key used for the deposit, and submits a claim to move to a new address
- User B: Controls the CL and EL key/mnemonic used for the EL deposit, but fails to submit a claim

It is possible/likely that User A would notice that all their funds in the EL deposit address had been stolen. This may signal that their CL key is compromised as well, so they decide to pick a new address for the withdrawal. The story will play out the same as Scenario 1 as the claim is uncontested. 

### 3: Same as #2, but the attacker submits a contested claim
- User A: Controls the CL keys/mnemonic and the EL key used for the deposit, and submits a claim to move to a new address
- User B: Controls the CL keys/mnemonic and the EL key used for the deposit, and submits a claim to move to a new address

This is a contested claim and as such there is no way to prove who is in control using on chain data. Instead, either user may try to persuade the community they are the rightful owner (identity verification, social media, etc.) in an attempt to get node operators to load their contested claim into their "Change Withdrawal Address Broadcast" file. However, there is no way to fully prove it. 

### 4: A user has lost either their CL key and/or mnemonic (no withdrawal key)
- User A: Lacks the CL keys and mnemonic

There is no way to recover this scenario with this proposal as we cannot prove a user has lost their keys, and the mnemonic is required to generate the withdrawal key. 

### 5: End game - attacker
- User A: Controls EL and CL key/mnemonic, successfully achieves a change address withdrawal
- User B: Controls CL key, decides to attack

Upon noticing User A has submitted a successful change address withdrawal, User B may run a validator and attempt to get User A slashed

### 6: Compromised key, but not vulnerable to withdrawal
- User A: Controls EL and CL key/mnemonic, but has a vulnerability which leaks their CL key but NOT their CL mnemonic
- User B: Controls the CL key, but lacks the CL mnemonic

User A may generate the withdrawal key (requires the mnemonic). User B can attack User A by getting them slashed, but will be unable to generate the withdrawal key. 

### 7: Attacker loads a malicious Change Withdrawal Address Broadcast and Change Withdrawal Address Acceptance files into one or multiple nodes, User A submits claim
- User A: Submits a valid uncontested claim which is broadcast out as soon as possible by many nodes
- User B: Submits no claim, but broadcasts a valid malicious claim out through their Change Withdrawal Address Broadcast list, and blocks User A's claim from their node.

User B's claim will make it into many nodes, but when it hits nodes that have adopted User A's signature they will be dropped and not rebroadcast. Statistically, User B will have a harder time achieving consensus among the entire community, but it will be down to chance. 

### 8: Same as #7, but User A submits no claim

The attacker will statistically likely win as they will be first to have their message broadcast to many nodes and, unless User A submits a request exactly at the time of support, it is unlikely to be heard by enough nodes to gain consensus. All users are encouraged to submit claims for this reason because nobody can be certain their mnemonic has not been compromised until it is too late. 

### Second Order Effects
1. A user who participates in the "Change Withdrawal Address Broadcast" may cause the attacker to give up early and instead start to slash. For some users, the thought of getting slashed is preferrable to giving an adversary any funds. As the proposal is voluntary, users may choose not to participate if they fear this scenario.
2. The attacker may set up their own unverified list of their own Change Withdrawal Address Acceptance file and nodes adopting this list to break ties in their favour. It is unlikely they would operate enough beacon nodes to form a consensus. 
3. The attacker may set up their own Change Withdrawal Address Broadcast to reject signatures not matching their attack. This is possible with or without this proposal. 
4. The attacker may be the one collecting "Change Withdrawal Address Broadcast" claims for this proposal and may purposefully reject legitimate requests. Anyone is free to set up their own community claim collection and gather their own community support using the same mechanisms described in this proposal to form an alternative social consensus. Come at me bro.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
