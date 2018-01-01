## Preamble

    EIP: <to be assigned>
    Title: PoS blockhash backward compatibility
    Author: Beether
    Type: Standard Track
    Category: Core
    Status: Draft
    Created: 2018-01-01
    Requires (*optional): <EIP number(s)>
    Replaces (*optional): <EIP number(s)>


## Simple Summary
In PoS, each block's `blockhash` changes from being an economically staked random number to being a value determined by a particular validator with only computational constraints (eg: not `0x0`). Thus, the assumptions of when and how to use `blockhash` will change from PoW to PoS. What was _tolerable_ or _benign_ before, is now potentially _catastrophic_.

In short, there is a signficant difference between `Miners can manipulate the blockhash if there is a financial gain to be made.` and `Miners can manipulate the blockhash.`


To preserve compatibility and expectations of `blockhash` from PoW to PoS, this EIP advises replacing PoS's `blockhash` with a similarly economically staked value; or, at the very least, exposing a new value named `block.entropyhash`.

## Abstract
In PoW, the `blockhash` is not knowable by a miner before first successfully hashing the block, which carries an economic cost. In this sense `blockhash` is used by contracts as a randomly distributed number under the assumption there must be some **_minimum_ economic incentive** required to exploit it.

In PoS, the `blockhash` is not a source of entropy at all; a validator can submit a block whose `blockhash` results in any desired outcomes, with _zero_ cost. In this sense, `blockhash` can now be exploited by validators provided there is **_any_ economic incentive.**

In PoW, the economic incentive to coerce `blockhash` had to be about `block reward - uncle reward`, in PoS, it merely needs to be `>0`. 

Some example cases in PoW that are now vulnerable in PoS:

 - Using `blockhash`, or any derivation of it, as a randomly distributed number for benign purposes; eg, distributing items into buckets.
 - Using `blockhash`, or any derivation of it, to determine outcomes that had a very small amount of Ether associated with it.

## Motivation
There are three main motivations for providing an economically staked randomly distributed number:

 - Preserve backward compatibility with PoW, which does provide such a number in the form of `blockhash`
 - Prevent validators from wreaking havoc on anything that currently uses `blockhash` in any form.
 - Provide a sanctioned value with clear specifications about when and how it can be used.

## Specification
Let `entropyhash` for a particuar `blockheight` be a value unknown to any validator before their block and vote are cast.  This ensures a validator has to commit to their _possibly-malicious-transactions_ before knowing what the results will be.

I'm not a PoS expert, so I don't know how exactly to generate `entropyhash`, but it seems that hashing `data-used-to-pick-winning-validator` is what we're after. No validator shoud know this ahead of time, and the result of this value should have an economic stake behind it.

Next, do either:

 1) take the winning block and replace the value of `blockhash` with `entropyhash`.
 
 2) If (1) is infeasible or inadvisible, append an additional field to the block called `entropyhash`, and make it available in the EVM to contracts.

## Rationale
The economically staked random number, which in PoW is `blockhash`, should be made available in PoS as well. Whether or not it should replace `blockhash` or be a new field is beyond my expertise.

## Backwards Compatibility


## Test Cases


## Implementation


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
