---
title: Increase the MAX_EFFECTIVE_BALANCE
description: Allow validators to have larger effective balances, while maintaining the 32 ETH lower bound.
author: Mike (@michaelneuder), Francesco (@fradamt), dapplion (@dapplion), Mikhail (@mkalinin), Aditya (@adiasg), Justin (@justindrake)
discussions-to: https://ethresear.ch/t/increase-the-max-effective-balance-a-modest-proposal/15801
status: Draft
type: Standards Track
category: Core
created: 2023-06-28
requires: 7002
---

## Abstract

Increases the CL constant `MAX_EFFECTIVE_BALANCE` to 2048 ETH. This allows
home-stakers to earn compounding rewards on their ETH and large staking 
operators to run fewer validators for the same amount of stake. 

## Motivation

The current `MAX_EFFECTIVE_BALANCE` of 32 ETH is tech debt from the original
sharding design, where we required majority honest subcommittees. This is no
longer a requirement, as subcommittes are only used for attestation aggregation,
and thus have a `1/N` honesty assumption. The current 32 ETH max results in an
artificially large validator set, where staking operators run thousands of
essentially redundant validators many of which from the same CL node. 

The large and rapidly growing validator set puts an [unnecessary burden](https://ethresear.ch/t/removing-unnecessary-stress-from-ethereums-p2p-network/15547)
on the p2p network and blocks critical protocol upgrades such as [SSF](https://ethresear.ch/t/a-simple-single-slot-finality-protocol/14920). See [a modest proposal](https://ethresear.ch/t/increase-the-max-effective-balance-a-modest-proposal/15801) for more context.

## Specification

### Constants

| Name | Value |
| - | - |
| `COMPOUNDING_WITHDRAWAL_PREFIX` | `Bytes1('0x02')` |
| `MIN_ACTIVATION_BALANCE` | `Gwei(2**5 * 10**9)`  (32 ETH) |
| `MAX_EFFECTIVE_BALANCE_MAXEB` | `Gwei(2**11 * 10**9)` (2048 ETH) |

### Execution layer

This requires no changes to the Execution Layer.

### Consensus layer

See https://github.com/michaelneuder/consensus-specs/pull/3/files for a diff
view of the CL spec changes. In summary

1. Add `COMPOUNDING_WITHDRAW_PREFIX` and `MIN_ACTIVATION_BALANCE` constants, while updating the value of `MAX_EFFECTIVE_BALANCE`.
2. Create the `PendingDeposit` container, which is used to track incoming deposits in the weight-based rate limiting mechanism.
3. Update beacon state with fields needed for deposit and exit queue weight-based rate limiting.
4. Modify `is_eligible_for_activation_queue` to check against `MIN_ACTIVATION_BALANCE` rather than `MAX_EFFECTIVE_BALANCE`.
5. Modify `get_validator_churn_limit` to be weight-based rather than validator count based.
6. Modify `initiate_validator_exit` to rate limit the exit queue by balance rather than number of vaidators.
7. Modify `initialize_beacon_state_from_eth1` to use `MIN_ACTIVATION_BALANCE`.
8. Add `process_pending_balance_deposits` to epoch processing logic.
9. Modify `process_registry_updates` to activate all eligible validators.
10. Modify `get_validator_from_deposit` to initialize effective balance to zero (its updated by the pending deposit flow).
11. Modify `apply_deposit` to store incoming deposits in `state.pending_balance_deposits`. 
12. Modify `is_aggregator` to be weight-based.
13. Modify `compute_weak_subjectivity_period` to use new churn limit function.
14. Add `has_compounding_withdrawal_credential` to check for `0x02` credential.
15. Modify `is_fully_withdrawalable_validator` to check for compounding credentials.
16. Add `get_validator_excess_balance` to calculate the excess balance of validators.
17. Modify `is_partially_withdrawable_validator` to check for excess balance.
18. Modify `get_expected_withdrawals` to use excess balance.

### Features

1. **`0x02` withdrawal credential signals compounding.** These validators will be excluded from the partial withdrawals sweep and their balance compounds (may be unnecessary if we use EL-initiated partial withdrawals and want to turn the sweep off entirely).
2. **Limiting the penalty of proposer equivocations.** Proposer equivocations should not be proportional to the weight of the proposer, even if attesting equivocations are.


### Optional, in-discussion features

1. **EL initiated partial withdrawals** (we propose to include this in [EIP-7002](https://ethereum-magicians.org/t/eip-7002-execution-layer-triggerable-exits/14195)).
2. **Allow validators to consolidate without exiting.** Combine validator indices without exiting. This is a massive UX benefit. 
2. **Changes to validator behavior being be opt-in.** i.e., validators who don't change anything still have the 32 ETH partial withdrawal sweep.
3. **Remove the partial withdrawal sweep all together** (making compounding the default option).
4. **Rethink ejection balance** (perhaps by reusing the `activation_eligibility_epoch` field in the validator struct). 
5. **Allow validators to use the withdrawal credentials to specify a custom ceiling for their balance.** Partial withdrawals would kick in past the custom ceiling.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

See https://notes.ethereum.org/@fradamt/meb-increase-security for full analysis
of the security considerations surrounding this change.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).