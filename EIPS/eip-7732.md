---
eip: 7732
title: Enshrined Proposer-Builder Separation
description: Separates the ethereum block in consensus and execution parts, adds a mechanism for the consensus proposer to choose the execution proposer.
author: Francesco D'Amato <francesco.damato@ethereum.org>, Barnabé Monnot <barnabe.monnot@ethereum.org>, Michael Neuder <michael.neuder@ethereum.org>, Potuz (@potuz), Justin Traglia <jtraglia@ethereum.org>, Terence Tsao <ttsao@offchainlabs.com>
discussions-to: https://ethereum-magicians.org/t/eip-7732-enshrined-proposer-builder-separation-epbs/19634
status: Draft
type: Standards Track
category: Core
created: 2024-06-28
---

## Abstract

This EIP fundamentally changes the way an Ethereum block is validated by decoupling the execution validation from the consensus validation both logically as well as temporally. It does so by introducing a new in-protocol entity called *builders* and adding a new duty (submitting *payload timeliness attestations*) to Ethereum validators. The `ExecutionPayload` field of the `BeaconBlockBody` is removed and instead it is replaced by a signed commitment (a `SignedExecutionPayloadBid` object) from a builder to later reveal the corresponding execution payload. This commitment specifies in particular the blockhash of the execution block and a *value* to be paid to the beacon block proposer. When processing the `BeaconBlock`, the committed value is deducted from the builder's beacon chain balance and later a withdrawal is placed to an address, of the proposer's choosing, in the execution layer. A subset of validators in the beacon committee is assigned to the *Payload Timeliness Committee* (PTC), these validators are tasked to attest (by broadcasting a `PayloadAttestationMessage`) to whether the corresponding builder has revealed the committed execution payload (with the right blockhash) in a timely fashion and whether the correspoding blob data was available according to their view. PTC members are not required to validate the execution payload, execution validation is thus deferred until the next beacon block validation. While builder's are staked entities, their stake is not actively validating the beacon chain, they are not subject to the usual deposit and exit churn/queues and can be staked for as little as 1ETH. While the in-protocol payment via withdrawals is trustlessly deducted from this stake, the protocol also accomodates for trusted payments in the form of *promises* to be fulfiled elsewhere. 

## Motivation

This EIP solves a different set of unrelated important problems. 

- An overwhelming majority of beacon block proposers outsource the construction of the execution payload within their blocks to a third party (henceforth called a *builder*). In order to do so, they request the hash tree root (HTR) of a promised execution payload and submit a `SignedBlindedBeaconBlock` to a trusted party that is tasked with replacing the HTR with the full execution payload (received from the builder) before broadcasting. This EIP allows for a trust-free fair exchange between the beacon block proposer and the builder, guaranteeing that an honest beacon block proposer will receive payment from the builder regardless of the latter's actions and that the honest builder's payload will be the canonical head of the chain regardless of the proposer's action. 
- Currently, validators have the time between receiving the full beacon block (including an execution payload) and the attesting deadline (4 seconds in Ethereum mainnet) to perform both consensus and execution state transition functions, check blob data availability and evaluate the new head of the blockchain. The remainder of the slot time is spent doing less CPU-intense and critical task. By separating the validation of the execution and consensus part of the block, validators are only tasked to perform the consensus state transition function in this critical time before attesting, while execution and data availability validation is deferred for most of the remainder of the slot (between the builder's reveal time and the next attestation deadline). 
- By removing the full execution payload size from the consensus block, it allows for faster network propagation on the critical path. 
- It removes the increased reorg likeliness of including blob transactions in blocks given the natural increase in timelines for data availability checks and the fact that the builder may broadcast the blob sidecars even before attestations for the beacon block have been released. 
- It prevents validators from missing attestations and strengthens the weight properties of fork choice in the event that builders produce invalid payloads. 
- It removes the need to use trusted middleware in order to delegate block construction to a builder.

## Specification

### Execution Layer

No changes are required. 

### Consensus Layer

The full consensus changes can be found in the consensus-specs Github repository. They are split between: 

- [Beacon Chain](https://github.com/ethereum/consensus-specs/blob/c94138e73e0e70eb4b27f9be4d4e9325fa1aebf7/specs/gloas/beacon-chain.md) changes.
- [Fork choice](https://github.com/ethereum/consensus-specs/blob/c94138e73e0e70eb4b27f9be4d4e9325fa1aebf7/specs/gloas/fork-choice.md) changes.
- [P2P](https://github.com/ethereum/consensus-specs/blob/c94138e73e0e70eb4b27f9be4d4e9325fa1aebf7/specs/gloas/p2p-interface.md) changes.
- [Honest validator guide](https://github.com/ethereum/consensus-specs/blob/c94138e73e0e70eb4b27f9be4d4e9325fa1aebf7/specs/gloas/validator.md) changes.
- A new [honest builder](https://github.com/ethereum/consensus-specs/blob/c94138e73e0e70eb4b27f9be4d4e9325fa1aebf7/specs/gloas/builder.md) guide. 
- [Fork logic](https://github.com/ethereum/consensus-specs/blob/c94138e73e0e70eb4b27f9be4d4e9325fa1aebf7/specs/gloas/fork.md) changes. 

A summary of the main changes is included below, the [Rationale](#rationale) section contains explanation for most of the design decisions around these changes. 

#### Beacon chain changes

##### Types

| Name           | SSZ equivalent | Description            |
| -------------- | -------------- | ---------------------- |
| `BuilderIndex` | `uint64`       | Builder registry index |

##### Constants

###### Index flags

| Name                 | Value           | Description                                                                                |
| -------------------- | --------------- | ------------------------------------------------------------------------------------------ |
| `BUILDER_INDEX_FLAG` | `uint64(2**40)` | Bitwise flag which indicates that a `ValidatorIndex` should be treated as a `BuilderIndex` |

##### Domains

| Name                          | Value                      |
| ----------------------------- | -------------------------- |
| `DOMAIN_BEACON_BUILDER`       | `DomainType('0x0B000000')` |
| `DOMAIN_PTC_ATTESTER`         | `DomainType('0x0C000000')` |
| `DOMAIN_PROPOSER_PREFERENCES` | `DomainType('0x0D000000')` |

##### Misc

| Name                                    | Value                      | Description                                          |
| --------------------------------------- | -------------------------- | ---------------------------------------------------- |
| `BUILDER_INDEX_SELF_BUILD`              | `BuilderIndex(UINT64_MAX)` | Value which indicates the proposer built the payload |
| `BUILDER_PAYMENT_THRESHOLD_NUMERATOR`   | `uint64(6)`                |                                                      |
| `BUILDER_PAYMENT_THRESHOLD_DENOMINATOR` | `uint64(10)`               |                                                      |

##### Withdrawal prefixes

| Name                        | Value            | Description                                |
| --------------------------- | ---------------- | ------------------------------------------ |
| `BUILDER_WITHDRAWAL_PREFIX` | `Bytes1('0x03')` | Withdrawal credential prefix for a builder |

##### Preset

###### Misc

| Name       | Value                  |
| ---------- | ---------------------- |
| `PTC_SIZE` | `uint64(2**9)` (= 512) |

###### Max operations per block

| Name                       | Value |
| -------------------------- | ----- |
| `MAX_PAYLOAD_ATTESTATIONS` | `4`   |

###### State list lengths

| Name                                | Value                                 | Unit                        |
| ----------------------------------- | ------------------------------------- | --------------------------- |
| `BUILDER_REGISTRY_LIMIT`            | `uint64(2**40)` (= 1,099,511,627,776) | Builders                    |
| `BUILDER_PENDING_WITHDRAWALS_LIMIT` | `uint64(2**20)` (= 1,048,576)         | Builder pending withdrawals |

###### Withdrawals processing

| Name                                 | Value              |
| ------------------------------------ | ------------------ |
| `MAX_BUILDERS_PER_WITHDRAWALS_SWEEP` | `2**14` (= 16,384) |

##### Configuration

###### Time parameters

| Name                                | Value                 |  Unit  |
| ----------------------------------- | --------------------- | :----: |
| `MIN_BUILDER_WITHDRAWABILITY_DELAY` | `uint64(2**6)` (= 64) | epochs |

##### Containers

###### New containers

###### `Builder`

```python
class Builder(Container):
    pubkey: BLSPubkey
    version: uint8
    execution_address: ExecutionAddress
    balance: Gwei
    deposit_epoch: Epoch
    withdrawable_epoch: Epoch
```

###### `BuilderPendingPayment`

```python
class BuilderPendingPayment(Container):
    weight: Gwei
    withdrawal: BuilderPendingWithdrawal
```

###### `BuilderPendingWithdrawal`

```python
class BuilderPendingWithdrawal(Container):
    fee_recipient: ExecutionAddress
    amount: Gwei
    builder_index: BuilderIndex
```

###### `PayloadAttestationData`

```python
class PayloadAttestationData(Container):
    beacon_block_root: Root
    slot: Slot
    payload_present: boolean
    blob_data_available: boolean
```

###### `PayloadAttestation`

```python
class PayloadAttestation(Container):
    aggregation_bits: Bitvector[PTC_SIZE]
    data: PayloadAttestationData
    signature: BLSSignature
```

###### `PayloadAttestationMessage`

```python
class PayloadAttestationMessage(Container):
    validator_index: ValidatorIndex
    data: PayloadAttestationData
    signature: BLSSignature
```

###### `IndexedPayloadAttestation`

```python
class IndexedPayloadAttestation(Container):
    attesting_indices: List[ValidatorIndex, PTC_SIZE]
    data: PayloadAttestationData
    signature: BLSSignature
```

###### `ExecutionPayloadBid`

```python
class ExecutionPayloadBid(Container):
    parent_block_hash: Hash32
    parent_block_root: Root
    block_hash: Hash32
    prev_randao: Bytes32
    fee_recipient: ExecutionAddress
    gas_limit: uint64
    builder_index: BuilderIndex
    slot: Slot
    value: Gwei
    execution_payment: Gwei
    blob_kzg_commitments: List[KZGCommitment, MAX_BLOB_COMMITMENTS_PER_BLOCK]
```

###### `SignedExecutionPayloadBid`

```python
class SignedExecutionPayloadBid(Container):
    message: ExecutionPayloadBid
    signature: BLSSignature
```

###### `ExecutionPayloadEnvelope`

```python
class ExecutionPayloadEnvelope(Container):
    payload: ExecutionPayload
    execution_requests: ExecutionRequests
    builder_index: BuilderIndex
    beacon_block_root: Root
    slot: Slot
    state_root: Root
```

###### `SignedExecutionPayloadEnvelope`

```python
class SignedExecutionPayloadEnvelope(Container):
    message: ExecutionPayloadEnvelope
    signature: BLSSignature
```

###### Modified containers

###### `BeaconBlockBody`

*Note*: The removed fields (`execution_payload`, `blob_kzg_commitments`, and
`execution_requests`) now exist in `ExecutionPayloadEnvelope`.

```python
class BeaconBlockBody(Container):
    randao_reveal: BLSSignature
    eth1_data: Eth1Data
    graffiti: Bytes32
    proposer_slashings: List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
    attester_slashings: List[AttesterSlashing, MAX_ATTESTER_SLASHINGS_ELECTRA]
    attestations: List[Attestation, MAX_ATTESTATIONS_ELECTRA]
    deposits: List[Deposit, MAX_DEPOSITS]
    voluntary_exits: List[SignedVoluntaryExit, MAX_VOLUNTARY_EXITS]
    sync_aggregate: SyncAggregate
    # [Modified in Gloas:EIP7732]
    # Removed `execution_payload`
    bls_to_execution_changes: List[SignedBLSToExecutionChange, MAX_BLS_TO_EXECUTION_CHANGES]
    # [Modified in Gloas:EIP7732]
    # Removed `blob_kzg_commitments`
    # [Modified in Gloas:EIP7732]
    # Removed `execution_requests`
    # [New in Gloas:EIP7732]
    signed_execution_payload_bid: SignedExecutionPayloadBid
    # [New in Gloas:EIP7732]
    payload_attestations: List[PayloadAttestation, MAX_PAYLOAD_ATTESTATIONS]
```

###### `BeaconState`

```python
class BeaconState(Container):
    genesis_time: uint64
    genesis_validators_root: Root
    slot: Slot
    fork: Fork
    latest_block_header: BeaconBlockHeader
    block_roots: Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
    state_roots: Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
    historical_roots: List[Root, HISTORICAL_ROOTS_LIMIT]
    eth1_data: Eth1Data
    eth1_data_votes: List[Eth1Data, EPOCHS_PER_ETH1_VOTING_PERIOD * SLOTS_PER_EPOCH]
    eth1_deposit_index: uint64
    validators: List[Validator, VALIDATOR_REGISTRY_LIMIT]
    balances: List[Gwei, VALIDATOR_REGISTRY_LIMIT]
    randao_mixes: Vector[Bytes32, EPOCHS_PER_HISTORICAL_VECTOR]
    slashings: Vector[Gwei, EPOCHS_PER_SLASHINGS_VECTOR]
    previous_epoch_participation: List[ParticipationFlags, VALIDATOR_REGISTRY_LIMIT]
    current_epoch_participation: List[ParticipationFlags, VALIDATOR_REGISTRY_LIMIT]
    justification_bits: Bitvector[JUSTIFICATION_BITS_LENGTH]
    previous_justified_checkpoint: Checkpoint
    current_justified_checkpoint: Checkpoint
    finalized_checkpoint: Checkpoint
    inactivity_scores: List[uint64, VALIDATOR_REGISTRY_LIMIT]
    current_sync_committee: SyncCommittee
    next_sync_committee: SyncCommittee
    # [Modified in Gloas:EIP7732]
    # Removed `latest_execution_payload_header`
    # [New in Gloas:EIP7732]
    latest_execution_payload_bid: ExecutionPayloadBid
    next_withdrawal_index: WithdrawalIndex
    next_withdrawal_validator_index: ValidatorIndex
    historical_summaries: List[HistoricalSummary, HISTORICAL_ROOTS_LIMIT]
    deposit_requests_start_index: uint64
    deposit_balance_to_consume: Gwei
    exit_balance_to_consume: Gwei
    earliest_exit_epoch: Epoch
    consolidation_balance_to_consume: Gwei
    earliest_consolidation_epoch: Epoch
    pending_deposits: List[PendingDeposit, PENDING_DEPOSITS_LIMIT]
    pending_partial_withdrawals: List[PendingPartialWithdrawal, PENDING_PARTIAL_WITHDRAWALS_LIMIT]
    pending_consolidations: List[PendingConsolidation, PENDING_CONSOLIDATIONS_LIMIT]
    proposer_lookahead: Vector[ValidatorIndex, (MIN_SEED_LOOKAHEAD + 1) * SLOTS_PER_EPOCH]
    # [New in Gloas:EIP7732]
    builders: List[Builder, BUILDER_REGISTRY_LIMIT]
    # [New in Gloas:EIP7732]
    next_withdrawal_builder_index: BuilderIndex
    # [New in Gloas:EIP7732]
    execution_payload_availability: Bitvector[SLOTS_PER_HISTORICAL_ROOT]
    # [New in Gloas:EIP7732]
    builder_pending_payments: Vector[BuilderPendingPayment, 2 * SLOTS_PER_EPOCH]
    # [New in Gloas:EIP7732]
    builder_pending_withdrawals: List[BuilderPendingWithdrawal, BUILDER_PENDING_WITHDRAWALS_LIMIT]
    # [New in Gloas:EIP7732]
    latest_block_hash: Hash32
    # [New in Gloas:EIP7732]
    payload_expected_withdrawals: List[Withdrawal, MAX_WITHDRAWALS_PER_PAYLOAD]
```

The `BeaconState` container is modified with the addition of:

- `builders`, of type `List[Builder, BUILDER_REGISTRY_LIMIT]` to track the new in-protocol staked builders. 
- `next_withdrawal_builder_index` of type `BuilderIndex` to help tracking builder withdrawals.
- `execution_payload_availability`, of type `Bitvector[SLOTS_PER_HISTORICAL_ROOT]` to track the presence of execution payloads on the canonical chain. 
- `builder_pending_payments`, of type `Vector[BuilderPendingPayment, 2 * SLOTS_PER_EPOCH]` to track pending payments from builders to proposers before the execution payload has been processed. 
- `builder_pending_withdrawals`, of type `List[BuilderPendingWithdrawal, BUILDER_PENDING_WITHDRAWALS_LIMIT]` to track pending withdrawals to the execution layer with the builders' payments. 
- `latest_block_hash`, of type `Hash32`, to track the blockhash of the last execution payload in the blockchain. 
- `payload_expected_withdrawals` of type `List[Withdrawal, MAX_WITHDRAWALS_PER_PAYLOAD]` to track the latest withdrawals that were deducted in the consensus layer and need to still be honored in the Execution Layer.

The `BeaconBlockBody` is modified with the addition of:

- `signed_execution_payload_bid` of type `SignedExecutionPayloadBid` with the builder's commitment.
- `payload_attestations` of type `List[PayloadAttestation, MAX_PAYLOAD_ATTESTATIONS]` a list of PTC attestations from the previous slot.

The `ExecutionPayloadHeader` object is changed (and renamed to `ExecutionPayloadBid`) to only track the minimum information needed to commit to a builder's payload.

State transition logic is modified by: 

- A new beacon state getter `get_ptc` returns the PTC members for a given slot. 
- `process_withdrawals` is modified as follows. Withdrawals are obtained directly from the beacon state instead of the execution payload. They are deducted from the beacon chain. The beacon state `latest_withdrawals_root` is updated with the HTR of this list. The next execution payload MUST include withdrawals matching the `state.latest_withdrawals_root`. 
- `process_execution_payload` is removed from `process_block`. Instead a new function `process_execution_payload_bid` is included, this function validates the `SignedExecutionPayloadBid` included in the `BeaconBlockBody`, ensures the payment from the builder's balance can be deducted and adds a `BuilderPendingPayment` object to the beacon state.
- `process_deposit_request` is removed from `process_operations` and deferred until `process_execution_payload`. Special care is added for deposit requests from new validator pubkeys, with withdrawal credentials starting with the prefix `BUILDER_WITHDRAWAL_PREFIX`. These deposits are immediately added to the beacon chain and processed as new builders. 
- `process_withdrawal_request` is removed from `process_operations` and deferred until `process_execution_payload`.
- `process_consolidation_request` is removed from `process_operations` and deferred until `process_execution_payload`. 
- A new `process_payload_attestation` is added to `process_operations`, this function validates the payload timeliness attestations broadcast by the PTC members. 
- `process_execution_payload` is now called as a separate helper when receiving a `SignedExecutionPayloadEnvelope` on the P2P layer. This function in particular checks that the HTR of the resulting beacon state coincides with the committed one in the payload envelope. On sucessful processing of the execution payload, the corresponding `BuilderPendingPayment` is removed from the beacon state and a `BuilderPendingWithdrawal` is queued. 

Epoch processing is modified by addition of a new helper function `process_builder_pending_payments`, that processes the builder pending payments from those payloads that were not included in the canonical chain. 
Although there is no change in the `AttestationData` object, the `index` field which is unused since the Electra fork, is now repurposed to signal payload availability. The value of `0` is used when attesting to the current beacon block or a past beacon block without a payload present, and the value of `1` is used to attest to a past beacon block with a payload present. 

#### Fork-Choice changes

Forkchoice is changed substantially to deal with the fact that forkchoice nodes can have different payload content. 


#### P2P changes

- A new global topic for broadcasting `SignedExecutionPayloadBid` messages (builder bids).
- A new global topic for broadcasting `PayloadAttestationMessage` objects. 
- A new global topic for broadcasting `ProposerPreferences` objects.

### Engine API

No changes needed.

## Rationale

### Staked builders

Being a builder is a new type of entity tracked in the beacon state. As such builders are staked in the beacon chain and they have their own withdrawal credential prefix. This allows for in-protocol trustless enforcement of the builder's payment to the proposer. Alternatively, payment could be enforced in the Execution Layer (EL) at the cost of adding the corresponding EL consensus-changing logic. Payments in the EL have the advantage of not requiring the builder to periodically submit deposit transactions to replenish their validator balance. Both systems require availability of funds before the payload is revealed: in the Consensus Layer (CL) this is done by getting builders to stake. In the EL this is done with a balance check and a payment transaction. This transaction can be checked without executing the payload only if it the first transaction of the block. 

### Delayed validation

The Payload Timeliness Committee members do not need to validate the execution payload before attesting to it. They perform basic checks such as verifying the builder's signature, and the correct blockhash is included. This takes away the full execution payload validation from the hot path of validation of an Ethereum block, giving the next proposer 6 seconds (`SECONDS_PER_SLOT * 2 // INTERVALS_PER_SLOT`) to validate the payload and every other validator 9 seconds (`SECONDS_PER_SLOT * 3 // INTERVALS_PER_SLOT`). From a user UX perspective, a transaction included in slot `N` by the builder is not widely validated until the proposer of slot `N+1` releases their beacon block on top of block `N` first and the attesters of slot `N+1` vote on this beacon block as the head of the chain.


### Fork choice

The following features of fork choice are guaranteed under specified margins of security: 

- Proposer unconditional payment.
- Builder reveal safety.
- Builder withhold safety.

Proposer unconditional payment refers to the following. An Ethereum slot can be either:

- *Full*: both the beacon block and the execution payload have been revealed and included on-chain.
- *Skipped*: No beacon block (and therefore no execution payload) has been included on-chain for this slot. 
- *Empty*: The beacon block has been included on-chain, but the committed execution payload has not. 

Proposer unconditional payment refers to the fact that in the third scenario the beacon block proposer received payment from the corresponding builder.

Builder reveal safety refers to the fact that if the builder acted honestly and revealed a payload in a timely fashion (as attested by the PTC) then the revealed payload will be included on-chain.

Builder withhold safety refers to the fact that if some beacon block containing a builder's commitment is withheld and revealed late, the builder will not be charged the value of the bid. In particular, the payload does not even need to be revealed in this case. 

The precise method by which these safety mechanisms are enforced is by allowing attestations to also signal their view of the slot as in either of the above options *Full*, *Skipped* or *Empty*. For this, the `index` field in the `AttestationData` is used as explained above. 

### PTC equivocations

There is no penalty for PTC nor payload equivocation (that is revealing the right payload and also a withheld message at the same time). A collusion of a builder controlling network partition with a single malicious PTC member could cause a split view by achieving consensus both on payload withheld and a payload present. This could be mitigated by setting `PAYLOAD_TIMELY_THRESHOLD` to be 2/3 of the PTC, in which case the malicious operator would have to control at least 33% of the PTC. 

Another mitigation mechanism is to add new slashing conditions for payload equivocation or PTC equivocations (both are signed messages by validators). 

Since this attack results in a split view at a cost for the builder (the payload is revealed and may not be included) this EIP opted for simplicity of implementation.


### Withdrawals

Withdrawals from the beacon chain are complex in nature, they involve removing funds from one layer and crediting them on another, with different trigger mechanisms that can start from either layer. Before applying the consensus layer state transition function to a given beacon state `pre_state` and processing a given signed beacon block `block`, the set of withdrawals that are expected to be deducted from the beacon chain are completely determined by `pre_state`. Previous to this EIP the set of withdrawals that are credited on the execution layer are included in `block`. The block is deemed invalid if these withdrawals do not match. With the separation included in this EIP, these operations of deducting and crediting become asynchronous:

- When processing the beacon block, the withdrawals are deducted from the beacon chain. 
- The set of withdrawals just deducted is committed to the beacon state `post_state`.  
- When processing any execution payload whose parent beacon state is `post_state`, the payload is deemed invalid if it doesn't include precisely the list of withdrawals committed to `post_state`. 

This asynchronous mechanism has some consequences as slots may be *empty* as defined above. In these cases, the consensus layer does not process any more withdrawals until an execution payload has fulfilled the outstanding ones. An alternative design would be to defer all of withdrawal processing to the execution payload validation phase (ie. `process_execution_payload`). This has the advantage of not needing to track the fulfilled withdrawals on the beacon chain. The logic changes when several payloads are missing, in which case balances on the beacon chain change and therefore a withdrawal that would be possible with the former mechanism may be different, or even impossible with the latter.

### Three state transition functions

The current EIP adds an extra state transition function to the block processing in Ethereum. Processing a `SignedBeaconBlock` changes the consensus layer `BeaconState`. A `SignedExecutionPayloadEnvelope` changes both the execution layer state and the consensus layer one. As such, the envelope commits to the consensus layer post-state-transition beacon state root. 

### Compatible designs 

#### Inclusion lists

This EIP is fully compatible with forkchoice enforced inclusion lists as specified in [EIP-7805](./eip-7805.md) or similar.

#### Slot auctions

A simple change to this EIP is to remove the blockhash commitment from the `SignedExecutionPayloadBid`. This allows the builder to commit any payload to the slot. A preliminary security analysis shows that payload equivocation does not weaken fork choice's FFG. Some advantages of Slot auctions include:

- Better user experience as any submitted transaction can be included in the next block (with block auctions a transaction sent in the first half of the slot can only be included in the following block). 
- Longer continuous time to build blocks. 
- Better compatibility designs with fork choice enforced inclusion list proposals. 


## Backwards Compatibility

This EIP introduces backward incompatible changes to the block validation rule set on the consensus layer and must be accompanied by a hard fork. 

## Security Considerations

### Free option problem 

Economically rational but malicious (as defined by the honest builder guide) builders may chose to withhold their payload in the event that it would be profitable for them. This could result in missed slots and degradation of user experience of Ethereum. Some preliminary data in the form of simulation suggests that the number of these occurrences may be noticeable. Some mitigations were proposed in the form of variable penalties for builders that fail to include their payload envelopes in the canonical chain. 

### Builder safety

- A colluding set of proposers and attesters controlling consecutive blocks and more than 20% of the total stake can reorg a builder's payload and force it to pay the bid's value. 
- There is no possible *unbundling* of the builder's payload in the same slot, that is, if the builder reveals a payload for the head of the chain, no other payload is possible for the current slot. 

### Malicious PTC

The expected time for a malicious attacker, controlling 35% of the total stake, to have a majority control on the PTC is 205 000 years. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
