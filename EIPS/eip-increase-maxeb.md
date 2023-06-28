---
eip: 7045
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

***Consensus layer changes***

See https://github.com/michaelneuder/consensus-specs/pull/3/files for a diff
view of the CL spec changes. Changes are also copied below for convenience.

### Constants

| Name | Value |
| - | - |
| `COMPOUNDING_WITHDRAWAL_PREFIX` | `Bytes1('0x02')` |
| `MIN_ACTIVATION_BALANCE` | `Gwei(2**5 * 10**9)`  (32 ETH) |
| `MAX_EFFECTIVE_BALANCE_MAXEB` | `Gwei(2**11 * 10**9)` (2048 ETH) |

### Containers

#### New containers

```python
class PendingBalanceDeposit(Container):
    index: ValidatorIndex
    amount: Gwei
```

#### Extended containers

```python
class BeaconState(Container):
    ...
    deposit_validator_balance: Gwei
    exit_queue_churn:          Gwei
    pending_balance_deposits:  List[PendingBalanceDeposit]
```

### Helpers

#### Predicates

```python
def is_eligible_for_activation_queue(validator: Validator) -> bool:
    """
    Check if ``validator`` is eligible to be placed into the activation queue.
    """
    return (
        validator.activation_eligibility_epoch == FAR_FUTURE_EPOCH
        # --- MODIFIED --- #
        and validator.effective_balance >= MIN_ACTIVATION_BALANCE
        # --- END MODIFIED --- #
    )
```

```python
def has_compounding_withdrawal_credential(validator: Validator) -> bool:
    """
    Check if ``validator`` has an 0x02 prefixed "compounding" withdrawal credential.
    """
    return validator.withdrawal_credentials[:1] == COMPOUNDING_WITHDRAWAL_PREFIX
```

```python
def is_fully_withdrawable_validator(validator: Validator, balance: Gwei, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is fully withdrawable.
    """
    return (
        # --- MODIFIED --- #
        (has_eth1_withdrawal_credential(validator) or has_compounding_withdrawal_credential(validator))
        # --- END MODIFIED --- #
        and validator.withdrawable_epoch <= epoch
        and balance > 0
    )
```

```python
def get_validator_excess_balance(validator: Validator, balance: Gwei) -> Gwei:
    """
    Get excess balance for partial withdrawals for ``validator``.
    """
    if has_compounding_withdrawal_credential(validator) and balance > MAX_EFFECTIVE_BALANCE:
        return balance - MAX_EFFECTIVE_BALANCE
    elif has_eth1_withdrawal_credential(validator) and balance > MIN_ACTIVATION_BALANCE:
        return balance - MIN_ACTIVATION_BALANCE
    return Gwei(0)
```

```python
def is_partially_withdrawable_validator(validator: Validator, balance: Gwei) -> bool:
    """
    Check if ``validator`` is partially withdrawable.
    """
    # --- MODIFIED --- #
    return get_validator_excess_balance(validator, balance) > 0
    # --- END MODIFIED --- #
```

#### Beacon state accessors

```python
def get_validator_churn_limit(state: BeaconState) -> Gwei:
    churn = max(config.MIN_PER_EPOCH_CHURN_LIMIT * MIN_ACTIVATION_BALANCE, get_total_active_balance(state) // config.CHURN_LIMIT_QUOTIENT)
    return churn - churn % EFFECTIVE_BALANCE_INCREMENT
```

#### Beacon state mutators

```python
def initiate_validator_exit(state: BeaconState, index: ValidatorIndex) -> None:
    """
    Initiate the exit of the validator with index ``index``.
    """
    ...
    # Compute exit queue epoch
    exit_epochs = [v.exit_epoch for v in state.validators if v.exit_epoch != FAR_FUTURE_EPOCH]
    exit_queue_epoch = max(exit_epochs + [compute_activation_exit_epoch(get_current_epoch(state))])
    # --- MODIFIED --- #
    exit_balance_to_consume = validator.effective_balance
    per_epoch_churn_limit = get_validator_churn_limit(state)
    if state.exit_queue_churn + exit_balance_to_consume <= per_epoch_churn_limit:
        state.exit_queue_churn += exit_balance_to_consume
    else:  # Exit balance rolls over to subsequent epoch(s)
        exit_balance_to_consume -= (per_epoch_churn_limit - state.exit_queue_churn)
        additional_epochs, state.exit_queue_churn = divmod(exit_balance_to_consume - (per_epoch_churn_limit - state.exit_queue_churn), per_epoch_churn_limit)
        exit_queue_epoch += Epoch(additional_epochs + 1)
    # --- END MODIFIED --- #

    # Set validator exit epoch and withdrawable epoch
    validator.exit_epoch = exit_queue_epoch
    validator.withdrawable_epoch = Epoch(validator.exit_epoch + MIN_VALIDATOR_WITHDRAWABILITY_DELAY)
```

### Genesis

```python
def initialize_beacon_state_from_eth1(eth1_block_hash: Hash32,
                                      eth1_timestamp: uint64,
                                      deposits: Sequence[Deposit]) -> BeaconState:
    ...
        # --- MODIFIED --- #
        if validator.effective_balance >= MIN_ACTIVATION_BALANCE: 
            validator.activation_eligibility_epoch = GENESIS_EPOCH
            validator.activation_epoch = GENESIS_EPOCH
        # --- END MODIFIED --- #
    # Set genesis validators root for domain separation and chain versioning
    state.genesis_validators_root = hash_tree_root(state.validators)
    return state
```

### Beacon chain state transition function 

#### Epoch processing

```python
def process_epoch(state: BeaconState) -> None:
    ...
    process_eth1_data_reset(state)
    # --- MODIFIED --- #
    process_pending_balance_deposits(state)
    # --- END MODIFIED --- #
    ...
```

```python
def process_registry_updates(state: BeaconState) -> None:
    ...
    # Dequeue validators for activation up to churn limit [MODIFIED TO BE WEIGHT-SENSITIVE]
    # --- MODIFIED --- #
    activation_balance_to_consume = get_validator_churn_limit(state)
    for index in activation_queue:
        validator = state.validators[index]
        # Validator can now be activated
        if state.activation_validator_balance + activation_balance_to_consume >= validator.effective_balance:
            activation_balance_to_consume -= (validator.effective_balance - state.activation_validator_balance)
            state.activation_validator_balance = Gwei(0)
            validator.activation_epoch = compute_activation_exit_epoch(get_current_epoch(state))
        else:  
            state.activation_validator_balance += activation_balance_to_consume
            break
    # --- END MODIFIED --- #
```

```python
def process_pending_balance_deposits(state: BeaconState) -> None:
    deposit_balance_to_consume = get_validator_churn_limit(state)
    next_pending_deposit_index = 0
    for pending_balance_deposit in state.pending_balance_deposits:
        if state.deposit_validator_balance + deposit_balance_to_consume >= pending_balance_deposit.amount:
            deposit_balance_to_consume -= pending_balance_deposit.amount - state.deposit_validator_balance
            state.deposit_validator_balance = Gwei(0)
            increase_balance(state, pending_balance_deposit.index, pending_balance_deposit.amount)
            next_pending_deposit_index += 1
        else:
            state.deposit_validator_balance += deposit_balance_to_consume
            break
    state.pending_balance_deposits = state.pending_balance_deposits[next_pending_deposit_index:]
```

#### Block Processing

```python
def get_expected_withdrawals(state: BeaconState) -> Sequence[Withdrawal]:
    ...
    for _ in range(bound):
        ...
        elif is_partially_withdrawable_validator(validator, balance):
            withdrawals.append(Withdrawal(
                index=withdrawal_index,
                validator_index=validator_index,
                address=ExecutionAddress(validator.withdrawal_credentials[12:]),
                # --- MODIFIED --- #
                amount=get_validator_excess_balance(validator, balance),
                # --- END MODIFIED --- #
            ))
        ... 
    return withdrawals
```

```python
def apply_deposit(state: BeaconState,
                  pubkey: BLSPubkey,
                  withdrawal_credentials: Bytes32,
                  amount: uint64,
                  signature: BLSSignature) -> None:
    validator_pubkeys = [v.pubkey for v in state.validators]
    # --- MODIFIED --- #
    if pubkey not in validator_pubkeys:
        ...
        if bls.Verify(pubkey, signing_root, signature):
            state.validators.append(get_validator_from_deposit(pubkey, withdrawal_credentials))
            state.balances.append(0)
        ...
    else:
        # Increase balance by deposit amount, up to MIN_ACTIVATION_BALANCE
        index = ValidatorIndex(validator_pubkeys.index(pubkey))
    state.pending_balance_deposits.append(PendingBalanceDeposit(index, amount))
    # --- END MODIFIED --- #
```

```python
def get_validator_from_deposit(pubkey: BLSPubkey, withdrawal_credentials: Bytes32) -> Validator:
    return Validator(
        pubkey=pubkey,
        withdrawal_credentials=withdrawal_credentials,
        activation_eligibility_epoch=FAR_FUTURE_EPOCH,
        activation_epoch=FAR_FUTURE_EPOCH,
        exit_epoch=FAR_FUTURE_EPOCH,
        withdrawable_epoch=FAR_FUTURE_EPOCH,
        # --- MODIFIED --- #
        effective_balance=0,
        # --- END MODIFIED --- #
    )
```

```python
def is_aggregator(state: BeaconState, slot: Slot, index: CommitteeIndex, validator_index: ValidatorIndex, slot_signature: BLSSignature) -> bool:
    validator = state.validators[validator_index]
    committee = get_beacon_committee(state, slot, index)
    min_balance_increments = validator.effective_balance // MIN_ACTIVATION_BALANCE
    committee_balance = get_total_balance(state, set(committee))
    denominator = committee_balance ** min_balance_increments
    numerator = denominator - (committee_balance -  TARGET_AGGREGATORS_PER_COMMITTEE * MIN_ACTIVATION_BALANCE) ** min_balance_increments
    modulo = denominator // numerator
    return bytes_to_uint64(hash(slot_signature)[0:8]) % modulo == 0
```

## Rationale

See https://notes.ethereum.org/@mikeneuder/maxeb-status for current status and
design goals.

### Features

1. **`0x02` withdrawal credential signals compounding.** These validators will be excluded from the partial withdrawals sweep and their balance compounds.
2. **Limiting the penalty of proposer equivocations.** Proposer equivocations should not be proportional to the weight of the proposer, even if attesting equivocations are.
3. **Allow topups past 32 ETH.** These need to be rate limited. 
4. (Optional) **Changes to validator behavior being be opt-in.** I.e., validators who don't change anything still have the 32 ETH partial withdrawal sweep.
5. (Optional) **Allow validators to consolidate without exiting.** Combine validator indices without exiting. This is a massive UX benefit. 

### Change log

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

### Optional, in-discussion features

1. EL initiated partial withdrawals (we propose to include this in [EIP-7002](https://ethereum-magicians.org/t/eip-7002-execution-layer-triggerable-exits/14195)).
2. Allow validators to consolidate without exiting.
3. Remove the partial withdrawal sweep all together (making compounding the default option).
4. Rethink ejection balance (perhaps by reusing the `activation_eligibility_epoch` field in the validator struct). 
5. Allow validators to use the withdrawal credentials to specify a custom ceiling for their balance.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

See https://notes.ethereum.org/@fradamt/meb-increase-security for full analysis
of the security considerations surrounding this change.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).