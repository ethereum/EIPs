Allow an address to replay a contract deploy if it is the same contract, and
if the contract that was there before has been killed. Intended to fix
the latest Parity hack, which I guess is in some way a DDoS.


## Preamble

    EIP: <to be assigned>
    Title: Allow redeploy of the same contract
    Author: Brian Wheeler <bwheeler96@gmail.com>
    Type: Standard Track
    Category Core
    Status: Draft
    Created: 2017-11-07

## Simple Summary
Disclaimer: I hardly know what I'm talking about

An address might be allowed to redeploy the exact same contract
to the same address as a safeguard against contracts that were accidentally killed.

## Abstract
The parity wallet was hacked and access to funds is locked because a library function
that was designed to terminate the wallet was used to kill the library itself.

## Motivation
Create a mechanism for affected Parity wallets to recover funds.

## Specification
Allow a contract to be restored by allowing the original creator of the contract
to redeploy the contract using the same nonce, only if the contract code is the same
code that was previously deployed, and the contract has been killed.

Previously stated, I'm not versed on 100% of the details, but it looks
like these checks could allow for a safe recovery of Parity funds.

## Rationale

## Backwards Compatibility
There are a lot of security considerations to consider, mainly preventing
a malicious user from defrauding a particular contract. I'm not sure that
this issue is solveable in a proveable manner, and it absolutely needs to be
for this type of a patch to work.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
