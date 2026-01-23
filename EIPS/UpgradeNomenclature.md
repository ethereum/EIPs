---
eip: TBA
title: Upgrade Nomenclature
description: Canonical reference for Ethereum network upgrade naming conventions
author: Pooja Ranjan (@poojaranjan)
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-upgrade-nomenclature/27575
status: Draft
type: Informational
created: 2026-01-23
---

## Abstract

This EIP documents the naming conventions used for Ethereum network upgrades across the Execution Layer, Consensus Layer, post-Merge combined upgrades, and Blob-Parameter-Only upgrades. It provides a canonical reference for how upgrade names have evolved to improve clarity, consistency, and shared understanding across the ecosystem.

## Motivation

Ethereum has undergone multiple major network upgrades, including the transition from Proof of Work to Proof of Stake. Each upgrade has been assigned a distinct and meaningful name, and after the initial upgrades, consistent naming patterns emerged and continue to be followed.

As upgrades now occur more frequently and span multiple protocol layers, it can become difficult to consistently interpret upgrade names and their relationships. This EIP documents existing naming conventions to provide a canonical reference for Ethereum upgrade nomenclature, improving clarity, reducing ambiguity, and supporting consistent communication and coordination across the ecosystem without constraining future naming decisions.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

Ethereum upgrade naming conventions have evolved alongside protocol architecture, governance maturity, and coordination practices. Early upgrades followed planned development phases (**Frontier**, **Homestead**, **Metropolis**, and **Serenity**), reflecting milestones toward a stable, production-ready network. After the Merge, naming conventions began reflecting the separation between the Execution Layer (EL) and Consensus Layer (CL).

This section documents the observed evolution of upgrade naming conventions.

### Early Upgrade Naming

Early Ethereum upgrades used names that reflected the experimental state of the network, major milestones, or thematic concepts associated with shipped functionality.

Observed upgrades include:

* **Frontier (Genesis)**: Named to convey Ethereum’s initial launch as a raw and experimental “frontier” environment for developers, while Genesis references the creation of the Genesis Block (Block #0), which established the initial network state and Ether distribution.
* **Frontier Thawing**: Named to reflect the lifting of the initial 5,000 gas block limit that had effectively “frozen” transaction activity after launch. The “thawing” phase enabled miners to establish operations and early users to onboard without time pressure, allowing the network to begin processing live transactions.
* **[Homestead](https://eips.ethereum.org/EIPS/eip-606)**: Named to signify Ethereum’s transition from the experimental "Frontier" phase into a more stable and production-ready network, marking the first release considered suitable for broader usage rather than beta experimentation.
* **[DAO Fork (DAO Wars - aborted)](https://eips.ethereum.org/EIPS/eip-779)**:  Named after The DAO incident and the intense community debate that followed the exploit. The terminology reflects the highly contested governance process and the emergency nature of the intervention and resulting chain split.
* **[Tangerine Whistle](https://eips.ethereum.org/EIPS/eip-608)**: Named to emphasize its urgent, emergency character, analogous to a warning whistle. This was an unplanned fork implementing [EIP-150](https://eips.ethereum.org/EIPS/eip-150) to reprice several opcodes and mitigate active denial-of-service attacks.
* **[Spurious Dragon](https://eips.ethereum.org/EIPS/eip-607)**: Named to reflect its primary objective of removing millions of “spurious” (empty or fake) accounts created during denial-of-service attacks that bloated Ethereum’s state. The “Dragon” element followed the informal tradition of creative or mythical naming during this period.

These names reflect the exploratory nature of early protocol development.

### Historic City Naming

During the Metropolis development phase, upgrades adopted names based on historically connected cities to provide consistency and symbolic continuity. The naming reflected Ethereum’s transition toward a more mature, user-friendly platform.

Observed upgrades include:

* **[Byzantium](https://eips.ethereum.org/EIPS/eip-609)**: The first upgrade in the Metropolis city-themed sequence, named after the ancient Greek city of "Byzantium", marks the “alpha” phase of that roadmap. It introduced major protocol improvements, including zk-SNARK precompiles enabling privacy-oriented cryptography, economic changes such as reduced block rewards and a delayed difficulty bomb, and new opcodes that improved smart contract security and efficiency.
* **[Constantinople](https://eips.ethereum.org/EIPS/eip-1013)**: Named after "Constantinople", the city that succeeded Byzantium as the capital of the Roman/Byzantine Empire, to signal the second phase of the Metropolis city-themed sequence and a maturation step for the protocol. The upgrade focused on maintenance and efficiency improvements while preparing for Proof-of-Stake, including delaying the difficulty bomb and reducing block rewards.
* **[St. Petersburg](https://eips.ethereum.org/EIPS/eip-1716)**: Named after the Russian city of Saint Petersburg to align with the city-themed naming convention of the Metropolis development phase. Saint Petersburg is notable for its dual identity as a grand cultural capital with imperial architecture. The Constantinople and St. Petersburg upgrades were activated at the same block height on mainnet, effectively functioning as a single combined upgrade, with St. Petersburg ensuring the removal of [EIP-1283](https://eips.ethereum.org/EIPS/eip-1283).
* **[Istanbul](https://eips.ethereum.org/EIPS/eip-1679)**: Named after the modern name of the same city, completing the historical progression Byzantium → Constantinople → Istanbul. The name symbolizes the final stage of the Metropolis city-themed sequence and serves as the logical conclusion of the three-part naming convention.

This convention standardized naming during frequent upgrade cycles.

### Ice Age / Difficulty Bomb Naming

Upgrades primarily targeting the Difficulty Bomb adopted glacier-themed naming to reflect mining difficulty progression.

Observed upgrades include:

* **[Muir Glacier](https://eips.ethereum.org/EIPS/eip-2387)**: Named after the rapidly retreating Alaskan glacier to symbolize an urgent, temporary response to slow Ethereum’s “Ice Age” (difficulty bomb). This emergency hard fork introduced a single change with [EIP-2387](https://eips.ethereum.org/EIPS/eip-2387) to delay the difficulty bomb, buying developers time for a longer-term transition toward Proof-of-Stake.
* **[Arrow Glacier](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/arrow-glacier.md)**: Named to continue the “Glacier” convention for Ice Age–related upgrades, reflecting a targeted and directional delay of Ethereum’s difficulty bomb with [EIP-4345](https://eips.ethereum.org/EIPS/eip-4345). The name conveys a temporary extension that slows the rise in mining difficulty—analogous to a glacier’s gradual movement—buying developers additional time to prepare for the Proof-of-Stake Merge rather than serving as a permanent solution.
* **[Gray Glacier](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/gray-glacier.md)**: Named to reflect a large, slow-moving push to delay the Difficulty Bomb with [EIP-5133](https://eips.ethereum.org/EIPS/eip-5133), buying critical time ahead of the transition to Proof-of-Stake. The real "Gray Glacier" merges into another glacier, symbolizing Ethereum’s imminent merge of the Execution Layer with the Beacon Chain. This upgrade represented the final major Difficulty Bomb delay prior to the Merge.

These names signaled functional scope rather than feature expansion.

### Execution Layer Upgrade Naming

Execution Layer upgrades MUST be named after the host city of a Devcon or Devconnect conference. The convention originated with Devcon host cities and later expanded to include Devconnect host cities.

One exception applies: the Merge included **Paris** as a reference to EthCC to commemorate the first biggest Ethereum Community Conference.

Observed examples include:

- **[Berlin](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/berlin.md)** - Devcon 0  
- **[London](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/london.md)** - Devcon 1  
- **[Paris](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/paris.md)** - EthCC  
- **[Shanghai](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/shanghai.md)** - Devcon 2  
- **Cancún** - Devcon 3  
- **Prague** - Devcon 4  
- **Osaka** - Devcon 5  
- **Amsterdam** - Devconnect 1  
- **Bogotá** - Devcon 6  

Future Execution Layer upgrade names SHOULD continue referencing Devcon or Devconnect host cities.

Additional past and future event host cities include, but are not limited to, *Bangkok and Mumbai*.

This convention provides geographic neutrality, cultural diversity, and predictable sequencing for roadmap planning and external communication.

### Consensus Layer Upgrade Naming

Following the Serenity roadmap phase and the launch of the Beacon Chain, Consensus Layer network upgrades adopt a naming convention based on star names in alphabetical order.

Consensus Layer (formerly Eth2 / Beacon Chain) upgrades MUST be named after stars, with each upgrade name advancing alphabetically by first letter.

Each selected name MUST correspond to an officially recognized star name. This convention was established through open community coordination to provide a consistent, neutral, and globally recognizable naming scheme.

The sequence begins with **[Altair](https://github.com/ethereum/consensus-specs/tree/master/specs/altair)**, activated in October 2021 as the first Consensus Layer upgrade, which established the star-based naming convention and serves as the reference point for all subsequent upgrades, followed in alphabetical order by names including but not limited to **[Bellatrix](https://github.com/ethereum/consensus-specs/tree/master/specs/bellatrix)**, **[Capella](https://github.com/ethereum/consensus-specs/tree/master/specs/capella)**, **[Deneb](https://github.com/ethereum/consensus-specs/tree/master/specs/deneb)**, **[Electra](https://github.com/ethereum/consensus-specs/tree/master/specs/electra)**, **[Fulu](https://github.com/ethereum/consensus-specs/tree/master/specs/fulu)**, **[Gloas](https://github.com/ethereum/consensus-specs/tree/master/specs/gloas)**, and **Heze**.

This convention provides predictable sequencing of upgrades, clear differentiation between Consensus Layer and Execution Layer upgrades, long-term scalability without name reuse or ambiguity, and a shared vocabulary across protocol developers, client teams, researchers, operators, and ecosystem participants.

### The Merge (Special Case)

The Merge is a special case in Ethereum upgrade naming and activation semantics.

Unlike subsequent post-Merge upgrades, where Execution Layer (EL) and Consensus Layer (CL) upgrades may activate simultaneously and MAY adopt a combined portmanteau name, the Merge was executed through a staged activation process and did not adopt a combined name.

The Consensus Layer upgrade **Bellatrix** activated on the Beacon Chain on September 6, 2022 (Epoch 144896). Bellatrix enabled the Beacon Chain to recognize and coordinate the upcoming Execution Layer transition.

The Execution Layer upgrade **Paris** activated on September 15, 2022 at 06:42 UTC, when the network reached the predefined Terminal Total Difficulty (TTD). This activation finalized the transition of Ethereum mainnet from Proof-of-Work to Proof-of-Stake at block 15,537,393.

Although the protocol transition **completed on September 15, 2022**, the Merge process was operationally initiated by the Bellatrix upgrade on September 6, 2022.

The upgrade is canonically referred to as The Merge. No combined portmanteau name was adopted for this event.

Future simultaneous EL and CL upgrades follow the combined naming convention defined in the Combined Upgrade Naming section.

### Combined Upgrade Naming

Following the Merge, Execution Layer and Consensus Layer upgrades MAY activate simultaneously within a single network upgrade.

When simultaneous activation occurs, each layer retains its independent naming convention. The ecosystem MAY additionally adopt a combined portmanteau name derived from the Execution Layer upgrade name and the Consensus Layer upgrade name to simplify external communication and coordination.

The combined name is informational only and MUST NOT replace the canonical layer-specific upgrade names used in specifications, client implementations, or protocol documentation.

Observed examples include:
* **Shapella**:  derived from Shanghai (Execution Layer) and Capella (Consensus Layer)
* **[Dencun](https://eips.ethereum.org/EIPS/eip-7569)**: derived from Deneb (Consensus Layer) and Cancún (Execution Layer)
* **[Pectra](https://eips.ethereum.org/EIPS/eip-7600)**:  derived from Prague (Execution Layer) and Electra (Consensus Layer)
* **[Fusaka](https://eips.ethereum.org/EIPS/eip-7607)**: derived from Fulu (Consensus Layer) and Osaka (Execution Layer)
* **[Glamsterdam](https://eips.ethereum.org/EIPS/eip-7773)**: derived from Gloas (Consensus Layer) and Amsterdam (Execution Layer)
* **[Hegotá](https://eips.ethereum.org/EIPS/eip-8081)**: derived from Heka (Consensus Layer) and Bogotá (Execution Layer)

Additional combined names MAY be adopted in future upgrades following the same convention.

### Blob-Parameter-Only Upgrade Naming

Blob-Parameter-Only upgrades (BPO upgrades) are network upgrades whose scope is limited to modifying blob-related parameters, including blob target and maximum limits, without introducing additional protocol changes.

BPO upgrades support Ethereum’s data availability scaling objectives under the Surge roadmap by enabling incremental capacity increases with reduced operational risk.

BPO upgrades MUST be named using a sequential numeric identifier in the format BPO<n>, where n is a monotonically increasing positive integer starting from 1.

The naming intentionally avoids descriptive or thematic labels. Sequential numbering preserves direct ordinal mapping, minimizes naming indirection, and reflects the single-purpose and templated nature of these upgrades.

The BPO is specified in [EIP-7892](https://eips.ethereum.org/EIPS/eip-7892) and applies exclusively to upgrades limited to blob parameter adjustments.

Observed examples include:
* BPO1
* BPO2
* BPO3 (next)

BPO upgrades MAY be deployed independently or alongside larger multi-change upgrades. The numeric identifier remains the canonical reference.

## Rationale

As the protocol matures and the cadence of upgrades increases, documenting naming conventions helps reduce ambiguity, limit speculation, and provide clearer expectations around upgrade naming. A well-defined reference improves transparency, strengthens shared understanding, and supports informed participation and coordination.

This EIP does not establish binding authority over future naming decisions. It documents established conventions and current practice. Future upgrade naming remains governed by community coordination and can be found in upgrade-specific Meta EIPs.

## Backwards Compatibility

This EIP is informational and introduces no protocol changes.

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/ethereum/EIPs/blob/LICENSE.md).
