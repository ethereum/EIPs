---
eip: 
title: Off-chain Checks
description: Low cost distribution of ERC-1155 tokens with off-chain check writing and batched or bundled mint
author: CiviaTeam (@civia-code), Peng Cheng <cheng3932@gmail.com>, Roc Xu (@goldroc-Hsu), SHAOFEI GAO (@sfgao), Camille Li (@camille1022), Joye Wang (@0xjoye)
discussions-to: url
status: Draft
type: Standards Track
category: ERC
created: 2023-06-07
requires: 712, 1155
---

## Abstract

We propose a low cost approach to distribute [ERC-1155](./eip-1155.md) tokens for high-frequency token issuance use cases such as game rewards, implemented with a one-time deployed Check contract, the off-chain issuing and signing of Checks by the issuers, and batching or bundling of the Checks to mint tokens on-chain by the receivers.

## Motivation

Mass token issuance is one of the most common blockchain activities, traditionally done by direct transfers of tokens to receiver addresses, or programming the issuance logic into smart contracts for receivers to mind their tokens on-chain. Both approaches involve high gas cost especially in large receiver base or high frequency issuance cases.

This approach minimize on-chain operations while maintaining security with the following steps:

1. Issuer register the token once with the Check contract which would mint tokens for the receivers
1. Issuer writes as many off-chain Checks as needed to receivers with no gas, Checks signed by the issuer are non-reputable
1. Receiver collects any number of Checks off-chain with no gas cost
1. Receiver decides when to batch or bundle multiple Checks which can be minted on-chain, with substantial savings in gas cost

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The Check contract MAY be deployed by any party prior to Check issuance, and MUST implement the following interfaces: 

```javascript
interface IERC1155Check {
    /**
     * The Check data structure
     * @param tokenAddr  ERC-1155 token contract address
     * @param issuerAddr issuer's Check signing address
     * @param receiverAddr receiver address
     * @param tokenId token id in the ERC-1155 contract
     * @param beginId begin id of the issued Check
     * @param endId end id of the issued Check
     * @param amt token amount in the Check corresponding to the tokenId
     * For each Check issued individually, beginId == endId
     * For bundled Check, beginId < endId, representing a Check sequence
     */
    struct Check {
        address tokenAddr;
        address issuerAddr;
        address receiverAddr;
        uint256 tokenId;
        uint256 beginId;
        uint256 endId;
        uint256 amt;
    }

    /**
     * Issuer MUST register a fungible token with this function
     * @dev MUST revert if the msg.sender has no minter role
     * @dev MUST revert if the issuerAddr is address(0)
     * @dev MUST revert if the tokenId already registered as non-fungible
     * @param tokenAddr ERC-1155 token contract address
     * @param issuerAddr issuer's Check signing address
     * @param tokenId token id in the ERC-1155 contract
     * @param amt increase by amt the number of tokens for tokenId allowed to issue
     * un_register() is not supported because Checks issued are not revokable
     */
    function registerFungible(address tokenAddr, address issuerAddr, uint256 tokenId, uint256 amt);

    /**
     * Issuer MUST register non-fungible tokens with this function
     * @dev MUST revert if the msg.sender has no minter role
     * @dev MUST revert if the issuerAddr is address(0)
     * @dev MUST revert if fromTokenId > toTokenId
     * @dev MUST revert if the tokenId range includes tokenId already registered as fungible
     * @param tokenAddr ERC-1155 token contract address
     * @param issuerAddr issuer's Check signing address
     * @param fromTokenId token id in the ERC-1155 contract
     * @param toTokenId token id in the ERC-1155 contract
     */
    function registerNonFungible(address tokenAddr, address issuerAddr, uint256 fromTokenId, uint256 toTokenId);

    /**
     * Get the last minted Check id for a (tokenAddr, receiverAddr, tokenId) triple
     * @dev MUST revert if tokenAddr is not registered
     * @param tokenAddr token contract address
     * @param receiverAddr receiver address
     * @param tokenId token id in the ERC-1155 contract
     * @return The last minted Check id for a (tokenAddr, receiverAddr, tokenId) triple
     */
    function getLastCheckId(address tokenAddr, address receiverAddr, uint256 tokenId) view returns (uint256);

    /**
     * Batch mint. Checks in the batch MAY have different tokenAddr, receiverAddr, tokenId
     * Check numbers for any (tokenAddr, receiverAddr, tokenId) triple MUST be continuous, incremental
     * @dev MUST revert if any signature in the batch is invalid
     * @dev MUST revert if the beginId for a (tokenAddr, receiverAddr, tokenId) != last minted Check id + 1
     * @dev the Check contract MUST keep a record of the last minted Check id for all (tokenAddr, receiverAddr, tokenId)
     * @param checks list of Check data
     * @param [v|r|s]_[issuer|receiver] list of EIP-712 signatures corresponding to each Check
     */
    function mint(
        Check [] memory checks,
        uint8[] memory v_issuer, 
        bytes32[] memory r_issuer,
        bytes32[] memory s_issuer,
        uint8[] memory v_receiver, 
        bytes32[] memory r_receiver,
        bytes32[] memory s_receiver
    );
}
```

### Off-chain Check data

* The off-chain Check data MUST comply with the Check data structure defined in the `IERC1155Check` interface
* beginId for each (tokenAddr, receiverAddr, tokenId) MUST starts with 1
* Checks issued individually from the issuer MUST have beginId == endId
* In the bundle request sent from the receiver to the issuer, Check numbers for a (tokenAddr, receiverAddr, tokenId) triple MUST be continuous and incremental for the Check sequence
* The issuer's response to the bundle request includes the bundled Check data, in which beginId < endId, representing a Check sequence bundled in a single Check
* Issuer MUST sign each Check before sending to receiver
* Receiver MUST sign each received Check (individual or bundled) before submit to the Check contract to mint

* Example of a single signed Check from issuer

```json
{
    "tokenAddr":"0x9a73F3E1Bf1c882fCEffDd8a4991997063a0aBb6",
    "issuerAddr":"0x39e60EA6d6417ab2b4a44f714b7503748Ce658eD",
    "receiverAddr":"0x39e60ea6d6417ab2b4a44f714b7503748ce658ed",
    "tokenId": 35,
    "beginId":10,
    "endId":10,
    "amt":"32000000000000000000",
    "sig": {
        "r":"0x3de40d575b74ba7bdf7216841feb7bae1feb410694e5a42d350a513eddf95924",
        "s":"0x44fe3a367f9fb967adfc1997a3a08b35c1bd930d659966a8c1a1b0038ee974d4",
        "v":27
    }
}
```

* Example of a bundle Check request sent by the receiver to the issuer: "please bundle Check 10-11 of tokenId 35 into a single Check"

```json
[
    {
        "tokenAddr":"0x9a73F3E1Bf1c882fCEffDd8a4991997063a0aBb6",
        "issuerAddr":"0x39e60EA6d6417ab2b4a44f714b7503748Ce658eD",
        "receiverAddr":"0x39e60ea6d6417ab2b4a44f714b7503748ce658ed",
        "tokenId": 35,
        "beginId":10,
        "endId":10,
        "amt":"32000000000000000000",
        "sig": {
            "r":"0x3de40d575b74ba7bdf7216841feb7bae1feb410694e5a42d350a513eddf95924",
            "s":"0x44fe3a367f9fb967adfc1997a3a08b35c1bd930d659966a8c1a1b0038ee974d4",
            "v":27
        }
    },
    {
        "tokenAddr":"0x9a73F3E1Bf1c882fCEffDd8a4991997063a0aBb6",
        "issuerAddr":"0x39e60EA6d6417ab2b4a44f714b7503748Ce658eD",
        "receiverAddr":"0x39e60ea6d6417ab2b4a44f714b7503748ce658ed",
        "tokenId": 35,
        "beginId":11,
        "endId":11,
        "amt":"55000000000000000000",
        "sig": {
            "r":"0xf1738d5695030b42882363a33f234d84de205384b118ab6f6c29d549fd96036a",
            "s":"0x0c3ad283b407a5169f7a04c54eee1ff3b6c8ce284642af3352f37a9199e49240",
            "v":27
        }
    }
]
```

* Example of a bundled Check returned by the issuer as response to bundle request

```json
{
    "tokenAddr":"0x9a73F3E1Bf1c882fCEffDd8a4991997063a0aBb6",
    "issuerAddr":"0x39e60EA6d6417ab2b4a44f714b7503748Ce658eD",
    "receiverAddr":"0x39e60ea6d6417ab2b4a44f714b7503748ce658ed",
    "tokenId": 35,
    "beginId":10,
    "endId":11,
    "amt":"87000000000000000000",
    "sig": {
        "r":"0x9df0984f6d231016a3c923b4f8935d9c7e81233b762f211603ff0c373726ebb8",
        "s":"0x3f7646642b0d0d38350d39ebe9f650f6811f3be35f629a296846e2e60db926da",
        "v":27
    }
}
```

### Check workflow

```mermaid
sequenceDiagram
    autonumber
    participant Erc-1155 Token
    actor Issuer
    participant CheckContract
    actor Receiver

    Issuer->>+CheckContract: registers token addr and the Check signing addr with the Check contract
    CheckContract-->>-Issuer: success on chain
    Issuer->>+Erc-1155 Token: authorizes the Check contract to mint tokens with the ERC-1155 contract
    Erc-1155 Token-->>-Issuer: success on chain
    loop every check
        Issuer->>Issuer:   writes and signs Checks
        Issuer->>Receiver: sends Check to receiver
    end
    alt batch mint
        Receiver->>Receiver: collects and signs each Check
        Receiver->>+CheckContract: creates Check batch and sends to the Check contract to mint tokens
        CheckContract->>Erc-1155 Token: mint
        CheckContract-->>-Receiver: success on chain
    else bundle mint
        Receiver->>Issuer: sends request to Issuer to bundle multiple checks
        Issuer->>Issuer: merges the receiver's Checks
        Issuer->>Receiver:  issues a bundled Check with the sum of token values
        Receiver->>Receiver: signs the bundled Check
        Receiver->>+CheckContract: sends to the Check contract to mint tokens
        CheckContract->>Erc-1155 Token: mint
        CheckContract-->>-Receiver: success on chain
    end
```

## Rationale

The off-chain check workflow, while shifting the main cost of token distribution from the issuers to the receivers, adds flexibilities to token issuance. The issuers don't have to decide beforehand when and how many tokens must be minted to what group of receivers. After they register the tokens, the issuers can write Checks as they go. 

The receivers on the other hand, before minting the tokens on-chain, are assured of the promised tokens with issuers' signatures on the Checks. The receivers accumulate Checks to mint in batch or bundle to save gas, and have the option to mint in a time period of low gas cost.

## Backwards Compatibility

No backward compatibility issues found

## Test Cases

## Reference Implementation

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

To maintain the integrity of the Check sequence issued for a (tokenAddr, receiverAddr, tokenId), Check ids must follow the numbering rules specified. The Check contract keeps the last minted Check id for each (tokenAddr, receiverAddr, tokenId) and refuse to mint if the coming beginId in the mint request is out of order. Enforcing the Check sequencing numbers also defies same Check double issue by the issuer or double mint by the receiver.

Off-chain checks are signed by the issuer and are not reputable once issued. After receiving multiple Checks from the issuer, if the issuer refuses to bundle, the receiver can still submit Checks to batch mint, albeit with reduced gas saving effect.

The Check contract requires receiver signature on each Check in the mint request, so that the issuer, after sending a Check with high value, cannot issue a low value Check with the same Check id and mint for the receiver, i.e. replacing a high value Check with a low value Check in the Check sequence on-chain for the receiver before the receive having a chance to mint the high value Check.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).