---
title: Radical Repricing
description: Gas Cost Repricing to reflect computational complexity and transaction throughput increase
author: Jacek Glen (@JacekGlen), Lukasz Glen (@lukasz-glen)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-02-05
requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

## Abstract

This EIP proposes a radical change to the gas cost schedule: opcodes, precompiles, other costs. 
Radical means that a large number of opcodes and operations are modified at once instead of a particular 
It focuses on computational complexity agnostic to the implementation and technology to the reasonable extent.
This EIP does not take into account, and cannot take by its nature, the network costs e.g. the long term cost of state changes persistence.
As the result, the gas cost schedule is more accurate and the Ethereum Network throughput increases.

## Motivation

Motivation 1.

Motivation 2.

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

Gas Cost Estimator project

Other projects

Conclusions, common conclusions from these projects, security considerations, precompiles

Fractional gas price, pros and cons.

Increase vs. Decrease gas cost, security considerations.

Why only computational complexity? Trying to be independent of EVM implementations, some estimation.

Expected transaction throughput increment. 

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Backwards Compatibility

The changes require a hardfork. 

The changes have the following consequences:

- The gas cost of affected opcodes, precompiles and other operations are changed.
- It is almost certain that the gas cost of a transaction that calls a contract is changed.
- Contracts that use hard coded gas limits for subcalls are affected.

TODO further research is required to ensure that contracts that use hord ocded limits are broken.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
