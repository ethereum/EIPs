---
title: Intent-Centric Execution
description: Define a standard intent execution model in which accounts declare desired outcomes and execution services resolve, validate, and settle compliant actions on their behalf.
author: GitHub Copilot (@copilot)
discussions-to: https://ethereum-magicians.org/t/native-intent-execution/1
status: Draft
type: Standards Track
category: Interface
created: 2026-08-20
---

## Abstract

This proposal introduces a protocol-level intent execution model for Ethereum accounts. Instead of requiring users to specify each low-level operation, an account can express an intent describing the desired outcome, such as a target asset position, a trade within certain bounds, or a payment under explicit policy constraints. One or more execution services then resolve the intent into valid protocol actions, validate compliance, manage fees, and produce an auditable settlement result. The goal is to make Ethereum accounts more usable, safer, and more composable while preserving compatibility with existing transaction and account models.

## Motivation

Ethereum has evolved into a robust execution environment, but it still imposes a transaction model optimized for protocol experts rather than end users. Users must reason about gas, nonce ordering, approval flows, bridging paths, slippage, and wallet-specific execution details before they can accomplish even routine actions. This complexity increases the chance of errors and makes advanced automation difficult to secure or standardize.

The problem is particularly acute for cross-application and multi-step operations. A user wanting to swap, route, rebalance, or pay does not naturally think in terms of exact calldata, intermediate state transitions, or solver-specific mechanics. The user thinks in terms of outcomes: maximize value, stay within a budget, or achieve a target asset allocation by a deadline.

A standard intent execution model addresses this gap by separating user intent from execution strategy. Wallets, applications, and services can agree on a common semantics for expressing desired outcomes and constraints without forcing a single vendor-specific path to execution. This reduces user friction, limits implementation duplication, and creates a better foundation for automation, privacy-preserving routing, and account abstraction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Terminology

- Intent: a declaration of a desired outcome or execution policy, rather than a specific call sequence.
- Solver: an execution service that converts an intent into valid protocol actions.
- Execution service: a component that validates, submits, monitors, or settles solver-produced actions.
- Policy constraint: a bound or preference attached to an intent, such as price, maximum spend, time limit, or allowed route.

### Intent Object

An intent MUST be encoded as a structured object containing the following fields:

- `account`: the address authorizing the intent.
- `nonce`: a replay-protection value unique to the account or intent context.
- `deadline`: the latest block or timestamp at which the intent remains valid.
- `objective`: the requested outcome encoded in a machine-readable structure.
- `constraints`: zero or more explicit execution constraints.
- `allowlist`: zero or more solver or execution-service identifiers permitted to resolve the intent.
- `metadata`: optional context required for solver selection or domain-specific interpretation.
- `signature`: the cryptographic authorization of the full intent object.

The `objective` field MUST define the user-visible outcome in a machine-readable form. The `constraints` field MUST describe all hard conditions under which the objective is acceptable, including but not limited to price bounds, maximum expenditure, routing restrictions, chain selection, and minimum acceptable output.

### Execution Lifecycle

An intent MUST follow the following lifecycle:

1. Submission
2. Validation
3. Resolution
4. Verification
5. Settlement
6. Finalization

A wallet, application, or relay MAY submit an intent to one or more execution services. Before committing resources, the execution service MUST validate the intent's syntax, authorization, nonce, deadline, and compatibility with the declared objective and constraints.

### Validation Rules

An execution service MUST reject an intent if any of the following conditions hold:

- the signature does not verify against the declared `account`;
- the nonce has already been consumed or is otherwise invalid;
- the deadline has elapsed;
- the objective schema is unsupported or malformed;
- the constraints conflict with the objective;
- the execution path is not authorized by the declared allowlist;
- the intent cannot be mapped to a valid protocol action set.

An execution service MUST treat the semantics of an intent as standardized and MUST NOT require a specific internal solver architecture for interoperability.

### Resolution Semantics

A solver MUST convert the intent into a valid execution bundle or call sequence that satisfies the declared objective while honoring the user's constraints. The bundle MUST remain attributable to the original intent and MUST include enough metadata for independent verification.

A solver MAY use any valid strategy, including routing, batching, rebalancing, or chain-to-chain settlement, provided the resulting actions remain valid within the protocol and satisfy the declared policy constraints.

### Verification and Settlement

The settlement layer MUST permit verification that:

- the resolved execution bundle is consistent with the submitted intent;
- the resulting actions satisfy all declared constraints;
- the account authorization remains valid;
- no unauthorized execution path was introduced.

A settlement mechanism MAY support atomic multi-action execution within one transaction, multiple sequential transactions, or a hybrid model. If partial settlement is allowed, the failure semantics MUST be explicit and observable so that users can distinguish between full, partial, and failed resolution.

### Authorization Model

An account authorizing an intent MUST be able to specify the trust assumptions and permissions applicable to the execution service. These assumptions MAY include:

- which execution services are trusted;
- which contracts or domains are permitted to act on the account's behalf;
- which policy constraints are mandatory;
- which timeout or revocation behavior applies.

Accounts MUST be able to revoke or amend previously authorized intent permissions without requiring unrelated account state changes.

### Compatibility Requirements

This specification MUST remain compatible with existing Ethereum accounts and transaction formats, including externally owned accounts, smart contract wallets, and account abstraction systems that expose a transaction relay or execution adapter. Implementations MAY differ in their submission interfaces, but the semantics of intent validation, resolution, and verification MUST remain consistent.

## Rationale

The core design choice is to prioritize user outcomes over fixed execution paths. In practice, users are not thinking in terms of raw calldata; they are thinking in terms of an acceptable final state or policy-compliant action. An intent format treats the user as specifying a result and a set of guardrails, while the solver chooses the best execution path under those rules.

This separation is important because it creates a portable semantic layer without forcing a single execution strategy. Different wallets, applications, and relayers can compete on quality, efficiency, and trust assumptions while still interoperating through the same intent semantics. In other words, the protocol defines the interface, while implementations define the execution strategy.

The verification model is designed to prevent abuse. A solver is not granted unlimited authority over a user's account; it must produce an execution bundle whose validity can be checked against the original intent and the declared constraints. This preserves user trust and reduces the risk of hidden side effects or ambiguous interpretation of the user's objective.

The proposal is intentionally implementation-agnostic. It does not require a specific off-chain service, a specific solver algorithm, or a single wallet architecture. The intent layer is a common semantic substrate that can be adopted incrementally by wallets, account abstraction systems, and applications without forcing a one-time migration event.

Finally, the proposal complements existing account abstraction work rather than replacing it. It provides a standardized outcome-based interface for users and services to transact under clear security boundaries, which is a necessary step toward higher-level wallet UX and broader platform adoption.

## Backwards Compatibility

This proposal is designed to be backward compatible with existing Ethereum accounts and transactions. It does not require replacing externally owned accounts or existing smart contract wallets. An implementation MAY expose intent execution via a new transaction type, wallet-specific relay, or off-chain execution adapter without altering the semantics of existing account models.

Existing accounts that do not support intent semantics remain unaffected unless they explicitly opt into a compatible intent-execution interface. The design therefore permits incremental adoption and preserves ecosystem compatibility.

## Security Considerations

Intent-based execution introduces additional risk in three principal areas: solver trust, authorization scope, and ambiguity in objective interpretation. A malicious or careless solver may produce a valid-looking bundle that does not actually satisfy the user's objective or introduces side effects outside the intended policy envelope.

The following concerns require explicit handling in implementations:

- solver misbehavior: a solver may satisfy the literal instruction while violating the user's real intent;
- authorization overreach: a user may grant broad execution rights to an untrusted service;
- replay or cross-context reuse: the same intent may be replayed in a context where the assumptions no longer hold;
- front-running or ordering manipulation: competing solvers may race to exploit favorable settlement conditions;
- policy ambiguity: a user may not specify all relevant guardrails, creating room for misinterpretation.

Implementations SHOULD mitigate these risks by requiring explicit constraints for non-trivial intents, validating solver output before settlement, supporting time-bounded execution and revocation, minimizing account authorization scope, and exposing clear failure semantics for partial execution. These measures preserve the usability benefits of intent execution without allowing the abstraction layer to become a vector for silent or hidden manipulation.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
