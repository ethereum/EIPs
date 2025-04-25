EIP: <to be assigned>
Title: Available Attestation: A Reorg-Resilient Fork Choice Rule for Ethereum
Author: Mingfei Zhang <mingfei.zh@outlook.com>, Rujia Li <rujia@tsinghua.edu.cn>, Xueqian Lu <xueqian.lu@bitheart.org>, Sisi Duan <duansisi@tsinghua.edu.cn>
Status: Draft
Type: Core
Category: Consensus
Created: 2025-03-25

---

## Abstract

We propose a modification to Ethereum's fork choice rule called Available Attestation (AA) that is provably resilient to malicious reorganization attacks (reorgs) during periods of network synchrony. Our approach introduces a stable block rule based on weak quorum certificates and replaces the HLMD-GHOST fork choice with a longest stable chain rule. AA is compatible with Ethereum's partially synchronous model, retains safety and liveness properties, and incurs minimal performance overhead. Our proposal is motivated by extensive analysis and real-world implementation validated in a USENIX Security 2025 publication.

---

## Motivation

Ethereum's transition to Proof-of-Stake (PoS) introduced a new class of attacks known as malicious reorganization attacks. These attacks, where Byzantine validators strategically delay or withhold blocks and attestations, manipulate fork choice to discard honest blocks, gain unfair rewards, or degrade protocol liveness.

Despite several ad-hoc mitigations (e.g., proposer boosting, Capella/Deneb upgrades), existing solutions are either insufficient, introduce new vulnerabilities (e.g., sandwich/staircase attacks), or rely on unproven assumptions.

We propose a principled, formally verified mechanism that ensures reorg resilience under synchrony, addressing both block weight and filtering attacks systematically.

---

## Specification

We define a new rule for fork choice based on **stable blocks**. A block is considered *stable* if it includes attestations for its parent block from at least one-third of validators in the previous slot. The fork choice is modified to:

- Only consider chains composed of consecutive stable blocks.
- Among those, choose the longest chain (by number of stable blocks).
- Break ties by selecting the chain whose latest block has the highest slot number.

### Protocol Changes

- Replace HLMD-GHOST with Longest Stable Chain fork choice rule.
- Modify attestation rules to include forwarding info of proposed blocks.
- Proposers must reference a recent stable block as parent if available.
- Blocks carry a reference (`u`) to recent unstable blocks to preserve transaction continuity.

### Notation

- A block `b` proposed in slot `t` is **stable** if it includes ≥ 1/3 attestations for its parent block in slot `t-1`.
- A chain is **stable** if its leaf block is stable.
- `AA_t` is formed if a block in slot `t` meets the stability condition.

---

## Rationale

The proposed AA mechanism is inspired by weak quorum certificates in BFT protocols, ensuring that once a stable block is proposed by an honest validator, all subsequent stable blocks must build upon it.

We use one-third as the threshold as it is the minimum needed to ensure at least one honest validator's vote is included. The longest stable chain rule makes reorgs by delaying or withholding attacks impossible in synchronous periods.

---

## Backwards Compatibility

The proposal modifies the fork choice logic and attestation format, which may not be compatible with existing clients. A hard fork or protocol version flag will be required for deployment.

---

## Reference Implementation

Available at: [https://zenodo.org/records/14760370](https://zenodo.org/records/14760370)

Implementation based on Prysm v5.0 with minimal code modifications (~1,000 LOC).

---

## Security Considerations

- **Resilience to reorg attacks**: The protocol is provably resilient to all known forms of reorg attacks in synchronous networks.
- **No new attack surfaces**: The protocol avoids introducing new message types or unnecessary overhead.
- **Safe and live**: Maintains standard safety and liveness in partially synchronous networks.

A full formal proof of correctness and evaluation over 16,384 validators is provided in the companion paper accepted to USENIX Security 2025.

---

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

