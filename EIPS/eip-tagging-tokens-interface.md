---
eip: <to be assigned>
title: Tagging Tokens Indicator Interface
author: Francisco (@RandomDecryptor)
discussions-to: https://github.com/ethereum/EIPs/issues/2630
status: Draft
type: Standards Track
category: ERC
created: 2020-05-02
requires: 20
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Tagging tokens provide a simple way, using compatibility with ERC-20 tokens, to tag certain ethereum addresses.
This standard will allow for a simple way to distinguish between normal ERC-20 tokens and taggings tokens.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
A simple standard just to distinguish normal ERC-20 tokens from tagging tokens.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Tagging tokens will allow the tagging of any ethereum address. Users using any wallet that supports standard ERC-20 will be able to see the tags in their wallets. Or using etherscan (or other blockchain explorer's compatible with ERC-20 tokens) see the taggings in the ethereum addresses they want (maybe to check if an address is safe to interact with).

This new interface will allow wallets to easily ignore or separate the tagging tokens if they so choose to.  

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

```
solidity
contract ITag {

    function isTag() public constant returns (bool);

    function getTagVersion() public constant returns (bytes4);

}
```

### isTag

Will show if the contract is a tag (tagging token). It will return true in that case.

### getTagVersion

Returns the tag version.
The version will be a byte array, like the following 1.0.5.2, with each byte being a part of the version. The first byte will be the major version, the second byte the minor version and so on.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The main aspect of the interface is, of course, the isTag() function.

With it, wallets and blockchain explorers can detect if the ERC-20 token they are checking is a normal ERC-20 token or a tagging token.
The getTagVersion function is to allow for future evolutions, so it's possible to know the version of the Tag.  

Tags in its initial version (version 1.0.0.0), will have the following restrictions:
- One address A can only tag another address B with a certain tag once;
- One address can be tagged with many different tags;
- The tag tokens are not transferable, that is, operations that would allow a user to transfer a token after receiving it are blocked (transfer, transferFrom and approve);
- Only the user that does a tagging can remove it, that is, if address A has tagged address B previously, only address A can remove its tagging from address B.
- The total supply of the token (that corresponds to the Tag) is increased by 1 for each tagging;
- The total supply of the token is reduced by 1 for each removal of a tagging;

So tagging tokens would be a subset of ERC-20 tokens with the restrictions mentioned above applied. 

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
- [Tag.gd Test Site](https://www.tag.gd/test/)
- [Tag.gd More Modern Test](https://www.tag.gd/test2/) ([github](https://github.com/RandomDecryptor/NewTaggedSite))

### References
- [Tagging Tokens](https://ethresear.ch/t/tagging-tokens-tag-dangerous-addresses-or-use-other-tags-to-signal-other-situations/7360)

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
In terms of just this simple interface, no security issues should emerge.

Only certain privacy problems can maybe appear from the using of Taggings Tokens, if they are used in some way to expose information associated with certain ethereum addresses. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
