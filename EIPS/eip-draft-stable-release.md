---
eip: tbd
title: Long-Term Support Release
author: William Morriss (@wjmelements)
discussions-to: TBD
type: Meta
status: Draft
created: 2025-04-01
---

## Abstract

To designate the current version of Ethereum as a long-term support stable release.

## Motivation

Any upgrade can break userspace, either intentionally or by accident.
Breaking userspace, even testnets, causes serious hardship to developers.
Whether the damage affects their testing procedures or their life savings, the impact can be tremendous.

Developers should expect for a platform to not have any breaking changes.
Communicating the stability of a release will help developers decide which version to build upon.
They may want stability guarantees or they may want the newest features.

Ethereum is good enough now that we can designate the current version as a stable release.
Previous versions still in-use can also be designated as stable releases.

## Specification

### Release Types

There are 2 types of Ethereum releases: Bleeding-Edge (BE) and Long-Term Support (LTS).
LTS releases will never break or change.
Each Ethereum LTS is maintained for 10000 years total: 5 years of standard support + 9995 years of ESM (Extended-Security Maintenance).
BE releases are maintained only when current.

Releases are designated End-Of-Life (EOL) after their support period.

#### Testnets
Testnets, including devnets, are temporary networks used for testing.
They may last for days or years depending on their purpose.
Developers should not expect them to be stable.
However, the order and frequency in which testnets adopt BE releases should inform developers about their relative stability:
the network that upgrades first and most-often is the least stable, while the network that upgrades last and least often is the most stable.

### LTS Designation Process

All network upgrades are initially BE.
If core developers fail to activate another upgrade for more than a year, then the current version becomes an LTS release.
After the next BE release, the LTS version will survive but change to a new chain ID.

### Ethereum Classic LTS

The Mystique version of Ethereum Classic is designated as the first LTS release.

### Ethereum v2 LTS

The Dencun version of Ethereum is designated as the second LTS release.

### Ethereum v3 BE

The Pectra version of Ethereum is the first BE release on v3.
Future Ethereum development will continue on v3.

## Rationale

### Chain ID

The Chain ID change ensures that transactions intended for one release are not replayable on another.

### Ten-Thousand Years

万, meaning ten-thousand, was the largest numerical unit in Chinese for a long time, and so has the symbolic meaning of "forever".
This number was chosen because LTS versions should be supported forever.
However, after ten-thousand years, future generations can decide whether to end support for an LTS version.

### Designation

By designating releases as LTS only when upgrades are delayed, the core developers are incentivized to deliver improvements on a regular release schedule.
The previous mechanism, the "difficulty bomb", penalized users when core developers failed to upgrade and discouraged contentious hard forks.
This new method instead punishes the core developers by committing them to ten-thousand years of technical support.
They will not be allowed to change jobs or die.
They will be chained to their desk and kept on life support, writing security patches and providing technical support for increasingly rare issues until EOL.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
