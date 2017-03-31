## Preamble

    EIP: <to be assigned>
    Title: New EVM opcode 'TERMINATE'
    Author: Nick Johnson
    Type: Standard Track
    Category (*only required for Standard Track): Core
    Status: Draft
    Created: 2017-04-01


## Simple Summary
We propose a new EVM opcode, 'TERMINATE', that facilitates new compute operations not previously possible in the EVM.

## Abstract
'TERMINATE' is a new opcode, tentatively assigned code 0xFC. When executed, it destroys the universe.

## Motivation
According to the [many-worlds interpretation](https://en.wikipedia.org/wiki/Many-worlds_interpretation) of quantum physics, every quantum interaction results in the creation of two distinct universes, one for each outcome of the interaction. As a result, every combination of quantum interactions exists in a potential universe somewhere.

This provides a method by which we can implement algorithms with better efficiency bounds than traditional classical algorithms. For instance, O(n) general purpose sorting becomes possible by implementing the Quantum Bogosort algorithm:

  1. Randomly shuffle the list to be sorted.
  2. Iterate over the list, checking if each element is in order.
  3. If any elements are found to be out-of-order, destroy the universe.

Even more significantly, an O(1) algorithm for factoring integers becomes possible:

  1. Generate a random number between 2 and the square root of the input number.
  2. Try and divide the input number by the number selected in 1.
  3. If the numbers do not divide, destroy the universe.

We do not recommend running this algorithm on known primes.

Random numbers can be provided by an offchain random oracle, making use of quantum randomness such as nuclear decay.

## Specification
When a compliant EVM implementation encounters 0xFC, 'TERMINATE', it should destroy the universe.

EVM instances not connected to the appropriate hardware should treat 0xFC as a no-op.

## Rationale
The specification of 'TERMINATE' is relatively straightforward. The decision to allow implementations to comply by treating  TERMINATE as a no-op is due to the constraints described in the Implementation section, and does not affect consensus.

## Backwards Compatibility
There are no backwards compatibility implications.

## Test Cases
TBD.

## Implementation
We expect implementation to be straightforward, as only one client needs to implement TERMINATE as anything other than a no-op, and only one active node need be configured to execute it correctly. However, we recommend multiple nodes enable this operation, so as to avoid incorrect results being returned in the event that no connected nodes are capable of destroying the universe.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
