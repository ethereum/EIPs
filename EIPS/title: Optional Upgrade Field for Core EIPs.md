---
title: Optional Upgrade Field for Core EIPs
description: An optional preamble field to record the network upgrade for Core EIPs.
author: <Pooja Ranjan (@poojaranjan)>
discussions-to: <URL>
status: Draft
type: Meta
created: <2026-01-03>
---

## Abstract

This proposal introduces an optional EIP preamble field -`Upgrade` for a Standards Track-Core EIP moving to `Final` status. The field records Ethereum "network upgrade" in which the EIP was deployed, improving discoverability and historical clarity without altering the EIP lifecycle.

## Motivation

At present, the network upgrade in which a finalized Standards Track Core EIP was deployed is not directly visible in the `Final` EIP itself. While this information can be derived from Meta EIPs, upgrade announcements, or external tooling, the lack of an explicit reference in the EIP creates unnecessary friction for developers and readers attempting to understand upgrade scope, deployment history, and protocol evolution.

## Specification

This proposal defines an optional `Upgrade` field in the EIP preamble with the following semantics.

- The `Upgrade` field is **optional** and **informational**.
- It is applicable **only to Standards Track – Core EIPs**.
- The field MUST NOT be present during the `Draft`, `Review`, or `Last Call` statuses.
- The field MUST be added **only when an EIP transitions from `Last Call` to `Final` status**.
- The field MUST specify the name of the Ethereum Network Upgrade in which the EIP was deployed.

This proposal applies exclusively to Standards Track-Core EIPs. It does not apply to Networking, Interface, or Informational EIPs, nor to Meta EIPs, as network upgrade information is already captured within Meta EIPs. Responsibility for adding and maintaining the `Upgrade` field lies with the EIP co-authors or the designated EIP champion.

Examples:

A. Before (Final Core EIP – current state)

```yaml
---
eip: 7594
title: PeerDAS - Peer Data Availability Sampling
description: Introducing simple DAS utilizing gossip distribution and peer requests
author: Danny Ryan (@djrtwo), Dankrad Feist (@dankrad), Francesco D'Amato (@fradamt), Hsiao-Wei Wang (@hwwhww), Alex Stokes (@ralexstokes)
discussions-to: https://ethereum-magicians.org/t/eip-7594-peerdas-peer-data-availability-sampling/18215
status: Final
type: Standards Track
category: Core
created: 2024-01-12
requires: 4844
---
```

B. After (Final Core EIP – with upgrade field)

```yaml
---
eip: 7594
title: PeerDAS - Peer Data Availability Sampling
description: Introducing simple DAS utilizing gossip distribution and peer requests
author: Danny Ryan (@djrtwo), Dankrad Feist (@dankrad), Francesco D'Amato (@fradamt), Hsiao-Wei Wang (@hwwhww), Alex Stokes (@ralexstokes)
discussions-to: https://ethereum-magicians.org/t/eip-7594-peerdas-peer-data-availability-sampling/18215
status: Final
type: Standards Track
category: Core
upgrade: Fusaka
created: 2024-01-12
requires: 4844
---
```

C. Draft / Review / Last Call status (No upgrade field allowed)

```yaml
---
eip: 7594
title: PeerDAS - Peer Data Availability Sampling
description: Introducing simple DAS utilizing gossip distribution and peer requests
author: Danny Ryan (@djrtwo), Dankrad Feist (@dankrad), Francesco D'Amato (@fradamt), Hsiao-Wei Wang (@hwwhww), Alex Stokes (@ralexstokes)
discussions-to: https://ethereum-magicians.org/t/eip-7594-peerdas-peer-data-availability-sampling/18215
status: Last Call
last-call-deadline: 2025-10-28
type: Standards Track
category: Core
created: 2024-01-12
requires: 4844
---
```

D. Final Non-Core EIP (No upgrade field allowed)

```yaml
---
eip: 7642
title: eth/69 - history expiry and simpler receipts
description: Adds history serving window and removes bloom filter in receipt
author: Marius van der Wijden (@MariusVanDerWijden), Felix Lange <fjl@ethereum.org>, Ahmad Bitar (@smartprogrammer93) <smartprogrammer@windowslive.com>
discussions-to: https://ethereum-magicians.org/t/eth-70-drop-pre-merge-fields-from-eth-protocol/19005
status: Final
type: Standards Track
category: Networking
created: 2024-02-29
requires: 5793
---
```

The `Upgrade` field MAY be retroactively added to finalized Standards Track Core EIPs that were included in historical Meta EIPs.  However, Core EIPs that were activated asynchronously, and therefore not tied to a coordinated network upgrade, MUST NOT receive this field.

## Rationale

The `Upgrade` field provides a lightweight and authoritative way to surface deployment context directly within finalized Core EIPs. This approach avoids reliance on external tooling, preserves Meta EIPs as the coordination mechanism for upgrade planning, and keeps finalized EIPs self-contained and historically accurate.

The field is intentionally restricted to finalized Core EIPs to avoid premature signaling and unnecessary metadata during earlier lifecycle stages. 

## Backwards Compatibility

This proposal introduces no backward compatibility concerns. It adds an optional, non-normative metadata field and does not affect protocol behavior, consensus rules, or client implementations.

## Security Considerations

This proposal introduces no protocol-level security risks. Incorrect or misleading metadata is mitigated through editorial review and by restricting field usage to finalized EIPs only.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/ethereum/EIPs/blob/master/LICENSE.md)￼.










