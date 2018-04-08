---
eip: X
title: Hybrid Casper FFG
status: Draft
type: Standards Track
category: Core
author: Danny Ryan <danny@ethereum.org>, Chih-Cheng Liang <cc@ethereum.org>
created: 2018-04-05
---

## Abstract

This EIP describes the specification for implementating and hard-forking the Ethereum network to support hybrid Proof of Work (PoW)/Proof of Stake (PoS) via Casper the Friendly Finality Gadget (FFG). In this hybrid model, existing PoW mechanics are used as the block proposal mechanism while PoS is layered on top providing economic finality through a modified forkchoice rule. Because network security is partially shifted from PoW to PoS, PoW block reward is reduced.

This EIP does not provide safety or liveness proofs. See the [Casper FFG](https://arxiv.org/abs/1710.09437) paper for a more detailed formal discussion.

This EIP does not provide validator implementation details. See the [Casper Implementation Guide](https://github.com/ethereum/casper/blob/master/IMPLEMENTATION.md) for validator details.

## Motivation

Transitioning the Ethereum network from PoW to PoS has been on the roadmap and in the [Yellow Paper](https://github.com/ethereum/yellowpaper) since the launch of the protocol. Although effective in coming to a decentralized consensus, PoW consumes an incredible amount of energy. Bitcoin's energy consumption alone is currently estimated to be about as much as the entire country of Columbia, and Ethereum's is estimated at about that of Cuba's ([Bitcoin Energy Index](https://digiconomist.net/bitcoin-energy-consumption), [Ethereum Energy Index](https://digiconomist.net/ethereum-energy-consumption)). Excessive energy consumption, issues with equal access to mining hardware, and an emerging market of ASICs each provide a distinct motivation to make the transition as soon as possible.

Until recently, the proper way to make this transition was still an open area of research. In October of 2017 [Casper the Friendly Finality Gadget](https://arxiv.org/abs/1710.09437) was published, solving open questions of providing economic finality and punishing bad attackers validating across multiple forks. Through the FFG contract, validators post a deposit in ether and finalize "checkpoints" providing consensus on points in the chain that will never be reverted. If a validator is caught signing messages that could result in the finalization of conflicting checkpoints, proof of these messages can be submit to the FFG contract, and the validator's deposit is "slashed" or burned. This slashing mechanism provides "accountable safety". For a detailed discussion and proofs of "accountable safety" and "plausible liveness", please see the [Casper FFG](https://arxiv.org/abs/1710.09437) paper.

The FFG contract can be layered on top of any block proposal mechanism, providing finality to the underlying chain. This EIP proposes layering FFG on top of the existing PoW block proposal mechanism as a conservative step-wise approach in the transition to full PoS. The new FFG staking mechanism requires minimal changes to the protocol, allowing us to fully test and vet FFG on PoW before moving to a validator based block proposal mechanism.

## Parameters

* `HYBRID_CASPER_FORK_BLKNUM`: TBD
* `CASPER_ADDR`: TBD
* `CASPER_CODE`: see below
* `CASPER_BALANCE`: 5e24 (5_000_000 eth)
* `SIGHASHER_ADDR`: TBD
* `SIGHASHER_CODE`: see below
* `PURITY_CHECKER_ADDR`: TBD
* `PURITY_CHECKER_CODE`: see below
* `NULL_SENDER`: `2**160 - 1`
* `NEW_BLOCK_REWARD`: 6e17 wei (0.6 ETH)
* `NON_REVERT_MIN_DEPOSIT`: amount in wei decided by client

### Casper Contract Parameters

* `EPOCH_LENGTH`: 50 blocks
* `WITHDRAWAL_DELAY`: 15000 epochs
* `DYNASTY_LOGOUT_DELAY`: 700 dynasties
* `SIGHASH_ADDR`: TBD
* `PURITY_CHECKER_ADDR`: TBD
* `BASE_INTEREST_FACTOR`: TBD
* `BASE_PENALTY_FACTOR`: TBD
* `MIN_DEPOSIT_SIZE`: 1000e18 wei (1000 ETH)

## Specification

### Deploying Casper Contract

If `block.number == HYBRID_CASPER_FORK_BLKNUM`, then when processing the block, before processing any transactions:

* set the code of `SIGHASHER_ADDR` to `SIGHASHER_CODE`
* set the code of `PURITY_CHECKER_ADDR` to `PURITY_CHECKER_CODE`
* set the code of `CASPER_ADDR` to `CASPER_CODE`
* set balance of `CASPER_ADDR` to `CASPER_BALANCE` for issuance

### Initialize Epochs

If `block.number >= HYBRID_CASPER_FORK_BLKNUM and block.number % EPOCH_LENGTH == 0`, then execute a call with the following parameters at the start of the block:

* `SENDER`: NULL_SENDER
* `GAS`: 3141592
* `TO`: CASPER_ADDR
* `VALUE`: 0
* `DATA`: <encoded call casper_translator.encode('initialize_epoch', [floor(block.number / EPOCH_LENGTH)])>

This transaction utilizes no gas.

### Casper Votes

If `block.number >= HYBRID_CASPER_FORK_BLKNUM`, then:

* all successful `vote` transactions to `CASPER_ADDR` with sender as `NULL_SENDER` must be included at the end of the block
* all successful `vote` transactions to `CASPER_ADDR` with sender as `NULL_SENDER` utilize no gas
* all unsuccessful `vote` transactions to `CASPER_ADDR` are considered invalid and are not to be included in the block

### Fork Choice

If `block.number >= HYBRID_CASPER_FORK_BLKNUM`, the fork choice rule is the following:
1. Start with last finalized checkpoint
2. From that finalized checkpoint, select the casper checkpoint with the highest justified epoch: `casper.last_justified_epoch()`
3. Starting from that justified epoch, choose the block with the highest PoW score as the new head

A client considers a checkpoint finalized if the following hold true:

* During an epoch, the previous epoch is finalized within the casper contract -- `casper.last_finalized_epoch() == casper.get_current_epoch() - 1`
* The current dynasty deposits _during the proposed finalized epoch_ were greater than `NON_REVERT_MIN_DEPOSIT` -- `casper_during_finalized_epoch.total_curdyn_deposits_scaled() > NON_REVERT_MIN_DEPOSIT`
* The previous dynasty deposits _during the proposed finalized epoch_ were greater than `NON_REVERT_MIN_DEPOSIT` -- `casper_during_finalized_epoch.total_prevdyn_deposits_scaled() > NON_REVERT_MIN_DEPOSIT`


### Block Reward

If `block.number >= HYBRID_CASPER_FORK_BLKNUM`, then `block_reward = NEW_BLOCK_REWARD` and utilize the same formulas for uncle and nephew rewards but with the updated `block_reward`.

### Validators

The mechanics and responsibilities of validators are not specified in this EIP because they rely upon network transactions to the contract at `CASPER_ADDR` rather than on protocol level implementation and changes.
See the [Casper Implementation Guide](https://github.com/ethereum/casper/blob/master/IMPLEMENTATION.md) for validator details.

### SIGHASHER_CODE

The source code for `SIGHASHER_CODE` is located [here](https://github.com/ethereum/casper/blob/master/casper/validation_codes/verify_hash_ladder_sig.se).

The EVM init code is:
```
0x
```

The EVM bytecode that the contract should be set to is:
```
0x
```

### PURITY_CHECKER_CODE

The source code for `PURITY_CHECKER_CODE` is located [here](https://github.com/ethereum/research/blob/master/impurity/check_for_impurity.se).

The EVM init code is:
```
0x
```

The EVM bytecode that the contract should be set to is:
```
0x
```

### CASPER_CODE

The source code for `CASPER_CODE` is located at
[here](https://github.com/ethereum/casper/blob/master/casper/contracts/simple_casper.v.py).

The EVM init code with the above specified params is:
```
0x
```

The EVM bytecode that the contract should be set to is:
```
0x
```
