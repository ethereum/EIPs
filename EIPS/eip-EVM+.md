---
title: EVM+
description: Decimal math in the EVM
author: 1m1 (@1m1-github)
discussions-to: https://ethereum-magicians.org/t/decimal-math-on-evm/16194
status: Draft
type: Standards Track
category: Core
created: 2023-10-22
---


## Abstract

This EIP adds *decimal fixed* OPCODEs for arithmetic (DECADD, DECNEG, DECMUL, DECINV) and expression of all elementary functions (DECEXP, DECLN, DECSIN). All decimal values upto the maximal precision allowed by a int256 coefficient and exponent are represented exactly, as c*10^q. All implemented algorithms converge for all inputs given enough precision, as chosen by the user. All calculations are deterministic and gas is embedded bottom-up. Allowing high precision decimal elementary functions invites the worlds of mathematical finance, machine learning, science, digital art, games and others to Ethereum. The implementation is functional.

## Motivation

Currently, to take a power, a^b, of non integer values, requires vast amounts of Solidity code.
The simplest task in trading e.g. is to convert volatilities from yearly to daily, which involves taking the 16th root.

Giving users/devs the same ability that scientific calculators have allows for the creation of apps with higher complexity.

### Why decimal?
A simple value like 0.1 cannot be represented finitely in binary. Decimal types are much closer to the vast majority of numerical calculations run by humans.

### eVm

The EVM is a virtual machine and thereby not restricted by hardware. Usually, assembly languages provide OPCODES that are mimic the ability of hardware. In a virtual machine, we have no such limitations and nothing stops us from adding more complex OPCODEs, as long as fair gas is provided. At the same time, we do not want to clutter the OPCODEs library. EXP, LN and SIN are universal functions that open the path to: powers, trigonometry, integrals, differential equations, machine learning, digital art, etc.


<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

### Decimal

A decimal is defined as

c * 10^q

where c and q are int256.

Notationwise:
a = ac * 10^aq
b = bc * 10^bq
etc.

### OPCODE defs

0xd0 DECADD a+b -> c    : (ac, aq, bc, bq, precision) -> (cc, cq)
0xd1 DECNEG  -a -> b    : (ac, aq) -> (bc, bq)
0xd2 DECMUL a*b -> c    : (ac, aq, bc, bq, precision) -> (cc, cq)
0xd3 DECINV 1/a -> b    : (ac, aq, precision) -> (bc, bq)
0xd4 DECEXP exp(a) -> b : (ac, aq, precision, steps) -> (bc, bq)
0xd5 DECLN   ln(a) -> b : (ac, aq, precision, steps) -> (bc, bq)
0xd6 DECSIN sin(a) -> b : (ac, aq, precision, steps) -> (bc, bq)

precision is the # of digits kept during all calculations. steps for DECEXP and DECSIN are the # of Taylor expansion steps. steps for DECLN is the depth of the continued fractions expansion.

### Why these functions?

The proposed functions (+,-,*,/,exp,ln,sin) form a small set that combined enable all calculation of all elementary functions, which includes the sets of sums, products, roots and compositions of finitely many polynomial, rational, trigonometric, hyperbolic, and exponential functions, including their inverse functions.

a^b = exp(b * ln(a)) gives us powers and polynomials.
cos(a) = sin(tau/4-a), tan(a)=sin(a)/cos(a), etc., gives us all of trigonometry.

together with arithmetic, we get all elementary functions.

### DECNEG instead of DECSUB

Negation is a more general operation vs subtraction. OPCODEs should be as fundamental as possible and as complex as desirable.
For the same reason, we have DECINV instead of DECDIV.

DECSUB(a,b) = DECADD(a,DECNEG(b))
DECDIV(a,b) = DECMUL(a,DECINV(b))

### DECEXP, DECSIN via Taylor series

The Taylor series of exp and sin converge everywhere and fast. The error falls as fast as the factorial of steps.

### DECLN via continued fractions

Ln converges fast using continued fractions within the interval ]0,2]. The implementation scales the input into this interval and scales the result back correctly.

### math/big

The implementation allows arbitrary precision, in theory. In practice, resources are always finite.

The implementation uses the same lib as used for the stack (uint256).
Using math/big would allow for arbitrary[*] intermediate precision. That version is also functional, on another branch.
Even tho using math/big, input and output values have to fit into the stack.
Using uint256 is much faster, natural for the stack and still allows for far more precision that most applications need.




<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

### gas

all the above OPCODEs are deterministic, hence the gas cost can be determined. at the same time, the calculations are complex and depend on the input.

it is crucial to have accurate gas costs to avoid energy attacks on nodes.

to this end, i have wrapped the underlying uint256 lib with gas accumulation (https://github.com/1m1-github/go-ethereum-plus/blob/main/core/vm/uint256_wrapped.go). this gives a bottom-up approach to calculating gas, by running the OPCODE.

because the EVM interprator expects the gas cost before actually running the OPCODE, we are running the OPCODE twice. the first run, identical to the second, is to get the bottom-up gas cost, which is then doubled to account for the actual run plus the gas calculation. on top, we add a fixed emulation cost.

this gives an embedded gas calcuation, which works well for complex OPCODEs (see gasEVMPlusEmulate in https://github.com/1m1-github/go-ethereum-plus/blob/main/core/vm/gas_table.go).

to remove the double gas, a future EIP would suggest the following: allow contract code to run whilst accumulating gas (at runtime) and panicking in case of limit breach, without requiring the cost in advance. this only works for contract code that is local, defined as code that only depends on the user input and the inner bytecode of the contract. local contracts cannot use state from the chain, nor make calls to other contracts. pure mathematical functions would e.g. be local contracts. local contracts are fully deterministic given the input, allowing a user to estimate gas costs offline (cheaper) and the EVM to panic at runtime, without knowing gas in advance.

since the costs depend on the input, a fuzzing would give us close to the worst cases (TODO).

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

../assets/eip-EVM+/decimal_fixed_test.go

## Reference Implementation

The following is a view of the complete and functional implementation in golang:
https://github.com/ethereum/go-ethereum/compare/master...1m1-github:go-ethereum-plus:main
The main file is: core/vm/decimal_fixed.go

If the community likes this EIP by trying it out using the above implementation, I could then formalize the "Reference Implementation" abstractly for other clients to follow.

## Security Considerations

There are no security considerations, as long as numerical correctness is guaranteed and gas is collected fairly.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
