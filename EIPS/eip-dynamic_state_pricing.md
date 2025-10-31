---
eip: XXXX
title: Dynamic State Pricing for Steady Growth
description: Dynamically adjust state creation opcode costs based on block gas limit to maintain steady state growth
author: Łukasz Rozmej (@LukaszRozmej)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2025-10-31
requires: 2929, 3529
---

## Abstract

This proposal introduces dynamic pricing for state creation operations that automatically adjusts based on the current block gas limit. By scaling opcode costs proportionally to the gas limit, this EIP ensures state growth remains constant at approximately 350 MB per day regardless of future gas limit increases. The pricing model is anchored at 45M gas limit with current gas costs and scales linearly.

## Motivation

Current opcode pricing is fixed regardless of block gas limits. As gas limits increase to scale Ethereum's throughput, state creation operations maintain the same gas cost, leading to proportionally higher state growth. For example, doubling the gas limit from 30M to 60M could potentially double the rate of state growth, quickly making the state database unmanageable for node operators.

This proposal solves this problem by making opcode costs dynamic:
- At lower gas limits, state creation is cheaper, encouraging usage
- At higher gas limits, state creation costs scale proportionally, maintaining steady state growth
- The system self-regulates to target 350 MB of state growth per day

### Current State Growth Problem

After the gas limit increase from 30M to 36M, daily state creation doubled from ~102 MiB to ~205 MiB. Without intervention, further increases would lead to unsustainable state growth:
- At 60M gas limit: ~580 MB/day, 207 GB/year
- At 100M gas limit: ~967 MB/day, 345 GB/year
- At 300M gas limit: ~2.9 GB/day, 1 TB/year

This EIP maintains steady growth regardless of gas limit increases.

## Specification

### Gas Limit Normalization Factor

Define a **gas limit normalization factor** `k` that scales all state creation costs:

```
k = current_gas_limit / BASE_GAS_LIMIT
```

Where:
- `BASE_GAS_LIMIT` is derived from the `TARGET_STATE_GROWTH_PER_DAY` parameter
- `current_gas_limit` is the gas limit of the block being executed

The core network parameter is `TARGET_STATE_GROWTH_PER_DAY` (in bytes), which determines the maximum acceptable daily state growth. This is converted to `BASE_GAS_LIMIT` using the following formula:

```
BASE_GAS_LIMIT = (TARGET_STATE_GROWTH_PER_DAY × BLOCKS_PER_DAY × BASE_COST_PER_BYTE) / 
                 (BLOCK_UTILIZATION × STATE_CREATION_GAS_RATIO)
```

Where:
- `BLOCKS_PER_DAY = 7,200` (constant: 12-second block time)
- `BASE_COST_PER_BYTE = 132` (gas per byte at the base calibration)
- `BLOCK_UTILIZATION = 0.5` (50% average block fullness)
- `STATE_CREATION_GAS_RATIO = 0.3` (30% of gas used for state creation, empirically observed)

### TARGET_STATE_GROWTH_PER_DAY Schedule

The following schedule defines `TARGET_STATE_GROWTH_PER_DAY` values at different hard fork activations:

| Hard Fork | Activation Block | TARGET_STATE_GROWTH_PER_DAY | Derived BASE_GAS_LIMIT | Rationale |
|-----------|------------------|------------------------------|------------------------|-----------|
| This EIP activation | TBD | 367,001,600 bytes (350 MB) | 45,000,000 | Initial deployment, sustainable growth rate |
| Future adjustment 1 | TBD | TBD | TBD | To be determined based on client capabilities |
| Future adjustment 2 | TBD | TBD | TBD | To be determined based on network conditions |

**Calculation example for initial deployment:**
```
BASE_GAS_LIMIT = (367,001,600 × 7,200 × 132) / (0.5 × 0.3)
               = 350,161,536,000,000 / 0.15
               = 2,334,410,240,000,000 / 51,840
               ≈ 45,000,000
```

At the base gas limit, `k = 1.0`, preserving the pricing at that calibration point. As gas limits deviate from BASE_GAS_LIMIT, `k` adjusts proportionally, raising or lowering state creation costs.

### Dynamic Cost Calculation

For each state creation operation, the effective gas cost becomes:

```
effective_cost = base_cost × k
```

This scaling applies to the following operations:

| Operation | Parameter | Current Base Cost | Formula |
|-----------|-----------|-------------------|---------|
| Contract creation | `GAS_CREATE` | 32,000 | `32,000 × k` |
| Code deposit | `GAS_CODE_DEPOSIT` | 200 | `200 × k` |
| New account funding | `GAS_NEW_ACCOUNT` | 25,000 | `25,000 × k` |
| Self-destruct to new account | `GAS_SELF_DESTRUCT_NEW_ACCOUNT` | 25,000 | `25,000 × k` |
| Storage slot creation | `GAS_STORAGE_SET` | 20,000 | `20,000 × k` |
| EOA delegation (EIP-7702) | `PER_EMPTY_ACCOUNT_COST` | 25,000 | `25,000 × k` |
| EOA delegation auth | `PER_AUTH_BASE_COST` | 12,500 | `12,500 × k` |

### State Growth Target

This EIP targets 350 MB of state growth per day, which translates to approximately 127 GB per year.

**Derivation of BASE_GAS_LIMIT from target:**

Given `TARGET_STATE_GROWTH_PER_DAY = 367,001,600 bytes` (350 MB):

1. **Daily gas budget at 50% utilization:**
   - At BASE_GAS_LIMIT, blocks are 50% full on average
   - Daily gas processed: `BASE_GAS_LIMIT × 0.5 × 7,200 blocks`

2. **Gas allocated to state creation (30% empirically observed):**
   - State creation gas: `BASE_GAS_LIMIT × 0.5 × 7,200 × 0.3`

3. **Cost per byte at base calibration:**
   - At BASE_GAS_LIMIT, the effective cost is `132 gas/byte`
   - This is derived from current opcode costs and typical state creation patterns

4. **Solving for BASE_GAS_LIMIT:**
   ```
   STATE_CREATION_GAS_PER_DAY = TARGET_BYTES_PER_DAY × COST_PER_BYTE
   BASE_GAS_LIMIT × 0.5 × 7,200 × 0.3 = 367,001,600 × 132
   BASE_GAS_LIMIT = (367,001,600 × 132) / (0.5 × 7,200 × 0.3)
   BASE_GAS_LIMIT = 48,444,211,200 / 1,080
   BASE_GAS_LIMIT ≈ 45,000,000
   ```

**As gas limits change, the mechanism maintains the target:**
- At 90M gas limit (k=2): State creation costs 2× more, offsetting the 2× capacity increase
- At 180M gas limit (k=4): State creation costs 4× more, maintaining 350 MB/day
- At 22.5M gas limit (k=0.5): State creation costs 50% less, but capacity is also halved

### Examples

**Scenario 1: Gas limit = 45M (k = 1.0)**
- Contract creation: 32,000 gas
- New storage slot: 20,000 gas
- 24KB contract: 32,000 + (200 × 24,576) = 4,947,200 gas

**Scenario 2: Gas limit = 90M (k = 2.0)**
- Contract creation: 64,000 gas (2× more expensive)
- New storage slot: 40,000 gas (2× more expensive)
- 24KB contract: 64,000 + (400 × 24,576) = 9,894,400 gas (2× more expensive)

**Scenario 3: Gas limit = 300M (k = 6.67)**
- Contract creation: 213,440 gas (6.67× more expensive)
- New storage slot: 133,400 gas (6.67× more expensive)
- 24KB contract: 213,440 + (1,334 × 24,576) = 33,009,824 gas (6.67× more expensive)

## Rationale

### Why Dynamic Pricing?

Fixed opcode costs create a fundamental scaling problem: as Ethereum's capacity increases through higher gas limits, state growth accelerates proportionally. This leads to:
1. Rapidly growing state databases that exclude node operators
2. Degraded sync times and node performance
3. Centralization pressure as only well-resourced operators can maintain full nodes

Dynamic pricing solves this by making state creation proportionally more expensive as capacity increases, ensuring state growth remains constant.

### Why Target 350 MB/day?

This target balances several factors:
- **Node operator sustainability:** 350 MB/day = ~127 GB/year of state growth, allowing nodes to plan for predictable storage needs
- **Application viability:** At current gas limits (45M), costs remain unchanged, ensuring no immediate impact
- **Future-proofing:** Even at 300M gas limit, state growth remains manageable

The target can be adjusted through hard forks by changing `TARGET_STATE_GROWTH_PER_DAY`. For example:
- Setting 500 MB/day (524,288,000 bytes) would derive BASE_GAS_LIMIT ≈ 64,285,714
- Setting 200 MB/day (209,715,200 bytes) would derive BASE_GAS_LIMIT ≈ 25,714,286

### Why Anchor at 45M Gas Limit (350 MB/day)?

The 45M gas limit represents a current target for Ethereum.

**Future adjustments:** If economic conditions, state growth patterns, or client capabilities change significantly, `TARGET_STATE_GROWTH_PER_DAY` can be adjusted through future hard forks. This allows the protocol to:
- Adjust to different acceptable state growth rates
- Respond to changes in client efficiency
- Adapt to improvements in state management (e.g., verkle trees, state expiry)

For example, if clients become significantly more efficient at managing state, a future hard fork could increase `TARGET_STATE_GROWTH_PER_DAY` to 500 MB/day, deriving a new BASE_GAS_LIMIT ≈ 64.3M. This makes state creation cheaper at the new baseline while maintaining the dynamic scaling mechanism.

### Linear Scaling

The linear relationship (`k = gas_limit / BASE_GAS_LIMIT`) is simple, predictable, and gas-efficient:
- No complex calculations or lookups
- Predictable costs for application developers
- Minimal additional computation during execution

### Alternative Approaches Considered

**1. Fixed higher costs (EIP-8037 approach)**
- Pros: Simple, immediate effect
- Cons: Doesn't adapt to future gas limit changes; one-time fix

**2. Exponential scaling**
- Pros: Stronger disincentive at very high gas limits
- Cons: Unpredictable; may overshoot and make state creation prohibitively expensive

**3. Step function (discrete tiers)**
- Pros: Predictable cost changes
- Cons: Creates cliff effects; encourages gaming around thresholds

### TARGET_STATE_GROWTH_PER_DAY Governance

The `TARGET_STATE_GROWTH_PER_DAY` parameter can be adjusted through future hard forks to respond to changing network conditions. This parameter directly expresses the policy goal (state growth rate) rather than an indirect gas limit value.

**When to adjust TARGET_STATE_GROWTH_PER_DAY:**

1. **State management improvements:** If client implementations become significantly more efficient at managing state (e.g., better data structures, or state expiry), the target can be increased to allow more state growth without degrading node performance.

2. **Hardware cost changes:** If storage becomes significantly cheaper or more expensive, the acceptable state growth rate can be adjusted accordingly.

3. **Network policy changes:** If the community consensus shifts on what constitutes acceptable state growth (balancing node operator burden vs. application utility), the target can be modified.

4. **Empirical calibration:** If observed state growth deviates significantly from the target (due to changes in user behavior or state creation patterns), the target can be recalibrated.

This preserves the dynamic scaling mechanism while recalibrating to new network capabilities and allowing more state growth.

**Decision criteria for TARGET_STATE_GROWTH_PER_DAY adjustments:**
- Empirical state growth data over 6-12 months
- Client benchmarking and performance metrics at different state sizes
- Hardware cost trends and node operator feedback
- Economic analysis of state creation costs vs. network utility
- Community consensus on acceptable state growth rates

**Advantages of TARGET_STATE_GROWTH_PER_DAY over BASE_GAS_LIMIT:**
- Directly expresses the policy goal (MB/day) in human-readable terms
- Makes trade-offs explicit when discussing hard fork changes
- Easier to reason about long-term sustainability (e.g., "350 MB/day = 127 GB/year")
- Derived BASE_GAS_LIMIT automatically adjusts to maintain the target

TARGET_STATE_GROWTH_PER_DAY adjustments require the same governance process as any other hard fork consensus change.

## Backwards Compatibility

This is a backwards-incompatible change requiring a scheduled network upgrade (hard fork).

### Impact on Applications

**Applications creating significant state:**
- At 45M gas limit: No change in costs
- As gas limit increases: Proportional cost increases
- Applications should design for efficiency and minimize unnecessary state creation

**Typical operations at 90M gas limit (2× current costs):**
- New EOA account: 50,000 gas (vs 25,000)
- New storage slot: 40,000 gas (vs 20,000)
- Small contract (5KB): 2× more expensive

### Gas Estimation

**Wallets and infrastructure:**
- Must query current gas limit when estimating transaction costs
- RPC methods like `eth_estimateGas` MUST calculate dynamic costs based on current gas limit
- Gas estimates should include a small buffer (5-10%) to account for gas limit fluctuations

## Security Considerations

### Gas Limit Manipulation

**Concern:** Validators could artificially lower gas limits to reduce state creation costs for their own transactions.

**Mitigation:** 
- Gas limit changes are constrained by EIP-1559 and can only adjust by 1/1024 per block
- Economic incentives favor higher gas limits (more transaction fees)
- The manipulation would be visible and could be addressed socially

### Cost Predictability

**Concern:** Fluctuating costs due to changing gas limits create uncertainty for users.

**Mitigation:**
- Gas limit changes are gradual (max ~0.1% per block)
- Over typical transaction timescales (minutes), costs remain stable
- Applications can query current gas limit for precise estimates

### Large Contract Deployments

**Concern:** Very large contracts could become prohibitively expensive at high gas limits.

**Mitigation:**
- Consider adopting multidimensional metering (similar to EIP-8037) if contract size limits become problematic
- At 300M gas limit (k=6.67), a 24KB contract costs ~33M gas, still within a single block
- Applications requiring large contracts can optimize or split across multiple contracts
- Explicitly decrease contract creation cost
- Apply EIP-8058 Duplication discount

## Test Cases

### Test Case 1: Base Gas Limit (45M)
```python
gas_limit = 45_000_000
k = 1.0
assert get_create_cost(k) == 32_000
assert get_sstore_new_slot_cost(k) == 20_000
```

### Test Case 2: Doubled Gas Limit (90M)
```python
gas_limit = 90_000_000
k = 2.0
assert get_create_cost(k) == 64_000
assert get_sstore_new_slot_cost(k) == 40_000
```

### Test Case 3: High Gas Limit (300M)
```python
gas_limit = 300_000_000
k = 6.67
assert get_create_cost(k) == 213_440
assert get_sstore_new_slot_cost(k) == 133_400
```

### Test Case 4: Sub-Base Gas Limit (30M)
```python
gas_limit = 30_000_000
k = 0.667
assert get_create_cost(k) == 21_344
assert get_sstore_new_slot_cost(k) == 13_340
# State creation is cheaper below base gas limit
```
## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
