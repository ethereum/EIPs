---
title: Universal Enshrined Encrypted Mempool
description: Add a scheme agnostic encrypted mempool
author: Jannik Luhn (@jannikluhn)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-12-17
requires: 7732
---

## Abstract

This EIP proposes to enshrine an encrypted mempool into the protocol. It enables users to encrypt their transactions until they have been included in a block, protecting them from front running and sandwiching attacks as well as increasing censorship resistance guarantees. The design is encryption technology agnostic by supporting arbitrary decryption key providers, which can for instance be based on threshold encryption, MPC committees, TEEs, delay encryption, or FHE schemes. Traditional plaintext transactions are still supported and progression of the chain is guaranteed even if decryption key providers fail.

## Motivation

The goal of this EIP is to prevent users from malicious transaction reordering attacks as well as increase real time ("weak") censorship resistance of the protocol. It also aims to reduce regulatory risks of block builders and other protocol participants by temporarily blinding them. The goal is not to improve user privacy (e.g., transaction confidentiality) as transactions are publicly revealed eventually.

This proposal builds on prior work such as the [Shutterized Beacon Chain](https://ethresear.ch/t/shutterized-beacon-chain/12249) and a live, out-of-protocol implementation of the encrypted mempool already deployed on [Gnosis Chain](https://www.gnosis.io/blog/shutterized-gnosis-chain-is-live). It addresses a long-standing issue with front running and has the potential to mitigate harmful second-order effects of MEV, such as builder centralization. The design also fits naturally with enshrined proposer-builder separation (ePBS), making it a logical extension of Ethereum’s roadmap.

## Specification

In the execution layer, a contract called the key provider registry is deployed. It allows any account to register a key provider and assigns them a unique ID. Registration requires specifying a contract with a decryption and a key validation function, each of which accept a key ID and a key message as byte strings. Additionally, key providers may designate other providers as directly trusted, thereby forming a directed trust graph. We define a key provider A to trust another key provider B if and only if a directed path from A to B exists in this graph. The beacon chain replicates the key provider registry in its state, analogously to the mechanism that handles beacon chain deposits.

Encrypted transactions are added as a new transaction type. They consist of an envelope and the encrypted payload. The envelope specifies the envelope nonce, gas amount, gas price parameters, key provider ID, key ID, and the envelope signature. The encrypted payload contains the payload nonce, value, calldata, and payload signature.

In a valid block, any transaction encrypted with a key from key provider A may only be preceded by

- Plaintext transactions
- Transactions encrypted with keys from key provider A
- Transactions encrypted with keys from key providers that A trusts

In each slot, when a key provider observes the execution payload published by the builder, they collect the key IDs referenced in the envelopes of all encrypted transactions addressed with their key provider ID. For each of those, they must publish either the corresponding decryption key or a key withhold notice. The corresponding message references the beacon block hash to prevent replays in a future slot. They may do so either immediately upon observing the execution payload or delay publication to a later point in the slot.

Members of the Payload Timeliness Committee (PTC) must listen for the decryption keys referenced by all encrypted transactions, as identified by the key provider ID and key ID fields. They must validate these keys using the validation function specified in the registry contract, using a hardcoded small gas limit per key. Finally, they must attest to the presence or absence of a valid key for each encrypted transaction in the payload attestation message, which is extended for this purpose with a dedicated bitfield.

During execution payload processing, after all plaintext transactions, the envelopes of the encrypted transactions are executed as a batch. This updates the nonces of the envelope signers and pays fees from the envelope accounts. The fee covers the cost of block space used by the envelope, decrypted payload, and decryption key, as well as the computation used during decryption and key validation. Subsequently, the encrypted payloads are decrypted with the key specified by the key provider ID and key ID on the envelope using the decryption function from the key provider registry. If decryption succeeds, the resulting payload transactions are executed subject to the gas limit specified on the envelopes as well as the block gas limit. If decryption or execution fails, including if the decryption key is attested as missing by the PTC, the transaction is skipped without reverting the envelope.

## Rationale

### Key Provider Registration

Registration is encryption technology agnostic to ensure neutrality of the protocol, to minimize barriers to entry for new key providers, and to empower users to choose the optimal scheme for their purposes. An execution layer contract was chosen as a canonical way of specifying arbitrary execution logic. Registration purely on the CL is a reasonable alternative.

Many encryption schemes are inefficient to express in the EVM and therefore would require dedicated precompiles. Adding those is, however, out of scope of this EIP.

### Key Provider Trust Graph

A user who sends an encrypted transaction must not only trust their own key provider, but also any key provider used for earlier transactions in a block (see Security Considerations). While the protocol should respect the users’ trust preferences, if each user only trusts their own key provider, builders would only be able to include transactions encrypted with keys from a single key provider in each block. This is undesirable because it makes it difficult for key providers with a small market share to compete, risking to create a key provider monopoly.

On the other hand, requiring users to explicitly state which third-party providers they trust would add a transaction size overhead and make block building more difficult due to the potentially large number of competing user preferences that need to be fulfilled. As a compromise, this proposal requires key providers to make this choice. Users implicitly agree by using the key provider’s keys.

With this solution, even if a quasi-monopoly consisting of a single dominating key provider emerges and this key provider does not specify any other key providers as trusted, builders can still include transactions that use other small key providers without opportunity costs, as long as the small key providers trust the major one (and potentially each other).

### Transaction Order

The proposal effectively splits blocks into a plaintext and an encrypted transaction section. Plaintext transactions are put first, enabling builders to fully simulate the execution in this section and apply existing block building techniques and MEV extraction strategies. Builders can thus append encrypted transactions to the end of the block without opportunity costs. If the order were reversed, fees for encrypted transactions would have to be considerably higher in order for blocks that include them to be competitive in PBS auctions compared to blocks with only plaintext transactions.

### Transaction Execution

The protocol as well as builders must be protected from including encrypted transactions that end up unable to pay for gas. To ensure this is the case irrespective of the content of any encrypted payload in a block, the fee payment is part of the plaintext envelope and all envelopes in a block are executed before any encrypted payload. Gas refunds are not paid out to guarantee the fee amount the builder and the protocol will receive at block building time.

For simplicity, the encrypted payload contains a signature. A less private but more efficient alternative is to consider the envelope signer as sender.

### Decryption Key Withholding

The protocol explicitly allows decryption key providers to withhold decryption keys under conditions of their choosing. This enables them to safely implement rules to restrict which users are allowed to use which keys, e.g., based on prior payments and to prevent key ID front running attacks (see Security Considerations). On the other hand, keys that have been withheld unjustifiably may be used in custom slashing mechanisms and reliability metrics (note that the protocol records which keys are present and which ones have been present and which ones have not).

### Lack of In-Protocol Key Provider Incentives

This proposal does not enshrine a fee mechanism for key providers, nor punishments for misbehavior. This allows for a variety of incentive models to be implemented off-chain. For instance, key providers could make agreements with builders, be paid on a per-transaction basis by users, or operate as public goods. They may also subject themselves to slashing conditions for unwarranted withholding of keys to make their service more appealing to users.

### Execution Payload Encryption

A future EIP may propose to let builders use the keys from the key providers to encrypt the execution payload. This enables them to publish the execution payload immediately after constructing it, compared to publishing it only at the 50% slot mark. This would increase p2p efficiency and protect builders from missed slots due to crashes. Additionally, if the builder attaches a zero knowledge proof about which keys have been used in a block, the key revelation time window could start earlier and therefore be longer. This feature is not included in this EIP to minimize complexity.

## Backwards Compatibility

The proposal makes backwards incompatible changes to the protocol to the execution and consensus layer.

## Security Considerations

### Trusted Key Providers

Users necessarily need to trust the key providers they use to encrypt their transactions to

- not release the decryption keys early which would allow front running and sandwiching attacks
- not release the decryption keys late which would prevent execution of the transaction while the envelope fee still has to be paid.

Key providers may earn this trust by cryptographic mechanisms (e.g., threshold encryption, hardware encryption), economic mechanisms (e.g., slashing for misbehavior), governance mechanisms (e.g., voting to select socially reputable entities), or a combination of these.

To a lesser degree, users need to trust all key providers used for encrypted transactions preceding theirs in a block. This is because key providers have the option to publish or to withhold decryption keys which they can take after observing decryption keys for following transactions. This option gives them one bit of influence over the pre-state of later transactions. Maliciously chosen “decryption” schemes may make this attack much stronger by allowing directly modifying specific parts of the decryption results using crafted decryption keys or setting it outright. This effectively enables front running.

Users do not have to trust any key provider used for transactions included after theirs because the pre-state of the user’s transaction payload is not affected by later transactions’ payloads (only their envelopes, but those are chosen before any decryption keys are published). Similarly, users of plaintext transactions do not have to trust any key provider (but they continue to have to trust builders).

### Reorgs

Decryption keys are published before the corresponding encrypted transactions are finalized. Thus, in the event of a chain reorg, a transaction may become public even though it is not necessarily included in the chain. However, since the decryption key message includes the block hash, it can be invalidated by the key validation function. This does not prevent inclusion of the envelope transaction, but does prevent execution and, hence, front running of the payload.

### Key ID Front Running

When a user encrypts a transaction with a particular key ID, another user could observe this transaction in flight and create another encrypted transaction that specifies the same key provider and key ID. If the second transaction is included in an earlier block than the original one, a naive key provider would reveal the key and thus the original transaction, even though it is not included yet.

Key providers can protect their users from this attack. One possible strategy to do so is “namespacing” key IDs: Providers only release keys for key IDs that are prefixed with the envelope signer’s address and withhold all others. As we can reasonably assume that the attacker does not have access to the envelope signer account, an attacker would be unable to produce a transaction with correctly namespaced key ID.

### Key Provider-Child Builder Collusion

To build a new block, builders need to know the post-state of the previous block and thus all decryption keys used in a block and which of them are withheld. This information is publicly known once the PTC attests. However, malicious key providers could collude with a block builder and give them an earlier heads up. This would give the builders a competitive advantage as they can start the block building process earlier.

The impact of the attack is deemed low because the time between publishing of the payload attestations and the end of the slot is still long enough for block building. Furthermore, the start of the block building period is much less critical than the end (since only then the full set of includable transactions is known), which is not affected by the attack. Also, delaying the release of decryption keys bears the risk of them not being attested to by the PTC, negating the competitive advantage of the attacker. And finally, if the number of encrypted transactions that use the malicious key provider is small, their impact on the tree state is likely small as well. This means optimistic block building strategies that don’t rely on full knowledge of the state tree could be viable, countering the attack.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
