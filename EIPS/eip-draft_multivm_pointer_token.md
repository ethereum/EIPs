---
eip: <to be assigned>
title: Multi-VM Pointer-Token Pattern
description: An informational standard for ERC-20 contracts that share underlying balance with non-EVM token representations (SPL, CIP-56, etc.) in multi-VM L1s
author: Hilal Agil (@hilarl) <hilal@tenzro.com>
discussions-to: https://ethereum-magicians.org/t/eip-multivm-pointer-token-pattern/<placeholder>
status: Draft
type: Informational
created: 2026-05-02
---

## Abstract

This Informational EIP describes the *pointer token* pattern, in which an
ERC-20 contract on a multi-VM chain does not hold its own balance. Instead,
all balance reads and writes are delegated to a system precompile, system
contract, or privileged storage area that exposes a single underlying
native-ledger balance. The same balance is simultaneously projected into
non-EVM token representations on the same chain — an SPL Token program
account, a Canton CIP-56 holding, a Cosmos bank module entry, or any other
ledger-native token type — so that a transfer in any VM moves the same
spendable balance.

A pointer ERC-20 is structurally distinct from a *wrapped* ERC-20: a wrapper
locks the underlying asset in its own contract and mints a separate token
balance with its own liquidity, while a pointer is a thin façade with no
balance of its own. This document defines the pattern abstractly, specifies
an additive `pointer()` discoverability function and a companion
`IPointerERC20` metadata interface, and gives EVM tooling — wallets,
indexers, explorers, bridges — a way to recognize pointer tokens and avoid
double-counting balances or treating cross-VM transfers as bridge events.

## Motivation

Multi-VM Layer-1 designs and rollups (mid-2024 onward) commonly expose a
single underlying native asset balance through more than one VM. Without a
formal way to mark an ERC-20 contract as a *pointer* rather than a *wrapper*,
EVM tooling cannot tell the two apart, leading to:

1. **Double-counting**: an indexer sees an account with `1000` units of
   native balance and `1000` units of the pointer ERC-20 and reports the
   user holds `2000` units. The two are the same balance viewed through
   two surfaces.
2. **Phantom liquidity**: a price aggregator treats the pointer ERC-20 as a
   bridged or wrapped representation with its own market depth. There is no
   separate liquidity pool — moving the pointer moves the underlying.
3. **Bad UX**: wallets show the pointer and the native balance as two
   separate "tokens" the user must manually consolidate. An attempt to
   "convert" between them is a no-op (already the same balance) but the
   wallet may surface a fake swap quote.
4. **Unsound bridge accounting**: a cross-chain indexer that snapshots
   pointer balance on chain A and underlying balance on chain B may infer
   a phantom bridge flow when in fact the chain never moved.
5. **Cross-VM transfer misclassification**: a transfer that originated in
   the SVM facade (SPL Token instruction) but propagates through the
   pointer's standard `Transfer(address,address,uint256)` event can be
   mistaken for an EVM-only ERC-20 transfer, suppressing the SVM origin
   in cross-VM analytics.

The ERC-20 ABI surface is unchanged in a pointer deployment — `balanceOf`,
`transfer`, `approve`, `transferFrom` all behave per ERC-20 semantics from
the caller's perspective. The only structural change is *where* the balance
lives. Tooling needs an additive, low-cost discovery mechanism to opt
into pointer-aware behavior. This EIP describes that mechanism.

The pattern is descriptive, not prescriptive: existing ERC-20 contracts are
unaffected, and a chain operator who chooses to deploy pointer contracts
opts in by including the additive interface. This is why the document is
classified Informational rather than Standards Track / ERC.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHOULD", "SHOULD NOT",
"RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted
as described in RFC 2119 and RFC 8174.

### 1. Definitions

**Pointer ERC-20**: An ERC-20 contract whose `balanceOf(address)` and
`transfer*` functions read from and write to a balance store that is *not*
an internal `mapping(address => uint256)` owned by the contract. The
balance store is one of:

- A system precompile address (typically in the `0x10xx` reserved range).
- A privileged storage area that the host VM mirrors into the underlying
  native ledger.
- A direct call into a host-provided system contract whose address is
  fixed by the chain's protocol rules.

**Wrapped ERC-20**: An ERC-20 contract that holds the underlying asset
(or a representation of it) in its own balance store. Examples include
WETH, wstETH, and any cross-chain bridge "synthetic". A wrapper has its
own liquidity, its own supply curve, and its own redemption path.

**Underlying ledger balance**: The single native-ledger balance for an
account, as seen by all VMs on the same chain. A pointer ERC-20 surfaces
this balance through ERC-20 semantics; the same balance is simultaneously
surfaced through whatever non-EVM token-program semantics the host chain
provides.

### 2. Discoverability function

A pointer ERC-20 contract MUST implement the following view function:

```solidity
function pointer() external view returns (
    bool    isPointer,
    bytes32 sourceLedgerId,
    bytes   sourceAccountFormat
);
```

- `isPointer` MUST return `true`.
- `sourceLedgerId` MUST be a stable 32-byte identifier for the underlying
  ledger. The recommended encoding is `keccak256` of a CAIP-2 chain
  identifier, or, where no CAIP-2 mapping exists, a `keccak256` of a
  reverse-DNS string (e.g., `keccak256("network.tenzro.native")`).
- `sourceAccountFormat` MUST be ABI-encoded metadata describing how an EVM
  `address` maps onto the underlying ledger's account identifier. The
  encoding is opaque to this EIP; the format is published alongside the
  contract. A common case is the empty string, indicating that the EVM
  address is byte-equal to the underlying account identifier.

A non-pointer ERC-20 MUST NOT implement `pointer()`, or, if it does for
historical reasons, MUST return `isPointer = false`. Tooling MUST treat
"function does not exist (revert / 0x bytes)" and `isPointer = false` as
equivalent: the contract is not a pointer.

### 3. `IPointerERC20` metadata extension

A pointer ERC-20 contract SHOULD implement the following companion
interface for richer metadata discovery:

```solidity
struct PointerInfo {
    bytes32 sourceLedgerId;        // same as pointer().sourceLedgerId
    bytes   sourceAccountFormat;   // same as pointer().sourceAccountFormat
    address[] siblingFacades;      // EVM addresses of sibling pointer
                                   // facades on the same chain (for
                                   // chains exposing >1 EVM facade)
    string  documentationUri;      // human/machine-readable spec of the
                                   // host chain's pointer model
}

interface IPointerERC20 {
    function pointerInfo() external view returns (PointerInfo memory);
}
```

The interface ID for `IPointerERC20`, computed per ERC-165, is:

```
keccak256("pointerInfo()")[0:4]
```

A pointer ERC-20 implementing `IPointerERC20` MUST return `true` for
`supportsInterface(IPointerERC20.interfaceId)` per ERC-165.

### 4. Behavior of standard ERC-20 functions

A pointer ERC-20 MUST preserve the externally observable semantics of
ERC-20:

- `balanceOf(addr)` MUST return the underlying ledger balance of the
  account that maps to `addr` per `sourceAccountFormat`.
- `transfer(to, amount)` MUST move `amount` of the underlying ledger
  balance from `msg.sender` to `to`. The same movement MUST be observable
  on every other VM facade exposing the same balance.
- `approve` and `transferFrom` MUST behave per ERC-20. Allowances MAY be
  stored in the pointer contract's local storage (this is the typical
  case) or in the host system contract.
- `Transfer(address,address,uint256)` and `Approval(address,address,uint256)`
  events MUST be emitted on every state change, including state changes
  that originate from a non-EVM facade. The `from`/`to` addresses in such
  events MUST be the EVM-mapped addresses of the underlying ledger
  accounts that moved balance.

`totalSupply()` MUST return the underlying-ledger total supply. If the
underlying ledger has multiple denominations or precision differences
between the EVM facade and the native facade, the pointer contract MUST
expose the EVM-side `decimals()` consistently and round half-toward-zero
on any precision-loss boundary.

### 5. Cross-VM transfer events (optional)

A pointer ERC-20 MAY emit an additional event when a balance change
originated from a non-EVM facade:

```solidity
event CrossVmCredit(address indexed account, uint256 amount, bytes sourceVm);
event CrossVmDebit(address indexed account, uint256 amount, bytes sourceVm);
```

`sourceVm` is opaque metadata identifying the originating VM facade
(e.g., the SPL Token program address, the Canton synchronizer ID). These
events SHOULD accompany — not replace — the standard ERC-20 `Transfer`
event so that off-the-shelf indexers continue to function.

### 6. What this EIP does NOT specify

- The wire format or RPC surface of the underlying system precompile.
- The non-EVM token-program semantics on sibling facades.
- Any consensus or settlement properties of the host chain.
- Cross-chain bridging of pointer tokens to other chains. Once a pointer
  token leaves its host chain via a bridge, the resulting bridged
  representation is a *wrapped* token on the destination chain, governed
  by the destination chain's bridge contract — not by this EIP.

## Rationale

**Why Informational, not ERC?** The pattern does not change the ERC-20
ABI. Existing tokens, wallets, indexers, and explorers continue to work
unchanged. The discovery mechanism (`pointer()` and `IPointerERC20`) is
purely additive: a tool that ignores it is no worse off than today. An
ERC (Standards Track) is appropriate when the goal is to define a *new*
contract interface that others should implement; this document instead
*describes* a deployment pattern that already exists across multiple
multi-VM chains, and standardizes how to recognize it. That is the canonical
use case for an Informational EIP.

**Why a separate function `pointer()` and a separate interface
`IPointerERC20`?** Two reasons. First, the discoverability function is
intentionally narrower than `IPointerERC20`: a contract may want to expose
only the boolean and ledger-id without committing to the full metadata
struct. Second, ERC-165 dispatch on `IPointerERC20.interfaceId` is the
mechanism that lets older contracts (deployed before this EIP) decline
implementation cleanly without breaking. A wallet that calls
`pointer()` first, falls back to `supportsInterface(IPointerERC20)`, and
finally treats absence as "not a pointer" handles all three deployment
generations correctly.

**Why `sourceLedgerId` as `bytes32`?** A CAIP-2 string would force every
indexer to parse and validate variable-length strings on hot paths. A
fixed 32-byte hash of the canonical identifier is cheap to compare, can
be matched against a lookup table in tooling, and avoids ambiguity when
two strings normalize to the same identifier.

**Why allow allowances to be stored locally?** The ERC-20 allowance model
is EVM-native and has no analogue in many non-EVM token programs. Storing
allowances in the pointer contract's local storage preserves
EVM-application compatibility (DEX routers, permit2, ERC-4626 vaults)
without requiring the underlying ledger to model approvals.

**Why not require `CrossVmCredit`/`CrossVmDebit`?** Off-the-shelf
indexers (Etherscan, Subgraph, Dune) already understand
`Transfer(address,address,uint256)`. Forcing pointer contracts to emit a
new event would either fragment indexer behavior or impose an indexing
cost on chains that don't need it. The optional event lets pointer-aware
tooling enrich displays without breaking pointer-unaware tooling.

## Backwards Compatibility

There are no backwards-compatibility concerns. The ERC-20 ABI surface is
unchanged. Tooling that does not implement pointer detection continues
to treat a pointer ERC-20 as a normal ERC-20, which is correct in every
single-balance scenario; the only failure mode is *double-counting*
when the same tool also separately reads the underlying-ledger balance.
Implementations of this EIP can therefore be deployed alongside legacy
ERC-20 contracts on the same chain without disruption.

## Reference Implementation

The pointer pattern was first popularized by Sei Network's Sei V2
architecture in mid-2024, which introduced an EVM execution layer
sharing balance with the underlying Cosmos SDK bank module. The Sei V2
"pointer contract" terminology and design — an ERC-20 façade that
delegates to a system precompile rather than holding internal balance —
is the originating reference for the pattern described in this EIP.

Other adopters include:

- **Tenzro Network** (multi-VM L1 with EVM, SVM, and Canton/DAML
  facades). The wTNZO pointer ERC-20 is deployed at
  `0x7a4bcb13a6b2b384c284b5caa6e5ef3126527f93`. Balance reads and writes
  delegate to a system precompile at the protocol-reserved address
  `0x...0000001001` (`TNZO_BRIDGE`). The same underlying balance is
  exposed through an SPL Token adapter on the SVM facade and a CIP-56
  holding on the Canton facade. Source:
  <https://github.com/tenzro/tenzro-network/blob/main/crates/tenzro-vm/src/evm/wtnzo.rs>.

A normative reference contract for `IPointerERC20` is not provided
because the contract body is platform-specific (the pointer's balance
delegate target differs per chain). A non-normative skeleton:

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

interface IPointerERC20 {
    struct PointerInfo {
        bytes32 sourceLedgerId;
        bytes   sourceAccountFormat;
        address[] siblingFacades;
        string  documentationUri;
    }
    function pointerInfo() external view returns (PointerInfo memory);
}

abstract contract PointerERC20Skeleton is IPointerERC20 {
    address internal immutable SYSTEM_PRECOMPILE;

    constructor(address systemPrecompile) {
        SYSTEM_PRECOMPILE = systemPrecompile;
    }

    function pointer() external view returns (
        bool isPointer,
        bytes32 sourceLedgerId,
        bytes memory sourceAccountFormat
    ) {
        PointerInfo memory info = pointerInfo();
        return (true, info.sourceLedgerId, info.sourceAccountFormat);
    }

    function balanceOf(address who) external view returns (uint256) {
        (bool ok, bytes memory data) = SYSTEM_PRECOMPILE.staticcall(
            abi.encodeWithSignature("balanceOf(address)", who)
        );
        require(ok, "pointer: balance read failed");
        return abi.decode(data, (uint256));
    }

    // transfer / transferFrom delegate to SYSTEM_PRECOMPILE similarly.
    // approve / allowance MAY be stored in this contract's local storage.
}
```

## Security Considerations

1. **Trust in the system precompile.** A pointer ERC-20's balance reads
   and writes are only as trustworthy as the system precompile or system
   contract it delegates to. A bug in the precompile that allows
   unauthorized balance mutation is a chain-level vulnerability, not an
   EIP-level concern. Operators MUST treat the pointer-target precompile
   as a privileged consensus-critical component.

2. **Wallet display semantics.** Wallets MUST treat
   `transfer()` on a pointer ERC-20 the same as `transfer()` on any
   other ERC-20 — both move the user's spendable balance. Wallets SHOULD
   use the `pointer()` discoverability function to avoid showing the
   pointer and the underlying native balance as two separate assets.
   When in doubt, displaying *only* the underlying native balance and
   omitting the pointer entry is the safer default.

3. **Indexer double-counting.** Off-chain indexers MUST NOT sum the
   pointer ERC-20 `balanceOf` and the underlying-ledger balance for the
   same account. The two are the same value. Indexers SHOULD use
   `pointer()` to detect pointer contracts and exclude them from
   independent supply-tracking aggregates.

4. **Bridge accounting.** Bridges that snapshot ERC-20 balances and
   underlying balances on the source chain MUST detect pointer contracts
   and avoid emitting cross-chain attestations claiming the user holds
   "X units of pointer + X units of native" — that double counts. A
   bridge that locks a pointer ERC-20 on the source chain and mints a
   wrapped representation on the destination chain MUST NOT also lock
   the underlying native balance separately.

5. **Cross-VM event consistency.** A balance change initiated on a
   non-EVM facade MUST emit a corresponding `Transfer` event on the
   EVM facade. Failure to emit means EVM-side indexers miss state
   changes and produce stale data. Implementations should test
   round-trip: every SPL `Transfer` instruction (or analogous non-EVM
   operation) MUST produce a corresponding ERC-20 `Transfer` log within
   the same block.

6. **Allowance staleness.** When allowances are stored in the pointer
   contract's local storage but the underlying balance can be moved
   from a non-EVM facade, an outstanding allowance can become "larger
   than the balance" if the owner moves funds out via a non-EVM
   instruction. This is identical to the ERC-20 standard behavior of
   stale allowances after a balance decrease and does not introduce a
   new vulnerability, but wallets SHOULD warn when an allowance exceeds
   the current balance.

7. **Precision and rounding.** When the underlying ledger uses fewer
   decimals than the ERC-20 facade declares, conversions on the
   precision boundary can lose value. Pointer implementations MUST
   round half-toward-zero on debits (preventing a user from spending
   more than they own) and MUST reject deposits that would lose
   precision rather than silently truncating.

8. **Reentrancy through the system precompile.** A pointer ERC-20 that
   delegates to a system precompile inherits whatever reentrancy
   guarantees that precompile provides. Pointer implementations MUST
   document the reentrancy semantics and SHOULD follow checks-effects-
   interactions for any local storage mutations (e.g., allowances).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE/LICENSE-CC0.md).
