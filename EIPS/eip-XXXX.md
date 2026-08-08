---
title: ePBS Mandatory Burn of Execution Rewards
description: Burns a fixed fraction of the gross value committed by selected ePBS builder bids.
author: Ben Adams (@benaadams)
discussions-to: <DISCUSSION URL>
status: Draft
type: Standards Track
category: Core
created: 2026-08-07
requires: 7732
---

## Abstract

This EIP changes the ePBS payment mechanism from [EIP-7732](./eip-7732.md).

An external `ExecutionPayloadBid` declares `gross_value`. `gross_value` is the total value that the builder commits if the bid becomes payable.

The protocol divides `gross_value` into three parts:

- a consensus-layer burn;
- a trustless proposer payment;
- an optional trusted execution-layer payment.

The following identity must hold:

```text
G = B + V + E
```

The terms have these meanings:

- `G` is `gross_value`.
- `B` is the burn.
- `V` is the trustless proposer payment.
- `E` is `execution_payment`.

The builder must fully collateralize `B` and `V`. Consensus does not guarantee `E`.

A public bid must have `execution_payment == 0`. Therefore, a public bid is fully collateralized.

The burn and the trustless proposer payment use one settlement lifecycle. They become payable together or they are released together. The same EIP-7732 liability conditions control both amounts.

A self-built payload has no burn. The protocol cannot measure the external payment value of a self-built payload.

This EIP does not add an attester duty. This EIP does not add a burn rule to fork choice.

## Motivation

[EIP-7732](./eip-7732.md) makes a builder payment an explicit protocol object. This gives the protocol a direct value that it can split.

The protocol can use this value to reduce proposer windfalls from execution auctions. The protocol can do this without a second auction. The protocol can also do this without a subjective price oracle.

### MEV as variable validator revenue

An execution payload can contain value that does not come from normal blockspace pricing. Examples include arbitrage, liquidations, order-flow advantages, and other forms of maximal extractable value (MEV).

In a competitive builder market, a builder can pay part of this value to the proposer. The builder makes this payment to increase the chance that the proposer selects its payload.

Builder payments can have a highly skewed distribution. Most proposal slots have modest value. A small number of slots can have very large value.

Large and rare payments can create these effects:

- A high-value slot can increase the reward from a reorganization or a targeted denial-of-service attack.
- A high-value slot can increase the reward from key compromise or operator theft.
- Variable rewards can increase demand for reward smoothing and pooling.
- Large operators can spread specialized infrastructure costs across many validators.
- Large operators receive more proposal opportunities because they control more stake.
- More proposal opportunities reduce the relative variance of operator income.

A large operator does not receive more expected MEV per unit of stake only because it has more validators. The main scale advantage comes from lower relative variance, fixed-cost sharing, and better infrastructure economics.

Stake in one operational failure domain still adds slashable economic weight. However, more validators in the same failure domain do not add independent nodes, operators, network paths, or failure domains in the same proportion.

Ethereum cannot directly measure independent physical nodes or independent operational control. Therefore, this EIP does not try to reward these properties directly.

This EIP has a narrower decentralization objective. It reduces one reward component that can make large-scale validator operation more attractive.

The objective is measurable:

> Reduce the share and variance of validator revenue that comes from random execution-auction value. Do not materially increase the advantage of large or vertically integrated staking operators.

### Redirect execution-auction value

[EIP-1559](./eip-1559.md) burns the execution base fee. It does not give the base fee to the block producer.

Builder payments are not base fees. However, builder payments are another protocol-visible value stream that is connected to execution rights.

A proportional burn has these properties:

- The burn increases when the selected builder bid increases.
- A high-value block creates a high burn.
- The protocol removes a known fraction of each visible builder bid before the proposer payment.
- The protocol does not need a new recipient set.
- The protocol does not need a redistribution mechanism.
- The burn reduces ETH supply.

This EIP does not burn all MEV. It burns a fixed fraction of value that appears in a selected external ePBS bid.

The protocol cannot burn value that a self-builder keeps internally. The protocol also cannot burn a payment that the builder and proposer keep outside the signed bid.

### Why use a proportional burn

A proposer has no direct reason to select a larger voluntary burn. If a builder can use the same expenditure as a proposer payment, the proposer prefers the payment.

A separate burn field creates an incentive conflict. It also creates a second auction dimension.

This EIP removes that choice. The protocol fixes the burn fraction for all external bids.

For public bids, the burn fraction is constant and `execution_payment == 0`. Therefore, a larger `gross_value` also gives a larger trustless proposer payment.

A proposer can maximize its own public-bid revenue without choosing the burn amount.

This design also avoids an attester-observed burn floor. A local burn floor can differ between honest nodes because nodes can receive different bids before a deadline.

This EIP does not use local bid observations for consensus. The burn is a deterministic result of the selected signed bid and the fork constant.

### Design goals

This EIP has these goals:

1. The burn is objective and is derivable from canonical consensus data.
2. The burn does not depend on local attester observations of builder bids.
3. The proposer does not select the burn fraction.
4. The public ePBS bid path remains fully collateralized.
5. A public ePBS bid does not expose the proposer to trusted-payment risk.
6. A private or relay bid can use a declared trusted payment.
7. A declared trusted payment contributes to the burn calculation.
8. The burn and the trustless proposer payment use one liability decision.
9. Self-building remains possible without a declared MEV value.
10. The mechanism makes post-fork economic effects easy to measure.

## Specification

This specification changes the consensus-layer ePBS mechanism from [EIP-7732](./eip-7732.md).

### Definitions

For one selected external-builder bid, use these terms:

- `G`: `gross_value`. This is the builder's total declared expenditure if the bid becomes payable.
- `B`: `burn_amount`. Consensus destroys this amount if the builder commitment becomes payable.
- `P`: total proposer compensation after the burn.
- `E`: `execution_payment`. This is the trusted proposer-payment amount from EIP-7732.
- `V`: `trustless_payment`. Consensus guarantees this proposer-payment amount.
- `C`: `consensus_liability`. The builder MUST cover this amount with consensus-layer builder balance.

The following equations MUST hold:

```text
B = floor(G * BUILDER_PAYMENT_BURN_NUMERATOR / BUILDER_PAYMENT_BURN_DENOMINATOR)
P = G - B
V = P - E
G = B + V + E
C = B + V
C = G - E
```

A bid is invalid if `E > P`.

Consensus does not guarantee `E`.

A larger `E` does not reduce the burn if `G` stays the same. A larger declared total commitment requires a larger `G`. A larger `G` increases `B`.

### Configuration

The proposed mainnet configuration is:

```python
BUILDER_PAYMENT_BURN_NUMERATOR = uint64(1)
BUILDER_PAYMENT_BURN_DENOMINATOR = uint64(3)
```

`BUILDER_PAYMENT_BURN_DENOMINATOR` MUST be greater than zero.

`BUILDER_PAYMENT_BURN_NUMERATOR` MAY be zero. A zero numerator disables the burn without disabling the payment path.

`BUILDER_PAYMENT_BURN_NUMERATOR` MUST NOT be greater than `BUILDER_PAYMENT_BURN_DENOMINATOR`.

An implementation MUST use integer floor division to calculate `B`.

An implementation MUST calculate `G * BUILDER_PAYMENT_BURN_NUMERATOR // BUILDER_PAYMENT_BURN_DENOMINATOR` without intermediate integer overflow. A fixed-width implementation MUST use a sufficiently wide intermediate type or an equivalent overflow-safe algorithm.

Any division remainder stays in `P`. Therefore, `B + P == G` always holds.

### Execution layer

This EIP does not require an execution-layer consensus change.

The protocol applies the burn directly to the EIP-7732 consensus-layer builder balance.

`execution_payment` keeps its EIP-7732 trusted-payment meaning.

### Modified `ExecutionPayloadBid`

Replace `ExecutionPayloadBid.value` with `gross_value`:

```python
class ExecutionPayloadBid(ProgressiveContainer(active_fields=[1] * 12)):
    parent_block_hash: Hash32
    parent_block_root: Root
    block_hash: Hash32
    prev_randao: Bytes32
    fee_recipient: ExecutionAddress
    gas_limit: Uint64
    builder_index: BuilderIndex
    slot: Slot
    gross_value: Gwei
    execution_payment: Gwei
    blob_kzg_commitments: BlobKZGCommitments
    execution_requests_root: Root
```

`SignedExecutionPayloadBid` signs `gross_value` as part of the bid.

The builder MUST NOT supply `trustless_payment` as an independent field.

The builder MUST NOT supply `burn_amount` as an independent field.

Consensus MUST derive both values from `gross_value` and `execution_payment`.

### Builder bid construction

An external builder MUST use `gross_value` for the total declared expenditure of the bid.

The builder MUST choose `execution_payment` so that `execution_payment <= proposer_amount`.

A public bid MUST set `execution_payment = 0`.

For a public bid, the trustless proposer payment is `gross_value - burn_amount`.

A private or relay bid MAY set `execution_payment > 0`.

For a private or relay bid, the trustless proposer payment is the remaining proposer compensation after `execution_payment`.

A builder MUST NOT treat `execution_payment` as an amount in addition to `gross_value`.

### Burn and payment helpers

Consensus implementations MUST calculate the bid components deterministically.

The following pseudocode is normative in behavior:

```python
def get_builder_burn(gross_value: Gwei) -> Gwei:
    return Gwei(
        gross_value
        * BUILDER_PAYMENT_BURN_NUMERATOR
        // BUILDER_PAYMENT_BURN_DENOMINATOR
    )


def get_bid_payment_components(bid: ExecutionPayloadBid) -> tuple[Gwei, Gwei, Gwei]:
    burn_amount = get_builder_burn(bid.gross_value)
    proposer_amount = Gwei(bid.gross_value - burn_amount)
    assert bid.execution_payment <= proposer_amount
    trustless_payment = Gwei(proposer_amount - bid.execution_payment)
    return burn_amount, trustless_payment, bid.execution_payment


def get_bid_consensus_liability(bid: ExecutionPayloadBid) -> Gwei:
    burn_amount, trustless_payment, _ = get_bid_payment_components(bid)
    return Gwei(burn_amount + trustless_payment)
```

For every valid external bid, the following equation is also valid:

```text
consensus_liability = gross_value - execution_payment
```

### `BuilderPendingSettlement`

Replace `BuilderPendingPayment` with a settlement object that contains both protocol liabilities:

```python
class BuilderPendingSettlement(Container):
    weight: Gwei
    withdrawal: BuilderPendingWithdrawal
    proposer_index: ValidatorIndex
    gross_value: Gwei
    burn_amount: Gwei
```

`withdrawal.amount` MUST equal `V`.

`burn_amount` MUST equal `B`.

`proposer_index` identifies the proposer for the existing EIP-7732 proposer-slashing release path. It is not a payment recipient.

`withdrawal.fee_recipient` keeps the existing EIP-7732 fee-recipient semantics. It is the proposer-designated recipient used by the existing bid flow.

`gross_value` and `burn_amount` are stored values in the settlement object. They make the obligation easy to audit from consensus state.

The builder does not supply `burn_amount` as a separate signed input. Consensus derives it from the signed `gross_value`.

Replace the EIP-7732 `builder_pending_payments` state vector with an equivalent `builder_pending_settlements` vector.

### Pending builder liability

The pending-liability helper MUST count both trustless proposer payments and burns.

Conceptually:

```python
def get_pending_builder_liability(state: BeaconState, builder_index: BuilderIndex) -> Gwei:
    pending_withdrawals = sum(
        withdrawal.amount
        for withdrawal in state.builder_pending_withdrawals
        if withdrawal.builder_index == builder_index
    )
    pending_settlements = sum(
        settlement.withdrawal.amount + settlement.burn_amount
        for settlement in state.builder_pending_settlements
        if settlement.withdrawal.builder_index == builder_index
    )
    return Gwei(pending_withdrawals + pending_settlements)
```

`can_builder_cover_bid` MUST use the new bid's `consensus_liability`.

`can_builder_cover_bid` MUST NOT require collateral for the trusted `execution_payment`.

Conceptually:

```python
def can_builder_cover_bid(
    state: BeaconState,
    builder_index: BuilderIndex,
    consensus_liability: Gwei,
) -> bool:
    builder_balance = state.builders[builder_index].balance
    pending_liability = get_pending_builder_liability(state, builder_index)
    min_balance = MIN_DEPOSIT_AMOUNT + pending_liability
    if builder_balance < min_balance:
        return False
    return builder_balance - min_balance >= consensus_liability
```

Builder exit processing MUST treat a pending burn as a pending builder liability.

A builder MUST NOT exit while a pending burn or a pending trustless proposer payment exists.

Pending consensus liabilities have priority over later deductions from builder balance. A state transition that decreases a builder balance MUST leave enough balance to cover all pending builder liabilities that remain after that transition.

For each builder after such a transition, this invariant MUST hold:

```text
builder_balance >= get_pending_builder_liability(state, builder_index)
```

A future penalty or slashing rule that decreases builder balance MUST preserve this invariant or MUST first resolve the affected pending liabilities.

### Process an execution payload bid

For `BUILDER_INDEX_SELF_BUILD`, these conditions MUST hold:

```text
gross_value == 0
execution_payment == 0
```

A self-build does not create a burn or a pending settlement.

For an external builder, the implementation MUST do these steps:

1. Calculate `B`, `V`, and `C`.
2. Verify that `execution_payment <= gross_value - B`.
3. Perform the existing EIP-7732 builder activity, version, and signature checks.
4. Verify that the builder can cover `C` and all other pending liabilities.
5. If `C > 0`, record one `BuilderPendingSettlement` that contains `B` and `V`.
6. Cache the bid as the latest execution payload bid as specified by EIP-7732.

Conceptually:

```python
burn_amount, trustless_payment, _ = get_bid_payment_components(bid)
consensus_liability = Gwei(burn_amount + trustless_payment)

if bid.builder_index == BUILDER_INDEX_SELF_BUILD:
    assert bid.gross_value == 0
    assert bid.execution_payment == 0
    assert signed_bid.signature == bls.G2_POINT_AT_INFINITY
else:
    assert is_active_builder(state, bid.builder_index)
    assert state.builders[bid.builder_index].version == PAYLOAD_BUILDER_VERSION
    assert can_builder_cover_bid(state, bid.builder_index, consensus_liability)
    assert verify_execution_payload_bid_signature(state, signed_bid)

if consensus_liability > 0:
    settlement = BuilderPendingSettlement(
        weight=0,
        withdrawal=BuilderPendingWithdrawal(
            fee_recipient=bid.fee_recipient,
            amount=trustless_payment,
            builder_index=bid.builder_index,
        ),
        proposer_index=get_beacon_proposer_index(state),
        gross_value=bid.gross_value,
        burn_amount=burn_amount,
    )
    state.builder_pending_settlements[
        SLOTS_PER_EPOCH + bid.slot % SLOTS_PER_EPOCH
    ] = settlement
```

### Atomic settlement lifecycle

The burn and the trustless proposer payment MUST use one liability decision.

A pending settlement has only two final results:

1. `PAYABLE`: `B` and `V` both become payable.
2. `RELEASED`: the protocol charges neither `B` nor `V`.

The protocol MUST NOT charge `B` and release `V`.

The protocol MUST NOT pay `V` and release `B`.

The existing EIP-7732 payment conditions MUST control the complete settlement. These conditions include the normal payload path and the builder-payment quorum path.

This EIP does not add a separate burn-liability condition.

If an EIP-7732 proposer-slashing path clears a pending payment, it MUST clear the matching `BuilderPendingSettlement`.

That path MUST NOT charge `B` or `V`.

### Apply a payable settlement

When a settlement becomes payable, consensus MUST do these steps:

1. Deduct `burn_amount` from the builder's consensus-layer balance.
2. Do not create an execution-layer credit for `burn_amount`.
3. If `withdrawal.amount > 0`, append the `BuilderPendingWithdrawal` for the trustless proposer payment.
4. Clear the `BuilderPendingSettlement`.

Conceptually:

```python
def settle_builder_settlement(state: BeaconState, settlement_index: Uint64) -> None:
    settlement = state.builder_pending_settlements[settlement_index]
    builder_index = settlement.withdrawal.builder_index
    settlement_liability = settlement.burn_amount + settlement.withdrawal.amount

    assert state.builders[builder_index].balance >= settlement_liability

    if settlement.burn_amount > 0:
        state.builders[builder_index].balance -= settlement.burn_amount

    if settlement.withdrawal.amount > 0:
        state.builder_pending_withdrawals.append(settlement.withdrawal)

    state.builder_pending_settlements[settlement_index] = BuilderPendingSettlement()
```

The balance reduction for `B` is the burn.

The protocol MUST NOT represent `B` as an execution-layer transfer to a burn address.

The existing withdrawal path continues to process `V`.

### Settlements outside the pending window

EIP-7732 has a direct-payment path for a parent payload whose pending-payment entry is no longer in the bounded window.

Any equivalent path under this EIP MUST settle the burn and the trustless proposer payment together.

The implementation MUST derive `B` and `V` from the cached signed bid.

The implementation MUST then do these actions in one settlement operation:

1. Deduct `B` from the builder's consensus-layer balance.
2. Queue `V` as a builder withdrawal if `V > 0`.

A late-payload path MUST NOT queue `V` without the matching burn.

### Attestation weight accounting

EIP-7732 uses attestation weight to decide when a pending builder payment becomes payable if the normal payload path is not available.

Under this EIP, weight MUST accumulate when the pending `consensus_liability` is not zero.

This rule also applies when `V == 0` and `B > 0`.

An implementation MUST use a check equivalent to this check:

```python
def has_pending_consensus_liability(settlement: BuilderPendingSettlement) -> bool:
    return settlement.withdrawal.amount + settlement.burn_amount > 0
```

The quorum threshold does not change.

The other EIP-7732 attestation rules do not change.

### Public bid gossip

The existing EIP-7732 public-gossip rule MUST remain unchanged:

```text
execution_payment == 0
```

Therefore, every public bid has:

```text
C = G
```

A public bid is fully collateralized for its complete gross commitment.

Public gossip MUST compare `gross_value` instead of the former `value` field.

For public bids, the burn fraction is constant and `execution_payment == 0`. Therefore, ordering by `gross_value` is also ordering by the trustless proposer payment.

The existing EIP-7732 one-bid-per-builder-per-slot-and-parent gossip policy does not change.

### Private and relay bids

A bid that does not use the public gossip topic MAY have `execution_payment > 0`.

The following condition MUST hold:

```text
execution_payment <= gross_value - burn_amount
```

Consensus guarantees only `B + V`.

The builder MUST provide consensus collateral for `B + V`.

Consensus does not define the credit value of `E`.

A proposer MAY discount or reject `E`. A proposer MAY use relay guarantees, builder reputation, or other local information to value `E`.

`gross_value` sets the burn and the builder's declared total commitment.

`gross_value` does not tell the proposer how to compare bids that have different trusted-payment risk.

### Self-built payloads

A self-built payload MUST have these values:

```text
builder_index == BUILDER_INDEX_SELF_BUILD
gross_value == 0
execution_payment == 0
```

A self-built payload does not create a burn.

The protocol does not estimate MEV that a proposer keeps inside a self-built payload.

### Burn observability

For each selected external-builder bid, canonical data MUST make these values derivable:

```text
slot
builder_index
gross_value
burn_amount
trustless_payment
execution_payment
settlement outcome
```

The signed bid is the source of truth for `gross_value` and `execution_payment`.

Consensus derives `burn_amount` and `trustless_payment`.

Consensus clients SHOULD expose these values through a stable state-inspection, event, or API surface.

This exposure supports supply accounting and post-fork economic analysis.

This EIP does not define a specific API endpoint.

### Chain specifics

Mainnet is proposed to use this burn fraction:

```text
BUILDER_PAYMENT_BURN_NUMERATOR   = 1
BUILDER_PAYMENT_BURN_DENOMINATOR = 3
```

A devnet or testnet MAY use a different fraction.

The active values MUST be part of chain configuration.

The values MUST NOT change without a protocol upgrade.

## Rationale

### Why `gross_value` includes all builder expenditure

`gross_value` is the total economic expenditure in the selected builder bid.

It includes the burn and all declared proposer compensation:

```text
G = B + V + E
```

This definition keeps the burn fraction easy to understand.

At a one-third burn rate, the protocol destroys about one third of the builder's declared gross expenditure. The remaining amount is proposer compensation.

The burn is not a charge on proposer revenue. The protocol removes the burn from the builder's gross bid. The proposer revenue is only the net amount `P = G - B`.

An alternative definition could make `gross_value` equal only to proposer compensation. The burn would then be an extra cost on top of `gross_value`.

That alternative changes the meaning of the rate constant. It also makes historical backcasts and payment-avoidance calculations use a different parameter.

This EIP uses expenditure-inclusive `gross_value` so that the rate has one meaning in all parts of the analysis.

### Why derive `V`

The builder supplies only two monetary fields:

- `gross_value`;
- `execution_payment`.

Consensus derives `burn_amount` and `trustless_payment`.

This design removes redundant monetary fields.

If the builder supplied all four values, consensus would have to check the same accounting identity in many places.

A derived value cannot disagree with the source fields.

### Why retain `execution_payment`

If all proposer compensation had to be trustless, builders would need consensus-layer collateral for the complete proposer payment.

A rare high-value block could then require a very large builder balance.

Large collateral requirements can favor the largest builders.

`execution_payment` keeps the EIP-7732 distinction between trustless and trusted proposer compensation.

The builder fully collateralizes its protocol commitments:

```text
C = B + V
```

The builder does not collateralize `E` through consensus.

The burn still uses `G`. It does not use only `V`.

Therefore, a declared trusted payment does not remove its share of the burn.

If a builder increases `G` to advertise a larger trusted payment, the builder also increases its fully collateralized burn liability.

This makes a false high trusted-payment declaration more expensive than a design that burns only the trustless payment.

This rule does not make `E` trustless. The builder can still fail to deliver `E`. Consensus does not resolve that default.

### Why public bids require `E == 0`

The public ePBS topic is the default path for proposers that do not use a relay-specific credit relationship.

A public bid must have `execution_payment == 0`.

Therefore, every public bid is fully collateralized:

```text
C = G
```

A proposer that uses only public gossip does not accept trusted-payment risk by default.

Private and relay paths can use trusted payments. This can reduce builder collateral needs without changing the trust model of public gossip.

### Why there is no minimum trustless payment

This EIP does not set a minimum `V`.

A proposer can accept a private bid in which some or all proposer compensation is trusted.

The protocol still fully collateralizes the burn and any nonzero trustless payment.

A minimum `V` would make consensus choose an arbitrary credit-risk floor.

A minimum `V` would also increase builder collateral needs.

A minimum could cause bids to group at the minimum value.

The public path stays fully trustless because it requires `E == 0`.

### Why self-build is exempt

A self-built block has no external builder payment that the protocol can measure as `gross_value`.

A rule that asks a self-builder to declare its own MEV is not enforceable.

A self-builder can keep value in many execution-layer accounts. A self-builder can also use private order flow or integrated search.

Therefore, self-build has no burn under this EIP.

The exemption also keeps local building as a fallback against builder concentration.

Local building is often most competitive in low-value slots. The burn on external builder payments can increase local building in this part of the distribution.

A large staking operator can also own a builder and use self-build to avoid the burn on high-value slots. The "Self-build avoidance and vertical integration" subsection describes this risk.

### Why there is no attester burn floor

A burn floor based on bids that each attester saw before a deadline is not an objective consensus value.

Honest nodes can receive different bids because of normal network delay.

An attacker can also send a bid to only part of the network.

Different local bid sets can create different local burn floors.

This EIP does not use local bid observations for burn decisions.

Attesters do not price MEV. Attesters do not add a burn rule to fork choice.

The protocol derives the burn from the selected signed bid and a chain constant.

### Why burn and payment use one settlement lifecycle

The burn and the trustless proposer payment come from the same builder commitment.

A separate liability rule for the burn can create an error during a reorganization or withholding case.

For example, one path could charge the burn while another path releases the proposer payment.

`BuilderPendingSettlement` prevents this split.

One state object contains both protocol liabilities. One liability transition resolves both liabilities.

### Why the burn occurs in the consensus layer

EIP-7732 stores builder balance in the consensus layer.

The protocol can destroy `B` by reducing that balance without creating a matching withdrawal.

The protocol must not send `B` to an execution-layer burn address.

An execution-layer burn address still has an execution-layer balance. It does not express direct consensus-layer supply destruction.

### Proposed burn fraction and historical scale

The proposed mainnet rate is one third.

This rate is intended to be large enough to reduce visible proposer windfalls. It also leaves most gross builder expenditure as proposer compensation.

The following historical comparison uses aggregate data from August 2025 through July 2026.

During this period:

- gross MEV-Boost proposer payments were approximately 72,619 ETH;
- execution base-fee burn was approximately 27,546 ETH.

The following table is a static backcast. It does not include behavioral changes after a burn is introduced.

| Burn rate | Additional builder-payment burn | Relative to execution base-fee burn | Proposer share of gross bid |
| ---: | ---: | ---: | ---: |
| 25% | about 18,155 ETH | about 65.9% | 75% |
| 33 1/3% | about 24,206 ETH | about 87.9% | about 66 2/3% |
| 40% | about 29,048 ETH | about 105.5% | 60% |

The 365-day period has 2,628,000 scheduled slots.

The same aggregate data gives these approximate values per scheduled slot:

| Quantity | ETH per scheduled slot |
| --- | ---: |
| Gross external builder payments | 0.0276 |
| Execution base-fee burn | 0.0105 |
| 25% builder-payment burn | 0.0069 |
| 33 1/3% builder-payment burn | 0.0092 |
| 40% builder-payment burn | 0.0111 |

These numbers show the possible scale of the mechanism. They do not predict the final market result.

A burn can change proposer and builder behavior. It can change how much value stays in declared external-builder bids.

Let `q(t)` be the fraction of baseline gross builder-payment value that remains in declared external ePBS bids at burn rate `t`.

Then:

```text
realized_burn(t) = t * q(t) * baseline_gross_value
```

This equation gives direct tests for candidate rates.

For example:

```text
one-third burn is greater than 25% burn if:
q(1/3) / q(1/4) > 0.75
```

Also:

```text
40% burn is greater than one-third burn if:
q(0.40) / q(1/3) > 0.8333
```

A higher rate is counterproductive if it causes enough gross value to leave the bid path where the burn applies.

For an expenditure-inclusive bid, the extra gross expenditure that is required to give a fixed proposer payment is:

```text
t / (1 - t)
```

The following table shows this amount:

| Burn rate | Extra gross expenditure per unit of proposer compensation |
| ---: | ---: |
| 25% | 33.3% |
| 33 1/3% | 50% |
| 40% | 66.7% |

A higher rate gives more reason to use self-build or undeclared payment channels.

For this reason, payment retention and self-build behavior are primary evaluation metrics.

### Rate evaluation metrics

Before mainnet activation, evaluations should measure these items:

1. The value-weighted share of builder payments that stays in declared ePBS `gross_value`.
2. The public-bid share and the private-bid share.
3. The distribution of `execution_payment / proposer_amount`.
4. Self-build share by block count.
5. Self-build share by estimated value that would otherwise go to an external builder.
6. High-value self-build concentration by identifiable staking operator.
7. Builder market concentration.
8. Builder collateral concentration.
9. Proposer-payment percentiles, including p50, p95, p99, and p99.9.
10. Realized burn as a fraction of declared gross external-builder value.
11. Trusted-payment defaults when they are observable.
12. Missed-payload and missed-proposal rates.
13. The gap between shadow local payload value and the best external bid.

The burn rate should not be selected only to reach a target amount of ETH burn.

The main objective is to reduce security-relevant proposer windfalls and concentration pressure.

The mechanism must also keep enough value in protocol-visible external bidding to remain effective.

## Backwards Compatibility

This EIP changes consensus and requires a hard fork.

It changes the SSZ semantics and field name of `ExecutionPayloadBid.value` to `gross_value`. The field keeps its position and its type. The container layout does not change.

It changes the builder pending-payment state object.

It changes builder collateral accounting.

A pre-fork signed bid is not valid as a post-fork bid.

Consensus clients, validator clients, builders, relays, and APIs must use the new bid semantics after activation.

The public bid path keeps the same trust model. Public bids still have `execution_payment == 0`. Public bids are fully collateralized. Public bids use one scalar value for ordering.

If the final EIP-7732 container keeps the field name `value`, an implementation-compatible fallback reuses the existing field in place.

In this fallback, consensus reads `value` as `gross_value`. The field keeps its position and its type. The fallback does not add a field. The fallback does not change the container layout.

Consensus then derives `burn_amount` and `trustless_payment` from `value` and `execution_payment`. This derivation is the same as the Specification derivation for `gross_value`.

The fallback does not add a redundant field.

## Test Cases

The following examples use a one-third burn rate.

The examples use simple integer units.

### Fully trustless public bid

Input:

```text
G = 9
E = 0
```

Expected result:

```text
B = 3
P = 6
V = 6
C = 9
```

The bid is valid for public gossip.

The builder needs 9 units of consensus collateral.

### Partially trusted private bid

Input:

```text
G = 9
E = 2
```

Expected result:

```text
B = 3
P = 6
V = 4
C = 7
```

The bid is not valid for public gossip.

Consensus requires 7 units of builder collateral.

### All proposer compensation is trusted

Input:

```text
G = 9
E = 6
```

Expected result:

```text
B = 3
P = 6
V = 0
C = 3
```

The bid is valid only through a private or relay path.

The burn is fully collateralized.

The proposer payment is fully trusted.

Attestation weight must still accumulate because `C > 0`.

### Invalid trusted payment

Input:

```text
G = 9
E = 7
```

Derived values:

```text
B = 3
P = 6
```

The bid is invalid because `E > P`.

### Rounding

Input:

```text
G = 10
E = 0
```

Expected result:

```text
B = 3
P = 7
V = 7
C = 10
```

The division remainder stays in proposer compensation.

### Zero burn rate

Use this test configuration:

```text
BUILDER_PAYMENT_BURN_NUMERATOR = 0
BUILDER_PAYMENT_BURN_DENOMINATOR = 1
G = 9
E = 0
```

Expected result:

```text
B = 0
P = 9
V = 9
C = 9
```

The payment accounting is equivalent to the fully trustless EIP-7732 payment path after mapping `gross_value` to the former trustless bid value.

### Full burn rate

Use this test configuration:

```text
BUILDER_PAYMENT_BURN_NUMERATOR = 1
BUILDER_PAYMENT_BURN_DENOMINATOR = 1
G = 9
E = 0
```

Expected result:

```text
B = 9
P = 0
V = 0
C = 9
```

A bid with `G = 9` and `E > 0` is invalid at a full burn rate because `P = 0`.

### Large-value multiplication

Use this test configuration:

```text
BUILDER_PAYMENT_BURN_NUMERATOR = 2
BUILDER_PAYMENT_BURN_DENOMINATOR = 3
G = 18446744073709551615
E = 0
```

Expected result:

```text
B = 12297829382473034410
P = 6148914691236517205
V = 6148914691236517205
C = 18446744073709551615
```

The mathematical product `G * 2` is greater than the maximum `uint64` value. The implementation must still calculate the expected result without intermediate overflow.

### Self-build

Input:

```text
builder_index = BUILDER_INDEX_SELF_BUILD
G = 0
E = 0
```

Expected result:

```text
B = 0
V = 0
C = 0
```

The protocol does not create a pending settlement.

A self-build is invalid if `G != 0` or `E != 0`.

### Pending-liability balance invariant

Assume a builder has 12 units of consensus-layer balance. Assume the builder has 9 units of pending consensus liability.

A separate state transition tries to deduct 4 units before the pending liability is resolved.

The transition is invalid because the resulting balance would be 8 and the remaining pending liability would be 9.

A deduction that leaves at least 9 units can satisfy this EIP invariant. Other EIP-7732 balance rules can still make that deduction invalid.

### Successful payload settlement

Given this pending settlement:

```text
B = 3
V = 6
```

When the normal EIP-7732 payment path makes the settlement payable, consensus must do these actions:

1. Decrease the builder consensus balance by 3.
2. Queue a builder withdrawal of 6 for the proposer.
3. Clear the pending settlement.

### Quorum settlement without the normal payload path

Use the same pending settlement:

```text
B = 3
V = 6
```

If the EIP-7732 builder-payment quorum makes the settlement payable, consensus must do the same actions:

1. Decrease the builder consensus balance by 3.
2. Queue a builder withdrawal of 6.
3. Clear the pending settlement.

The burn and trustless payment must have the same result.

### Released settlement

If EIP-7732 releases the builder from the pending payment, consensus must produce this result:

```text
burn charged = 0
withdrawal queued = 0
```

Consensus must clear the pending settlement.

### Late parent settlement

A parent payload can arrive after its pending settlement leaves the bounded pending-settlement window.

In this case, the implementation must derive `B` and `V` from the cached bid.

The implementation must apply both components in the same settlement operation.

A test must fail if the implementation can queue `V` without also applying `B`.

## Reference Implementation

A complete reference implementation requires a consensus-spec change against the final post-EIP-7732 fork specification.

The Specification section is the normative source for an implementation. It defines the modified `ExecutionPayloadBid`, the `BuilderPendingSettlement` state object, the burn and payment helpers, and the settlement, liability, and gossip rules.

## Security Considerations

### Undeclared proposer compensation

Ethereum can burn only value that appears in consensus-visible bid data.

A builder and proposer can try to move compensation outside `gross_value`.

Examples include later transfers, bilateral agreements, vertically integrated accounting, or other side payments.

This EIP does not make undeclared value observable.

This EIP does not claim to burn undeclared value.

A higher burn fraction gives a stronger incentive to use a payment path where the burn does not apply.

For this reason, mainnet activation should use measurements or simulations of value-weighted payment retention for candidate rates.

### Collusion and evasion economics

This EIP does not prevent collusion.

Two evasion paths remain open:

- A group of builders can agree to declare a low `gross_value`. They can settle the rest through another channel.
- A builder and a proposer can agree to declare a low `gross_value`. They can move the rest through a side payment.

Each path can reduce the declared burn to near zero for the affected bids. The protocol cannot burn value that does not appear in a signed bid. The "Undeclared proposer compensation" and "Self-build avoidance and vertical integration" subsections describe this same limit.

The partial burn fraction is a deliberate response to this limit. The rate does not try to capture all execution value. The rate stays below the value at which evasion is worthwhile in the common case.

Two properties support a moderate rate.

First, most slots have modest builder payments. A fraction of a small payment is a small amount. The fixed cost and the counterparty risk of a side channel are larger than this burn. The fixed cost and the counterparty risk of a sustained cartel are also larger than this burn. For most blocks and most proposers, honest declaration through the public bid path costs less than evasion.

Second, the large and rare opportunities occur in unpredictable slots. A builder cannot move a high-value opportunity to a chosen proposer. A proposer cannot choose to receive one. A single high-value opportunity occurs in one slot. That slot has one fixed proposer. To evade the burn on this tail, an actor needs one of two things. The first is a standing side channel with a large share of proposers. The second is a builder and a large staker under one control that self-builds these slots. In a competitive builder market, the proposer for the slot selects the best public bid, and the burn applies.

A higher rate would increase the reward for evasion in every block. A higher rate would lower the value at which a side channel or a cartel becomes worthwhile. A higher rate would move more value out of the bid path where the burn applies. The `q(t)` analysis in the Rationale describes this effect.

A moderate rate keeps the public bid path the lowest-cost path for most blocks. A moderate rate still burns a meaningful share of the visible high-value tail that lands on proposers outside a cartel.

This reasoning reduces the incentive to evade. It does not remove the evasion paths. A sustained builder cartel is a residual risk. A vertically integrated large staker is also a residual risk. Evaluation must measure declared payment retention and high-value self-build concentration. The "Rate evaluation metrics" subsection lists these measurements.

### Trusted payment default

`execution_payment` remains trusted.

A proposer that accepts `E > 0` accepts counterparty risk.

Consensus does not insure that risk.

This EIP makes a large declared trusted payment costly to exaggerate if it increases `G`.

A larger `G` causes a larger fully collateralized burn.

However, the builder can still fail to deliver `E`.

The public gossip path avoids this risk because it requires `E == 0`.

### Proposer ranking across trust classes

The burn increases with `gross_value`.

A rational proposer values a private bid according to the expected value of the trusted payment.

Therefore, the proposer can select a lower-`gross_value` bid if the other bid has more trusted-payment risk.

This result is normal credit-risk pricing. It is not a consensus failure.

The protocol does not define a global credit model.

### Self-build avoidance and vertical integration

Self-build has no burn because the protocol cannot objectively measure internal MEV.

This exemption can create an avoidance path.

A large staking operator can own or control a specialized builder. The operator can then use self-build for valuable slots.

If high-value external-builder slots move to integrated self-build, realized burn can decrease.

This behavior can also increase the advantage of large or vertically integrated staking operators.

Evaluation must measure more than the self-build block count.

Evaluation should estimate the value that moved from external bidding to self-build.

Evaluation should also measure the concentration of high-value self-build by operator.

### Builder capital concentration

The builder must fully collateralize the burn.

A fully trustless public bid requires collateral for all of `G`.

A private bid can reduce consensus collateral by using `E` for part of proposer compensation.

A high burn rate still creates material collateral requirements.

Exceptional-MEV slots can create especially large requirements.

Multiple pending liabilities can also increase working-capital needs.

Large collateral requirements can favor large builders.

Builder balance concentration and builder market concentration should be measured before and after activation.

### Residual proposer jackpots

A proportional burn reduces a visible proposer payment by the configured fraction.

It does not remove the remaining payment.

At a one-third burn rate, about two thirds of a fully trustless gross bid remains proposer compensation.

An exceptional bid can therefore still create a large proposer windfall.

Large remaining windfalls can preserve incentives for reorganization, key theft, targeted denial of service, or operator misconduct.

For security analysis, proposer-payment percentiles are more useful than aggregate burn alone.

The analysis should include p99 and p99.9 proposer payments.

### Builder payload withholding

This EIP does not solve the EIP-7732 builder free-option or payload-withholding problem.

This EIP changes the destination of a payable builder commitment.

This EIP does not add a delivery bond or a new withholding penalty.

A future EIP-7732 liability change must preserve the atomic relationship between `B` and `V`.

### Reorganizations and liability coupling

The burn and the trustless proposer payment must use the same payable condition.

An implementation must not charge the burn before the shared liability decision.

An implementation must not release one component and charge the other component.

An incorrect implementation can create supply-accounting errors or unfair builder losses.

Tests must cover reorganization, proposer slashing, payload absence, quorum payment, and delayed payload processing.

### Supply accounting

The burn decreases a consensus-layer builder balance.

The protocol does not create an execution-layer withdrawal for the burned amount.

Supply accounting must count the destruction exactly once.

The protocol must not also represent the burn as an execution-layer transfer or withdrawal.

### Integer arithmetic and rounding

The burn uses integer floor division.

The division remainder stays in proposer compensation.

Implementations must not use floating-point arithmetic.

Implementations must not allow intermediate overflow in the burn calculation. This requirement applies even when `gross_value` is near the maximum `Gwei` value and the configured numerator is greater than one.

All implementations must calculate the same integer result.

### No new attester pricing duty

An implementation must not reject an otherwise valid block because the node saw a higher builder bid locally.

This requirement prevents consensus behavior from depending on local message history. The "Why there is no attester burn floor" subsection explains why the burn does not use local bid observations.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
