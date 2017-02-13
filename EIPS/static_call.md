## Preamble
<pre>
  EIP: to be assigned
  Title: New opcode STATIC_CALL
  Author: Vitalik Buterin &lt;vitalik@ethereum.org&gt;, Christian Reitwiessner &lt;chris@ethereum.org&gt;
  Type: Standard Track
  Category(*only required for Standard Track): Core
  Status: Draft
  Created: 2017-02-13
</pre>

## Simple Summary

To increase smart contract security, this proposal adds a new opcode that can be used to call another contract (or itself) while disallowing any modifications to the state during the call (and its subcalls, if present).

## Abstract


## Motivation


## Specification

Opcode: `0xfa`.

`STATIC_CALL` functions equivalently to a `CALL`, except it takes 6 arguments not including value, and calls the child with a `STATIC` flag on. Any calls, static or otherwise, made by an execution instance with a `STATIC` flag on will also have a `STATIC` flag on. Any attempts to make state-changing operations inside an execution instance with a `STATIC` flag on will instead throw an exception. These operations include nonzero-value calls, creates, `LOG` calls, `SSTORE`, `SSTOREBYTES` and `SUICIDE`.

## Rationale

This allows contracts to make calls that are clearly non-state-changing, reassuring developers and reviewers that re-entrancy bugs or other problems cannot possibly arise from that particular call; it is a pure function that returns an output and does nothing else. This may also make purely functional HLLs easier to implement.

## Backwards Compatibility

This proposal adds a new opcode but does not modify the behaviour of other opcodes and thus is backwards compatible for old contracts that do not use the new opcode.

## Test Cases

To be written.

## Implementation

