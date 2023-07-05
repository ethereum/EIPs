---
title: Bridged Token Standard (xERC20)
description: An interface for creating fungible representations of tokens bridged across domains.
author: Shaito (@0xShaito), Excalibor (@excaliborr), Arjun Bhuptani (@arjunbhuptani)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-06-27
requires: 20
---

## Abstract

This proposal (affectionately called xERC20) defines a minimal extension to ERC-20 that enables bridging tokens across domains without creating multiple infungible representations of the same underlying asset. Token issuers can define which bridges are able to mint or burn the xERC20 on a given domain and configure rate limits for each allowed bridge.

## Motivation

With the rapid proliferation of L2 domains, fungible token liquidity has become increasingly fragmented across domains. This, coupled with the need for projects to transfer tokens between chains faster than rollup exit windows, has meant that token issuers must choose from one of two options to bridge their tokens:

1. Bridge tokens through the “canonical” rollup bridge and work with atomic swap or fast-liquidity providers for L2→L1 or L2→L2 interactions. While this is the safer option, it necessitates significant requirements for issuers to incentivize or bootstrap liquidity on every supported chain, limiting support to only the most liquid of assets. Liquidity-based bridging additionally introduces slippage or other unpredictable pricing for users, hindering composability across domains.
2. Work with a 3rd party bridge. This option removes liquidity and pricing concerns making it more favorable for longer-tail issuers, but locks a given minted representation of a bridged token to only its associated bridge. This creates a tradeoff for issuers between security/sovereignty and user experience: If the token is bridged through only a single provider, the token supply and implementation is now fully and in perpetuity controlled by the bridge. If the token is bridged through multiple options (including "canonical" rollup bridges), multiple infungible (“wrapped”) representations of the same underlying asset are created on L2.

In the ideal case, token issuers want the following properties for bridged representations of their tokens:

- Sovereignty. Issuers want to be the logical owners of the canonical representation of their token on L2 and not be locked into any single specific option forever.
- Fungibility. Token issuers want a single “canonical” representation of their token on each L2, regardless of which bridges (canonical or otherwise) are supported by the issuer.
- Security. Issuers want to opt into novel secure bridging approaches as they are developed and have granular control over their risk tolerance for any given option.
- Minimal Liquidity. Issuers want to minimize the costs and complexity of acquiring liquidity for their token on each supported bridge and chain. This property becomes increasingly important as the space eventually expands to 100s or 1000s of connected domains.

There has been some previous work to solve this problem. However, solutions have historically either failed to satisfy all of the above desirable properties or have been custom-built for only a single token ecosystem.

- Celer’s Open Canonical Token Standard proposed a lock-in free standard for bridging tokens to new domains. However, it largely targeted alternative L1s (that don’t already have a canonical bridge) and did not fully solve the fungibility problem. Regardless, Celer’s approach inspired some of the key thinking behind this standard.
- Maker’s Teleport facility allows for minting and burning canonical DAI between domains. While the approach solves for the desirable properties above, it is highly custom to Maker’s architecture and relies on Maker’s own economic security to function. Circle CCTP similarly solves this problem, but using a mechanism that only centralized token issuers can implement.
- Token issuer multi-bridge implementations, e.g. Angle protocol and Threshold Network’s tBTC. These examples solve for some or all of the above desiderata and can be applied more broadly to all tokens if coupled with minor additions for compatibility with existing deployed tokens.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview

The system proposed below has two main components:

- A standard interface for bridged tokens
- A wrapper (aka “Lockbox”) that allows existing tokens to adopt the above interface

### Token Interface

All xERC20 tokens MUST implement the standard ERC20 interface.  Note that while many of the below functions are inspired by ERC777, implementers are NOT REQUIRED to adhere to the full ERC777 specification.

All EIP-XX tokens MUST implement the following interface.

```ts
interface IXERC20 {
  /**
   * @notice Emits when a lockbox is set
   *
   * @param _lockbox The address of the lockbox
   */

  event LockboxSet(address _lockbox);

  /**
   * @notice Emits when a limit is set
   *
   * @param _newLimit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  event BridgeLimitsSet(uint256 _newLimit, address indexed _bridge);

  /**
   * @notice Emits when a limit is set
   *
   * @param _newLimit The updated limit we are setting to the bridge
   * @param _burner The address of the bridge we are setting the limit too
   */

  event BurnerLimitsSet(uint256 _newLimit, address indexed _burner);

  /**
   * @notice Reverts when a user with too low of a limit tries to call mint/burn
   */

  error IXERC20_NotHighEnoughLimits();

  /**
   * @notice Reverts when caller is not the factory
   */

  error IXERC20_NotFactory();

  struct Bridge {
    BridgeParameters minterParams;
    BridgeParameters burnerParams;
  }

  struct BridgeParameters {
    uint256 timestamp;
    uint256 ratePerSecond;
    uint256 maxLimit;
    uint256 currentLimit;
  }

  /**
   * @notice Sets the lockbox address
   *
   * @param _lockbox The address of the lockbox (0x0 if no lockbox)
   */

  function setLockbox(address _lockbox) external;

  /**
   * @notice Updates the limits of any bridge
   * @dev Can only be called by the owner
   * @param _mintingLimit The updated minting limit we are setting to the bridge
   * @param _burningLimit The updated burning limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limits too
   */
  function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external;

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge The bridge we are viewing the limits of
   *  @return _limit The limit the bridge has
   */
  function mintingMaxLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function burningMaxLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge The bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function mintingCurrentLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function burningCurrentLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) external;

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) external;
}
```

Implementations MUST additionally satisfy the following requirements:
- `mint` MUST check that the caller's current available `limit` is greater than or equal to `_amount`
- `mint` MUST increase the supply of the underlying ERC-20 by `_amount` and reduce the current available `limit`
- `burn` MUST check that the caller's current available `limit` is greater than or equal to `_amount`
- `burn` MUST decrease the supply of the underlying ERC-20 by `_amount` and reduce the current available `limit`

## Lockbox

The lockbox tries to emulate the WETH contract interface as much as possible. Lockboxes MUST implement the following interface:

```ts
interface IXERC20Lockbox {
  /**
   * @notice Emitted when tokens are deposited into the lockbox
   */

  event Deposit(address _sender, uint256 _amount);

  /**
   * @notice Emitted when tokens are withdrawn from the lockbox
   */

  event Withdraw(address _sender, uint256 _amount);

  /**
   * @notice Reverts when a user tries to deposit native tokens on a non-native lockbox
   */

  error IXERC20Lockbox_NotNative();

  /**
   * @notice Reverts when a user tries to deposit non-native tokens on a native lockbox
   */

  error IXERC20Lockbox_Native();

  /**
   * @notice Reverts when a user tries to withdraw and the call fails
   */

  error IXERC20Lockbox_WithdrawFailed();

  /**
   * @notice Deposit ERC20 tokens into the lockbox
   *
   * @param _amount The amount of tokens to deposit
   */

  function deposit(uint256 _amount) external;

  /**
   * @notice Withdraw ERC20 tokens from the lockbox
   *
   * @param _amount The amount of tokens to withdraw
   */

  function withdraw(uint256 _amount) external;
}
```

Lockboxes SHOULD additionally implement the following alternative `deposit` function for native (non-ERC20) assets.
```ts
/**
   * @notice Deposit native assets (e.g. ETH) into the lockbox
   */

  function deposit() external payable;
```


## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

The proposed standard attempts to satisfy the following conditions for bridged tokens regardless of where and how they are bridged:

1. Tokens received at the destination should be the canonical tokens.
2. Bridges should not need to bootstrap liquidity for each new chain and asset.
3. Cross-domain interactions involving tokens should be slippage-free, simplifying composability.
4. Token issuers should own decision-making around which bridges to support and be able to parametrize risk for each. They should not be locked into only supporting a single bridge.

### Fungibility

The core problem that this standard tackles is the **********************fungibility********************** of tokens bridged across domains against the “canonical” token on that domain. (Note: which token is “canonical” is dictated by the token issuer and is sometimes, but not always, the token minted by a given domain’s enshrined bridge - e.g. a rollup bridge).

!https://s3-us-west-2.amazonaws.com/secure.notion-static.com/524e6503-835b-4833-82f4-9640806ec438/fragmentation.png

It is not enough to simply allow multiple bridges to mint the same representation on a remote domain if liquidity is locked into bridges on the home domain. To illustrate this, consider an example where two bridges control minting rights of canonical USDT on an L2:

- Alice bridges 100 USDT from L1→L2 through bridge 1. The underlying L1 USDT tokens is locked in bridge 1 and 100 USDT is minted on L2.
- Bob bridges 100 USDT from L1→L2 through bridge 2. Similar to the above case, the underlying L1 USDT tokens are locked in bridge 2 and 100 USDT is minted on L2.
- Suppose Alice pays Bob her 100 USDT. Bob now has 200 USDT.
- Bob attempts to bridge the 200 USDT from L2→L1 through bridge 2. This transaction fails, because bridge 2 only has 100 USDT custodied that it can give to Bob.

The core property that this example illustrates is that locking tokens across multiple bridges on the token’s “home” domain makes it impossible to have fungibility without impeding user experience on remote domains. Minting or burning the token can solve this problem, but not all ERC20 tokens implement a configurable mint/burn interface. 

### Lockbox

This proposal specifically solves for the above problem in cases where tokens do not already have a mint/burn interface. Tokens on the source chain are locked into a Lockbox, which mints corresponding xERC20-compatible tokens that can be sent to bridges.

!https://s3-us-west-2.amazonaws.com/secure.notion-static.com/1b11d689-a130-443a-8458-2db7da03198e/xERC20.png

1. A given ERC20 is wrapped into its xERC20 representation.
2. The xERC20 can then be transferred to any approved bridge. The bridge should check rate limits for the token and then `burn` the token.
3. On the target domain, the bridge then similarly `mint`s the token.
4. When transferring back to the home chain, the xERC20 can be unwrapped back into the original ERC20 token.

Using this mechanism, the underlying ERC20 token is consolidated to the Lockbox contract, and shared across all supported bridges.

### Rate Limits

A key consideration for consolidating home chain liquidity (and, by extension, allowing multiple bridges to mint the same representation) is the risk introduced due to the failure of any single bridge. In other words, there is a tradeoff space between fungibility (i.e. user experience) and security.

The current best practice for limiting this risk is for issuers to enshrine a single bridge that mints the canonical representation on a given domain (this is often the rollup bridge, but we are increasingly seeing projects moving to proprietary/3rd party bridges citing liquidity and UX concerns). In this case, the token issuer fully trusts the enshrined bridge. Alternative bridges that want to support the token then must build liquidity for the token, where the risk to the token issuer of a given bridge’s failure is capped to the total liquidity locked in the bridge.

The xERC20 proposal attempts to mimic and improve upon this risk topology without the need for external liquidity. Instead of risk being capped by the locked tokens in a given (non-enshrined) bridge, risk is now capped by rate limits that are configurable on a per-bridge basis. This gives issuers granular control over their risk appetite as issuers can experiment with different bridges and adjust their confidence over time. Perhaps most importantly: this approach also encourages more open competition around security, as issuers no longer have to default to using only the most liquid or well-funded options.

### Edge Case Considerations for Limits

Minting and burning limits introduce failure modes that can impede UX. This is a necessary part of ensuring that bridge risk is compartmentalized and this standard assumes that implementers can work towards raising or altogether removing limits for bridges as they build confidence in them over time.

Regardless of the above, the failure modes associated with rate limits generally map directly to **existing** failure modes around insufficient liquidity on bridges, and in many cases improve upon them. The two cases to consider here are:

1. Hitting burn limits on the source chain. This case is hit when a given bridge has capped its limit on burning tokens, causing a revert of the transaction that included a call to the bridge. 
    1. In the current liquidity-bridging model, bridges will typically have no way to know upfront if they have sufficient liquidity on the target chain for a given transaction. This means that a limit-based approach (where the transaction **fails fast**) is a significant improvement to UX.
2. Hitting minting limits on the destination chain. This case can be hit *after* tokens are burned on the source chain in cases where many different minting transactions are simultaneously triggered on a given destination domain and bridge combination, leading to the bridge’s limit being saturated.
    1. This problem exists in the current model if there is insufficient liquidity on the destination for a given bridge to complete a transaction within some defined slippage constraints. This case is not well-handled by bridges at the moment. Bridges are forced to either output some wrapped representation, or force users to wait until there is more liquidity. 
    2. In the limit-based approach, the bridge will similarly not be able to complete the transaction on the destination domain until it has more capacity available. However, a limit approach provides some more reasonable guarantees to the user: (1) user have a much higher degree of predictability around time and pricing of the outputted transaction, (2) users would not receive some wrapped representation, and (3) bridges would have a simpler pathway for users to send the tokens back to the source domain or any other destination.

## Backwards Compatibility

This proposal is fully backwards compatible with ERC-20.

Aside from the above, the following compatibility vectors were considered when designing this proposal:

- Compatibility with existing/deployed tokens
- Compatibility with canonical & 3rd party bridges

### Compatibility with Deployed Tokens

There are three states that token issuers begin with when migrating to xERC20s:

1. The token does not exist yet OR is upgradeable/controlled by the issuer on each supported domain.
2. The token is deployed to a single home domain but not others yet.
3. The token is deployed and/or bridged to multiple domains

The proposed xERC20 standard solves for (1) out of the box - token issuers should simply deploy xERC20 interface-compatible tokens on all domains they wish to support with no lockbox needed.

Case (2) is straightforward to solve with xERC20s as well. Token issuers should deploy a lockbox on their home chain, and then wrap their ERC20s into xERC20s prior to bridging them. This wrapping step may add some friction depending on the bridge - this is discussed further in the Compatibility with Bridges section.

Case (3) is the most challenging to solve for as issuers may not have sovereign control over the “canonical” representation of the token on any remote domain and this necessitates a token migration of some form at least. As an example, tokens bridged using the default Arbitrum rollup bridge would be fully controlled by the rollup bridge. For these cases, we recommend the following migration path for issuers:

1. Deploy a lockbox on the remote domain which locks the canonical-bridge-minted token and mints a new xERC20.
2. Establish the new xERC20 token as the canonical asset for the domain - this is largely a social consensus activity driven by DAO agreement and project communications.
3. Deploy a lockbox on the home domain which locks the home canonical token and mints a new xERC20.
4. Allowlist all desired bridges *including* the canonical bridge that owns the legacy implementation, mapping the xERC20 representation on the home domain to the xERC20 representation on the remote.
5. At this point, it is fully possible for users to begin transferring the token across all bridges as would be expected from the xERC20 standard. However, note that the canonical bridge connecting home to remote will now have two bridge paths: (a) ERC20→ERC20 (locking the ERC20 at home), and (b) xERC20→xERC20. Now, the issuer can begin the process of sunsetting the legacy canonical ERC20 on the remote domain.
6. The issuer should at this point disallow minting *new* legacy canonical ERC20s on the remote domain and only allow users to bridge ERC20s *back* to the home domain (by unwrapping xERC20 on the remote). This would organically & gradually lead to the ERC20 on the home chain becoming unlocked from the home<>remote canonical bridge, but token issuers can also incentivize this behavior if there is a desire for it to occur more quickly.

### Compatibility with Bridges

One key benefit to the xERC20 model is that the simple requirement of a burn & mint interface makes this proposal compatible with most bridges either out of the box or through a predefined custom token mapping process. The following bridges & domains were considered in the creation of this proposal:

- **3rd party bridges:** every 3rd party bridge that relies on messaging infrastructure already supports a mint and burn interface and has a pathway to map custom minted tokens.
- **Arbitrum rollup bridge:**  Arbitrum allows token issuers to [write a custom gateway](https://developer.arbitrum.io/asset-bridging#other-flavors-of-gateways).
- **OP Stack bridge:** Optimism supports [adding a custom bridge](https://community.optimism.io/docs/guides/bridge-dev/#building-a-custom-bridge).
- **Polygon PoS bridge:** Polygon supports custom tokens [through their fx portal](https://wiki.polygon.technology/docs/develop/l1-l2-communication/fx-portal).
- **ZkSync bridge**: Zksync supports [custom bridges of any kind](https://era.zksync.io/docs/reference/concepts/bridging/bridging-asset.html#custom-bridges-on-l1-and-l2).
- **GnosisChain Omnibridge:** GnosisChain does not currently support custom tokens, but is in the process of redesigning their omnibridge and plans to allow this functionality.

Note: In most of the above cases, a custom bridge integration also means integration into canonical bridge UIs, ensuring that users have a consistent experience throughout the process. Additionally, a single xERC20 custom bridge implementation could be built for each ecosystem and serve any number of token issuers.

## Reference Implementation

You can find a reference implementation and associated test cases [here](https://github.com/defi-wonderland/xTokens/blob/dev/solidity/contracts/XERC20.sol).

## Security Considerations

Please see the associated discussion in the **Rationale** section.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
