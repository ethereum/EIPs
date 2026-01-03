---
title: Add Network Upgrade Stage Field for EIPs
description: Adds optional metadata field to improve upgrade tracking and coordination across EIPs.
author: Pooja Ranjan (@poojaranjan)
discussions-to: <URL to be added>
status: Draft
type: Meta
created: 2026-01-03
requires: 7723
---

## Abstract

This proposal introduces _**an optional**_ metadata field `Stage` for network upgrade stage to an EIP preamble to improve visibility, coordination, and traceability during multi-upgrade preparation cycles. The `Stage` field is temporary and used during `Draft` till `Last Call` status across multiple EIP types & categories.

## Motivation

With the adoption of a multi-upgrade preparation model for Ethereum network upgrades, it is increasingly difficult to determine which EIPs are under active consideration for a given upgrade and the specific network stage they have reached, particularly while proposals are in `Draft` or `Review` status. This information is currently fragmented across meeting notes, Upgrade Meta EIPs, and external tooling, creating coordination overhead for authors, editors, client and testing teams, and the broader community. Introducing standardized, non-normative metadata in EIP preambles would improve visibility and coordination during upgrade planning without modifying the EIP lifecycle.

## Specification

This proposal adds an optional EIP preamble field: `Stage` that an EIP is being discussed or considered in the context of a specific network upgrade with the following semantics.

- This field is "informational" in nature and reflects inclusion stages as defined in [EIP-7723](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7723.md).
- It is applicable to Standards Track (Core, Interface, and Networking) and Informational EIPs and not in Upgrade Meta EIP.
- It is applicable to `Draft`, `Review` or `Last Call` statuses.
- This field **MUST NOT** be present in the "initial Draft" submission and **MUST** be added added to update the EIP later.
- It **MAY** be added when another PR is made to update the Meta EIP of the respective upgrade to update the inclusion stage of this EIP.
- It **MUST** be removed when the EIP moves to `Final`, `Stagnant`, or `Withdrawn`, regardless of EIP type.
- Eligible EIPs **MUST** specify one of the following inclusion stages: `Proposed for Inclusion` (PFI), `Considered for Inclusion` (CFI), `Declined for Inclusion` (DFI), or `Scheduled for Inclusion` (SFI) separately for each network upgrade.

It is anticipated that this proposal will add value in addition to "Optional Upgrade Field for Core EIPs" with specifications to be displayed in all statuses from `Draft` to `Final` instead of just `Final`.

Example:

A. Initial Draft submission (MUST NOT include `stage`)

```yaml
---
eip: 7805
title: Fork-choice enforced Inclusion Lists (FOCIL)
description: Allow a committee of validators to force-include a set of transactions in every block
author: Thomas Thiery (@soispoke) <thomas.thiery@ethereum.org>, Francesco D'Amato <francesco.damato@ethereum.org>, Julian Ma <julian.ma@ethereum.org>, Barnabé Monnot <barnabe.monnot@ethereum.org>, Terence Tsao <ttsao@offchainlabs.com>, Jacob Kaufmann <jacob.kaufmann@ethereum.org>, Jihoon Song <jihoonsong.dev@gmail.com>
discussions-to: https://ethereum-magicians.org/t/eip-7805-committee-based-fork-choice-enforced-inclusion-lists-focil/21578
status: Draft
type: Standards Track
category: Core
created: 2024-11-01
---
```

B. Later update (Draft/Review/Last Call) after a Meta EIP PR is made

```yaml
---
eip: 7805
title: Fork-choice enforced Inclusion Lists (FOCIL)
description: Allow a committee of validators to force-include a set of transactions in every block
author: Thomas Thiery (@soispoke) <thomas.thiery@ethereum.org>, Francesco D'Amato <francesco.damato@ethereum.org>, Julian Ma <julian.ma@ethereum.org>, Barnabé Monnot <barnabe.monnot@ethereum.org>, Terence Tsao <ttsao@offchainlabs.com>, Jacob Kaufmann <jacob.kaufmann@ethereum.org>, Jihoon Song <jihoonsong.dev@gmail.com>
discussions-to: https://ethereum-magicians.org/t/eip-7805-committee-based-fork-choice-enforced-inclusion-lists-focil/21578
status: Draft
type: Standards Track
category: Core
upgrade: Hegota
stage: CFI
created: 2024-11-01
---
```

C. EIP moves to Final/Stagnant/Withdrawn (MUST remove `stage`)
```yaml
---
eip: 2315
title: Simple Subroutines for the EVM
description: Two opcodes for efficient, safe, and static subroutines.
author: Greg Colvin (@gcolvin), Martin Holst Swende (@holiman), Brooklyn Zelenka (@expede), John Max Skaller <skaller@internode.on.net>
discussions-to: https://ethereum-magicians.org/t/eip-2315-simple-subroutines-for-the-evm/3941
status: Withdrawn
type: Standards Track
category: Core
created: 2019-10-17
requires: 3540, 3670, 4200
withdrawal-reason: This proposal has been superseded by the EOF proposals.
---
```

## Rationale

The design intentionally separates temporary coordination metadata (Stage) from permanent historical metadata (Upgrade):
	•	Keeps finalized EIPs clean and authoritative.
	•	Avoids premature signaling of upgrade inclusion.
	•	Preserves Meta EIPs as the source of truth during upgrade planning.
	•	Aligns with existing editorial and governance workflows.

## Backwards Compatibility

No backward compatibility issues are introduced. The proposal adds optional, non-normative metadata fields and does not affect EIP semantics, consensus rules, or client behavior.

## Security Considerations

This proposal introduces no protocol-level or implementation-level security risks.
Incorrect or misleading metadata is mitigated through:
	•	Editorial review
	•	Automatic removal of temporary fields at finalization.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md)￼.
