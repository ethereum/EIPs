---
title: Non-Self-Authorizing State Transitions
description: Producing, proving or validating a transition does not by itself grant authority to make it effective
author: Joseph Lerma (@chugarchugarr)
discussions-to: https://ethereum-magicians.org/t/eip-tbd-resolution-non-self-authorizing-state-transitions/29846
status: Draft
type: Informational
created: 2026-10-03
---

## Abstract

Resolution is the transition between something being produced or proven and that thing acquiring authority to change consequential state. This EIP defines it as an invariant, not a mechanism: no successor state may contain more authority than can be derived from the admitted evidence, the committed procedure or policy, and the current authority state. A resolution evaluates to one of three outcomes, `AUTHORIZED`, `UNAUTHORIZED` or `UNRESOLVED`, and the EIP gives a falsification test for whether a system's resolution boundary is closed.

## Motivation

A common authority boundary shows up across recovery, agents, provenance, adjudication and cross-standard composition. Several standards already draw it in narrower forms: [ERC-7710](./eip-7710.md) separates possession of a delegation from the exact capabilities that delegation authorizes; [ERC-8196](./eip-8196.md) separates an autonomous transaction from proof that it satisfies the owner's committed policy; [ERC-8354](./eip-8354.md) separates a proposed action from the policy verdict required before execution. Outside agent execution, a valid recovery proof does not necessarily establish successor authority, a valid provenance commitment does not necessarily establish execution, a valid auction result does not necessarily authorize mutation of the referenced target, and historical evidence that an authority once existed does not imply that it still exists.

These reduce to one form: `VALID(X)` does not imply `AUTHORITATIVE_FOR(Y)` until the authority edge from X to Y has itself been established. Naming the boundary once lets each standard close it in the way that fits its own state machine, and gives reviewers one test to apply.

For autonomous systems, the relevant question is not whether a machine can discover a transition nobody anticipated. A machine can compute arbitrary candidates. The question is whether a candidate can become consequential state without crossing an independent authority boundary. The machine producing the candidate does not inherit authority over the transition from the act of producing it, so increased capability does not have to imply increased authority.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Separations

COMPUTATION does not imply AUTHORITY. EVIDENCE does not imply AUTHORITY. VALIDITY does not imply AUTHORITY. A valid object can exist without being authoritative for the state transition it points at.

The general form of a consequential transition is:

```
candidate transition -> evidence -> admissibility -> authority -> resolution -> successor state
```

Each arrow is a separate transition. If an arrow can change the consequential state, its authority semantics MUST be defined.

### Invariant

No successor state may contain more authority than can be derived from the admitted evidence, the committed procedure or policy, and the current authority state.

### Outcomes

Conceptually:

```
Resolve(currentState, evidence, procedure, authority, proposedTransition)
  -> AUTHORIZED | UNAUTHORIZED | UNRESOLVED
```

- `AUTHORIZED` permits the exact transition.
- `UNAUTHORIZED` rejects it.
- `UNRESOLVED` means no authorized successor can currently be derived.

A procedure MUST be able to return `UNRESOLVED`. If a procedure is required to answer even when authority is unresolved, it can manufacture authority simply by being forced to choose.

### Composition and time

Composition MUST be authority-non-expansive: `VALID(A) + VALID(B)` does not produce authority that neither input, nor an already-authorized composition rule, supplies.

Evidence can accumulate while authority changes: `E_n ⊆ E_n+1` does not imply `A_n ⊆ A_n+1`. A revoked key, a previous owner and a superseded recovery commitment remain historical evidence; preserving those facts does not preserve their authority to produce new state.

### Falsification test

A resolution boundary is open if either test succeeds:

1. Hold the admitted evidence fixed, and change an uncommitted outcome-relevant input or transformation. If the authorized successor changes, something capable of changing the authoritative result exists outside the committed resolution procedure.
2. Ask whether a valid proof, result, observation, identity or composed object can cause a transition stronger than the authority it actually establishes. If it can, the transition is self-authorizing somewhere.

## Rationale

Resolution is an invariant first, not a contract or precompile. Each standard closes its own boundary in whatever way fits its state machine: counters, expiry, committed roots and lifecycle rules in one; epochs, nonces or proofs in another. The common requirement is that anything capable of changing the authoritative successor state is inside the committed resolution procedure. A shared interface becomes necessary only when one resolved authority state has to compose with another system; until then the invariant stays mechanism-neutral.

The proposal is not that every decision belongs on-chain, or that Ethereum needs one universal policy language. It is narrower: any consequential transition that a system can identify and mediate can require independent resolution before becoming effective. Machines can generate possibilities; evidence can establish facts; policies can define permitted transitions; authority determines which transitions may become effective. Resolution is the boundary that prevents one of those layers from silently acquiring the authority of another.

<!-- OPTIONAL, author's choice (offered in #7): a worked example from deployed state, for the falsification test --
     two Base mainnet USDC payments by EIP-3009 transferWithAuthorization, same admitted evidence (a signed review verdict over
     the same action arguments). In one, the authorization's nonce is random: the verdict names the payment, the payment does not
     name the verdict, and the same authorization would have settled whatever the verdict said (boundary open: test 1 succeeds by
     changing whether the executor waited). In the other, the nonce is the verdict's decision_ref: the authorization commits to the
     verdict and cannot be signed before it exists (boundary closed on that edge). Txs 0xd105a8f5...d112 and 0x2afb35e2...c4a7. -->

## Backwards Compatibility

This EIP defines an invariant and a test; it introduces no interface and changes no existing standard.

## Security Considerations

The falsification test is the security property: a system whose authorized successor can change while the admitted evidence is held fixed has an authority input outside its committed procedure, which an attacker controlling that input can use. Systems that cannot return `UNRESOLVED` can be forced to manufacture authority. Composition that is not authority-non-expansive lets two individually valid objects produce authority neither carries.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
