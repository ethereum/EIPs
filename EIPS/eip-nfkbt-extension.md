---
title: <ERC-6809 Custom SafeFallback Extension>
description: <An interface for transferring and retrieving specific NFKBT assets.>
author: <Mihai Onila (@MihaiORO), Nick Zeman (@NickZCZ), Narcis Cotaie (@NarcisCRO)>
discussions-to: <URL>
status: Idea
type: <Standards Track, Meta, or Informational>
category: <ERC> # Only required for Standards Track. Otherwise, remove this field.
created: <2024-09-23>
requires: <ERC-6809> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

The standard is an extension of ERC-6809, Non-Fungible Key Bound Tokens (**NFKBT/s**). It proposes the additional function `customSafeFallback`, allowing asset owners to select and retrieve specific tokens from a smart contract that has NFKBT security activated. 

## Motivation

NFKBTs contain an optional on-chain 2FA security system built directly into the token standard. When activated within they smart contract, all assets within that smart contract are secured, and retrievable. This is achieved via the `safeFallback` function uniquely found within ERC-6809, which curates the transfer of NFKBTs from the holding wallet to the opposite Key wallet that called the function. However, currently the way `safeFallback` works is that it transfers all the NFKBT assets within the given smart contract once the function is called. There is no option for someone to specify which NFKBT asset or assets they would like to transfer out of the holding wallet requiring all to be moved. 

 In the situation where someone owns multiple assets within the same NFKBT collection, the gas fee to call the `safeFallback` function increases based on how many assets they own as each asset accounts for one transfer. The `customSafeFallback` function provides the option to select which NFKBT assets they would like individually, or in batches, transfer out of the holding wallet. Presumably, the most desired assets that hold the most value to the owner could be selectively transferred out, rather than moving all of assets at once and incurring undesired fees from undesired assets. Additionally, the holder may not have access to funds to cover the gas fees for the assets and is counting on selling one on the open-market, in order to regain possesion of all the other NFKBTs that remain frozen until `safeFallback` or `customSafeFallback` can be called.

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

By standardizing the `customSafeFallback` as an extension, an even more tailored experience is achieved when utilizing NFKBTs built in security. As an extension, it doesn’t result in any negative impact or reduce functionality of ERC-6809 smart contracts or the on-chain 2FA security they provide. The likelihood of someone retrieving assets from a compromised holding wallet would however theoretically increase.

Take this example, someone owns 100 NFKBTS all within the same collection and the security has been activated. While attempting to connect to dApp via the holding wallet, the wallet containing the NFKBTs, the owner mistakenly connected through a malicious website and now those assets are in stasis as they cannot be unlocked or else they will be stolen. Another common example is someone losing their seed phrase and losing access to the wallet containing their assets. The `safeFallback` function was created for these scenarios and many others, however when attempting to use the `safeFallback` function the fees far exceed the amount available as it attempts to do 100 transfers. Even if there is only 1 desired asset, calling the function would still require the transfer of all 100 to get the in order to get the 1.

With the `customSafeFallback` function, a list of `tokenID` can be selected. Rather than transferring all 100, only the specified assets are transferred making the cost far more reasonable and affordable. Truth be told, maybe only a few assets actually have any value and are worth retrieving. 

## Backwards Compatibility

This standard is fully ERC-6809 compatible.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
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

The extension doesn't hinder the security NFKBT security provides, but rather offers another option on how one can utilize and specify the `safeFallback` function via `customSafeFallback`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
