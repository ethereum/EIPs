---
eip: <to be assigned by editors>
title: Counterfactual Rejection Event Log (CREL) Standard
description: Canonical on-chain event format for algorithmically rejected DEX trading candidates with post-rejection outcome fields.
author: Arati Uday Kamat (@aartikamat) <arati.kamat@ieee.org>
discussions-to: TBD (Ethereum Magicians thread URL to be added)
status: Draft
type: Standards Track
category: ERC
created: 2026-06-08
---

## Abstract

This ERC proposes a standardized event log format for algorithmically rejected trading candidates on decentralized exchange (DEX) protocols. The Counterfactual Rejection Event Log (CREL) standard defines two events: RejectionLogged emitted at the moment of filter rejection, and OutcomeSampled emitted at fixed intervals after rejection to capture post-rejection market state. Conforming protocols enable downstream measurement of filter precision, counterfactual outcome analysis, and cross-protocol comparison of filter-stack quality.

## Motivation

DEX trading protocols and filter middleware reject the majority of candidate tokens they evaluate. Existing protocols log accepted trade events with detailed metadata but do not log rejection events in a structured format. As a consequence:

1. Filter precision cannot be measured without bespoke off-chain data infrastructure.
2. Cross-protocol comparison of filter quality is impossible because rejection criteria are not surfaced.
3. Counterfactual outcome measurement (what would the rejected token have done if traded) requires private off-chain replay infrastructure.

The RED-2400 public benchmark dataset (arXiv 2605.12151) documents this gap empirically: 6,660 rejection events on Solana DEX venues over a 49-day window were captured only through off-chain instrumentation, with 94 percent of rejected tokens ceasing trading activity within 24 hours and 6 percent surviving with significant returns. The Post-Rejection Follow-up Sampling (PRFS) methodology defines the measurement framework. CREL provides the on-chain logging primitive that allows this measurement to occur natively on Ethereum without off-chain coordination.

## Specification

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, and OPTIONAL in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Events

A CREL-conforming contract MUST emit the following two events.

#### RejectionLogged

```solidity
event RejectionLogged(
    bytes32 indexed candidateId,
    address indexed tokenAddress,
    uint256 indexed rejectionTimestamp,
    uint8 rejectReason,
    uint256 marketCapAtRejection,
    uint256 liquidityAtRejection,
    bytes additionalMetadata
);

Where:

candidateId: A unique identifier for the candidate trade or token under evaluation. Implementations MAY use a deterministic hash of token address plus rejection timestamp.
tokenAddress: The ERC-20 contract address of the token being evaluated.
rejectionTimestamp: Unix timestamp at the moment the rejection decision was made.
rejectReason: A categorical code identifying the filter rule that triggered rejection. Reserved codes 0 through 15 are defined below. Codes 16 through 255 are protocol-defined.
marketCapAtRejection: Market capitalization in USD (1e18-scaled) at rejection time. Implementations MAY use 0 if not available.
liquidityAtRejection: Pool liquidity in USD (1e18-scaled) at rejection time. Implementations MAY use 0 if not available.
additionalMetadata: Optional ABI-encoded extension data. Reserved for protocol-specific fields.
OutcomeSampled
event OutcomeSampled(
    bytes32 indexed candidateId,
    uint256 indexed sampleTimestamp,
    uint8 outcomeClass,
    uint256 priceAtSample,
    uint256 liquidityAtSample
);
Where:

candidateId: Matches the candidateId from a prior RejectionLogged event.
sampleTimestamp: Unix timestamp of the post-rejection sample.
outcomeClass: One of three values. 0 means gone (token absent from pool). 1 means alive_dormant (token present but liquidity below activity threshold). 2 means alive_active (token present with active liquidity).
priceAtSample: Token price in USD (1e18-scaled) at sample time.
liquidityAtSample: Pool liquidity in USD (1e18-scaled) at sample time. 0 if the token has been removed from the pool.
Reserved Rejection Reason Codes
Codes 0 through 15 are reserved for the most common filter rules observed in the RED-2400 corpus:

Code	Reason
0	market_cap_out_of_range
1	liquidity_threshold_fail
2	downtrend_24h
3	downtrend_5m
4	holder_concentration
5	token_age_too_new
6	token_age_too_old
7	volume_threshold_fail
8	transaction_count_threshold_fail
9	anti_bot_check_fail
10	rug_check_fail
11	contract_verification_fail
12	dev_wallet_activity
13	bundle_pattern_detected
14	sniper_pattern_detected
15	comment_spam_pattern
Codes 16 through 255 are available for protocol-specific reasons.

Sampling Cadence
A CREL-conforming protocol SHOULD emit at least one OutcomeSampled event per rejected candidate within 24 hours of the corresponding RejectionLogged event. Recommended cadences are 5 minutes, 15 minutes, 1 hour, 4 hours, and 24 hours after rejection, matching the PRFS methodology.

A protocol MAY emit additional samples beyond 24 hours for extended outcome measurement.

Indexer Conventions
Off-chain indexers consuming CREL events SHOULD construct a rejection corpus by joining RejectionLogged with all corresponding OutcomeSampled events by candidateId. A reference indexer implementation is provided in the RED-2400 replication toolkit (Software Heritage SWHID: swh:1:rev:a85bf1ff1eb4af345752555a3a1844e5b172bf3e).

Rationale
Two events instead of one
Rejection and outcome measurement are temporally separated. A single combined event would force protocols to delay rejection logging until outcome data is available, which defeats the purpose of capturing the rejection moment.

Three-class outcome taxonomy
The three-class partition (gone, alive_dormant, alive_active) is the minimal classification that supports the save-to-miss ratio computation in the PRFS methodology. A five-class extension is documented in the companion paper but is not required at the on-chain event level for this minimum specification.

Backwards Compatibility
CREL is additive. Conforming protocols can emit CREL events alongside existing event streams without breaking existing integrations. No existing ERC events conflict with the proposed names or signatures.

Reference Implementation
A reference indexer implementation is available at https://github.com/aartikamat/red2400-replication-toolkit (Software Heritage SWHID: swh:1:rev:a85bf1ff1eb4af345752555a3a1844e5b172bf3e). A reference Solidity contract implementing CREL events will be released in the v1.1 update post-EIP acceptance.

Security Considerations
CREL events are public on-chain data and reveal the rejection criteria of conforming protocols. Protocols using proprietary filter logic MAY choose to emit only the categorical rejectReason code without leaking the underlying threshold values. The additionalMetadata field SHOULD NOT contain sensitive operational data unless the protocol explicitly accepts public disclosure of that data.

CREL does not introduce new attack surfaces beyond standard event-emission gas costs.

Copyright
Copyright and related rights waived via CC0.
