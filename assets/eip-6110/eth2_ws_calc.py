"""
This script calculates the Eth2 Weak Subjectivity period as defined by eth2.0-specs: https://github.com/ethereum/eth2.0-specs/blob/dev/specs/phase0/weak-subjectivity.md
"""

from eth2spec.phase0.mainnet import (
    uint64, Ether,
    ETH_TO_GWEI, 
    MAX_DEPOSITS, 
    MAX_EFFECTIVE_BALANCE,  
    SLOTS_PER_EPOCH, 
    config, 
)

MIN_VALIDATOR_WITHDRAWABILITY_DELAY = config.MIN_VALIDATOR_WITHDRAWABILITY_DELAY
MIN_PER_EPOCH_CHURN_LIMIT = config.MIN_PER_EPOCH_CHURN_LIMIT
CHURN_LIMIT_QUOTIENT = config.CHURN_LIMIT_QUOTIENT

def get_validator_churn_limit(validator_count: uint64) -> uint64:
    return max(MIN_PER_EPOCH_CHURN_LIMIT, validator_count // CHURN_LIMIT_QUOTIENT)

def compute_weak_subjectivity_period(N: uint64, t: Ether) -> uint64:
    """
    Returns the weak subjectivity period for the current ``state``. 
    This computation takes into account the effect of:
        - validator set churn (bounded by ``get_validator_churn_limit()`` per epoch), and 
        - validator balance top-ups (bounded by ``MAX_DEPOSITS * SLOTS_PER_EPOCH`` per epoch).
    A detailed calculation can be found at:
    https://github.com/runtimeverification/beacon-chain-verification/blob/master/weak-subjectivity/weak-subjectivity-analysis.pdf
    """
    ws_period = MIN_VALIDATOR_WITHDRAWABILITY_DELAY
    # N = len(get_active_validator_indices(state, get_current_epoch(state)))
    # t = get_total_active_balance(state) // N // ETH_TO_GWEI
    T = MAX_EFFECTIVE_BALANCE // ETH_TO_GWEI
    delta = get_validator_churn_limit(N)
    MAX_DEPOSITS = 1024
    Delta = MAX_DEPOSITS * SLOTS_PER_EPOCH
    D = SAFETY_DECAY

    if T * (200 + 3 * D) < t * (200 + 12 * D):
        epochs_for_validator_set_churn = (
            N * (t * (200 + 12 * D) - T * (200 + 3 * D)) // (600 * delta * (2 * t + T))
        )
        epochs_for_balance_top_ups = (
            N * (200 + 3 * D) // (600 * Delta)
        )
        ws_period += max(epochs_for_validator_set_churn, epochs_for_balance_top_ups)
    else:
        ws_period += (
            3 * N * D * t // (200 * Delta * (T - t))
        )
    
    return ws_period

print("| Safety Decay | Avg. Val. Balance (ETH) | Val. Count | Weak Sub. Period (Epochs) |")
print("| ---- | ---- | ---- | ---- |")
for SAFETY_DECAY in [10]:
    for balance_eth in range(20, 32+1, 4):
      average_active_validator_balance = Ether(balance_eth)
      for log_val_count in range(15, 21, 1):
        validator_count = uint64(2**log_val_count)
        weak_subjectivity_period = compute_weak_subjectivity_period(validator_count, average_active_validator_balance)
        print(f"| {SAFETY_DECAY} | {average_active_validator_balance} | {validator_count} | {weak_subjectivity_period} |")
