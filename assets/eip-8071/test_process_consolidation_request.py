from eth2spec.test.context import (
    default_activation_threshold,
    scaled_churn_balances_exceed_activation_exit_churn_limit,
    single_phase,
    spec_state_test,
    spec_test,
    with_custom_state,
    with_electra_and_later,
    with_presets,
)
from eth2spec.test.helpers.constants import MINIMAL
from eth2spec.test.helpers.withdrawals import (
    set_compounding_withdrawal_credential,
    set_compounding_withdrawal_credential_with_balance,
    set_eth1_withdrawal_credential_with_balance,
)

#  ***********************
#  * CONSOLIDATION TESTS *
#  ***********************


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_in_current_consolidation_epoch(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set earliest consolidation epoch to the expected exit epoch
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    state.earliest_consolidation_epoch = expected_exit_epoch
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    # Set the consolidation balance to consume equal to churn limit
    state.consolidation_balance_to_consume = consolidation_churn_limit

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check consolidation churn is decremented correctly
    assert (
        state.consolidation_balance_to_consume
        == consolidation_churn_limit - spec.MIN_ACTIVATION_BALANCE
    )
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_with_excess_target_balance(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set earliest consolidation epoch to the expected exit epoch
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    state.earliest_consolidation_epoch = expected_exit_epoch
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    # Set the consolidation balance to consume equal to churn limit
    state.consolidation_balance_to_consume = consolidation_churn_limit

    # Add excess balance
    state.balances[target_index] = state.balances[target_index] + spec.EFFECTIVE_BALANCE_INCREMENT

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check consolidation churn is decremented correctly
    assert (
        state.consolidation_balance_to_consume
        == consolidation_churn_limit - spec.MIN_ACTIVATION_BALANCE
    )
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_in_new_consolidation_epoch(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    # Set consolidation balance to consume to some arbitrary nonzero value below the churn limit
    state.consolidation_balance_to_consume = spec.EFFECTIVE_BALANCE_INCREMENT
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    yield from run_consolidation_processing(spec, state, consolidation)

    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    # Check consolidation churn is decremented correctly
    # consolidation_balance_to_consume is replenished to the churn limit since we move to a new consolidation epoch
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    assert (
        state.consolidation_balance_to_consume
        == consolidation_churn_limit - spec.MIN_ACTIVATION_BALANCE
    )
    # Check exit epochs
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_with_preexisting_churn(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set earliest consolidation epoch to the expected exit epoch
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    state.earliest_consolidation_epoch = expected_exit_epoch
    # Set some nonzero preexisting churn lower than churn limit and sufficient to process the consolidation
    preexisting_churn = 2 * spec.MIN_ACTIVATION_BALANCE
    state.consolidation_balance_to_consume = preexisting_churn

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check consolidation churn is decremented correctly
    assert state.consolidation_balance_to_consume == preexisting_churn - spec.MIN_ACTIVATION_BALANCE
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_with_insufficient_preexisting_churn(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set earliest consolidation epoch to the first available epoch
    state.earliest_consolidation_epoch = spec.compute_activation_exit_epoch(current_epoch)
    # Set preexisting churn lower than required to process the consolidation
    preexisting_churn = spec.MIN_ACTIVATION_BALANCE - spec.EFFECTIVE_BALANCE_INCREMENT
    state.consolidation_balance_to_consume = preexisting_churn

    yield from run_consolidation_processing(spec, state, consolidation)

    # It takes one more epoch to process the consolidation due to insufficient churn
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch) + 1
    # Check consolidation churn is decremented correctly
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    remainder = spec.MIN_ACTIVATION_BALANCE % preexisting_churn
    assert state.consolidation_balance_to_consume == consolidation_churn_limit - remainder
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_with_compounding_credentials(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to compounding credentials
    source_address = b"\x22" * 20
    set_compounding_withdrawal_credential(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set the consolidation balance to consume equal to churn limit
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    state.consolidation_balance_to_consume = consolidation_churn_limit

    yield from run_consolidation_processing(spec, state, consolidation)

    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    # Check consolidation churn is decremented correctly
    assert (
        state.consolidation_balance_to_consume
        == consolidation_churn_limit - spec.MIN_ACTIVATION_BALANCE
    )
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_consolidation_churn_limit_balance(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set source effective balance to consolidation churn limit
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    state.validators[source_index].effective_balance = consolidation_churn_limit
    # Churn limit increases due to higher total balance
    updated_consolidation_churn_limit = spec.get_consolidation_churn_limit(state)

    yield from run_consolidation_processing(spec, state, consolidation)

    # validator's effective balance fits into the churn, exit as soon as possible
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    # Check consolidation churn is decremented correctly
    assert (
        state.consolidation_balance_to_consume
        == updated_consolidation_churn_limit - consolidation_churn_limit
    )
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_source_has_less_than_max_effective_balance(spec, state):
    # Move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH

    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)

    # Lower the source validator's effective balance
    source_effective_balance = spec.MAX_EFFECTIVE_BALANCE - spec.EFFECTIVE_BALANCE_INCREMENT
    state.validators[source_index].effective_balance = source_effective_balance

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set earliest consolidation epoch to the expected exit epoch
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    state.earliest_consolidation_epoch = expected_exit_epoch
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    # Set the consolidation balance to consume equal to churn limit
    state.consolidation_balance_to_consume = consolidation_churn_limit

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check consolidation churn is decremented correctly
    assert (
        state.consolidation_balance_to_consume
        == consolidation_churn_limit - source_effective_balance
    )
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_basic_consolidation_target_has_less_than_min_activation_effective_balance(spec, state):
    # Move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH

    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)

    # Lower the target validator's effective balance
    # This shouldn't prevent the consolidation from happening
    target_effective_balance = spec.MIN_ACTIVATION_BALANCE - spec.EFFECTIVE_BALANCE_INCREMENT
    state.validators[target_index].effective_balance = target_effective_balance

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set earliest consolidation epoch to the expected exit epoch
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch)
    state.earliest_consolidation_epoch = expected_exit_epoch
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    # Set the consolidation balance to consume equal to churn limit
    state.consolidation_balance_to_consume = consolidation_churn_limit

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_consolidation_balance_larger_than_churn_limit(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set source effective balance to 2 * consolidation churn limit
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    state.validators[source_index].effective_balance = 2 * consolidation_churn_limit

    # Consolidation churn limit increases due to higher total balance
    updated_consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    remainder = state.validators[source_index].effective_balance % updated_consolidation_churn_limit
    expected_balance = updated_consolidation_churn_limit - remainder

    yield from run_consolidation_processing(spec, state, consolidation)

    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch) + 1
    # Check consolidation churn is decremented correctly
    assert state.consolidation_balance_to_consume == expected_balance
    # Check exit epoch
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_consolidation_balance_through_two_churn_epochs(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set source balance higher to 3 * consolidation churn limit
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    state.validators[source_index].effective_balance = 3 * consolidation_churn_limit

    new_churn_limit = spec.get_consolidation_churn_limit(state)
    remainder = state.validators[source_index].effective_balance % new_churn_limit
    expected_balance = new_churn_limit - remainder

    yield from run_consolidation_processing(spec, state, consolidation)

    # when exiting a multiple of the churn limit greater than 1, an extra exit epoch is added
    expected_exit_epoch = spec.compute_activation_exit_epoch(current_epoch) + 2
    assert state.validators[0].exit_epoch == expected_exit_epoch
    # since the earliest exit epoch moves to a new one, consolidation balance is back to full
    assert state.consolidation_balance_to_consume == expected_balance


@with_electra_and_later
@spec_state_test
def test_basic_switch_to_compounding(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation from source to source
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=True)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_with_excess(spec, state):
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Add excess balance
    state.balances[source_index] = state.balances[source_index] + spec.EFFECTIVE_BALANCE_INCREMENT
    # Make consolidation from source to source
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=True)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_with_pending_consolidations_at_limit(spec, state):
    state.pending_consolidations = [
        spec.PendingConsolidation(source_index=0, target_index=1)
    ] * spec.PENDING_CONSOLIDATIONS_LIMIT

    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]

    # Set source to eth1 credentials
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Add excess balance
    state.balances[source_index] = state.balances[source_index] + spec.EFFECTIVE_BALANCE_INCREMENT
    # Make consolidation from source to source
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=True)


# Tests that should fail


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_same_source_target(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH

    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    # Set source and target to be the same
    target_index = source_index
    source_address = b"\x22" * 20
    # Make source/target a compounding validator (0x02) so this request isn't a
    # valid switch to compounding request. To be a valid switch to compounding
    # request, the source validator must be an eth1 validator (0x01).
    set_compounding_withdrawal_credential_with_balance(
        spec, state, target_index, address=source_address
    )
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_exceed_pending_consolidations_limit(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH

    state.pending_consolidations = [
        spec.PendingConsolidation(source_index=0, target_index=1)
    ] * spec.PENDING_CONSOLIDATIONS_LIMIT

    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the the return condition
    assert len(state.pending_consolidations) == spec.PENDING_CONSOLIDATIONS_LIMIT

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
@single_phase
def test_incorrect_not_enough_consolidation_churn_available(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH

    state.pending_consolidations = [spec.PendingConsolidation(source_index=0, target_index=1)]

    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the the return condition
    assert spec.get_consolidation_churn_limit(state) <= spec.MIN_ACTIVATION_BALANCE

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_exited_source(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # exit source
    spec.initiate_validator_exit(state, source_index)

    # Check the the return condition
    assert state.validators[source_index].exit_epoch != spec.FAR_FUTURE_EPOCH

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_exited_target(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)
    # exit target
    spec.initiate_validator_exit(state, 1)

    # Check the the return condition
    assert state.validators[target_index].exit_epoch != spec.FAR_FUTURE_EPOCH

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_inactive_source(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # set source validator as not yet activated
    state.validators[source_index].activation_epoch = spec.FAR_FUTURE_EPOCH

    # Check the the return condition
    assert not spec.is_active_validator(state.validators[source_index], current_epoch)

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_inactive_target(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # set target validator as not yet activated
    state.validators[1].activation_epoch = spec.FAR_FUTURE_EPOCH

    # Check the the return condition
    assert not spec.is_active_validator(state.validators[target_index], current_epoch)

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_no_source_execution_withdrawal_credential(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up a correct consolidation, but source does not have
    # an execution withdrawal credential
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the the return condition
    assert not spec.has_execution_withdrawal_credential(state.validators[source_index])

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_target_with_bls_credential(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up a correct consolidation, but target does not have
    # an execution withdrawal credential
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Check the the return condition
    assert not spec.has_execution_withdrawal_credential(state.validators[target_index])

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_source_with_bls_credential(spec, state):
    # Move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH

    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Ensure that the source validator has BLS-type withdrawal credentials
    assert state.validators[source_index].withdrawal_credentials[:1] == spec.BLS_WITHDRAWAL_PREFIX

    # An attacker could create a new validator with BLS withdrawal credentials where the last twenty
    # bytes of the BLS pubkey are hardcoded to an address that they control. To be clear, the source
    # address field in consolidation requests cannot be set to an arbitrary value.
    source_address = state.validators[source_index].withdrawal_credentials[-20:]

    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_target_with_eth1_credential(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to eth1 credentials
    set_eth1_withdrawal_credential_with_balance(spec, state, target_index)

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_source_address(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with different source address
    consolidation = spec.ConsolidationRequest(
        source_address=b"\x33" * 20,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the the return condition
    assert (
        not state.validators[source_index].withdrawal_credentials[12:]
        == consolidation.source_address
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_source_pubkey_is_target_pubkey(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with different source pubkey
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        # Use the target's pubkey instead
        source_pubkey=state.validators[target_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)
    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_unknown_source_pubkey(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with different source pubkey
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=b"\x00" * 48,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the the return condition
    assert not state.validators[source_index].pubkey == consolidation.source_pubkey

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_unknown_target_pubkey(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with different target pubkey
    consolidation = spec.ConsolidationRequest(
        source_address=b"\x33" * 20,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=b"\x00" * 48,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the return condition
    assert not state.validators[target_index].pubkey == consolidation.target_pubkey

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_source_has_pending_withdrawal(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    excess_balance = spec.EFFECTIVE_BALANCE_INCREMENT // 4
    set_eth1_withdrawal_credential_with_balance(
        spec,
        state,
        source_index,
        address=source_address,
        effective_balance=spec.MIN_ACTIVATION_BALANCE,
        balance=spec.MIN_ACTIVATION_BALANCE + excess_balance,
    )
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Create pending withdrawal
    pending_withdrawal = spec.PendingPartialWithdrawal(
        validator_index=0, amount=excess_balance, withdrawable_epoch=current_epoch
    )
    state.pending_partial_withdrawals.append(pending_withdrawal)

    # Check the return condition
    assert spec.get_pending_balance_to_withdraw(state, source_index) > 0

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_incorrect_source_not_active_long_enough(spec, state):
    # Set up an otherwise correct consolidation
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    source_address = b"\x22" * 20
    excess_balance = spec.EFFECTIVE_BALANCE_INCREMENT // 4
    set_eth1_withdrawal_credential_with_balance(
        spec,
        state,
        source_index,
        address=source_address,
        effective_balance=spec.MIN_ACTIVATION_BALANCE,
        balance=spec.MIN_ACTIVATION_BALANCE + excess_balance,
    )
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )
    set_compounding_withdrawal_credential_with_balance(spec, state, target_index)

    # Check the return condition
    assert (
        current_epoch
        < state.validators[source_index].activation_epoch + spec.config.SHARD_COMMITTEE_PERIOD
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_exited_source(spec, state):
    # Set up an otherwise correct request
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    # Initiate exit for source
    spec.initiate_validator_exit(state, source_index)

    # Check the return condition
    assert state.validators[source_index].exit_epoch != spec.FAR_FUTURE_EPOCH

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_inactive_source(spec, state):
    # Set up an otherwise correct request
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    # Set source validator as not yet activated
    state.validators[source_index].activation_epoch = spec.FAR_FUTURE_EPOCH

    # Check the the return condition
    assert not spec.is_active_validator(state.validators[source_index], current_epoch)

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_source_bls_withdrawal_credential(spec, state):
    # Set up a correct request, but source does have
    # a bls withdrawal credential
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    consolidation = spec.ConsolidationRequest(
        source_address=state.validators[source_index].withdrawal_credentials[12:],
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    # Check the the return condition
    assert not spec.has_eth1_withdrawal_credential(state.validators[source_index])

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_source_compounding_withdrawal_credential(spec, state):
    # Set up a correct request, but source does have
    # a compounding withdrawal credential and excess balance
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    source_address = b"\x22" * 20
    set_compounding_withdrawal_credential(spec, state, source_index, address=source_address)
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )
    state.balances[source_index] = spec.MIN_ACTIVATION_BALANCE + spec.EFFECTIVE_BALANCE_INCREMENT

    # Check the the return condition
    assert not spec.has_eth1_withdrawal_credential(state.validators[source_index])

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_not_authorized(spec, state):
    # Set up an otherwise correct request
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make request with different source address
    consolidation = spec.ConsolidationRequest(
        source_address=b"\x33" * 20,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[source_index].pubkey,
    )

    # Check the the return condition
    assert (
        not state.validators[source_index].withdrawal_credentials[12:]
        == consolidation.source_address
    )

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@spec_state_test
def test_switch_to_compounding_unknown_source_pubkey(spec, state):
    # Set up an otherwise correct request
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    source_address = b"\x22" * 20
    set_eth1_withdrawal_credential_with_balance(spec, state, source_index, address=source_address)
    # Make consolidation with different source pubkey
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=b"\x00" * 48,
        target_pubkey=b"\x00" * 48,
    )

    # Check the the return condition
    assert not state.validators[source_index].pubkey == consolidation.source_pubkey

    yield from run_switch_to_compounding_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_single_consolidation_request_at_max_eb(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set source to compounding credentials with max_eb
    source_address = b"\x22" * 20
    source_balance = spec.MAX_EFFECTIVE_BALANCE_ELECTRA-state.balances[target_index]
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, balance=source_balance, address=source_address)

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Add pending consolidation from a another source to another target
    another_source_address = b"\x42" * 20
    another_source_index = spec.get_active_validator_indices(state, current_epoch)[2]
    another_target_index = spec.get_active_validator_indices(state, current_epoch)[3]
    set_eth1_withdrawal_credential_with_balance(spec, state, another_source_index, address=another_source_address)
    another_pending_consolidation = spec.PendingConsolidation(
        source_index = another_source_index,
        target_index = another_target_index
    )
    state.pending_consolidations.append(another_pending_consolidation)

    # Set earliest consolidation epoch to the expected exit epoch
    state.earliest_consolidation_epoch = spec.compute_activation_exit_epoch(current_epoch)
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    # Set the consolidation balance to consume equal to churn limit
    state.consolidation_balance_to_consume = consolidation_churn_limit

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check consolidation churn is decremented correctly
    assert (state.consolidation_balance_to_consume ==
        consolidation_churn_limit - source_balance % consolidation_churn_limit)
    # Check exit epoch
    expected_exit_epoch = (
        spec.compute_activation_exit_epoch(current_epoch) + source_balance // consolidation_churn_limit)
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_no_pending_consolidations_exceeding_max_eb(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set the source effective balance to exceed max_eb
    source_address = b"\x22" * 20
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, balance=spec.MAX_EFFECTIVE_BALANCE_ELECTRA, address=source_address)

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_single_pending_consolidation_exceeding_max_eb(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set the source effective balance to exceed max_eb
    source_address = b"\x22" * 20
    source_balance = spec.MAX_EFFECTIVE_BALANCE_ELECTRA-state.balances[target_index]
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, balance=source_balance, address=source_address)

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Add pending consolidation from another source
    another_source_index = spec.get_active_validator_indices(state, current_epoch)[2]
    set_eth1_withdrawal_credential_with_balance(spec, state, another_source_index, address=source_address)
    another_source_pending_consolidation = spec.PendingConsolidation(
        source_index = another_source_index,
        target_index = target_index
    )
    state.pending_consolidations.append(another_source_pending_consolidation)

    # Check the return condition
    assert (
        spec.get_pending_balance_to_consolidate(state, target_index)
        + state.validators[source_index].effective_balance
        + state.balances[target_index] > spec.MAX_EFFECTIVE_BALANCE_ELECTRA
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_multiple_pending_consolidations_at_max_eb(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    second_source_index = spec.get_active_validator_indices(state, current_epoch)[2]

    source_address = b"\x22" * 20

    # Add pending consolidation from the second source
    set_eth1_withdrawal_credential_with_balance(spec, state, second_source_index, address=source_address)
    second_pending_consolidation = spec.PendingConsolidation(
        source_index = second_source_index,
        target_index = target_index
    )

    # Set the first source balance to match the max_eb
    first_source_balance = (
        spec.MAX_EFFECTIVE_BALANCE_ELECTRA
        - state.validators[second_source_index].effective_balance
        - state.balances[target_index]
    )
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, balance=first_source_balance, address=source_address)

    # Make consolidation with the first source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Add pending consolidation from a another source to another target
    another_source_address = b"\x42" * 20
    another_source_index = spec.get_active_validator_indices(state, current_epoch)[3]
    another_target_index = spec.get_active_validator_indices(state, current_epoch)[4]
    set_eth1_withdrawal_credential_with_balance(spec, state, another_source_index, address=another_source_address)
    another_pending_consolidation = spec.PendingConsolidation(
        source_index = another_source_index,
        target_index = another_target_index
    )
    state.pending_consolidations.append(another_pending_consolidation)

    # Set earliest consolidation epoch to the expected exit epoch
    state.earliest_consolidation_epoch = spec.compute_activation_exit_epoch(current_epoch)
    consolidation_churn_limit = spec.get_consolidation_churn_limit(state)
    # Set the consolidation balance to consume equal to churn limit
    state.consolidation_balance_to_consume = consolidation_churn_limit

    yield from run_consolidation_processing(spec, state, consolidation)

    # Check consolidation churn is decremented correctly
    assert (state.consolidation_balance_to_consume ==
        consolidation_churn_limit - first_source_balance % consolidation_churn_limit)
    # Check exit epoch
    expected_exit_epoch = (
        spec.compute_activation_exit_epoch(current_epoch) + first_source_balance // consolidation_churn_limit)
    assert state.validators[source_index].exit_epoch == expected_exit_epoch


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_multiple_pending_consolidations_exceeding_max_eb(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]
    second_source_index = spec.get_active_validator_indices(state, current_epoch)[2]

    source_address = b"\x22" * 20

    # Add pending consolidation from the second source
    set_eth1_withdrawal_credential_with_balance(spec, state, second_source_index, address=source_address)
    second_pending_consolidation = spec.PendingConsolidation(
        source_index = second_source_index,
        target_index = target_index
    )
    state.pending_consolidations.append(second_pending_consolidation)

    # Set the first source balance to match the max_eb
    first_source_balance = (
        spec.MAX_EFFECTIVE_BALANCE_ELECTRA
        - state.validators[second_source_index].effective_balance
        - state.balances[target_index]
        + spec.EFFECTIVE_BALANCE_INCREMENT
    )
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, balance=first_source_balance, address=source_address)

    # Make consolidation with the first source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Add pending consolidation from a another source to another target
    another_source_address = b"\x42" * 20
    another_source_index = spec.get_active_validator_indices(state, current_epoch)[3]
    another_target_index = spec.get_active_validator_indices(state, current_epoch)[4]
    set_eth1_withdrawal_credential_with_balance(spec, state, another_source_index, address=another_source_address)
    another_pending_consolidation = spec.PendingConsolidation(
        source_index = another_source_index,
        target_index = another_target_index
    )
    state.pending_consolidations.append(another_pending_consolidation)

    # Check the return condition
    assert (
        spec.get_pending_balance_to_consolidate(state, target_index)
        + state.validators[source_index].effective_balance
        + state.balances[target_index] > spec.MAX_EFFECTIVE_BALANCE_ELECTRA
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_exceeding_max_eb_with_the_target_balance_but_not_eb(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set the source effective balance to exceed max_eb
    source_address = b"\x22" * 20
    target_effective_balance = spec.get_max_effective_balance(state.validators[target_index])
    source_balance = spec.MAX_EFFECTIVE_BALANCE_ELECTRA - target_effective_balance
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, balance=source_balance, address=source_address)

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials with the balance excess
    set_compounding_withdrawal_credential_with_balance(
        spec, state, target_index,
        effective_balance=target_effective_balance, balance=target_effective_balance+1
    )

    # Check the return condition
    assert (state.validators[source_index].effective_balance + state.balances[target_index]
        > spec.get_max_effective_balance(state.validators[target_index]))
    assert (state.validators[source_index].effective_balance + state.validators[target_index].effective_balance
        <= spec.get_max_effective_balance(state.validators[target_index]))

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_exceeding_max_eb_with_the_source_eb_but_not_the_balance(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    source_index = spec.get_active_validator_indices(state, current_epoch)[0]
    target_index = spec.get_active_validator_indices(state, current_epoch)[1]

    # Set the source effective balance to exceed max_eb
    source_address = b"\x22" * 20
    target_effective_balance = spec.get_max_effective_balance(state.validators[target_index])
    source_balance = spec.MAX_EFFECTIVE_BALANCE_ELECTRA - target_effective_balance
    set_compounding_withdrawal_credential_with_balance(
        spec, state, source_index, effective_balance=source_balance, balance=source_balance-1, address=source_address)

    # Make consolidation with source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Set target to compounding credentials with the balance excess
    set_compounding_withdrawal_credential_with_balance(
        spec, state, target_index,
        effective_balance=target_effective_balance, balance=target_effective_balance+1
    )

    # Check the return condition
    assert (state.validators[source_index].effective_balance + state.balances[target_index]
        > spec.get_max_effective_balance(state.validators[target_index]))
    assert (state.balances[source_index] + state.balances[target_index]
        <= spec.get_max_effective_balance(state.validators[target_index]))

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


@with_electra_and_later
@with_presets([MINIMAL], "need sufficient consolidation churn limit")
@with_custom_state(
    balances_fn=scaled_churn_balances_exceed_activation_exit_churn_limit,
    threshold_fn=default_activation_threshold,
)
@spec_test
@single_phase
def test_multiple_pending_consolidations_exceeding_max_eb_with_the_source_eb_but_not_the_balance(spec, state):
    # move state forward SHARD_COMMITTEE_PERIOD epochs to allow for consolidation
    state.slot += spec.config.SHARD_COMMITTEE_PERIOD * spec.SLOTS_PER_EPOCH
    # This state has 256 validators each with 32 ETH in MINIMAL preset, 128 ETH consolidation churn
    current_epoch = spec.get_current_epoch(state)
    active_indices = spec.get_active_validator_indices(state, current_epoch)
    source_indices = active_indices[:4]
    target_index = active_indices[4]

    # Set target to compounding credentials
    set_compounding_withdrawal_credential(spec, state, target_index)

    # Set sources and their pending consolidations
    source_address = b"\x22" * 20
    source_effective_balance = spec.MAX_EFFECTIVE_BALANCE_ELECTRA // 4
    source_balance = source_effective_balance - spec.EFFECTIVE_BALANCE_INCREMENT // 4
    for source_index in source_indices[:3]:
        set_compounding_withdrawal_credential_with_balance(
            spec, state,
            source_index,
            effective_balance=source_effective_balance,
            balance=source_balance,
            address=source_address
        )
        pending_consolidation = spec.PendingConsolidation(
            source_index = source_index,
            target_index = target_index
        )
        state.pending_consolidations.append(pending_consolidation)

    # Set the last source balance
    request_source_index = source_indices[3]
    target_balance = state.balances[target_index]
    set_compounding_withdrawal_credential_with_balance(
            spec, state,
            request_source_index,
            effective_balance=source_effective_balance + spec.EFFECTIVE_BALANCE_INCREMENT-target_balance,
            balance=source_balance + spec.EFFECTIVE_BALANCE_INCREMENT-target_balance,
            address=source_address
        )

    # Make consolidation with the last source address
    consolidation = spec.ConsolidationRequest(
        source_address=source_address,
        source_pubkey=state.validators[request_source_index].pubkey,
        target_pubkey=state.validators[target_index].pubkey,
    )

    # Add pending consolidation from a another source to another target
    another_source_address = b"\x42" * 20
    another_source_index = active_indices[5]
    another_target_index = active_indices[6]
    set_eth1_withdrawal_credential_with_balance(spec, state, another_source_index, address=another_source_address)
    another_pending_consolidation = spec.PendingConsolidation(
        source_index = another_source_index,
        target_index = another_target_index
    )
    state.pending_consolidations.append(another_pending_consolidation)

    # Check the return condition
    assert (
        sum(state.balances[index] for index in source_indices)
        + state.balances[target_index] <= spec.MAX_EFFECTIVE_BALANCE_ELECTRA
    )
    assert (
        spec.get_pending_balance_to_consolidate(state, target_index)
        + state.validators[request_source_index].effective_balance
        + state.balances[target_index] > spec.MAX_EFFECTIVE_BALANCE_ELECTRA
    )

    yield from run_consolidation_processing(spec, state, consolidation, success=False)


def run_consolidation_processing(spec, state, consolidation, success=True):
    """
    Run ``process_consolidation``, yielding:
      - pre-state ('pre')
      - consolidation_request ('consolidation_request')
      - post-state ('post').
    If ``success == False``, ``process_consolidation_request`` would return without any state change.
    """
    if success:
        validator_pubkeys = [v.pubkey for v in state.validators]
        source_index = spec.ValidatorIndex(validator_pubkeys.index(consolidation.source_pubkey))
        target_index = spec.ValidatorIndex(validator_pubkeys.index(consolidation.target_pubkey))
        source_validator = state.validators[source_index]
        target_validator = state.validators[target_index]
        pre_exit_epoch_source = source_validator.exit_epoch
        pre_exit_epoch_target = target_validator.exit_epoch
        pre_pending_consolidations = state.pending_consolidations.copy()
        pre_source_balance = state.balances[source_index]
        pre_target_balance = state.balances[target_index]
    else:
        pre_state = state.copy()

    yield "pre", state
    yield "consolidation_request", consolidation

    spec.process_consolidation_request(state, consolidation)

    yield "post", state

    if success:
        # Check source has execution credentials
        assert spec.has_execution_withdrawal_credential(source_validator)
        # Check target has compounding credentials
        assert spec.has_compounding_withdrawal_credential(state.validators[target_index])
        # Check source address in the consolidation fits the withdrawal credentials
        assert source_validator.withdrawal_credentials[12:] == consolidation.source_address
        # Check source and target are not the same
        assert source_index != target_index
        # Check source and target were not exiting
        assert pre_exit_epoch_source == spec.FAR_FUTURE_EPOCH
        assert pre_exit_epoch_target == spec.FAR_FUTURE_EPOCH
        # Check source is now exiting
        assert state.validators[source_index].exit_epoch < spec.FAR_FUTURE_EPOCH
        # Check that the exit epoch matches earliest_consolidation_epoch
        assert state.validators[source_index].exit_epoch == state.earliest_consolidation_epoch
        # Check that the withdrawable_epoch is set correctly
        assert state.validators[source_index].withdrawable_epoch == (
            state.validators[source_index].exit_epoch
            + spec.config.MIN_VALIDATOR_WITHDRAWABILITY_DELAY
        )
        # Check that the correct consolidation has been appended
        expected_new_pending_consolidation = spec.PendingConsolidation(
            source_index=source_index,
            target_index=target_index,
        )
        assert state.pending_consolidations == pre_pending_consolidations + [
            expected_new_pending_consolidation
        ]
        # Check no balance move happened
        assert state.balances[source_index] == pre_source_balance
        assert state.balances[target_index] == pre_target_balance
    else:
        assert pre_state == state


def run_switch_to_compounding_processing(spec, state, consolidation, success=True):
    """
    Run ``process_consolidation``, yielding:
      - pre-state ('pre')
      - consolidation_request ('consolidation_request')
      - post-state ('post').
    If ``success == False``, ``process_consolidation_request`` would return without any state change.
    """
    if success:
        validator_pubkeys = [v.pubkey for v in state.validators]
        source_index = spec.ValidatorIndex(validator_pubkeys.index(consolidation.source_pubkey))
        target_index = spec.ValidatorIndex(validator_pubkeys.index(consolidation.target_pubkey))
        source_validator = state.validators[source_index]
        pre_pending_consolidations = state.pending_consolidations.copy()
        pre_withdrawal_credentials = source_validator.withdrawal_credentials
        pre_balance = state.balances[source_index]
    else:
        pre_state = state.copy()

    yield "pre", state
    yield "consolidation_request", consolidation

    spec.process_consolidation_request(state, consolidation)

    yield "post", state

    if success:
        # Check that source and target are same
        assert source_index == target_index
        # Check that the credentials before the switch are of ETH1 type
        assert pre_withdrawal_credentials[:1] == spec.ETH1_ADDRESS_WITHDRAWAL_PREFIX
        # Check source address in the consolidation fits the withdrawal credentials
        assert (
            state.validators[source_index].withdrawal_credentials[12:]
            == consolidation.source_address
        )
        # Check that the source has switched to compounding
        post_withdrawal_credentials = (
            spec.COMPOUNDING_WITHDRAWAL_PREFIX + pre_withdrawal_credentials[1:]
        )
        assert state.validators[source_index].withdrawal_credentials == post_withdrawal_credentials
        # Check excess balance is queued
        assert state.balances[source_index] == spec.MIN_ACTIVATION_BALANCE
        if pre_balance > spec.MIN_ACTIVATION_BALANCE:
            assert len(state.pending_deposits) == 1
            pending_deposit = state.pending_deposits[0]
            assert pending_deposit.pubkey == source_validator.pubkey
            assert pending_deposit.withdrawal_credentials == post_withdrawal_credentials
            assert pending_deposit.amount == (pre_balance - spec.MIN_ACTIVATION_BALANCE)
            assert pending_deposit.signature == spec.G2_POINT_AT_INFINITY
            assert pending_deposit.slot == spec.GENESIS_SLOT
        # Check no consolidation has been initiated
        assert state.validators[source_index].exit_epoch == spec.FAR_FUTURE_EPOCH
        assert state.pending_consolidations == pre_pending_consolidations
    else:
        assert pre_state == state
