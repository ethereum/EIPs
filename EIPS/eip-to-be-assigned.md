---
eip: 9999
title: "ERC-vTOKEN"
description: "ERC-20-compatible token that only exists in contracts and auto-converts to native tokens for EOAs."
author: Fukuhi <aethercycle@gmail.com> (@aethercycle)
discussions-to: https://ethereum-magicians.org/t/your-topic-slug/12345
status: Draft
type: Standards Track
category: Interface
created: 2025-07-22
requires: 20
---

## Abstract

The ERC-vTOKEN introduces a new token architecture where tokens are non-transferable to externally owned accounts (EOAs), enabling mathematically permanent liquidity. vTOKENs exist only within smart contracts and convert automatically into native tokens when sent to EOAs. This model prevents rug pulls, liquidity extraction, and ensures immutable liquidity depth, while maintaining ERC-20 interface compatibility.

## Motivation

DeFi protocols suffer from fragile liquidity mechanisms:

- Liquidity can be withdrawn, breaking price floors
- Rug pulls by developers or LP owners
- Yield farming models that collapse post-incentives
- Users needing trust in human-controlled admin functions

ERC-vTOKEN addresses these problems by:

- Prohibiting user custody of vTOKENs
- Enabling seamless, automatic conversion to native tokens
- Locking liquidity in contracts permanently
- Enforcing economic sustainability mathematically

## Specification

### Core Features

1. **Non-transferable to EOAs**: vTOKENs revert when transferred to EOAs.
2. **Automatic Conversion**: Transfers to EOAs trigger conversion to native tokens.
3. **Whitelist System**: Only approved smart contracts can hold vTOKENs.
4. **ERC-20 Compatible**: Fully compliant with ERC-20 interface.

### Interface

```
interface IERCvTOKEN is IERC20 {
    event VirtualConversion(address indexed recipient, uint256 vTokenAmount, uint256 nativeTokenAmount);
    event WhitelistUpdated(address indexed account, bool status);

    function isWhitelisted(address account) external view returns (bool);
    function calculateNativeEquivalent(uint256 vTokenAmount) external view returns (uint256);
    function nativeToken() external view returns (address);
}
```

### Behavior

- Transfers to EOAs trigger a conversion: vTOKENs are burned, and native tokens sent.
- Transfers between whitelisted contracts proceed normally.
- Any unauthorized recipient address causes a revert.

## Rationale

- **Transfer Override** ensures all transfer logic paths enforce virtual conversion.
- **Whitelist Enforcement** allows strict protocol-defined behavior.
- **Burn-on-convert** model prevents supply inflation and ensures conservation.
- **Deterministic Conversion Logic** avoids manipulation; rate may be fixed or oracle-based.

## Backwards Compatibility

ERC-vTOKEN maintains:

- Compatibility with ERC-20 tools (balanceOf, transferFrom, etc.)
- Event and metadata consistency

It is **not compatible** with:

- Wallets expecting transferable tokens
- DEX aggregators without vTOKEN support

## Test Cases

Covered in repository:

- Transfer to EOA → converts
- Transfer to whitelisted contract → allowed
- Transfer to unknown → reverts
- Conversion with insufficient balance → reverts

## Reference Implementation

Reference implementation available in the [ERC-vTOKEN repository](../ERC-vTOKEN).

## Security Considerations

- **Reentrancy**: Conversion logic should use standard protections (e.g. nonReentrant).
- **Whitelist management** must be immutable or governance-controlled post-deployment.
- **Conversion failure**: Contracts should revert gracefully if native token balance insufficient.
- **Admin privileges**: Strongly recommended to renounce ownership post-deployment.

## Copyright

Copyright and related rights waived via CC BY-SA 4.0.

---

*This draft EIP proposes a new ERC standard for virtual tokens. Feedback and implementations are welcomed via the GitHub repository.*
