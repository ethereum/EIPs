---
eip: XXXX
title: uFund - Fund Metadata and Lifecycle Interface
description: Read-heavy interface for tokenized fund NAV, lifecycle, distributions, fees, and optional attestations.
author: Praveen Kumar (@praveensparkout)
discussions-to: https://ethereum-magicians.org/t/erc-ufund-standardized-fund-metadata-lifecycle-interface/28660
status: Draft
type: Standards Track
category: ERC
created: 2026-06-30
requires: 165
---

## Abstract

This ERC defines **uFund**, a minimal, composable, read-heavy interface for tokenized investment funds. It standardizes how integrators query a fund's current and historical net asset value (NAV) per share, lifecycle state, declared and paid distributions, basic fee parameters, subscription and redemption windows, minimum investment, and maturity. It also defines optional extensions for assets under management (AUM), per-holder lockups, accrued yield, multiple share classes, and proof-of-reserves attestations.

uFund is base-token-agnostic. The interface MAY be implemented alongside any share token, including ERC-20, ERC-4626, ERC-7540, ERC-7575, or ERC-3643-based contracts. It does not require the share token to be a vault, and it does not assume whether deposits and redemptions are synchronous, asynchronous, on-chain, or off-chain.

uFund deliberately does not standardize: subscription and redemption flows; compliance, identity, or transfer-restriction enforcement; cross-chain messaging of fund state; the methodology used to compute NAV or reserves; or the write functions used to update NAV, transition lifecycle state, or declare distributions. Write-side standardization is intentionally limited to events. Implementations are free to name, shape, and gate their own administrative functions, provided that the standardized events defined in this specification are emitted with the standardized fields whenever the corresponding state changes.

The standard is read-first. Its normative on-chain footprint consists of read functions and a small set of mandatory events that allow off-chain indexers, dashboards, wallets, custodians, risk systems, and audit pipelines to track fund state changes uniformly across implementations.

## Motivation

Tokenized funds, including money-market funds, Treasury funds, private credit funds, and other regulated fund wrappers, are becoming an important on-chain asset class. Each issuer tends to expose the same conceptual surface through a different ABI: current NAV, NAV timestamp, NAV freshness, lifecycle state, subscription status, redemption status, next distribution, and fee information.

For DeFi integrators, money markets, fixed-yield protocols, prime brokerages, custodians, indexers, wallets, and aggregators, this creates unnecessary integration work. A custom adapter must be written for every fund, even when the integrator needs only a small common set of read calls and a standardized event stream.

ERC-20 standardized fungible balances and transfers. ERC-4626 standardized synchronous vault accounting. ERC-7540 introduced asynchronous request and claim flows. uFund standardizes the fund-level metadata, valuation, and lifecycle layer that sits around those token and vault standards.

Existing standards address adjacent concerns but do not standardize fund operations:

| Standard | What it standardizes | What it does not standardize |
| --- | --- | --- |
| ERC-20 | Fungible balances and transfers | NAV, fees, fund state, distributions |
| ERC-4626 | Synchronous deposit/redeem math against a single underlying asset | Lifecycle state, corporate actions, multi-class funds, off-chain NAV |
| ERC-7540 | Asynchronous request and claim flows | Fund-level metadata, NAV freshness, distributions |
| ERC-7575 | Multi-asset entry points sharing one share token | Fund-level metadata and lifecycle state |
| ERC-3643 | Permissioned transfers and identity-bound compliance | Valuation, lifecycle, fees, corporate actions |

uFund is intentionally orthogonal to these standards. A single fund contract MAY implement ERC-20 + ERC-3643 + uFund, ERC-4626 + uFund, ERC-7540 + uFund, or simply a plain ERC-20 + uFund where NAV is published by an administrator or oracle. In all cases, an integrator that supports the uFund read interface and listens for the uFund event stream can render the same dashboard, price the same collateral subject to its own risk rules, and run the same monitoring logic.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

A contract claiming conformance with this ERC MUST implement `IERCUFund`, MUST emit the events defined in [Required Events](#required-events) whenever the corresponding state changes, and MUST implement ERC-165. The contract MAY additionally implement one or more optional extensions: `IERCUFundAUM`, `IERCUFundLockup`, `IERCUFundYield`, `IERCUFundMultiClass`, and `IERCUFundProofOfReserves`.

### Enums and Structs

```solidity
/// @notice Lifecycle states of a tokenized fund.
/// @dev Paused is modelled as a distinct state rather than an orthogonal flag so
/// that integrators can read a single field to decide whether to act.
/// Implementations MUST record the previous state when entering Paused and MUST
/// exit Paused only to that previous state or to a legal successor of it.
enum LifecycleState {
    Pending,
    SubscriptionOpen,
    SubscriptionClosed,
    Operating,
    RedemptionOnly,
    WindingDown,
    Closed,
    Paused
}

enum DistributionType {
    Dividend,
    Coupon,
    ReturnOfCapital,
    Other
}

enum DistributionStatus {
    Declared,
    ExDate,
    Paid,
    Cancelled
}

struct DistributionInfo {
    uint256 id;
    uint256 declaredAt;
    uint256 exDate;
    uint256 recordDate;
    uint256 paymentDate;
    uint256 amountPerShare;
    uint8 amountDecimals;
    bytes3 currency;
    DistributionType distributionType;
    DistributionStatus status;
}

struct ShareClassInfo {
    bytes32 id;
    string name;
    string symbol;
    uint256 minInvestment;
    uint8 minInvestmentDecimals;
    bytes eligibility;
}

struct AttestationInfo {
    bytes32 attestationHash;
    string attestationURI;
    uint256 attestedAt;
    address[] attestors;
    uint16 reservesToSupplyBps;
    string methodologyURI;
}
```

### Core interface: `IERCUFund`

```solidity
interface IERCUFund is IERC165 {
    /* ----------------------------- NAV reads ----------------------------- */

    /// @notice Current NAV per share of the default share class.
    /// @return nav NAV per share, scaled by `navDecimals`.
    /// @return navDecimals Decimal precision of `nav`.
    /// @dev MUST NOT revert. MUST return the last known value even when stale.
    function navPerShare() external view returns (uint256 nav, uint8 navDecimals);

    /// @notice NAV per share at or immediately before `timestamp`, default class.
    /// @dev MAY revert with a clear reason if historical NAV is not stored.
    function navAsOf(uint256 timestamp) external view returns (uint256 nav, uint8 navDecimals);

    /// @notice Unix timestamp at which the current NAV was last set.
    function navUpdatedAt() external view returns (uint256 timestamp);

    /// @notice True if the current NAV is older than `navStalenessThreshold()`.
    function navStale() external view returns (bool);

    /// @notice Maximum age in seconds before NAV is considered stale.
    function navStalenessThreshold() external view returns (uint256);

    /// @notice ISO 4217 alpha-3 valuation currency code, e.g. 0x555344 for USD.
    function valuationCurrency() external view returns (bytes3);

    /* -------------------------- Lifecycle state -------------------------- */

    function lifecycleState() external view returns (LifecycleState);
    function lifecycleStateUpdatedAt() external view returns (uint256);

    /* --------------------- Corporate actions / distributions ------------- */

    /// @notice Total number of distributions known to the implementation.
    /// @dev Distribution IDs SHOULD start at 1. ID 0 SHOULD indicate "none".
    function distributionCount() external view returns (uint256);

    /// @notice Distribution details by ID.
    /// @dev MAY revert if `id` is unknown.
    function distributionById(uint256 id) external view returns (DistributionInfo memory);

    /// @notice Pending distribution IDs. SHOULD be bounded to currently pending items.
    function pendingDistributionIds() external view returns (uint256[] memory);

    /// @notice Most recent paid distribution ID, or 0 if none has been paid.
    function lastDistributionId() external view returns (uint256);

    /// @notice Next scheduled distribution date, or 0 if not known or not applicable.
    function nextDistributionDate() external view returns (uint256);

    /* ---------------------------- Fund params ---------------------------- */

    function managementFeeBps() external view returns (uint16);
    function performanceFeeBps() external view returns (uint16);
    function subscriptionFeeBps() external view returns (uint16);
    function redemptionFeeBps() external view returns (uint16);
    function minInvestment() external view returns (uint256 amount, uint8 decimals);
    function subscriptionWindow() external view returns (uint256 opensAt, uint256 closesAt);
    function redemptionWindow() external view returns (uint256 opensAt, uint256 closesAt);
    function maturityDate() external view returns (uint256);
}
```

`navPerShare()` represents the issuer-reported, administrator-reported, oracle-reported, or contract-derived fund valuation per share. It MUST NOT be assumed to be a market-derived price unless the implementation explicitly documents that methodology.

`maturityDate()` MUST return `0` if the fund has no fixed maturity date.

`subscriptionWindow()` and `redemptionWindow()` MUST return `(0, 0)` if no current or future window is known or applicable.

`minInvestment()` SHOULD be interpreted in the fund's `valuationCurrency()` unless the implementation documents another denomination.

If a fee is not applicable, the corresponding fee function MUST return `0`. If a fee exists but cannot be represented as a fixed basis-point value, the implementation SHOULD return `0` and document the fee methodology off-chain.

### Required Events

A conformant `IERCUFund` implementation MUST emit the following events when the corresponding state changes. Function signatures that produce these state changes are NOT standardized.

```solidity
event NavUpdated(
    uint256 previousNav,
    uint256 newNav,
    uint8 navDecimals,
    uint256 effectiveAt
);

event LifecycleStateChanged(
    LifecycleState indexed previousState,
    LifecycleState indexed newState,
    uint256 timestamp
);

event DistributionDeclared(
    uint256 indexed id,
    DistributionType indexed distributionType,
    uint256 exDate,
    uint256 recordDate,
    uint256 paymentDate,
    uint256 amountPerShare,
    uint8 amountDecimals,
    bytes3 currency
);

event DistributionPaid(
    uint256 indexed id,
    uint256 totalAmount,
    uint8 amountDecimals,
    bytes3 currency,
    uint256 paidAt
);

event DistributionCancelled(uint256 indexed id, string reason);
```

Indexed fields above are normative. Implementations MUST NOT change which fields are indexed, because off-chain indexers rely on a stable topic layout for cross-implementation log filtering.

Implementations MUST NOT emit `NavUpdated` if the new NAV, decimals, and effective timestamp are identical to the most recently emitted values. Similarly, `LifecycleStateChanged` MUST NOT be emitted for a no-op transition.

### Optional extension: AUM — `IERCUFundAUM`

```solidity
interface IERCUFundAUM is IERCUFund {
    function aum() external view returns (uint256 amount, uint8 decimals);
    function aumUpdatedAt() external view returns (uint256 timestamp);

    event AUMUpdated(
        uint256 previousAum,
        uint256 newAum,
        uint8 decimals,
        uint256 effectiveAt
    );
}
```

AUM is optional because it is often calculated off-chain, may lag NAV, and may not perfectly reconcile with `navPerShare() * totalSupply()` across all fund architectures.

### Optional extension: lockups — `IERCUFundLockup`

```solidity
interface IERCUFundLockup is IERCUFund {
    function lockupExpires(address account) external view returns (uint256);
}
```

Lockups are optional because they are user-specific and can expose holder-level restrictions. Implementations that expose lockup data SHOULD document the privacy implications.

### Optional extension: accrued yield — `IERCUFundYield`

```solidity
interface IERCUFundYield is IERCUFund {
    function accruedYield(address account) external view returns (uint256);
}
```

This extension is optional because some funds accrue yield through NAV appreciation instead of separately claimable or separately reportable yield.

### Optional extension: multi-class shares — `IERCUFundMultiClass`

```solidity
interface IERCUFundMultiClass is IERCUFund {
    function shareClasses() external view returns (bytes32[] memory);
    function defaultShareClass() external view returns (bytes32);
    function shareClassInfo(bytes32 shareClassId) external view returns (ShareClassInfo memory);

    function navPerShare(bytes32 shareClassId) external view returns (uint256 nav, uint8 navDecimals);
    function navAsOf(bytes32 shareClassId, uint256 timestamp) external view returns (uint256 nav, uint8 navDecimals);
    function navUpdatedAt(bytes32 shareClassId) external view returns (uint256 timestamp);
    function navStale(bytes32 shareClassId) external view returns (bool);
    function valuationCurrency(bytes32 shareClassId) external view returns (bytes3);
    function lifecycleState(bytes32 shareClassId) external view returns (LifecycleState);
    function lifecycleStateUpdatedAt(bytes32 shareClassId) external view returns (uint256);
    function distributionCount(bytes32 shareClassId) external view returns (uint256);
    function distributionById(bytes32 shareClassId, uint256 id) external view returns (DistributionInfo memory);
    function pendingDistributionIds(bytes32 shareClassId) external view returns (uint256[] memory);
    function lastDistributionId(bytes32 shareClassId) external view returns (uint256);
    function nextDistributionDate(bytes32 shareClassId) external view returns (uint256);
    function managementFeeBps(bytes32 shareClassId) external view returns (uint16);
    function performanceFeeBps(bytes32 shareClassId) external view returns (uint16);
    function subscriptionFeeBps(bytes32 shareClassId) external view returns (uint16);
    function redemptionFeeBps(bytes32 shareClassId) external view returns (uint16);
    function minInvestment(bytes32 shareClassId) external view returns (uint256 amount, uint8 decimals);
    function subscriptionWindow(bytes32 shareClassId) external view returns (uint256 opensAt, uint256 closesAt);
    function redemptionWindow(bytes32 shareClassId) external view returns (uint256 opensAt, uint256 closesAt);
    function maturityDate(bytes32 shareClassId) external view returns (uint256);

    event ShareClassAdded(bytes32 indexed id, string name, string symbol);

    event ClassNavUpdated(
        bytes32 indexed shareClassId,
        uint256 previousNav,
        uint256 newNav,
        uint8 navDecimals,
        uint256 effectiveAt
    );

    event ClassLifecycleStateChanged(
        bytes32 indexed shareClassId,
        LifecycleState indexed previousState,
        LifecycleState indexed newState,
        uint256 timestamp
    );

    event ClassDistributionDeclared(
        bytes32 indexed shareClassId,
        uint256 indexed id,
        DistributionType indexed distributionType,
        uint256 exDate,
        uint256 recordDate,
        uint256 paymentDate,
        uint256 amountPerShare,
        uint8 amountDecimals,
        bytes3 currency
    );

    event ClassDistributionPaid(
        bytes32 indexed shareClassId,
        uint256 indexed id,
        uint256 totalAmount,
        uint8 amountDecimals,
        bytes3 currency,
        uint256 paidAt
    );

    event ClassDistributionCancelled(
        bytes32 indexed shareClassId,
        uint256 indexed id,
        string reason
    );
}
```

This extension does not prescribe whether share classes are represented by separate token contracts or by class identifiers within one contract.

A multi-class implementation MUST continue to implement the core `IERCUFund` reads for the default share class. For share-class-specific state changes, a multi-class implementation MUST emit the corresponding `Class*` event. For changes affecting the default share class, implementations MAY emit both the core event and the class-scoped event for compatibility, but MUST document this behaviour to avoid double-counting by indexers.

### Optional extension: proof-of-reserves — `IERCUFundProofOfReserves`

```solidity
interface IERCUFundProofOfReserves is IERCUFund {
    function latestAttestation() external view returns (AttestationInfo memory);
    function attestationHistory(uint256 fromTimestamp) external view returns (AttestationInfo[] memory);

    event AttestationPublished(
        bytes32 indexed attestationHash,
        uint256 attestedAt,
        uint16 reservesToSupplyBps,
        string attestationURI
    );
}
```

`latestAttestation()` exposes attestation metadata only. Integrators MUST independently verify the attestation source, signer quorum, and methodology before relying on it for solvency-critical decisions.

### ERC-165 interface identifiers

Interface IDs are the XOR of the 4-byte function selectors of every non-inherited function in each interface, per ERC-165. A contract MUST return `true` from `supportsInterface(id)` for each interface it implements.

| Interface | Interface ID |
| --- | --- |
| `IERCUFund` | `0x9539c458` |
| `IERCUFundAUM` | `0x081529b6` |
| `IERCUFundLockup` | `0xb6e90569` |
| `IERCUFundYield` | `0xc744ad19` |
| `IERCUFundMultiClass` | `0xe872a87f` |
| `IERCUFundProofOfReserves` | `0x9655511c` |

Authors MUST recompute these interface IDs from the final compiled ABI before finalization if any function signature changes.

### Behaviour rules

All view functions of `IERCUFund` and its extensions MUST NOT modify state. Core read functions MUST NOT revert, with these exceptions: `navAsOf` MAY revert if historical NAV is not stored; `distributionById` MAY revert if the distribution ID is unknown; per-class overloads MAY revert if `shareClassId` is unknown.

For implementations with on-chain vault math, `navPerShare()` SHOULD be consistent with the implementation's documented vault-accounting methodology. If the fund also implements ERC-4626, this MAY be derived from `convertToAssets(10 ** shareDecimals)` and scaled into the fund's `valuationCurrency()`. For implementations without on-chain vault math, `navPerShare()` MUST return the last value set by whatever administrative, oracle, or attestation path the implementation exposes.

When `navStale()` returns `true`, integrators SHOULD refuse to price collateral, accept new subscriptions, or rely on the NAV for solvency-critical computations unless they apply their own risk controls. The contract MUST continue to return the last-known NAV from `navPerShare()` even when stale.

Implementations MUST reject illegal lifecycle transitions. `Closed` is terminal. `Paused` MUST record the prior state and MUST exit to that state or to a legal successor of it.

Upon declaration, the implementation MUST emit `DistributionDeclared` with the assigned `id`. When payment is effected by any mechanism, whether on-chain or off-chain, the implementation MUST emit `DistributionPaid`. `DistributionCancelled` MAY be emitted at any time before payment.

## Rationale

### Why a separate standard rather than extending ERC-4626 or ERC-7540?

ERC-4626 and ERC-7540 are vault standards that bind the share token, deposit logic, and redemption logic into a specific contract model. Many regulated tokenized funds do not fit that model. The share token may be a permissioned ERC-20 whose price is updated by a fund administrator or oracle, with no on-chain vault math. A read-heavy, base-token-agnostic interface composes cleanly with vault and non-vault share tokens alike.

### Why events-only on the write side?

The tokenized-fund market accommodates different write models: vault-derived NAV, oracle-published NAV, administrator-published NAV, and batch-computed NAV. Standardizing a single `setNav` signature would be either too prescriptive or too loose. Standardizing the events instead achieves the integrator-side goal of uniform off-chain indexability without dictating the privileged administrative shape of the underlying implementation.

### Why move AUM, lockups, accrued yield, multi-class shares, and proof-of-reserves to extensions?

These features are valuable, but they are more implementation-specific than NAV, lifecycle state, fees, and distributions. Moving them into optional extensions keeps the mandatory core small while still allowing richer institutional funds to expose additional fields in a standardized way.

### Why `bytes3` for currency?

ISO 4217 alpha-3 codes are exactly three ASCII letters. `bytes3` is fixed-width, single-slot, decodable to ASCII in any client, and avoids the overhead and ambiguity of free-form strings.

## Backwards Compatibility

This proposal does not alter any existing standard and introduces no breaking changes. Existing fund tokens can adopt uFund by adding the read functions described above and by emitting the required events from whatever privileged operations they already expose. No pre-existing function signature, storage layout, or event needs to change. Integrators that do not call the uFund functions or listen for the uFund events are unaffected.

## Reference Implementation

A minimal reference implementation is available at: https://github.com/Blockchainxtech/ufund

The write function names and signatures in the reference implementation are non-normative. They illustrate one reasonable shape for an admin-driven fund. Implementers are free to use different write function names, parameter lists, and access-control models. What is normative is that the read functions and events match this specification.

## Security Considerations

Whatever functions an implementation exposes to update NAV, transition lifecycle state, declare distributions, publish AUM, expose lockups, or publish attestations constitute the trust surface of a uFund deployment. Implementations MUST use a hardened access pattern such as multisig, role-based control with timelock, or DAO-governed control. Single-EOA control is strongly discouraged for any deployment with non-trivial AUM.

A large holder who observes a pending NAV update may subscribe or redeem at a stale price. Mitigations include ex-NAV pricing, per-holder cooldowns, lockups, a `navStale()` guard at integrator adapters, and publishing NAV through a commit-reveal or timelocked oracle.

Integrators MUST check `navStale()` before using `navPerShare()` for any solvency-critical computation. Treating a stale NAV as fresh is a critical integration risk for tokenized funds.

Because integrators may rely on standardized uFund events as the source of truth for state-change notifications, an implementation that fails to emit a required event when state actually changes is non-conformant and can silently break downstream indexing. Implementations SHOULD include unit tests that assert event emission for every state-change path.

Any DeFi protocol that uses `navPerShare()` as a price oracle inherits the manipulation, latency, and governance risks of that NAV. Because tokenized funds are often priced by a single off-chain administrator, `navPerShare()` should be treated as an administered oracle, not a market-derived price, unless the implementation documents otherwise. Integrators SHOULD add circuit breakers and independent risk controls on top of `navStale()`.

On-chain attestations and per-holder lockups can expose sensitive information about holders, restrictions, reserves, or KYC-correlated metadata. Issuers SHOULD redact methodology documents where appropriate and carefully consider whether to expose per-holder restrictions publicly.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
