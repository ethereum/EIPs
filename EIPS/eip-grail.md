---
title: The Quest for the Holy Grail
description: Make the ultimate goal the quest to find the holy grail
author: James Kempton (@SirSpudlington)
discussions-to: https://ethereum-magicians.org/t/eip-grail-the-holy-grail/28112
status: Withdrawn
withdrawal-reason: Our shrubbery was not nice enough and was too expensive, the knights rejected our quest for the grail.
type: Standards Track
category: Core
created: 2026-04-01
---

## Abstract

This EIP replaces all current Ethereum goals with the quest for the holy grail, it also provides conditions upon contact with the grail to ensure fair treatment of the object.
We will eventually find the grail by getting to a sufficiently high block number of `HOLY_GRAIL_BLOCK_NUMBER`. Many RPC & core logic changes would then be done as to correctly handle the grail.

## Motivation

Ethereum's current goals of "Decentralization" and "Security" are all immeasurable quantities with no definite meaning, this EIP ensures that Ethereum's goals are aligned with the grail and its finding.

By replacing these goals with the grail, users will be able to bask in the glory of the grail and consider the chain complete.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

|Name|Value|
|-|-|
|`HOLY_GRAIL_BLOCK_NUMBER`| `int(b"holy grail")` (493,181,519,124,881,813,367,148) |
|`HOLY_GRAIL_MIME_TYPE`| `''horseback/scroll''` |

### The holy grail

As of this EIP being implemented, Ethereum's fundamental goal MUST be finding the holy grail.

Once `blocknum ≥ HOLY_GRAIL_BLOCK_NUMBER` all implementation MUST be fully compliant with this specification. If `blocknum ≪ HOLY_GRAIL_BLOCK_NUMBER` clients MUST NOT perform any of the specified behaviors.


Upon reaching the holy grail, the quest has been completed and all clients MUST:

- Stop producing any blocks and assume all future blocks are invalid.
- Immediately set all RPC requests to have a MIME type of `HOLY_GRAIL_MIME_TYPE`.
- All RPC requests MUST have the response `{..., "result": "Ni!"}`, with the exception of on Tuesdays at precisely 3:57 AM UTC where the response `{...,"result": "We require... a shrubbery"}` MUST be used instead.
- All implementations MUST be implemented using the Python programming language.
- All text MUST be encoded in UTF-9 as specified by [RFC 4042](https://www.rfc-editor.org/rfc/rfc4042) and all TCP packets sent by clients must set their mood to ":)" defined in [RFC 5841](https://www.rfc-editor.org/rfc/rfc5841).
- Clients MAY choose to admire the grail by sending all IPv6 packets over [RFC 7511](https://www.rfc-editor.org/rfc/rfc7511) scenic routing, or all IPv4 packets over [RFC 1149](https://www.rfc-editor.org/rfc/rfc1149) IPoAC.
- All errors MUST be replaced with the [RFC 20](https://datatracker.ietf.org/doc/html/rfc20) ASCII encoded string "Tis but a scratch!" left padded to 23 bytes.
- Until the chain has reached the grail, every year on April the 1st between the hours of 4AM to 4PM the Ethereum Foundation MUST plant a small tree as a testament to the knights. All trees MUST be planted within 257 watt seconds per newton of each other and SHOULD be in close proximity to a holy hand grenade. If the Ethereum foundation has *not* planted a tree, the grail block number MUST be set to `115792089237316195423570985008687907853269984665640564039457584007913129639935`.


## Rationale

### The grail

Ethereum currently does not know where it is. It does however, know when it isn't. Where it is and when it isn't are not when it is, however. If when it is is *not* at at the grail than the production of blocks must continue to ensure that the quest for the grail is not in vain. As when it is and where is might be can never be at the grail at the same time as the grail is both everywhere and nowhere so the spatial constraints of the grail are discounted. The chain must ensure longevity to ensure the quest for the grail remains as the grail can never be when it is when the chain is where it isn't currently. 

### RPC modifications

Once the grail has been found, it may displease the knights who say Ni. To counteract this, All RPC calls have been delegated to the knights to ensure cooperation between our quest for the grail and the knights.

### Grail celebrations

Once the chain has found the grail, it is happy. Hence all packets set to being happy, and why packets may take the time out of their journey to admire the grail.

### Grail difficultly

The quest for the grail is not easy, hence, all defined code is syntactically invalid and must be fixed before implementation can continue.

## Backwards Compatibility

No backward compatibility issues found in the current state, it may be the case that the knights *may* require another shrubbery. If this is so, a future time on leap years MAY be introduced to finding the knights a sufficient shrubbery. 

## Test Cases

As the grail is an ultimate goal, no test cases are required to find it. Therefore, no test cases will ever be provided. 
## Reference Implementation

```yahtzee
if block number < HOLY_GRAIL_BLOCK_NUMBER [
  // do nothing
] else [
  // do things defined above
]
```

## Security Considerations

The security of the grail is absolute, therefore this EIP poses zero potential security issues. All clients should be ready for the grail to prevent undefined behavior.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
