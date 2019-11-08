---
eip: <to be assigned>
title: ENS support for ERC 721 TokenID
author: Oisín Kyne (@OisinKyne) <oisin@kyne.eu>
discussions-to: https://github.com/ethereum/EIPs/issues/X
status: Draft
type: Meta
created: 2019-10-30
requires (*optional): EIP137
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

_TL;DR_: This EIP makes ERC721 Non-Fungible Tokens addressable by the Ethereum Name Service by adding a new resolver profile, `uint256 tokenID()`.

_Slightly longer TL;DR_: It makes sense to resolve an ENS name to a contract address for fungible tokens such as ERC20, as each token in the contract is indistinguishable from another. However, for non-fungible tokens, pointing to the contract address alone is not enough, as tokens within the contract are meant to be unique and distinguishable. Non-fungibles might have different valuations, might grant the holder different rights or rewards etc.

This EIP proposes a new ENS resolver for ERC721's tokenID field. This allows the Ethereum Name Service to address a single non-fungible token within an ERC721 token contract of many tokens.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

A single deployed ERC721 contract can contain multiple non-fungible tokens. Tokens are addressed by an unsigned 256bit integer, tokenID. This EIP proposes an extra getter and setter, `tokenID()` and `setTokenID()`, that can be included in an ENS resolver contract, to allow for ENS names to resolve to a specific non fungible token within a given ERC721 contract.

This makes it possible to have ENS domains like `bugcat.cryptokitties.eth` and `dragon.cryptokitties.eth` resolve to both the CryptoKitties contract address and the tokenID of the non-fungible kitty within it.

## Motivation

<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Non-fungible Tokens are meant to be globally unique, it makes sense to be able to name them. Giving NFTs names makes them more real to the non Ethereum enthusiast that doesn't understand what a contract address or tokenID is. A domain name in the existing web 2.0 world is already widely understood to be a finite resource, and as such, would help convey the scarcity that is a non-Fungible token to new users.

This change might also to an extent, decentralise access to non-fungibles on Ethereum. Currently, the mapping for a human readable name to an NFT is kept off chain, typically on the platform of the NFT issuer. However, if the community moved towards naming NFTs on chain, using ENS, this would allow any client that supports ENS resolution to resolve a name to an NFT, rather than just the issuer with the off-chain mapping of names to tokens.

## Specification

<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

The additional ENS Resolver Profile specified by this EIP would add two new functions to a deployed resolver contract:

```
    function tokenID(bytes32 node) public view returns(uint256);
    function setTokenID(bytes32 node, uint256 token);
```

You can evaluate whether a given ENS resolver supports this EIP by using the ERC165 standard `supportsInterface(bytes4)`.

The interface identifier for this interface is `0x4b23de55`.

## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The design of this smart contract is a modified replica of the [existing contenthash resolver profile](https://github.com/ensdomains/resolvers/blob/master/contracts/profiles/ContentHashResolver.sol).

## Backwards Compatibility

<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

No backwards compatibility issues arise. Users wanting to address NFTs will have to deploy new ENS resolvers themselves, or use the provided PublicResolver below.

## Implementation

<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

I propose the following code as a sample implementation of this proposed `tokenId` resolver:

```solidity
pragma solidity ^0.5.8;

import "../ResolverBase.sol";

contract TokenIDResolver is ResolverBase {
    bytes4 constant private TOKENID_INTERFACE_ID = 0x4b23de55;

    event TokenIDChanged(bytes32 indexed node, uint256 tokenID);

    mapping(bytes32=>uint256) _tokenIDs;

    /**
     * Returns the tokenID associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated tokenID.
     */
    function tokenID(bytes32 node) public view returns(uint256) {
        return _tokenIDs[node];
    }

    /**
     * Sets the tokenID associated with an ENS node.
     * May only be called by those authorised for this node in the ENS registry.
     * @param node The node to update.
     * @param token The tokenID to set
     */
    function setTokenID(bytes32 node, uint256 token) public authorised(node) {
        emit TokenIDChanged(node, token);
        _tokenIDs[node] = token;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == TOKENID_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
```

A fork of the [ens/resolvers](https://github.com/ensdomains/resolvers) repo with the change is available, [here](https://github.com/OisinKyne/resolvers/blob/master/contracts/profiles/TokenIDResolver.sol)

The ENS public resolver contract, with this new added profile, has been deployed and verified on etherscan on the following chains:

- Rinkeby Testnet: [0x5792E9C312F764E58E213C7c5621C1CD8D63b925](https://rinkeby.etherscan.io/address/0x5792e9c312f764e58e213c7c5621c1cd8d63b925)
- Ropsten Testnet: [0xfDaBbe9d850a6D8a0821236c39853F6d0b276484](https://ropsten.etherscan.io/address/0xfdabbe9d850a6d8a0821236c39853f6d0b276484)
- Mainnet: [0x888aB947Cb7135DC25D4936E9a49b4e2bcDEa467](https://etherscan.io/address/0x888ab947cb7135dc25d4936e9a49b4e2bcdea467)

To test this, I have set [this](https://etherscan.io/address/0x888ab947cb7135dc25d4936e9a49b4e2bcdea467) new resolver contract on mainnet to resolve [`devcon5.oisin.eth`](https://etherscan.io/enslookup?q=devcon5.oisin.eth) to my Devcon Ticket Non-Fugible.

The address it resolves to is:
[0x22cc8b3666e926bcbf58cb726143b2b044c80a0c](https://etherscan.io/token/0x22cc8b3666e926bcbf58cb726143b2b044c80a0c), which is the [contract address](https://etherscan.io/token/0x22cc8b3666e926bcbf58cb726143b2b044c80a0c) of all 91 tokens issued.
And the `tokenID()` function should return:
[10798952828109286844408842969080375883371044426718767566816061252817119618319](https://etherscan.io/token/0x22cc8b3666e926bcbf58cb726143b2b044c80a0c?a=10798952828109286844408842969080375883371044426718767566816061252817119618319), which is _my_ Non Fungible within that contract, hopefully illustrating this EIPs usefulness. :)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
