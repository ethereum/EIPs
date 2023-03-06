---
title: <The EIP title is a few words, not a complete sentence>
description: <Description is one full (short) sentence>
author: RE:DREAMER Lab (@REDREAMER_Lab), Archie Chang (@ChangArchie), Kai Yu (@cynical_kai)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-02-21
requires: 165, 721
---

## Abstract

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

## Motivation

<!--
This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

**Every ERC-9999 compliant contract must implement the `ERC9999` and `ERC721` interfaces**

```solidity
pragma solidity ^0.8.16;

/// @title ERC-9999 Redeemable NFT Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-9999
/// Note: 
interface ERC9999 /* is ERC721 */ {
    /// @dev This emits when any RNFT has been redeemed.
    event Redeem(
        address indexed _operator,
        uint256 indexed _tokenId,
        address redeemer,
        bytes32 _redemptionId,
        string _memo
    );

    /// @dev This emits when the redemption is canceled.
    event Cancel(
      address indexed _operator,
      uint256 indexed _tokenId,
      bytes32 _redemptionId,
      string _memo
    );

    /// @notice Check whether the redemption created by the operator is redeemed or not.
    /// @dev 
    /// @param _operator The operator redeemed the RNFT.
    /// @param _redemptionId The identifier for redemption.
    /// @param _tokenId The identifier for an RNFT.
    /// @return The RNFT is redeemed or not.
    function isRedeemed(address _operator, bytes32 _redemptionId, uint256 _tokenId) external view returns (bool);

    /// @notice List the redemptions of speficic operator and RNFT.
    /// @dev
    /// @param _operator The operator redeemed the RNFT.
    /// @param _tokenId The redemptions for an RNFT.
    /// @return The redemptions of speficic `_operator` and `_tokenId`.
    function getRedemptionIds(address _operator, uint256 _tokenId) external view returns (bytes32[]);
    
    /// @notice Redeem an RNFT
    /// @dev
    /// @param _redemptionId The redemption to redeem.
    /// @param _tokenId The RNFT to redeem.
    /// @param _memo
    function redeem(bytes32 _redemptionId, uint256 _tokenId, string _memo) external;

    /// @notice Cancel a redemption
    /// @dev
    /// @param _redemptionId The redemption to cancel.
    /// @param _tokenId The RNFT to cancel.
    /// @param _memo
    function cancel(bytes32 _redemptionId, uint256 _tokenId, string _memo) external;
}
```

The **metadata extension** is OPTIONAL for ERC-5566 smart contracts (see "caveats", below). This allows your smart contract to be interrogated for its name and for details about the assets which your NFTs represent.

```solidity
/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-9999
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC9999Metadata /* is ERC721Metadata */ {
    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC9999
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}
```

This is the "ERC9999 Metadata JSON Schema" referenced above.

```json
{
    "title": "Asset Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the asset to which this NFT represents"
        },
        "description": {
            "type": "string",
            "description": "Describes the asset to which this NFT represents"
        },
        "image": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
        }
    },
    "redemptions": {
        "scope-assetId-redemptionId": {
            "status": "redeemed"
        },
        "operaotr-tokenId-redemptionId": {
            "status": "shipping",
            "description": "Over the past 55 years, the legendary superhero Ultraman, created by Tsuburaya Productions, has wowed audiences across the world. From TV and film to manga and video games, Ultraman is an unrivalled Japanese pop-culture icon, akin to Superman in the West - and for the very first time, he's venturing into the metaverse."
        },
        "Brave Series Universe": {
            "status": "paid",
            "description": "The Brave Series RNFT is a redeemable NFT that can be redeemed for a physical Demon King Figure with unique attributes. Limited number of only 500 worldwide."
        }
    }
}
```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).