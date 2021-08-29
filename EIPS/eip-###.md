---
eip:
title: Time proof non-fungible Token
author: Cyberforker(cyberforker@outlook.com)
discussions-to: https://ethereum-magicians.org/t/a-time-proof-non-fungible-token/
status: draft
type: Standards Track
category: ERC
created: 2021-09-01
requires: 165, 721
---
## Simple Summary
This is a standard for time-stamp provable NFTs, which extends [ERC-721](./eip-721.md).
Enables NFT to mapping and anchor things that have time features. 
And also the time-stamp proof of NFTs can be the condition of interaction with smart contracts.
It is called Time proof Non-fungible Token and is referred to as tpNFT in the subsequent descriptions.
## Abstract
Based on the tokenURI parameter of ERC721, the plain text parameter and the encryption parameter are added, and the time proof is set for the update of these three parameters.
With these improvements, we can provide new possibilities for NFT, enabling NFT to map and capture time-level value.
Here are some brand new applications that can be achieved by tpNFT based on this extension. I believe you can find more and more interesting applications to bring more functions to the blockchain.

    1. Governance: As a proof of timestamp for governance voting, it is used to verify the validity of the vote and obtain governance incentives.
    2. Invention and creation: The idea is stored on the chain to prove that the idea existed before a certain point in time. And you can temporarily hide the specific technical implementation details through Hash encryption. Open source projects： Similarly to previous one to used to prove the originality of their products and leave a proof of their own open source.
    3. Scientific discoveries: Publish the publicly available content of relevant scientific discoveries in plain text, and fix some temporarily undisclosed demonstration details through encrypted parameters. Engrave the brilliance of human wisdom on the blockchain. The timestamp proves that it will not lie.
    4. Prophecy: Make predictions and cast them into tpNFT with time proof ability, as proof of personal ability, or as a certificate for receiving bonuses.
    5. Identity: Participating in a series of on-chain behaviors through tpNFT, including the prophecy mentioned in the previous point, revolves around tpNFT's timestamp proof, which has become a natural proof of identity.
    6. Legacy: Binding assets to a tpNFT, others can receive part or all of the assets by submitting the preimage of encryption parameter(Hash or HashTree). We have another EIP to solve the front-running attacks.
    7. Dynamic NFT: With tpNFT, we only need a little improvement than can get a brand new type of NFT which state on the chain will automatically change over time without consuming any gas fees. Such features can open up new areas for games, installation art, financial contracts, and so on.
   
Summarize: From a philosophical point of view, The NFT of the ERC721 standard is mainly used to anchor and map things related to space, while tpNFT is used for related to time.
    
## Motivation
Compared to other possible solutions for on-chain time proof such as CallData or ERC721 they only solve partial problems.

    1. Write directly in calldata on ethereum:  
       1. Tokenless related capabilities: no collection, no structured organization of data, no ownership, and not transferable.  
       2. No subsequent modification is possible, which in itself will also cause more storage space on the chain to be occupied.
    2. ERC721
       1. Unupdateable: The parameters cannot be updated, or the parameters can be updated but the imtamability will be lost and the credibility will be reduced. The timestamp of tpNFT proves that we meet the requirements of both updatability and credibility.
       2. Lack of timestamp proof: When mint an NFT, we directly ignored the time attribute and time value of the mapping object, while tpNFT solved this problem. 
       3. Lack of encryption information storage: Based on the above points, we found that it is still unable to solve the problem of encryption Hash storage without leaking key information. To solve this problem, we added encryption Hash storage parameter to tpNFT, and also under the management of timestamp proof.  
       4. Limited on-chain interaction and execution potential: Other contracts on the chain cannot interact directly with the NFT for timestamp + content validation to perform some automated logic, including but not limited to governance, prophecy, legacy processing, and other requirements mentioned in the summary. TpNFT's timestamp proof + other three parameters (description, URI, Hash encryption) provides a convenient possibility for the third party contract to directly interact, verify, and execute through the tpNFT contract interface.  
          1. The major difference between the on-chain timestamp and the timestamp stored in the log is that the on-chain timestamp parameters can be accessed directly by other contracts, thus allowing for composability. 
          2. The NFT has a time attribute that can make interactions with external accounts or between NFTs produce different results at different times, which provides a logical basis for the time dynamics of NFT.  

Inspired by and based on ERC721's associated token ownership, we have implemented a tpNFT architecture that combines renewability and timestamp proof and supports the preservation of encrypted content, addressing the problems of other known solutions and giving NFT time attributes. This standard is based on and fully follows the ERC721 series of methods. Additional superset methods based on ERC721 implementation are as follows:
## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Every ERC-tpNFT compliant contract must implement the 'TimeProofNonFungibleToken' and 'ERC165' interfaces** (subject to "caveats" below):

```
pragma solidity ^0.8.0;

/// @title ERC-tpNFT Time proof Non-Fungible Token Standard
/// @dev See <URL>
/// Note: the ERC-165 identifier for this interface is 0x12feabc7.
interface TimeProofNonFungibleToken {
    /// @dev This emits when the tokenURI of tokenId has been updated.
    /// And also the tokenUriUpdateTimestamp will been set to the current time: block.timestamp.
    event UpdateURI(uint256 indexed tokenId, string tokenURI);
    /// @dev This emits when the description of tokenId has been updated.
    /// And also the descriptionUpdateTimestamp will been set to the current time: block.timestamp.
    event UpdateDescription(uint256 indexed tokenId, string description);
    /// @dev This emits when the hashProof of tokenId has been updated.
    /// And also the hashedProofUpdateTimestamp will been set to the current time: block.timestamp.
    event UpdateHashProof(uint256 indexed tokenId, bytes32 hashedProof);

    /**
     * @notice Mint basic tpNFT without description and hashedProof to the caller.
     * During mint, the createTimestamp of tpNFT will also be set.
     * @dev NFTs assigned to the zero address are considered invalid,
     * and this function throws for queries about the zero address.
     * @param tokenURI the URI you want to set for tpNFT.
     * @return newTokenId The token id of the new tpNFT you just mint.
     */
    function mint(string calldata tokenURI)
        external
        returns (uint256 newTokenId);

    /**
     * @notice Mint full tpNFT with tokenURI, description, and hashedProof to the caller.
     * During mint, the createTimestamp of tpNFT will also be set. If the token URI, description,
     * and hashedProof are not empty or zero, the corresponding tokenUriUpdateTimestamp,
     * descriptionUpdateTimestamp, and hashedProofUpdateTimestamp of the tpNFT  will also be set.
     * @dev NFTs assigned to the zero address are considered invalid,
     * and this function throws for queries about the zero address.
     * @param tokenURI the URI you want to set for tpNFT.
     * @param description the description you want to set for tpNFT.
     * @param hashedProof the hashedProof you want to set for tpNFT.
     * @return newTokenId The token id of the new tpNFT you just mint.
     */
    function mintFullToken(
        string calldata tokenURI,
        string calldata description,
        bytes32 hashedProof
    ) external returns (uint256 newTokenId);

    /**
     * @notice Mint basic tpNFT without description and hashedProof to the address 'to'.
     * During mint, the createTimestamp of tpNFT will also be set.
     * @dev NFTs assigned to the zero address are considered invalid,
     * and this function throws for queries about the zero address.
     * @param to the address the new tpNFT to receive.
     * @param tokenURI the URI you want to set for tpNFT.
     * @return newTokenId The token id of the new tpNFT you just mint.
     */
    function mintTo(address to, string calldata tokenURI)
        external
        returns (uint256 newTokenId);

    /**
     * @notice Mint full tpNFT with tokenURI, description, and hashedProof to the address 'to'.
     * During mint, the createTimestamp of tpNFT will also be set. If the token URI, description,
     * and hashedProof are not empty or zero, the corresponding tokenUriUpdateTimestamp,
     * descriptionUpdateTimestamp, and hashedProofUpdateTimestamp of the tpNFT  will also be set.
     * @dev NFTs assigned to the zero address are considered invalid,
     * and this function throws for queries about the zero address.
     * @param to the address the new tpNFT to receive.
     * @param tokenURI the URI you want to set for tpNFT.
     * @param description the description you want to set for tpNFT.
     * @param hashedProof the hashedProof you want to set for tpNFT.
     * @return newTokenId The token id of the new tpNFT you just mint.
     */
    function mintFullTokenTo(
        address to,
        string calldata tokenURI,
        string calldata description,
        bytes32 hashedProof
    ) external returns (uint256 newTokenId);

    /**
     * @notice Update the tokenURI of your tpNFT. You must be the owner of the tpNFT.
     * @dev This function will be executed only when the length of the newTokenURI string and the updated 
     * tokenURI string is not zero, otherwise it will be skipped directly.
     * When this function is executed, the tokenUriUpdateTimestamp of the tpNFT MUST be automatically 
     * updated to the current block timestamp.
     * @param tokenId The tokenId you want to update tokenURI.
     * @param newTokenURI The new tokenURI you want to update.
     */
    function updateURI(uint256 tokenId, string calldata newTokenURI) external;

    /**
     * @notice Update the description of your tpNFT. You must be the owner of the tpNFT.
     * @dev This function will be executed only when the length of the newDescription string and the 
     * updated description string is not zero, otherwise it will be skipped directly.
     * When this function is executed, the descriptionUpdateTimestamp of the tpNFT MUST be automatically 
     * updated to the current block timestamp.
     * @param tokenId The tokenId you want to update tokenURI.
     * @param newDescription The new description you want to update.
     */
    function updateDescription(uint256 tokenId, string calldata newDescription)
        external;

    /**
     * @notice Update the hashedProof of your tpNFT. You must be the owner of the tpNFT.
     * @dev This function will be executed only when the value of the newHashedProof bytes32 and the 
     * updated hashedProof bytes32 is not bytes32(0), otherwise it will be skipped directly.
     * When this function is executed, the hashedProofUpdateTimestamp of the tpNFT MUST be automatically
     * updated to the current block timestamp.
     * @param tokenId The tokenId you want to update tokenURI.
     * @param newHashedProof The new hashedProof you want to update.
     */
    function updateHashProof(uint256 tokenId, bytes32 newHashedProof) external;

    /**
     * @notice Setting a tpNFT as permanent immutable, the operation is irreversible.
     * You must be the owner of the tpNFT.
     * @dev After a tpNFT is set to be immutable,
     * all the update methods mentioned before will become unavailable.
     * @param tokenId The tokenId you want to set permanent immutable.
     */
    function makeTokenImmutable(uint256 tokenId) external;

    /**
     * @notice Query all attributes of a tpNFT.
     * @dev If you call this function through other contracts, 
     * you can use tuples to get the data you need, and then execute the other logic that follows.
     * e.g (bool isImmutable,,,,,,bytes32 hashedProof,) = tpNFT.getTokenById(128);
     * @param tokenId The tokenId of tpNFT that you want to query all attributes.
     * @return isImmutable True if the tpNFT of tokenId is immutable.
     * @return createTimestamp The timestamp of when was tpNFT created, which is immutable.
     * @return tpnftTokenURI The tokenURI of ERC721 metadata can be updated later in tpNFT standard.
     * @return tokenUriUpdateTimestamp It will automatically update when the tpnftTokenURI is updated.
     * @return description The description of tpNFT.
     * @return descriptionUpdateTimestamp It will automatically update when the description is updated.
     * @return hashedProof The hash-proof  of tpNFT.
     * @return hashedProofUpdateTimestamp It will automatically update when the hashedProof is updated.
     */
    function getTokenById(uint256 tokenId)
        external
        view
        returns (
            bool isImmutable,
            uint64 createTimestamp,
            string memory tpnftTokenURI,
            uint64 tokenUriUpdateTimestamp,
            string memory description,
            uint64 descriptionUpdateTimestamp,
            bytes32 hashedProof,
            uint64 hashedProofUpdateTimestamp
        );

    /**
     * @notice Check whether a certain preimage matches a certain tpNFT hashedProof.
     * @dev Hashedproof can be a hash tree, which can be partially verified through external contracts and extension methods.
     * As for the front-running attack on submitted hashes, we have another effective solution.
     * @param tokenId The tokenId of tpNFT that you want to check.
     * @param preimage The preimage of hashedProof.
     * @return isPreimageMatch True if `preimage` is the preimage of hashedProof of the tpNFT of the tokenId.
     */
    function checkHashProof(uint256 tokenId, string calldata preimage)
        external
        view
        returns (bool isPreimageMatch);

    /**
     * @notice An experimental method is used to generate the hash value of the original image. It is RECOMMENDED to use in an offline environment.
     * @dev The preimage may be leaked due to RPC and other reasons when using this method of deploying the contract on the chain.
     * @param preimage The preimage you want to get the hashedProof.
     * @return hashedProof The hash value of preimage.
     */
    function genHashProof(string calldata preimage)
        external
        pure
        returns (bytes32 hashedProof);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

```
### Caveats
The 0.8.0 Solidity grammar is not expressive enough to document the tpNFT standard. There may be other grammars in the future to make the above functions more complete:
    
    - Setting tpNFT to immutable is achieved by restricting three update functions through modifiers. Logically the internal variables of tpNFT can still be updated, such as through some functions that SHOULD NOT be implemented, or delegatecall()(which is MUST NOT implement)and diamond standards eip-2535, etc.

## Rationale
   **Design motivation**

       1. Proof of time - Current NFT is used to anchor and map things related to space, while the tpNFT standard focuses on describing things related to time. Unlike existing NFT, time-proof has a natural resistance to copy-paste.
       2. Time value - The smaller timestamp, the more time value it has. The first appearance is called innovation, the second appearance is called imitation. It is precisely because of its earlier appearance that things have a higher value of time proof, and through the tpNFT, we greatly reduce the cost of time proof generation and verification for such things. Because of this, We are pleased to have found a new NFT standard to preserve the value of these precious things.
       3. On-chain timestamp state - Enables a range of services and applications that rely on timestamp proof to be automatically deployed and executed through smart contracts directly based on on-chain state, rather than once again relying on off-chain third parties to provide relevant data and proof. With this we can extend tpNFT as governance NFT, heritage NFT, dynamic NFT, etc.
   
   **Design decisions**

       1. Why based on ERC721: After several years of development, the NFT of ERC721 has reached maturity. Extending new features based on a mature standard can help users get started faster and provide good backward compatibility. 
       2. Why not use ERC1155 instead of ERC721: In 1155, there are not only 0 or 1 possible states for the balance of each account, and the relationship between the same ID items(tokens) is not non-fungible, so we don't know who has the authority to update token.

    2. Why add two parameters: [Description] and [Hash]
       1. The [Description] is used to store plain text for human-readable and contract to execute. Serves as a data reference for smart contract execution logic, such as the salt that encrypts hash parameters, decryption keys, attributes of in-game characters, and updates of on-chain or off-chain access through formatted data without transferring ownership.  
       2. [Hash] data has two functions: storing encrypted data or storing compressed data, which extends the storage capability of NFT in two directions.  

    3. Why include time proof for update tokenURI
       1. Human-readable perspective: Helps quickly determine whether an NFT with the same TokenURI is legitimate or pirated.  
       2. Execution for smart contracts: Funds the first legitimate NFT of a tokenURI. The funding provider does not need to judge the authenticity of a certain NFT by itself but only needs to set which tokenURI can fetch how much bonus. Smart contract has a waiting period, during which the NFT timestamp of the same tokenURI with the earlier timestamp can replace the later one, until the end of the waiting period, directly claim the funds. 

    4. Gas savings design
       1. The uint64 of four timestamps variables in the struct of TimeProof are arranged consecutively in the struct as one uint256.
       2. The maximum value of Uint64 is 18446744073709551615 (584942417355 years), which is sufficient for saving the timestamp.  
       3. In three update functions, if the value of the calldata and the parameter(URI or description or hashedproof) in the storage of tpNFT are both zero, the update will be skipped to save Gas and meet the needs of mint empty NFT.
   
**ERC-165 Interface**
We chose Standard Interface Detection (ERC-165) to expose the interfaces that a tpNFT smart contract supports.

## Backwards Compatibility
    1. Compatible with ERC165 and the implementation of the relevant interface and registration.
    2. Based on ERC721 and fully compatible, it is a superset of ERC721. If you only fill in the tokenURI and do not fill in the description and hash in the mint, and then set tpNFT to be constant, you will get a tpNFT that only has more tokenURI update timestamps than the standard NFT with tokenURI.
## Test Cases
### Mint
### UpdateTokenURI
### UpdateDescription
### UpdateHashedProof
### Query
## Reference Implementation
### TimeMarker
### Dynamic NFT
### Governance voting
## Security Considerations
    1. Inherit the security based on the ERC721 standard.
       1. Related security risks have been resolved by ERC721 and have been operating stably for many years without security issues.
       2. There may be some security risks: At present, ERC721 will execute the _checkOnERC721Received function when calling safeTransfer and _mint to call the onERC721Received function of the external contract, which brings the risk of external callback reentry. We can implement specific functions according to the specific function. The execution content adds a modifier to prevent reentry.
    2. security for addition tpNFT functional 
       1. Set tpNFT to immutable state (irreversible): The owner of tpNFT can set it to be immutable. After that, the series of update methods of this tpNFT will not be able to call, so that even if the NFT is lost for various reasons, it will not be modified.
       2. When updating the data of tpNFT, it is prohibited to directly modify the TimeProof struct in the _timeProofs mapping, must use the three internal methods _updateURI, _updateDescription, and _updateHashProof provided by the standard to update the data of tpNFT so that the updated content and the updated timestamp are in the same atom transaction and executed correctly.
    3. Keccak256 is selected as the function of Hash, it is widely used and its safety has been tested for a long time.
       1. Anti-collision: Can not find two different data with the same Hash value.
       2. Irreversible: Raw raw data cannot be obtained by reverse calculation of Hash value.
       3. Leakage risk: We provide a simple function [genHashProof] to pass in the string and generate the hash value. It should be clarified that this function is for reference only. The preimage may be leaked due to RPC and other reasons when using this method of deploying the contract on the chain. Therefore for safety, if your preimage is very important, it is recommended that you copy the source code to the local offline or use other SDK to generates hash values ​​in a local offline environment.
## References

**Standards**

1. [ERC-20](./eip-20.md) Token Standard.
2. [ERC-165](./eip-165.md) Standard Interface Detection.
3. [ERC-721](./eip-721.md) Non-Fungible Token Standard.
## Copyright
Copyright and related rights waived via CC0.
