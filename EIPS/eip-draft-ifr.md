---
eip: <to be assigned>
title: Invariant-First Reserve Receipt Token (IFR) (pETH)
description: A standard for reserve-backed ERC-20 tokens that enforce solvency as a transaction-validity condition via an on-chain accounting invariant.
author: Emiliano Solazzi Griminger
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2026-06-09
requires: 20
copyright: CC0-1.0
---

## Abstract

This EIP defines an **Invariant-First Reserve Receipt Token (IFR)** — an ERC-20-compatible primitive for reserve-backed tokens that enforces solvency as a transaction-validity condition rather than an external proof-of-reserves report.

The token represents claims on a native ETH reserve governed by a strict three-variable state tuple and two invariants that **MUST** hold after every state-changing operation:

- **Accounting invariant:** `T + F == R`
- **Physical reserve invariant:** `address(this).balance >= R`

Where:

- `R` — accounted reserve (wei)
- `T` — outstanding redeemable token supply (token units)
- `F` — protocol fee slice retained inside the reserve (wei)

If any state transition would violate these invariants, the transaction **MUST** revert.

---

## Motivation

Existing ETH wrapper and reserve-backed token designs share three structural weaknesses:

1. **Opaque solvency.** Reserve health is reported off-chain or informally, not enforced on-chain per transaction.
2. **Undifferentiated fee accounting.** Protocol fees are mixed with user backing without explicit attribution, making it impossible for integrators to distinguish user-redeemable backing from protocol-owned reserve.
3. **No canonical invariant interface.** There is no standard for wallets, explorers, auditors, or downstream protocols to query reserve state, fee attribution, or invariant status in a uniform way.

These weaknesses create systemic risk: insolvency can accumulate silently across blocks, and integrators have no on-chain signal until a withdrawal fails.

This EIP introduces a standard where:

- **Solvency is a local transaction property** — enforced by the contract itself at every state change.
- **Fee attribution is explicit** — `F` is a named, tracked, protocol-owned slice of the reserve, not an implicit residual.
- **Surplus is handled canonically** — ETH force-sent to the contract (e.g., via `selfdestruct`) is detected, quarantined from user backing, and optionally absorbed as protocol fees.
- **Integrators have a standard view interface** — any contract conforming to IFR exposes the full state tuple, fee helpers, surplus view, and invariant check functions.

The reference implementation (`InvariantFirstReserveToken`, pETH-IFE) demonstrates this pattern for native ETH collateral.

---

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### 1. State Tuple

Every IFR implementation MUST maintain three state variables:

| Variable | Type | Description |
|----------|------|-------------|
| `R` | `uint256` | Accounted reserve: total ETH (wei) the contract considers backing the system |
| `T` | `uint256` | Outstanding supply: total redeemable receipt tokens in circulation |
| `F` | `uint256` | Accumulated fees: protocol-owned slice of `R`, denominated in wei |

### 2. Invariants

Implementations **MUST** enforce both invariants after every state-changing operation. Any operation that would violate an invariant **MUST** revert before state is committed.

#### 2.1 Accounting Invariant

```
T + F == R
```

- Overflow guard: if `T > type(uint256).max - F`, the implementation **MUST** revert with a defined overflow error.

#### 2.2 Physical Reserve Invariant

```
address(this).balance >= R
```

- If the contract's actual ETH balance is less than `R`, the implementation **MUST** revert.

### 3. Economic Transitions

Let `x` denote a gross deposit or burn amount, and `f = fee(x)` the protocol fee on that amount.

#### 3.1 Mint

Deposits ETH and mints receipt tokens.

- **Input:** `x = msg.value` (gross ETH deposit, MUST be > 0)
- **Fee:** `f = fee(x)`
- **Minted:** `m = x - f` (MUST be > 0)
- **State transition:**

```
R' = R + x
T' = T + m
F' = F + f
```

- **Constraints:**
  - `msg.value > 0`
  - `m > 0`
  - Recipient MUST NOT be the zero address or the token contract itself.

#### 3.2 Burn

Burns receipt tokens and releases ETH to a receiver.

- **Input:** `x` (token amount to burn, MUST be > 0)
- **Fee:** `f = fee(x)`
- **Released:** `r = x - f` (MUST be > 0)
- **State transition:**

```
R' = R - r
T' = T - x
F' = F + f
```

> **Note:** `R` decreases by the released amount `r = x - f`, not by the gross burned amount `x`. This is the critical difference from a naive unwrap.

- **Constraints:**
  - `x > 0`
  - Caller's token balance MUST be >= `x`.
  - Receiver MUST NOT be the zero address or the token contract itself.

#### 3.3 Sweep Fees

Transfers accumulated protocol fees to a designated treasury address.

- **Input:** `y` (fee amount to sweep, MUST satisfy `0 < y <= F`)
- **State transition:**

```
R' = R - y
T' = T        (unchanged)
F' = F - y
```

- `y` is bounded by `F`, so this operation **MUST NOT** reduce user backing.
- Implementations SHOULD restrict this operation to a designated treasury role.

#### 3.4 Absorb Surplus as Fees

Brings force-sent ETH surplus into the accounted reserve as protocol fees.

- **Input:** `y` (surplus amount to absorb, MUST satisfy `0 < y <= surplus()`)
- **State transition:**

```
R' = R + y
T' = T        (unchanged)
F' = F + y
```

This preserves `T + F == R` and makes the previously unaccounted ETH sweepable as protocol fees.

### 4. Surplus

Surplus is ETH held by the contract above the accounted reserve:

```solidity
function surplus() public view returns (uint256) {
    uint256 bal = address(this).balance;
    if (bal <= R) return 0;
    return bal - R;
}
```

Surplus is **not** user backing unless explicitly absorbed via `absorbSurplusAsFees`. ETH arriving via `selfdestruct` or other force-credit mechanisms produces surplus and does not affect `R`, `T`, or `F` until absorbed.

### 5. Fee Calculation

Implementations **SHOULD** use the following overflow-safe basis-point fee formula:

```solidity
uint256 public constant BPS_DENOMINATOR = 10_000;

function _fee(uint256 amount) internal view returns (uint256) {
    return ((amount / BPS_DENOMINATOR) * feeBps)
        + (((amount % BPS_DENOMINATOR) * feeBps) / BPS_DENOMINATOR);
}
```

This formula is algebraically equivalent to `amount * feeBps / 10_000` for all finite inputs but avoids intermediate overflow for large `amount` values.

- `feeBps` SHOULD be bounded by a `MAX_FEE_BPS` constant (RECOMMENDED maximum: `1_000` = 10%).
- A `feeBps` of `0` is valid and produces a strict 1:1 mint/burn with no fee accumulation.

### 6. Required Interface

Implementations **MUST** be ERC-20 compatible. Implementations **MUST** expose the following additional functions:

```solidity
interface IInvariantFirstReserveToken is IERC20 {

    // ── State & invariant views ──────────────────────────────────────────────

    /// @notice Returns the full state tuple.
    /// @return accountedReserve  R: total accounted ETH backing the system (wei)
    /// @return outstandingSupply T: total redeemable token supply
    /// @return accumulatedFees   F: protocol-owned fee slice inside R (wei)
    /// @return actualETHBalance  address(this).balance at call time
    function stateTuple()
        external
        view
        returns (
            uint256 accountedReserve,
            uint256 outstandingSupply,
            uint256 accumulatedFees,
            uint256 actualETHBalance
        );

    /// @notice Returns true if both invariants hold.
    function invariant() external view returns (bool);

    /// @notice Returns detailed invariant diagnostics.
    /// @return holds                 True if both invariants hold.
    /// @return accountingDiff        |T + F - R|; zero when accounting invariant holds.
    /// @return reserveShortfallAmount R - balance when balance < R; otherwise zero.
    /// @return surplusAmount         balance - R when balance > R; otherwise zero.
    function checkInvariant()
        external
        view
        returns (
            bool holds,
            uint256 accountingDiff,
            uint256 reserveShortfallAmount,
            uint256 surplusAmount
        );

    // ── Fee helpers ──────────────────────────────────────────────────────────

    /// @notice Returns the fee for a given gross amount.
    function calculateFee(uint256 amount) external view returns (uint256);

    /// @notice Previews the result of a mint for a given gross deposit.
    function previewMint(uint256 grossDeposit)
        external
        view
        returns (uint256 fee, uint256 minted);

    /// @notice Previews the result of a burn for a given token amount.
    function previewBurn(uint256 burnAmount)
        external
        view
        returns (uint256 fee, uint256 released);

    // ── Backing views ────────────────────────────────────────────────────────

    /// @notice ETH surplus above accounted reserve; not user backing.
    function surplus() external view returns (uint256);

    /// @notice User-redeemable backing. SHOULD equal T.
    function userRedeemableBacking() external view returns (uint256);

    /// @notice Protocol-owned fee backing. SHOULD equal F.
    function protocolFeeBacking() external view returns (uint256);

    // ── Optional ─────────────────────────────────────────────────────────────

    /// @notice Semantic version string for telemetry and integrations.
    function version() external view returns (string memory);
}
```

Implementations MAY expose additional view helpers (e.g., `reserveToSupplyRatioBps()`).

### 7. Direct ETH Transfer Rejection

To prevent bypassing mint accounting, implementations **SHOULD** reject direct ETH transfers:

```solidity
receive() external payable {
    revert DirectETHNotAccepted();
}

fallback() external payable {
    revert DirectETHNotAccepted();
}
```

Surplus from force-credit mechanisms (e.g., `selfdestruct`) remains handleable via `absorbSurplusAsFees`.

### 8. Reentrancy

Implementations **MUST** guard all functions that execute external ETH transfers with a reentrancy guard or equivalent CEI pattern. The RECOMMENDED minimum guard:

```solidity
uint256 private constant _NOT_ENTERED = 1;
uint256 private constant _ENTERED     = 2;
uint256 private _status;

modifier nonReentrant() {
    if (_status == _ENTERED) revert Reentrancy();
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
}
```

### 9. Required Errors

Implementations **MUST** revert with typed errors on the following conditions:

| Error | Condition |
|-------|-----------|
| `ZeroAmount()` | Input amount is zero |
| `ZeroAddress()` | Address argument is the zero address |
| `InvalidReceiver(address)` | Receiver is the token contract itself |
| `InsufficientBalance(address, uint256, uint256)` | Caller balance < requested burn amount |
| `InsufficientAllowance(address, address, uint256, uint256)` | Allowance < requested transfer amount |
| `InvariantViolation(uint256 T, uint256 F, uint256 R)` | `T + F != R` after a transition |
| `InvariantOverflow(uint256 T, uint256 F)` | `T + F` would overflow |
| `ReserveShortfall(uint256 actual, uint256 R)` | `address(this).balance < R` |
| `SweepExceedsFees(uint256 requested, uint256 F)` | Sweep amount > `F` |
| `SurplusTooSmall(uint256 requested, uint256 available)` | Absorb amount > `surplus()` |
| `ETHTransferFailed(address, uint256)` | ETH transfer call returned false |
| `Reentrancy()` | Reentrant call detected |
| `DirectETHNotAccepted()` | ETH sent directly to `receive()` or `fallback()` |

---

## Rationale

### Invariant-first design

Enforcing `T + F == R` and `address(this).balance >= R` after every state change makes solvency a local, per-transaction property. Any mis-accounting — unbacked minting, fee miscalculation, or reserve drain — causes an immediate revert. This is categorically different from proof-of-reserves reports, which are episodic and require trust in the reporting process.

### Fee-from-backing accounting

The three-variable tuple cleanly separates:

- **User-redeemable backing (`T`):** what token holders can claim.
- **Protocol-owned backing (`F`):** fees retained inside the reserve.
- **Total accounted reserve (`R`):** the sum, which must equal the contract's accounting of its ETH holdings.

This makes fee attribution transparent and auditable at any block without off-chain tooling.

### Burn transition: `R -= released`, not `R -= burned`

The most common implementation error in reserve-backed tokens is decreasing `R` by the gross burn amount. Because a fee is taken on burn, the correct transition is `R -= (x - f)`. Using `R -= x` would underdrain the reserve, eventually making the physical reserve invariant unreachable. This EIP makes the correct transition explicit.

### Surplus quarantine

ETH can arrive via `selfdestruct` or coinbase assignment, bypassing `receive()`. Silently including this in user backing would break the invariant. Silently excluding it would cause the physical reserve invariant (`balance >= R`) to appear to hold with extra margin, potentially obscuring real shortfalls. The canonical approach defined here — detect via `surplus()`, absorb explicitly via `absorbSurplusAsFees` — gives operators a defined path while keeping invariant semantics clean.

### ERC-20 compatibility

`transfer` and `transferFrom` do not change `(R, T, F)`. Token holders transfer claims on the reserve, not reserve itself. This means all standard ERC-20 tooling (wallets, explorers, DEX routers) works without modification, while advanced integrators can layer on the additional view functions.

### Generalizability

The reference implementation uses native ETH as collateral, but the state tuple and invariant pattern applies directly to:

- ERC-20 collateral (by replacing `msg.value` and ETH transfers with token transfers),
- L2 native tokens,
- cross-chain reserve representations with bridge-controlled minting.

The interface is intentionally collateral-agnostic.

---

## Backwards Compatibility

IFR tokens are fully ERC-20 compatible. `balanceOf`, `transfer`, `approve`, `transferFrom`, and `allowance` behave exactly as specified in ERC-20. The additional functions defined in `IInvariantFirstReserveToken` are additive and do not conflict with any existing ERC standard.

Existing tooling that treats IFR tokens as plain ERC-20s will continue to function correctly. The additional interface is opt-in for integrators that want reserve and solvency data.

---

## Security Considerations

### Invariant enforcement must be post-state

The invariant check (`_assertInvariant`) **MUST** run after all state mutations in a given function. Checking before mutations — or omitting the check on any code path — can allow a violating state to persist. Implementations **SHOULD** use a modifier that runs after the function body.

### Reentrancy during ETH sends

ETH release in `burn` and `burnTo` calls an external address. This is an untrusted call: the receiver may re-enter the contract. The reentrancy guard **MUST** be applied before the ETH send and **MUST** remain set until the function returns. Checks-Effects-Interactions ordering alone is insufficient if the invariant guard also runs after the body, because the re-entrant call would find the guard unset.

### Fee truncation at small amounts

The basis-point fee formula truncates to zero for amounts below `BPS_DENOMINATOR / feeBps`. At `feeBps = 10` (0.1%), amounts below 10,000 wei produce zero fee. This is a known property, not a vulnerability, but integrators building on top of IFR tokens **SHOULD** be aware that very small deposits and withdrawals incur no fee.

### Surplus is not user backing

Surplus ETH is not reflected in `R` until explicitly absorbed. Integrators reading `R` or `T` as a reserve measure **MUST NOT** include `surplus()` in their calculations unless it has been absorbed.

### Treasury validation

The constructor does not verify that the treasury address is a payable contract. If the treasury cannot receive ETH (no `receive()` or `fallback()`), `sweepFees` will revert. Implementations **SHOULD** validate treasury payability at deployment time or allow treasury rotation.

### `selfdestruct` deprecation

The `selfdestruct` opcode behavior has changed post-EIP-6780 (Cancun). Force-credit via `selfdestruct` within the same transaction no longer transfers ETH in many contexts. Implementations relying on `selfdestruct` to test surplus handling in test suites **SHOULD** use alternative forced-ETH mechanisms as the EVM evolves.

---

## Reference Implementation

The canonical ETH-backed reference implementation is `InvariantFirstReserveToken` (pETH-IFE-1.0.0), which implements:

- The state tuple `(R, T, F)` with post-operation invariant enforcement via `_assertInvariant()`.
- `mint`, `burn`, `burnTo`, `sweepFees`, `absorbSurplusAsFees` following the transitions above.
- Full ERC-20 compatibility (`transfer`, `transferFrom`, `approve`, `increaseAllowance`, `decreaseAllowance`).
- `nonReentrant` modifier on all ETH-moving operations.
- `DirectETHNotAccepted` on `receive()` and `fallback()`.
- The full `IInvariantFirstReserveToken` view interface.

```
version(): "pETH-IFE-1.0.0"
```

The full implementation is available in the pETH repository.

---

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
