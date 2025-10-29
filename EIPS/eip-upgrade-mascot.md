---
eip: [to-be-assigned]
title: Upgrade Mascots
description: Process for assigning a mascot to each Ethereum network upgrade
author: Jordan Holberg (@eviljordan), Andrew B Coathup (@abcoathup)
discussions-to: https://ethereum-magicians.org/
status: Draft
type: Meta
created: 2024-10-29
requires: 
---

## Abstract

This Meta EIP establishes a standardized process for assigning a mascot to each Ethereum network upgrade. Mascots serve to humanize and celebrate upgrades, fostering community engagement while adhering to principles of cuteness, relevance, and inclusivity. The mascot is selected by a designated facilitator (the "Mascot Wrestler") through community-driven processes, with safeguards for appropriateness.

## Motivation

Ethereum network upgrades often introduce complex technical changes that can feel abstract to the broader community. Mascots provide a fun, memorable, and relatable symbol for each upgrade, drawing inspiration from its headliner(s). By mandating emoji-representable mascots that are cute and non-offensive, this process:

- Enhances community participation and excitement around network upgrades.
- Creates opportunities for creative expression in upgrade event branding, merchandise, and digital collectibles (e.g., POAPs).
- Builds a consistent, whimsical tradition that differentiates Ethereum's upgrade narrative from other ecosystems.

Without a formalized process, mascot selection risks inconsistency or neglect, diminishing their potential impact.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### 1. Mascot Requirements
- **Relevance**: The mascot **SHOULD** relate thematically to the network upgrade's headliner(s).
- **Representation**: The mascot **MUST** be expressible using one or more standard Unicode emojis (e.g., :panda: for the Merge).
- **Form**: The mascot **SHOULD** depict an animal (real, mythical, or stylized, but always animal-adjacent).
- **Tone**: The mascot **MUST NOT** be offensive (no depictions of violence, discrimination, or controversy) and **SHOULD** be inherently cute (e.g., avoiding aggressive or fearsome traits unless softened for adorability).

### 2. Roles and Responsibilities
- **Mascot Wrestler**: A self-selected community facilitator responsible for proposing, selecting, and adopting the mascot for a network upgrade. The Mascot Wrestler self-nominates. The role **MAY** rotate voluntarily per upgrade cycle to encourage diverse participation.
  - Duties include:
    - Soliciting and curating mascot candidates.
    - Facilitating selection processes.
    - Announcing the final mascot (e.g., Ethereum Magicians, All Core Devs).
- **Veto Powers**:
  - The Mascot Wrestler *MAY** veto any candidate mascot deemed inappropriate based on the requirements above.
  - A rough consensus of client teams **MAY** veto the selected mascot, triggering fallback to the next-highest-ranked candidate mascot.

### 3. Selection Process
The Mascot Wrestler shall conduct selection using one or more community-appropriate mechanisms, aiming for inclusivity and transparency:
- **Public Signaling Polls**: On platforms like Ethereum Magicians Forum, Forkcast, or social media.
- **OnChain Voting**
- **Prediction Markets**: where market resolution determines the winner.
- **Other Mechanisms**: Any fair, auditable process that allows broad participation.

The process **MUST**:
- Run for a minimum of 7 days.
- Present at least 2 candidates.
- Rank finalists by popularity.
- Document results publicly.

If no consensus is reached, the Mascot Wrestler selects the top candidate by default, subject to veto.

### 4. Usage Guidelines
Adopted upgrade mascots **MAY** be used to celebrate the upgrade in:
- **Logs and Announcements**: ASCII art in client logs, devnet announcements, and release notes.
- **Events and Collectibles**: POAPs, conference swag, or virtual badges featuring the mascot.
- **Merchandise**: community-created items (e.g., stickers, t-shirts), with attribution to the Mascot Wrestler and community contributors.
- **Branding**: Integration into upgrade roadmaps, blog posts, and social media campaigns.

All uses must respect the network upgrade mascot's cute, non-offensive nature and credit original concept creators where applicable.

## Rationale

This specification balances creativity with guardrails to prevent mascot drift (e.g., unrelated or edgy choices). Emoji-based representation ensures accessibility across digital platforms, while the animal/cute mandate aligns with Ethereum's community ethos of approachability. The self-selected Mascot Wrestler role decentralizes coordination, leveraging vetoes for accountability. Selection flexibility accommodates Ethereum's decentralized governance evolution.

Alternatives considered:
- Fully onchain mandates: Too rigid for creative processes.
- No formal process: Risks ad-hoc or absent mascots.
- Non-animal options: Animals evoke universality and whimsy.

## Backwards Compatibility

This EIP does not directly change the Ethereum protocol. It formalizes part of the current network upgrade process.  Past upgrades (e.g., Shapella's owl :owl:, Dencun's blowfish :blowfish:) are retroactively honored if they fit the criteria; future upgrades **MUST** comply starting with the next hard fork post-adoption.


## Security Considerations

None

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).