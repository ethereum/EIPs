---
title: Gasless Transactions
description: This EIP allows for gasless transactions for small transactions.
author: James Kempton (@JKincorperated)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2023-08-08
requires: 2718
---

## Abstract

This EIP allows for gasless transactions below 250,000 gas units every 32 epochs by introducing a new [EIP-2718](./eip-2718) transaction type, with the format `0x03 || rlp([chain_id, nonce, destination, amount, data, access_list, signature_y_parity, signature_r, signature_s])`.

## Specification

This specification is WIP and is not ready for production



The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

TBD

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
