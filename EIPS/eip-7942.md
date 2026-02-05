---
eip: 7942
title: Available Attestation
description: A reorg-resilient solution for Ethereum
author: Mingfei Zhang (@Mart1i1n) <mingfei.zh@outlook.com>, Rujia Li <rujia@tsinghua.edu.cn>, Xueqian Lu <xueqian.lu@bitheart.org>, Sisi Duan <duansisi@tsinghua.edu.cn>
discussions-to: https://ethereum-magicians.org/t/eip-7942-available-attestation-a-reorg-resilient-solution-for-ethereum/23927
status: Draft
type: Standards Track
category: Core
created: 2025-04-30
---

## Abstract

This EIP proposes Available Attestation (AA), a protocol enhancement to make Ethereum PoS resilient against reorganization attacks. The proposal introduces a stability criterion for blocks based on attestation quorums, requiring that a block must include at least one-third of validators' attestations from the previous slot to be considered stable. The proposal includes three main changes: (1) modifying the parent selection rule to require AA from the previous slot, (2) replacing HLMD-GHOST with a Longest Stable Chain fork choice rule, and (3) adding a reference field to recent unstable blocks to preserve transaction continuity. These changes collectively prevent Byzantine validators from successfully executing reorganization attacks in synchronous networks while maintaining safety and liveness properties in partially synchronous networks. A full technical analysis is available in our [companion paper](../assets/eip-7942/available-attestation-paper.pdf) accepted to USENIX Security 2025.

## Motivation

We find that all known effective attacks on Ethereum PoS belong to reorganization attacks, although they emphasize different types of adversarial strategies. According to how the canonical chain is manipulated by the adversary, we classify known attacks into two categories: attacks from *changing block weight* and attacks from *filtering block tree*. The attacks from changing block weight refer to the strategy where Byzantine validators modify the *weight* of their proposed blocks to make their fork eventually become the canonical chain. Meanwhile, the attacks from filtering block tree do not change the block weight. Instead, these attacks make honest validators prune the canonical chain. This is often achieved by changing the *state* of honest validators. We summarize these malicious reorganization attacks in the following table.

| **attack type**         | **scheme**                                                     | **timing assumption**  | **mitigation solution**             | **limitation**                |
|-------------------------|----------------------------------------------------------------|------------------------|-------------------------------------|-------------------------------|
| changing block weight   | ex-ante reorg                                     | synchrony              | proposer boosting v1           | cause sandwich reorg          |
|                         | balancing attack                                  | synchrony              | proposer boosting v1          | cause sandwich reorg          |
|                         | sandwich reorg                                    | synchrony              | proposer boosting v2⋆         | cannot fully prevent          |
| filtering block tree    | bouncing attack                                   | partial synchrony†     | safe-slots                    | cannot fully prevent          |
|                         | unrealized justification reorg                    | synchrony              | Capella upgrade                | cause staircase attack        |
|                         | justification withholding reorg                   | synchrony              | Capella upgrade                | cause staircase attack        |
|                         | staircase attack                                  | synchrony              | Deneb upgrade                   | cannot fully prevent          |

⋆ Proposer boosting parameter decreases from 0.7 to 0.4.  
† The attack is conducted after the network is synchronous.

In response to these vulnerabilities, mitigation approaches have been proposed from both academia and industry. They are often designed in an ad-hoc way, addressing one issue at a time. Without formal proof, these mitigation approaches may create new issues. For instance, to mitigate the ex-ante reorg attack and balancing attack, Ethereum implements the *proposer boosting* mechanism. By temporarily adjusting the weight of the block in the current slot, the forks created by the adversary will not become the canonical chain. However, this mitigation approach introduces new issues. A so-called *sandwich reorg attack* was later proposed, exploiting proposer boosting to create a reorg attack. The sandwich reorg attack is a variant of ex-ante reorg attacks where two Byzantine proposers collude to make the blocks by honest validators orphaned. Additionally, many known mitigation solutions lack formal analysis or introduce additional assumptions, e.g., by assuming that the ratio of stake controlled by the adversary is no more than 20%. Therefore, our approach aims to provide a provably secure and efficient solution that is resilient to reorg attacks in Ethereum PoS.

## Specification

### Overview

We provide a lightweight yet efficient solution for Ethereum PoS which is:

1) reorg resilient in a synchronous network; 
2) safe and live in a partially synchronous network;
3) easy to implement and deploy.

We introduce AA, an approach inspired by conventional BFT protocols from *weak quorum* of attestations. Namely, consider a system with $N$ validators, among which at most $f$ are faulty. If $f+1$ validators vote for a block $b$ in slot $t$, at least one honest validator has validated $b$. The $f+1$ attestations become a *proof* of the availability of $b$. We use $AA_t$ to denote a block with $f+1$ attestations in slot $t$. 

Putting the concept of weak quorums in the context of Ethereum PoS, we define AA as a mechanism that checks *whether a block includes matching attestations from at least one-third of validators* (For simplicity, we assume that all validators attest in every slot in this section). In particular, if $b$ is a block for slot $t$, its child must include attestations for $b$ from at least one-third of validators in slot $t$. We use the notion of *stable block* to describe this scenario.

### Definition

Formally, we give the following definitions for AA:

- (AA) We use $AA_t$ to denote a block that receives more than one-third of attestations voting for it in slot $t$.

- (Stable block) *A block $b$ proposed in slot $t$ is a stable block if the parent of block $b$ is $AA_{t-1}$*

- (Unstable block) *Block $b$ is an unstable block if $b$ is not a stable block.*

- (Stable chain) *The chain $c$ is a stable chain if the leaf block of $c$ is a stable block.*

In practice, the validators are divided into 32 disjoint committees randomly. Since the committees are sampled pseudorandomly, the number of Byzantine validators in each committee can be approximated by a binomial distribution. We use $f$ as the number of total Byzantine validators and $f'$ as the expected number of Byzantine validators in each committee.

- We use $\vartheta$ to denote a threshold on the number of Byzantine validators in each committee and $p$ as the desirable failure probability (i.e., the probability that the number of Byzantine validators in a committee is greater than $\vartheta$).

Given the desired value $p$, the value of $\vartheta$ can be calculated using $\vartheta = \lfloor\mu + \sigma \cdot \Phi^{-1}(1 - p)\rfloor,$ where $\mu = f'$, $\sigma^2 = f'(1 - f/n)$, and $\Phi^{-1}$ is the inverse of the cumulative distribution function of the normal distribution. We show some concrete examples of the ratio of Byzantine validators in a committee.

|  n     \ p   | 10⁻⁶  | 10⁻⁷  | 10⁻⁸  | 10⁻⁹  |
|-------------|--------|--------|--------|--------|
| 2¹⁴         | 0.4316 | 0.4414 | 0.4492 | 0.4570 |
| 2¹⁶         | 0.3828 | 0.3872 | 0.3916 | 0.3955 |
| 2¹⁸         | 0.3580 | 0.3603 | 0.3625 | 0.3645 |
| 2²⁰         | 0.3457 | 0.3468 | 0.3479 | 0.3489 |

Ethereum now has approximately $2^{20}$ validators. The maximum desirable probability $10^{-6}$ means that the protocol fails once every $10^{6}$ slots, i.e., 138 days. If the desirable failure probability is $10^{-9}$, malicious reorganization occurs once every 380 years. We can then draw the following conclusion: 

**For a large $n$, the ratio of Byzantine validators is closer to $f/n$. In this way, we can simply set $\vartheta$ as one-third of the committee size.**

### Protocol Changes

We make four main changes:

1. **Modify the selection rule of parent.** As mentioned in the overview, we require that a block $b$ in slot $t$ must include $\vartheta+1$ attestations to prove that the parent of block $b$ is a valid output in slot $t-1$. Therefore, the parent of block $b$ is the $AA_{t-1}$. Such a block is a stable block. If no $AA_{t-1}$ exists, the parent of block $b$ is the output of the fork choice rule. Such a block is an unstable block.

2. **Replace HLMD-GHOST with Longest Stable Chain fork choice rule.** We replace the HLMD GHOST with the longest chain as the fork choice rule. Our longest chain fork choice rule is very simple: it outputs the head of the chain with the most stable blocks. In case of a tie, the longest chain fork choice rule chooses the chain such that the leaf block has the largest slot number.

3. **Blocks carry a reference `unstable_root` to recent unstable blocks to preserve transaction continuity.** We additionally include a field `unstable_root` in a block b. Each proposer sets its `unstable_root` field as the hash of an unstable block. If there is no such unstable block, set `unstable_root` as None. The transactions in the unstable blocks should not conflict with the transactions in the longest chain. The transactions in `unstable_root` can also be finalized once block b (that includes `unstable_root`) is finalized.

4. **Simplify the filtering rule and the justification process.** We simplify the filtering rule as it only considers the chain that justifies the last justified checkpoint. Additionally, the justification process only updates when a chain crosses the epoch boundary.

### Pseudocode

The modifications are based on validator and fork-choice.

#### Modification 1

For the validator behavior specification (validator in consensus-specs):

To propose, the validator selects a `BeaconBlock`, `parent` using this process:

1. Compute AA blocks at the start of slot. Let `aa` be the later AA block and `aa_root` be the root of `aa`.
Set `parent_root = aa_root`.
2. If no AA block exists, compute fork choice's view of the head at the start of `slot`, after running
   `on_tick` and applying any queued attestations from `slot - 1`. Set `parent_root = get_head(store)`.
3. Let `parent` be the block with `parent_root`.

#### Modification 2

For the fork choice specification (fork_choice in consensus-specs):

Add a class called `chain` to manage the stable chains.

```python
@dataclass
class Chain(object):
    leaf: Root
    length: uint64
    justified_checkpoint: Checkpoint
```

Add chains in `store`.

```python
@dataclass
class Store(object):
    ...
    chains: Set[Chain]
```

Modify `get_head`

```python
def get_head(store: Store) -> Root:
    # Get filtered block tree that only includes viable branches
    chains = get_filtered_block_tree(store)
    # Execute the longest stable chain fork choice
    return max(chains, key=lambda c: c.length).leaf
```

#### Modification 3

For the validator behavior specification (validator in consensus-specs):

Modify `Preparing for a BeaconBlock`

To construct a `BeaconBlockBody`, a `block` (`BeaconBlock`) is defined with the necessary context for a block proposal:

##### unstable_root

Set `block.unstable_root` as the hash of the latest unstable block if such block exists. If none exists, set `block.unstable_root = None`. The transactions in `unstable_root` must not conflict with the stable chain and will be finalized once `block` is finalized.

#### Modification 4

For the fork choice specification (fork_choice in consensus-specs):

Modify `get_filtered_block_tree`. Only consider the chain that justifies the latest justified checkpoint.

```python
def get_filtered_block_tree(store: Store) -> List[Chain]:
    chains = []
    for chain in store.chains:
        if is_equal(store.justified_checkpoint.root, chain.justified_checkpoint.root):
            chains.append(chain)
    return chains
```

Remove the fields `unrealized_justified_checkpoint` and `unrealized_finalized_checkpoint`. Remove `compute_pulled_up_tip`, i.e., remove the justification and finalization process that occurs during an epoch. The `justified_checkpoint` field of a chain is only updated when crossing an epoch boundary.

## Rationale

The reason why our approach is reorg resilient is that the AA mechanism *prevents* Byzantine validators from creating conflicting branches. As summarized in the table, there are two strategies for Byzantine validators: (1) Byzantine validators directly propose a block conflicting with the canonical chain and (2) Byzantine validators propose a block that extends the canonical chain and delay releasing the block. Neither of these strategies works anymore after AA is implemented. For the first type, only the leaf blocks in the block tree can be the output of the fork choice rule. If a Byzantine validator tries to create a block $b_1$ that extends a block $b_0$ that is not a leaf block, $b_0$ will receive no attestations from honest validators. Thus, block $b_1$ is an unstable block. For the second type, our approach ensures that if Byzantine validators withhold at least two stable blocks, one of them must have already been observed by *all* honest validators (see Lemma 2 in our paper for details). 

Now it becomes clear why we use the *longest chain* rule to replace the HLMD-GHOST rule. Informally, as the HLMD-GHOST rule determines the canonical chain based on the weight of the blocks, and the weight is determined by the number of attestations, the HLMD-GHOST rule cannot prevent adversaries from withholding their attestations. 

Our modified protocol can achieve the safety and liveness properties of the consensus protocol. Safety still holds since we do not modify Casper, the finality gadget protocol. Liveness is achieved after GST mainly because our protocol is reorg resilient in a synchronous network. As all honest validators consider the blocks proposed by honest validators to be part of the longest chain, their attestations will be considered valid by all honest validators, so eventually some block is finalized. 

## Backwards Compatibility

The proposal modifies the fork choice logic and attestation format, which may not be compatible with existing clients. A hard fork or protocol version flag will be required for deployment.

## Security Considerations

- **Resilience to reorg attacks**: The protocol is provably resilient to all known forms of reorg attacks in synchronous networks.
- **No new attack surfaces**: The protocol avoids introducing new message types or unnecessary overhead.
- **Safe and live**: Maintains standard safety and liveness in partially synchronous networks.

A full formal proof of correctness and evaluation over 16,384 validators is provided in the [companion paper](../assets/eip-7942/available-attestation-paper.pdf).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
