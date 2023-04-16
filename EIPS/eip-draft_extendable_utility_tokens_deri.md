---
eip: .nan
title: Extendable Utility Tokens Derived from Origin NFTs
description: Structure and interface to increase the utility of Origin NFTs without transferring Origin NFTs
author: JB Won (@hypeodive), Geonwoo Shin(@0xdagarn), Jeniffer Lee(@)
discussions-to: will-be-soon
status: Draft
type: Standards Track
category: ERC
created: 2023-04-16
---

# Extendable Utility Tokens Derived from Origin NFTs

_Structure and interface to increase the utility of Origin NFTs without transferring Origin NFTs_

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

This EIP proposes a standard for separating ownership and usage rights of ERC721 non-fungible tokens (NFTs) to increase their utility, enable secure rental solutions, and ensure compatibility with multiverse environments. The standard introduces the concept of ChildERC721 tokens derived from the original MotherERC721 tokens, representing usage rights without transferring ownership.

## Motivation

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

NFTs have become some of the most valuable assets in the digital realm. While it is crucial to enhance the utility of NFTs, we must also ensure their safe and continuous use. To achieve this, we need a method to increase the utility of NFTs without the need for transferring them.

This shift is closely tied to advancements in AI technology. The emergence of generative AI has facilitated the creation of virtual worlds, giving rise to various multiverse environments, each with its own unique perspective. A single identity (e.g., BAYC #100) should be capable of functioning across multiple multiverse worlds (e.g., BAYC #100 for Sandbox, BAYC #100 for Decentraland, and so on).

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

_The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174._

The proposed standard introduces the concept of ChildERC721 tokens, which are derived from the original MotherERC721 tokens. ChildERC721 tokens represent usage rights, while the ownership of the asset remains with the MotherERC721 tokens. The following outlines the main components of the standard:

```solidity=
contract ChildERC721 is ERC721, IChildERC721 {
    address private _motherERC721;
    mapping(uint256 => uint256) private _expirations; // tokenId => expiration

    constructor(
        string memory name_,
        string memory symbol_,
        address motherERC721_
    ) ERC721(name_, symbol_) {
        require(motherERC721_ != address(0), "ChildERC721: origin is the zero address");
        _motherERC721 = motherERC721_;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert("We do not allow transfer of ownership.");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert("We do not allow transfer of ownership.");
    }

    function mint(uint256 tokenId) public virtual {
        address originOwner = IERC721(_motherERC721).ownerOf(tokenId);
        _safeMint(originOwner, tokenId);
    }

    function lend(address to, uint256 tokenId, uint256 duration) public override {
        address originOwner = IERC721(_motherERC721).ownerOf(tokenId);
        require(
            msg.sender == originOwner ||
            isApprovedForAll(originOwner, _msgSender())
        );

        uint256 expiration_ = block.timestamp + duration;
        _expirations[tokenId] = expiration_;

        _transfer(originOwner, to, tokenId); // TODO: should be safeTransfer?
        emit Lent(originOwner, to, tokenId, duration);
    }

    function claim(uint256 tokenId) public override {
        require(_expirations[tokenId] < block.timestamp, "ChildERC721: not expired");

        address originOwner = IERC721(_motherERC721).ownerOf(tokenId);
        require(
            msg.sender == originOwner ||
            isApprovedForAll(originOwner, _msgSender())
        );
        _expirations[tokenId] = 0;

        address owner = ERC721.ownerOf(tokenId);
        _transfer(owner, originOwner, tokenId);
        emit Claimed(originOwner, owner, tokenId, block.timestamp);
    }

    function giveBack(uint256 tokenId) public override {
        address owner = _ownerOf(tokenId);
        require(
            msg.sender == owner ||
            isApprovedForAll(owner, _msgSender())
        );
        _expirations[tokenId] = 0;

        address originOwner = IERC721(_motherERC721).ownerOf(tokenId);
        _transfer(owner, originOwner, tokenId);
        emit GivenBack(owner, originOwner, tokenId, block.timestamp);
    }

    function motherERC721() public view override returns (address) {
        return address(_motherERC721);
    }

    function expiration(uint256 tokenId) public view override returns (uint256) {
        return _expirations[tokenId];
    }
}

```

- **ChildERC721 contract**: A separate contract implementing the ERC721 standard, with additional functions to support lending, claiming, and giving back the ChildERC721 tokens.
- **Minting**: The mint function allows the owner of a MotherERC721 token to mint a corresponding ChildERC721 token. **Minting can be done by anyone, but the owner of the token will always be the owner of the MotherERC721 token.**
- **Lending**: The lend function enables the owner or an approved address to lend the ChildERC721 token to another address for a specified duration. **Lending can only be done by the owner (or authorized operator) of the MotherERC721.**
- **Claiming**: The claim function allows the owner or an approved address to reclaim the ChildERC721 token after the lending period expires. **Claiming can only be done by the owner (or authorized operator) of the MotherERC721.**
- **Giving back**: The giveBack function enables the current holder of the ChildERC721 token to return it to the owner of the corresponding MotherERC721 token voluntarily.
- **Restrictions**: The transferFrom and safeTransferFrom functions are overridden in the ChildERC721 contract to disallow the transfer of ownership, ensuring that ChildERC721 tokens can only be lent, not sold. **The value of MotherERC721 must be the sum of all utilities (ChildERC721 tokens).**

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

The rationale behind this EIP is to address the current limitations of NFTs in terms of utility, liquidity, secure rental solutions, and multiverse compatibility. By separating ownership and usage rights, we can create a more flexible and interoperable NFT ecosystem, benefiting both NFT holders and developers.

1. **Separating ownership and usage rights**: Introducing ChildERC721 tokens allows NFT holders to benefit from the utility and value of their assets without the need to transfer ownership. This separation enhances the overall ecosystem by reducing the risks associated with lending and renting NFTs.
2. **Increased utility and liquidity**: The creation of ChildERC721 tokens based on the original MotherERC721 tokens provides additional utility functions, leading to increased demand and liquidity for both tokens. As more ChildERC721 tokens are issued, the overall liquidity and value of the NFT ecosystem are improved.
3. **Secure rental solutions**: Traditional NFT rental services often require transferring ownership, posing risks to NFT holders. The proposed standard enables secure lending without transferring ownership of MotherERC721 tokens, reducing the potential for loss or fraud.
4. **Multiverse compatibility**: As the virtual world continues to expand, NFTs need to function seamlessly across multiple platforms and environments. By creating ChildERC721 tokens based on MotherERC721 tokens, a single NFT identity can be used across various multiverse worlds, increasing its value and utility.
5. **Compatibility with previously deployed NFTs**: Unlike most NFT-related proposals that introduce new standards and require compliance with those standards, our proposed standard can embrace all previously deployed NFTs. This approach ensures a more seamless adoption process and broader applicability across the existing NFT ecosystem.

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

The proposed EIP introduces a standard for ChildERC721 contracts that can interact with existing ERC721 contracts as MotherERC721 tokens, without requiring compatibility with the original standard. By simply having the address of the ERC721 as the MotherERC721, the ChildERC721 contracts can be created and function independently.

This standard allows for flexibility in the creation of ChildERC721 tokens with various utilities, extending beyond ERC721 to other token standards such as ERC1155. This approach enables a wider range of use cases for the ChildERC721 tokens, making the proposed standard more versatile and adaptable to the evolving NFT ecosystem.

As the proposed standard does not impose compatibility constraints on existing ERC721 contracts, it can be seamlessly adopted without requiring modifications to previously deployed NFTs.

## Test Cases

TODO

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

TODO

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
