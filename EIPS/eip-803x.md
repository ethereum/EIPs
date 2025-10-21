---
eip: 803x
title: Temporal Locality Gas Discounts
description: Multi‑block temporal locality discounts for state and account access
author: Ben Adams (@benaadams), Toni Wahrstätter (@nerolation), Amirul Ashraf (@asdacap)
discussions-to: https://ethereum-magicians.org/
status: Draft
type: Standards Track
category: Core
created: 2025-10-20
requires: 2929, 7928
---

## Abstract

This proposal introduces a deterministic, multi-block discount for the first
access to accounts and storage keys in a transaction. The discount depends on
the number of blocks since that item was last accessed and decays smoothly to
zero over a fixed window of recent blocks. Intra-block warming semantics remain
unchanged (no block-level warming).

The mechanism relies on block-level access lists ([EIP-7928](./eip-7928.md)) committed in headers so that a newly synced node can price the first block it validates without executing historical blocks.

## Motivation

Current warm and cold access pricing matches client realities but creates a
usability gap. However any gas saving that depends on other transactions in the same-block is capricious for users: they sign a transaction at a given price but might get a cheaper execution only if other transactions in the same block happen to touch the same items. That saving is both inherently not knowable or actionalable to users at submission time and thus has no impact on behaviour.

This EIP rewards short-term temporal locality across block boundaries while
preserving the familiar per-transaction warm set. The discount depends only on
prior blocks, so it is deterministic at submission, predictable across
builders, and behaviour-modifying in a useful direction.

As the saving depends only on publicly observable prior-block activity, it
is knowable at submission time. Unlike same-block effects, it is therefore
behaviour-shaping rather than incidental. It nudges workloads
that naturally cluster accesses to keep doing so, matching how clients
amortise repeated recent accesses.

This EIP is intentionally scoped to per-transaction warming and does not apply
intra-block warming across transactions.

## Specification

### Terminology and constants

The following names are used for clarity. Concrete values can be updated by
governance without changing the mechanism.

- `window_size_blocks` - number of recent blocks over which a discount may
  apply. Default: `63`.
- `current_block_number` - the block number of the transaction being executed.
- `last_access_block_number(item)` - the most recent block number strictly less
  than `current_block_number` in which `item` was accessed by an executed
  transaction. If unknown or older than `window_size_blocks`, it is treated as
  not found.
- `block_distance_in_blocks(item)` - defined as
  `current_block_number - last_access_block_number(item)` when the latter is
  found, else a value greater than `window_size_blocks`.

Gas constants from existing behaviour:

- `sload_warm_gas_cost = 100`
- `sload_cold_surcharge_gas = 2100`
- `account_warm_gas_cost = 100`
- `account_cold_surcharge_gas = 2600`

Discount caps (this EIP treats maximum as full cold surcharge, minimum as zero):

- `discount_max_sload = sload_cold_surcharge_gas`
- `discount_min_sload = 0`
- `discount_max_account = account_cold_surcharge_gas`
- `discount_min_account = 0`

This means the closest prior-block usage allows the first access in a
transaction to be charged at warm cost, and the far edge of the window trends
to the normal cold-plus-warm cost.

### Scope of operations

This EIP applies the discount to the **first access in a transaction** of:

- Storage keys accessed by `SLOAD` and by any operation that first reads a slot
  as part of its semantics (for example, `SSTORE`'s read step).
- Account touches that incur the cold account access surcharge under the
  current gas schedule, including but not limited to:
  `BALANCE`, `EXTCODEHASH`, `EXTCODESIZE`, `EXTCODECOPY`, and the target
  account of `CALL`, `CALLCODE`, `DELEGATECALL`, `STATICCALL`.

Writes are affected **only** to the extent they perform an initial read or
account touch that would have been charged as cold. Write-specific costs and
any refund semantics are unchanged.

Precompiles remain unchanged and are always warm. Because they do not pay a
cold surcharge, no discount is applied to precompile calls.

Access lists per EIP-2930 remain effective and, when present, pre-warm the
listed addresses and storage keys at the start of the transaction. For items
that are pre-warmed by an access list, this temporal discount does not apply.

### Discount function

Define a smooth, monotone falloff within the window using the programming form
of smoothstep (clamped cubic Hermite interpolation). 

```
Let d = current_block_number - last_access_block_number(item)
Let w = window_size_blocks
Let D_max = maximum discount, D_min = minimum discount (usually 0)
Let x = clamp((d - 1.0) / (w - 1.0), 0.0, 1.0)
Then:
  discount(d) = D_min + (D_max - D_min) * (1.0 - (3x^2 - 2x^3))
  cost(d)     = warm_gas_cost + max(0, cold_surcharge - discount(d))
```

Programattically

- `normalized_distance = (block_distance_in_blocks - 1) /
  (window_size_blocks - 1)` clamped to `[0, 1]`. This maps distance `1` to `0`
  and distance `window_size_blocks` to `1`.
- `smoothstep_value = normalized_distance * normalized_distance * (3 - 2 *
  normalized_distance)`.
- `discount_factor = 1 - smoothstep_value`. This is `1` at distance `1` and `0`
  at distance `window_size_blocks`.

For a given opcode family with parameters `discount_max` and `discount_min`,
the integer discount to apply to the **cold surcharge** is:

```
if block_distance_in_blocks <= 0 or 
   block_distance_in_blocks > window_size_blocks:
    discount_gas = 0
else:
    discount_gas = discount_min +
       round_to_nearest((discount_max - discount_min) * discount_factor))
```

Note: this should be scaled to interger space rather than using floating points. An example is given to do this in reference implementation.

`round_to_nearest` is round half up for integers in this specification. Any
consistent rule is acceptable if implemented consistently across clients.

This mechanism is a **discount**, not a refund. It reduces gas charged upfront
for a cold surcharge; it does not emit a rebate and does not affect refund
accounting or receipts.

### Charging rules (per transaction)

For the first access to an `item` **within a transaction**:

1. If `item` is already warm in this transaction due to same-transaction rules
   or pre-warmed via a transaction access list, charge the warm cost defined
   today. No temporal discount applies.
2. Otherwise compute `block_distance_in_blocks(item)`. If
   `1 <= block_distance_in_blocks(item) <= window_size_blocks`, apply the
   discount to the cold surcharge:
   - Storage read first access cost:
     - `sload_first_access_cost = sload_warm_gas_cost + max(0,
       sload_cold_surcharge_gas - discount_sload(block_distance_in_blocks))`
   - Account-touch first access cost:
     - `account_first_access_cost = account_warm_gas_cost + max(0,
       account_cold_surcharge_gas - discount_account(block_distance_in_blocks))`
3. If `block_distance_in_blocks(item) > window_size_blocks` or not found,
   charge the unmodified cold surcharge plus the warm component as today.

Subsequent accesses to the same `item` within the **same transaction** are warm
as per existing rules. This EIP does not introduce block-level warming across
transactions.

### Initial sync and pricing with block-level access lists

This EIP requires block-level access lists in headers. Each header carries
commitments to the sets of accounts and storage keys accessed during that
block.

A newly synced node can price the very first block it validates as follows:

1. For a block to validate at `current_block_number`, gather the headers for the
   previous `window_size_blocks` blocks.
2. For each of those headers, obtain the committed sets of accessed accounts and
   storage keys from the block body or via verified proofs against the header
   commitments.
3. Build a local index mapping each seen `item` to the most recent block number
   in which it appears within that window. This becomes
   `last_access_block_number(item)`.
4. When validating `current_block_number`, for each first access to `item`,
   compute
   `block_distance_in_blocks(item) = current_block_number - last_access_block_number(item)`
   when present, else treat as out-of-window. Apply the discount rules above.

Reorgs longer than `window_size_blocks` fall back to the same procedure as
initial resync. Items not present in the new canonical window are treated as
cold.

No execution of historical transactions is required to compute the discount at
validation time. Stateless verifiers can price gas using the current block plus
compact proofs that an item appears in one of the previous
`window_size_blocks` access lists.

### Wallet gas estimation guidance

Wallets and RPC endpoints should not assume that a temporal discount will apply
at submission, because the exact landing block is uncertain. General-purpose
estimators should price as if no temporal discount applies.

Operators who can predict landing with high confidence - for example via priority fees and private order flow - may account for the exact discount,
but this is an advanced path and not the default.

Motivated operators who can reliably land transactions in a specific block -
for example via private order flow and appropriately set priority fees - may
account for the exact discount. This is an advanced use case and should not be
the default behaviour for general-purpose wallets.

### Implementation guidance

Clients are expected to maintain a rolling in-memory index to avoid rescanning
headers for each block:

- Keep a ring buffer of `window_size_blocks` buckets, one per recent block. Each
  bucket stores first-touched accounts and first-touched storage keys for that
  block.
- Maintain two maps `last_seen_account` and `last_seen_storage_key` that track
  the latest block index within the window where each item was present. On block
  advance, drop the oldest bucket and delete items that only appeared there, or
  mark them as out of window.
- During execution, when an opcode is about to charge a cold surcharge for an
  item not yet warm in the current transaction, look up
  `block_distance_in_blocks` from `last_seen_*` and charge using the rules
  above. Then record first touches for the current block in the current bucket
  and update the maps.

This design keeps memory bounded by `window_size_blocks` times the number of
distinct first touches per block, which is itself bounded by the block gas
limit divided by the minimum per-item cost.

This is one approach; clients may also implement this via their caches or
pruning block distance hints in their trie.

## Rationale

- Determinism: discounts depend only on prior blocks, so users can predict costs
  at submission time. The block-level access lists in headers remove bootstrap
  ambiguity for new nodes. Intra-block dependent savings are inherently unknowable and non-actionable at submission, so they do not change behaviour; prior-block based savings do.
- Smooth curve: the chosen polynomial keeps strong incentive for very recent
  history and eases toward zero, aligning with how caches deliver benefit for
  temporal locality. Linear ramps are simpler but produce harsher edges.
- Window of 63: this captures longer-lived temporal locality without turning the
  feature into a long-term subsidy, and keeps proof and index sizes small.
- Discount not refund: reduces upfront charge only; does not change refund
  semantics or receipts.
- No correlation: simple to implement and reason about. The model is explicitly
  about last-access distance, not frequency.

Builder rotation and similar operational concerns are out of scope for this
EIP.


### Behavioural effects

The smoothstep curve over 63 blocks is gentle. Discount remains close to
maximum for roughly the first 12 to 16 blocks and decays toward zero near the
far edge of the window.

#### Storage slot (SLOAD) first-access pricing

(warm = 100, cold surcharge = 2100, window = 63)

| Distance (blocks) | Discount (gas) | Final cost (gas) | Comment               |
| --------------------: | -------------: | ---------------: | --------------------- |
|                     1 |           2100 |              100 | fully warm equivalent |
|                     4 |           2057 |              143 | almost full discount  |
|                     8 |           1946 |              254 |                       |
|                    12 |           1783 |              417 |                       |
|                    16 |           1577 |              623 |                       |
|                    20 |           1338 |              862 |                       |
|                    24 |           1080 |             1120 |                       |
|                    28 |            816 |             1384 |                       |
|                    32 |            561 |             1639 | half-way point        |
|                    36 |            327 |             1873 |                       |
|                    40 |            149 |             2051 | near-cold             |
|                    48 |             35 |             2165 | almost full cost      |
|                    56 |              5 |             2195 |                       |
|                    63 |              0 |             2200 | window edge           |
|                   >63 |              0 |             2200 | fully cold access     |


#### Account access first-access pricing

(warm = 100, cold surcharge = 2600, window = 63)

| Distance (blocks) | Discount (gas) | Final cost (gas) | Comment               |
| --------------------: | -------------: | ---------------: | --------------------- |
|                     1 |           2600 |              100 | fully warm equivalent |
|                     4 |           2546 |              154 | almost full discount  |
|                     8 |           2408 |              292 |                       |
|                    12 |           2206 |              494 |                       |
|                    16 |           1957 |              743 |                       |
|                    20 |           1679 |             1021 |                       |
|                    24 |           1382 |             1318 |                       |
|                    28 |           1090 |             1610 |                       |
|                    32 |            808 |             1892 | half-way point        |
|                    36 |            555 |             2145 |                       |
|                    40 |            340 |             2360 | near-cold             |
|                    48 |            104 |             2596 | almost full cost      |
|                    56 |             12 |             2688 |                       |
|                    63 |              0 |             2700 | window edge           |
|                   >63 |              0 |             2700 | fully cold access     |

#### Observations

* Accesses 1–8 blocks apart remain effectively warm (under 300–400 gas total).
* Around 30–32 blocks (≈6–7 minutes), costs rise to roughly half the cold cost.
* Beyond 55–60 blocks (≈11–12 minutes), costs are nearly cold again.
* The transition is smooth and monotone; there are no incentive cliffs.
* Both account and storage families reach exactly the warm level for items
accessed in the immediately preceding block.

Because the discount depends on prior blocks only,
users and dapps can plan around it. Unlike same-block effects, these savings are not capricious: they are visible before submission and can be acted
upon by automation or strategy.

If an operator wants to maintain most of the discount while sending as few
transactions as possible, a practical cadence for items touched repeatedly is:

- Maintain about 80 percent of the maximum discount by ensuring the item is
  touched again within approximately 18 blocks. The normalized threshold is the
  same for accounts and storage because the curve is applied as a fraction of
  each family's maximum.
- Maintain about 50 percent of the maximum discount by touching again within
  approximately 32 blocks.
- Beyond about 55 blocks the discount approaches zero and the access is nearly
  cold again.

In short, a maintenance touch roughly every 18 to 20 blocks is an efficient
sweet spot for min-maxing: high retained discount, low transaction frequency.

UX note: humans may not reliably act within these windows, but automated
keepers, dapps, and services can. Some state - for example, popular pair
balances - will tend to stay warm naturally due to organic use, indirectly
benefiting users.

This mechanism does not correlate across account and storage accesses. Each
item's discount is independent. Repeated touches within the window do not stack
beyond updating the last-access block used to compute the distance.



## Backwards compatibility

This EIP changes gas charging and therefore requires a hard fork. It only
decreases or equalises costs for affected opcodes and does not introduce new
failure modes for existing contracts. Warm and cold cost upper bounds do not
increase.

## Security considerations

- Index growth: the number of unique items per block is limited by the block
  gas limit and per-item minimum costs. Bounding the window keeps memory usage
  proportional to a small constant factor times that number.
- Reorgs: on reorg, recompute `last_access_block_number` from the committed
  access lists of the new canonical window. Reorgs longer than the window fall
  back to the initial resync procedure.
- Stateless operation: pricing proofs require only the current block and
  membership proofs for at most one of the previous `window_size_blocks` access
  lists per item.

## Test cases

Assume defaults:

- `window_size_blocks = 63`
- `sload_warm_gas_cost = 100`
- `sload_cold_surcharge_gas = 2100`
- `account_warm_gas_cost = 100`
- `account_cold_surcharge_gas = 2600`
- `discount_max_sload = 2100`, `discount_min_sload = 0`
- `discount_max_account = 2600`, `discount_min_account = 0`

Examples for the first storage read in a transaction:

- `block_distance_in_blocks = 1`:
  discount `2100`, charge `100` (equal to warm)
- `block_distance_in_blocks = 18`:
  discount about `0.8 * 2100 = 1680`, charge about `520`
- `block_distance_in_blocks = 32`:
  discount about `1050`, charge about `1150`
- `block_distance_in_blocks = 63`:
  discount `0`, charge `2200`
- `block_distance_in_blocks > 63`:
  discount `0`, charge `2200`

Examples for the first account touch in a transaction:

- `block_distance_in_blocks = 1`:
  discount `2600`, charge `100` (equal to warm)
- `block_distance_in_blocks = 32`:
  discount about `1300`, charge about `1400`
- `block_distance_in_blocks = 63`:
  discount `0`, charge `2700`
- `block_distance_in_blocks > 63`:
  discount `0`, charge `2700`

Exact integer results are defined by the reference implementation rounding
rule.

## Reference implementation (Python, integer only)

This implementation is normative for rounding and scaling. It uses a power-of-
two fixed-point scale so divisions by the scale are exact shifts in low-level
implementations. All intermediates fit below 2**53 so a JavaScript client can
mirror these steps without a big number library.

```python
# Gas constants
sload_warm_gas_cost = 100
sload_cold_surcharge_gas = 2100
account_warm_gas_cost = 100
account_cold_surcharge_gas = 2600

# Temporal discount parameters
window_size_blocks = 63
discount_max_sload = sload_cold_surcharge_gas
discount_min_sload = 0
discount_max_account = account_cold_surcharge_gas
discount_min_account = 0

# Fixed-point scale - power of two
scale_factor = 1 << 25           # 33_554_432
half_scale = scale_factor >> 1

def smooth_factor_scaled(block_distance_in_blocks: int,
                         window_blocks: int = window_size_blocks) -> int:
    """
    Returns round_to_nearest(scale_factor * discount_factor) where:
      normalized_distance = (block_distance_in_blocks - 1) / (window_blocks - 1),
      clamped to [0,1]
      smoothstep_value = normalized_distance^2 * (3 - 2 * normalized_distance)
      discount_factor = 1 - smoothstep_value
    The result is in [0, scale_factor].
    """
    if block_distance_in_blocks <= 0 or block_distance_in_blocks > window_blocks:
        return 0

    # Use exact rational form to minimise scaling multiplications:
    # Let t = block_distance_in_blocks - 1, d = window_blocks - 1.
    # discount_factor = (d^3 - 3*d*t^2 + 2*t^3) / d^3
    t = block_distance_in_blocks - 1
    d = window_blocks - 1
    d3 = d * d * d
    t2 = t * t
    t3 = t2 * t
    numerator = d3 - 3 * d * t2 + 2 * t3

    # round half up
    return (scale_factor * numerator + (d3 // 2)) // d3

def discount_gas_units(block_distance_in_blocks: int,
                       discount_max: int,
                       discount_min: int) -> int:
    """
    Integer discount within the window using the smooth falloff.
    Returns an integer number of gas units to subtract from the cold surcharge.
    """
    if block_distance_in_blocks <= 0 or block_distance_in_blocks > window_size_blocks:
        return 0
    factor_scaled = smooth_factor_scaled(block_distance_in_blocks, window_size_blocks)
    span = discount_max - discount_min
    scaled = (span * factor_scaled + half_scale) // scale_factor
    return discount_min + scaled

def sload_first_access_cost(block_distance_in_blocks: int) -> int:
    disc = discount_gas_units(block_distance_in_blocks,
                              discount_max_sload,
                              discount_min_sload)
    cold_part = sload_cold_surcharge_gas - disc
    if cold_part < 0:
        cold_part = 0
    return sload_warm_gas_cost + cold_part

def account_first_access_cost(block_distance_in_blocks: int) -> int:
    disc = discount_gas_units(block_distance_in_blocks,
                              discount_max_account,
                              discount_min_account)
    cold_part = account_cold_surcharge_gas - disc
    if cold_part < 0:
        cold_part = 0
    return account_warm_gas_cost + cold_part
```

### Relationship to block-level warming proposals

This EIP does not introduce intra-block warming across transactions. If a
block-level warming proposal is active, its semantics are unchanged. The
temporal discount defined here applies only to the first access to an item in
a transaction based on prior-block history.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
