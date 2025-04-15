---
eip: TBD
title: Hybrid Governance Documents  Management
description: Hybrid governance document management for on-chain organizations built upon off-chain legal frameworks
author: Akira Umeno (@cardene777), Takashi Oka <oktks@proton.me>
discussions-to: https://ethereum-magicians.org/t/new-erc-hybrid-governance-document-management-hgdm/23444?u=thxdao
status: Draft
type: Standards Track
category: ERC
created: 2025-04-10
---

## Abstract

This EIP standardizes a framework for encrypting and storing organizational governance documents—such as articles of incorporation and internal regulations—on-chain in hierarchical structures, while limiting access to designated NFT holders.

Client-side derivation of decryption keys ensures they never appear on-chain. Merkle trees efficiently verify document integrity, with each version tracked by its unique root hash. The system also preserves evidence of consensus by recording the final signature after multiple signatories have reached agreement.

This standard enables hybrid document management for on-chain organizations built upon off-chain legal frameworks (like articles of incorporation or operating agreements), a common structure in DAO LLCs.

## Motivation

While operating our DAO LLC, we sought to address information asymmetry by maintaining codified governance documents like articles of incorporation and internal regulations on-chain. However, these documents frequently contain confidential information meant only for internal circulation, making plaintext storage on public blockchains unsuitable.

We faced several significant challenges:

- We needed to store our DAO LLC's articles of incorporation and bylaws on-chain while restricting access exclusively to member NFT holders
- Our documents follow a hierarchical structure of articles, sections, and clauses, and undergo regular partial amendments
- We struggled to ensure overall document integrity when only specific portions were updated
- To minimize gas costs, we wanted to efficiently re-encrypt only the modified sections
- Distributing and managing individual keys for each member proved impractical
- While we required secure off-chain decryption, we needed to clearly establish on-chain who had decryption rights
- We needed an efficient and verifiable system to document consensus and approval from multiple board members

Through this EIP, we aim to address these challenges by creating a document management system that preserves privacy while leveraging blockchain's transparency and permanence. This solution dramatically improves how critical documents are managed in DAOs and decentralized organizations, expanding the possibilities for on-chain governance.

## Specification

Smart contracts complying with this standard must implement the following interface:

### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IAOI {
    // ************************************************
    // *                     EVENTS                   *
    // ************************************************

    /**
     * @dev Chapter updated
     * @param versionId Version ID
     * @param versionRoot Version root
     * @param finalSigner Final signer
     * @param signers Signers
     * @param updatedLocations Updated locations
     */
    event ChapterUpdated(
        uint256 versionId,
        bytes32 versionRoot,
        address finalSigner,
        address[] signers,
        ItemLocation[] updatedLocations
    );

    /**
     * @dev Ephemeral salt marked used
     * @param ephemeralSalt Ephemeral salt
     */
    event EphemeralSaltMarkedUsed(bytes32 ephemeralSalt);

    /**
     * @dev Governance updated
     * @param governance Governance
     */
    event GovernanceUpdated(address governance);

    /**
     * @dev Token updated
     * @param token Token
     */
    event TokenUpdated(address token);

    // ************************************************
    // *                     ERRORS                   *
    // ************************************************

    /**
     * @dev Length mismatch
     */
    error LengthMismatch();

    /**
     * @dev Not governance
     */
    error NotGovernance(address sender, address governance);

    /**
     * @dev Invalid articleId
     */
    error InvalidArticleId(uint256 articleId);

    /**
     * @dev Invalid signature
     */
    error InvalidSignature(address recovered, address signer);

    /**
     * @dev Ephemeral salt already used
     */
    error EphemeralSaltAlreadyUsed(
        bytes32 ephemeralSalt
    );

    // ************************************************
    // *                    STRUCTS                   *
    // ************************************************

    /**
     * @dev Item location
     * @param articleId Article ID
     * @param paragraphId Paragraph ID
     * @param itemId Item ID
     */
    struct ItemLocation {
        uint256 articleId;
        uint256 paragraphId;
        uint256 itemId;
    }

    /**
     * @dev Encrypted item
     * @param encryptedData Encrypted data
     * @param plaintextHash Plaintext hash
     * @param masterSaltHash Master salt hash
     */
    struct EncryptedItem {
        bytes encryptedData;
        bytes32 plaintextHash;
        bytes32 masterSaltHash;
    }

    /**
     * @dev Encrypted item input
     * @param location Item location
     * @param encryptedData Encrypted data
     * @param plaintextHash Plaintext hash
     * @param masterSaltHash Master salt hash
     */
    struct EncryptedItemInput {
        ItemLocation location;
        bytes encryptedData;
        bytes32 plaintextHash;
        bytes32 masterSaltHash;
    }

    // ************************************************
    // *           EXTERNAL WRITE FUNCTIONS           *
    // ************************************************

    /**
     * @notice Update chapter
     * @param versionRoot Version root
     * @param signers Signers
     * @param signatures Signatures
     * @param finalSignature Final signature
     * @param version Version
     * @param items Items
     */
    function updateChapter(
        bytes32 versionRoot,
        address[] calldata signers,
        bytes[] calldata signatures,
        bytes calldata finalSignature,
        string calldata version,
        EncryptedItemInput[] calldata items
    ) external;

    /**
     * @notice Set ephemeral salt as used
     * @param ephemeralSalt Ephemeral salt
     */
    function setEphemeralSalt(bytes32 ephemeralSalt) external;

    /**
     * @notice Set governance
     * @param governance Governance
     */
    function setGovernance(address governance) external;

    /**
     * @notice Set token
     * @param token Token
     */
    function setToken(address token) external;

    // ************************************************
    // *            EXTERNAL READ FUNCTIONS           *
    // ************************************************

    /**
     * @notice Get version
     * @return Version
     */
    function getVersion() external view returns (string memory);

    /**
     * @notice Get encrypted item
     * @param location Item location
     * @return Encrypted item
     */
    function getEncryptedItem(
        ItemLocation calldata location
    ) external view returns (EncryptedItem memory);

    /**
     * @notice Get version root
     * @param versionId Version ID
     * @return Version root
     */
    function getVersionRoot(uint256 versionId) external view returns (bytes32);

    function isEphemeralSaltUsed(
        bytes32 ephemeralSalt
    ) external view returns (bool);

    /**
     * @notice Verify decryption key hash
     * @param location Item location
     * @param expectedHash Expected hash
     * @return True if the hash is valid
     */
    function verifyDecryptionKeyHash(
        ItemLocation calldata location,
        bytes32 expectedHash
    ) external view returns (bool);

    /**
     * @notice Verify decryption key hash with salt hash
     * @param location Item location
     * @param ephemeralSalt Ephemeral salt
     * @param masterSaltHash Master salt hash
     * @param holder Holder
     * @return True if the hash is valid
     */
    function verifyDecryptionKeyHashWithSaltHash(
        ItemLocation calldata location,
        bytes32 ephemeralSalt,
        bytes32 masterSaltHash,
        address holder
    ) external view returns (bool);

    /**
     * @notice Get governance
     * @return Governance
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Get token
     * @return Token
     */
    function getToken() external view returns (address);
}

```

### Events

#### `ChapterUpdated`

```solidity
event ChapterUpdated(
    bytes32 versionRoot,
    ItemLocation[] updatedLocations
);
```

Event emitted when new chapter (article, paragraph, item) data is registered or updated.

This is emitted when the AOI contract is deployed or when executed by the Executor following a vote in the Governance contract.

#### Parameters:

- `versionId`
    - ID converted from `versionRoot` to `uint256`.
    - Used as an identifier for version management.
- `versionRoot`
    - Root hash of the articles being signed.
- `finalSigner`
    - Address of the Executor.
- `signers`
    - Array of addresses that participated in the vote in the Governance contract.
- `updatedLocations`: Array of positions (`ItemLocation`) of updated chapters.

#### `EphemeralSaltMarkedUsed`

```solidity
event EphemeralSaltMarkedUsed(bytes32 ephemeralSalt);
```

Event emitted when a user marks a specific `ephemeralSalt` (temporary session identifier) as used to prevent reuse of decryption keys.

Emitted when `setEphemeralSalt()` is executed.

- `ephemeralSalt`
    - Temporary salt value marked as used.
    - Cannot be reused.

#### `GovernanceUpdated`

```solidity
event GovernanceUpdated(address governance);
```

Event emitted when the Governance contract address is updated.

- `governance`
    - Updated Governance contract address.

#### `TokenUpdated`

```solidity
event TokenUpdated(address token);
```

Event emitted when the NFT contract address is updated.

- `token`
    - Updated NFT contract address.

### Struct

#### `ItemLocation`

```solidity
struct ItemLocation {
    uint256 articleId;
    uint256 paragraphId;
    uint256 itemId;
}
```

A struct that identifies the hierarchical structure of articles of incorporation as "chapter, section, item."

Used to point to a specific section in the articles of incorporation.

This structure allows flexible specification as follows:

- `{1, 0, 0}` → All of Article 1
- `{1, 1, 0}` → Article 1, Section 1
- `{1, 1, 1}` → Article 1, Section 1, Item 1

- `articleId`
    - ID representing a "chapter" (top-level hierarchy).
    - Must be 1 or greater.
    - "1" indicates "Article 1", "2" indicates "Article 2".
- `paragraphId`
    - ID representing a section.
    - "0" means no section specified.
    - If `itemId` is "1" or greater, this value must also be "1" or greater.
- `itemId`
    - ID representing an item.
    - "0" means no item specified.

#### `EncryptedItem`

```solidity
struct EncryptedItem {
    bytes encryptedData;
    bytes32 plaintextHash;
    bytes32 masterSaltHash;
}
```

A struct representing an encrypted item (chapter, section, or item) of the articles of incorporation registered on-chain.

- `encryptedData`
    - Content of the articles encrypted with AES or similar (requiring a key for decryption).
- `plaintextHash`
    - Hash value of the original plaintext (for verification after decryption).
- `masterSaltHash`
    - Hash value of `masterSalt` (used for decryption key derivation verification).

#### `EncryptedItemInput`

```solidity
struct EncryptedItemInput {
    ItemLocation location;
    bytes encryptedData;
    bytes32 plaintextHash;
    bytes32 masterSaltHash;
}
```

A struct used when registering or updating an encrypted item (chapter, section, or item) of the articles of incorporation.

- `location`
    - `ItemLocation` pointing to the target chapter (article, section, item).
- `encryptedData`
    - Encrypted chapter of the articles (article, section, item).
- `plaintextHash`
    - Hash value for verifying integrity after decryption.
- `masterSaltHash`
    - Hash value of `masterSalt` to verify the legitimacy of the decryption key.

### Function

#### `updateChapter`

```solidity
function updateChapter(
    bytes32 versionRoot,
    address[] calldata signers,
    bytes[] calldata signatures,
    bytes calldata finalSignature,
    string calldata version,
    EncryptedItemInput[] calldata items
) external;
```

Function executed based on votes in the Governance contract to batch update chapters (articles, sections, items) of the articles of incorporation.

Receives addresses that participated in the vote in the Governance contract and the Executor's address.

Registers the specified version.

After signature verification, it updates the articles data and emits the `ChapterUpdated` event.

Parameters

- `versionRoot`
    - Root hash indicating the version of the articles.
- `signers`
    - Array of addresses that participated in the vote in the Governance contract.
- `signatures`
    - Array of signatures corresponding to `signers`.
- `finalSignature`
    - Executor's signature.
- `items`
    - Array of `EncryptedItemInput` structures of chapters to be updated.

#### `setEphemeralSalt`

```solidity
function setEphemeralSalt(bytes32 ephemeralSalt) external;
```

Function to mark a specific temporary `ephemeralSalt` (unique value for each decryption session) as "used".

Used to prevent reuse of decryption keys. Returns an `EphemeralSaltAlreadyUsed` error if already used.

Parameters

- `ephemeralSalt`
    - Identification hash of the decryption session to mark as used.

#### `setGovernance`

```solidity
function setGovernance(address governance) external;
```

Function to update the Governance contract address.

Emits a `GovernanceUpdated` event.

- `governance`
    - Updated Governance contract address.

#### `setToken`

```solidity
function setToken(address token) external;
```

Function to update the NFT contract address.

Emits a `TokenUpdated` event.

- `token`
    - Updated NFT contract address.

#### `getVersion`

```solidity
function getVersion() external view returns (string memory);
```

Function to retrieve the current version of the articles of incorporation.

#### `getEncryptedItem`

```solidity
function getEncryptedItem(ItemLocation calldata location) external view returns (EncryptedItem memory);
```

Function to retrieve the articles data (encrypted) of the specified chapter, section, or item.

**Parameters**

- `location`
    - Position of the target chapter (article, section, item).

**Returns**

- Encrypted articles information (`EncryptedItem` struct).

#### `getVersionRoot`

```solidity
function getVersionRoot(uint256 versionId) external view returns (bytes32);
```

Function to retrieve the `versionRoot` corresponding to a version ID.

**Parameters**

- `versionId`
    - Arbitrary version identification number (uint256 conversion of `versionRoot`).

**Returns**

- `versionRoot`
    - Hash indicating the Merkle root of the articles.

#### `isEphemeralSaltUsed`

```solidity
function isEphemeralSaltUsed(bytes32 ephemeralSalt) external view returns (bool);
```

Function to check if the specified `ephemeralSalt` has been used.

**Parameters**

- `ephemeralSalt`
    - Temporary hash that serves as a session identifier.

**Returns**

- `true` if used, `false` if unused.

#### `verifyDecryptionKeyHash`

```solidity
function verifyDecryptionKeyHash(
    ItemLocation calldata location,
    bytes32 expectedHash
) external view returns (bool);
```

Function to verify if the `plaintext hash` of the specified chapter matches.

**Parameters**

- `location`
    - Position of the target chapter (article, section, item).
- `expectedHash`
    - Plaintext hash derived after decryption.

**Returns**

- `true` if the hash matches.

#### `verifyDecryptionKeyHashWithSaltHash`

```solidity
function verifyDecryptionKeyHashWithSaltHash(
    ItemLocation calldata location,
    bytes32 ephemeralSalt,
    bytes32 masterSaltHash,
    address holder
) external view returns (bool);
```

Function to verify the `ephemeralSalt`, `masterSaltHash`, and NFT ownership used to derive the decryption key.

Returns `false` if the `ephemeralSalt` has been used.

Returns `false` if the `masterSaltHash` differs from the value registered in the contract.

Returns `false` if the address is not an NFT holder.

**Parameters**

- `location`
    - Position of the target chapter (article, section, item).
- `ephemeralSalt`
    - Temporary session value (used for decryption).
- `masterSaltHash`
    - Hash of the pre-registered master salt.

**Returns**

- `true` if all match.

## Backwards Compatibility

No backwards compatibility issues were identified.

## Reference Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IAOI} from "./interfaces/IAOI.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AOI is IAOI, AccessControl {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ************************************************
    // *                   STORAGES                   *
    // ************************************************

    address private _governance;
    address private _token;
    string private _version;

    /** 
     * @dev articleId => paragraphId => itemId => EncryptedItem
     */
    mapping(uint256 => mapping(uint256 => mapping(uint256 => EncryptedItem)))
        public encryptedItems;

    /**
     * @dev versionId => versionRoot
     */
    mapping(uint256 => bytes32) public versionRoots;

    /**
     * @dev ephemeralSalt => used
     */
    mapping(bytes32 => bool) public usedEphemeralSalts;

    // ************************************************
    // *                 MODIFIERS                    *
    // ************************************************

    modifier onlyGovernance() {
        require(
            msg.sender == _governance,
            NotGovernance(msg.sender, _governance)
        );
        _;
    }

    // ************************************************
    // *                 CONSTRUCTOR                  *
    // ************************************************

    constructor(
        address admin,
        address governance,
        address token,
        EncryptedItemInput[] memory items
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _governance = governance;
        _token = token;

        bytes32[] memory leaves = new bytes32[](items.length);

        for (uint256 i = 0; i < items.length; i++) {
            _setEncryptedItem(items[i]);
            leaves[i] = items[i].plaintextHash;
        }

        bytes32 initialVersionRoot = _computeMerkleRoot(leaves);
        versionRoots[0] = initialVersionRoot;
        _version = "1.0.0";

        _emitChapterUpdated(
            0,
            initialVersionRoot,
            address(0),
            new address[](0),
            items
        );
    }

    // ************************************************
    // *           EXTERNAL WRITE FUNCTIONS           *
    // ************************************************

    /**
     * @dev Only Governance can call this function
     */
    function updateChapter(
        bytes32 versionRoot,
        address[] calldata signers,
        bytes[] calldata signatures,
        bytes calldata finalSignature,
        string calldata version,
        EncryptedItemInput[] calldata items
    ) external override onlyGovernance {
        (address finalSigner, ) = _verifyFinalAndAllSigners(
            versionRoot,
            signers,
            signatures,
            finalSignature
        );

        for (uint256 i = 0; i < items.length; i++) {
            _setEncryptedItem(items[i]);
        }

        uint256 versionId = uint256(versionRoot);
        versionRoots[versionId] = versionRoot;
        _version = version;

        _emitChapterUpdated(
            versionId,
            versionRoot,
            finalSigner,
            signers,
            items
        );
    }

    /**
     * @dev Only DefaultAdminRole can call this function
     */
    function setEphemeralSalt(
        bytes32 ephemeralSalt
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            !usedEphemeralSalts[ephemeralSalt],
            EphemeralSaltAlreadyUsed(ephemeralSalt)
        );
        usedEphemeralSalts[ephemeralSalt] = true;
        emit EphemeralSaltMarkedUsed(ephemeralSalt);
    }

    /**
     * @dev Only DefaultAdminRole can call this function
     */
    function setGovernance(
        address governance
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _governance = governance;
        emit GovernanceUpdated(governance);
    }

    /**
     * @dev Only DefaultAdminRole can call this function
     */
    function setToken(
        address token
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _token = token;
        emit TokenUpdated(token);
    }

    // ************************************************
    // *            INTERNAL WRITE FUNCTIONS          *
    // ************************************************

    function _setEncryptedItem(EncryptedItemInput memory item) internal {
        require(
            item.location.articleId >= 1,
            InvalidArticleId(item.location.articleId)
        );
        encryptedItems[item.location.articleId][item.location.paragraphId][
            item.location.itemId
        ] = EncryptedItem(
            item.encryptedData,
            item.plaintextHash,
            item.masterSaltHash
        );
    }

    function _computeMerkleRoot(
        bytes32[] memory leaves
    ) internal pure returns (bytes32) {
        while (leaves.length > 1) {
            uint256 len = leaves.length;
            uint256 newLen = (len + 1) / 2;
            bytes32[] memory next = new bytes32[](newLen);
            for (uint256 i = 0; i < len; i += 2) {
                next[i / 2] = (i + 1 < len)
                    ? keccak256(abi.encodePacked(leaves[i], leaves[i + 1]))
                    : leaves[i];
            }
            leaves = next;
        }
        return leaves[0];
    }

    function _emitChapterUpdated(
        uint256 versionId,
        bytes32 versionRoot,
        address finalSigner,
        address[] memory signers,
        EncryptedItemInput[] memory items
    ) internal {
        ItemLocation[] memory locations = new ItemLocation[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            locations[i] = items[i].location;
        }
        emit ChapterUpdated(
            versionId,
            versionRoot,
            finalSigner,
            signers,
            locations
        );
    }

    // ************************************************
    // *            EXTERNAL READ FUNCTIONS           *
    // ************************************************

    function getVersion() external view override returns (string memory) {
        return _version;
    }

    function getEncryptedItem(
        ItemLocation calldata location
    ) external view returns (EncryptedItem memory) {
        return
            encryptedItems[location.articleId][location.paragraphId][
                location.itemId
            ];
    }

    function getVersionRoot(uint256 versionId) external view returns (bytes32) {
        return versionRoots[versionId];
    }

    function isEphemeralSaltUsed(
        bytes32 ephemeralSalt
    ) external view returns (bool) {
        return usedEphemeralSalts[ephemeralSalt];
    }

    function verifyDecryptionKeyHash(
        ItemLocation calldata location,
        bytes32 expectedHash
    ) external view returns (bool) {
        return
            encryptedItems[location.articleId][location.paragraphId][
                location.itemId
            ].plaintextHash == expectedHash;
    }

    function verifyDecryptionKeyHashWithSaltHash(
        ItemLocation calldata location,
        bytes32 ephemeralSalt,
        bytes32 masterSaltHash,
        address holder
    ) external view returns (bool) {
        return (!usedEphemeralSalts[ephemeralSalt] &&
            encryptedItems[location.articleId][location.paragraphId][
                location.itemId
            ].masterSaltHash ==
            masterSaltHash &&
            IERC721(_token).balanceOf(holder) > 0);
    }

    function getGovernance() external view override returns (address) {
        return _governance;
    }

    function getToken() external view override returns (address) {
        return _token;
    }

    // ************************************************
    // *            INTERNAL READ FUNCTIONS           *
    // ************************************************

    function _verifyFinalAndAllSigners(
        bytes32 versionRoot,
        address[] memory signers,
        bytes[] memory signatures,
        bytes memory finalSignature
    )
        internal
        pure
        returns (address finalSigner, address[] memory recoveredSigners)
    {
        require(signers.length == signatures.length, LengthMismatch());
        recoveredSigners = new address[](signers.length);

        for (uint256 i = 0; i < signers.length; i++) {
            bytes32 hash = keccak256(abi.encodePacked(versionRoot))
                .toEthSignedMessageHash();
            address recovered = hash.recover(signatures[i]);
            require(
                recovered == signers[i],
                InvalidSignature(recovered, signers[i])
            );
            recoveredSigners[i] = recovered;
        }

        bytes32 metaHash = keccak256(
            abi.encode(versionRoot, signers, signatures)
        ).toEthSignedMessageHash();
        finalSigner = metaHash.recover(finalSignature);
    }
}

```

## Test Cases

Sample test code is available and running on Github.

## Rationale

### Why Use AES-256-GCM?

AES (Advanced Encryption Standard) is a widely used **symmetric key encryption method**. It's a system where encryption and decryption are performed with a single key, allowing information to be encrypted quickly and securely.

AES-256-GCM refers to using this AES with a 256-bit key length, operating in the GCM (Galois/Counter Mode). GCM provides not only encryption but also authentication functionality (MAC: Message Authentication Code), making it an "authenticated encryption" that can detect data tampering.

The main reasons for adopting this method are:

- High Security
    
    Using a 256-bit key provides very robust encryption.
    
- Tamper Detection
    
    GCM automatically checks if encrypted data has been altered.
    
- Fast Performance
    
    Optimized at the CPU level, it's very fast especially on Intel-based machines with hardware acceleration.
    
- Wide Compatibility
    
    Supported by many platforms and libraries, reducing implementation and operational burden.
    
- Simple Key Management
    
    Using a single secret key for both encryption and decryption makes key management relatively simple.
    

In a design like this project where all encryption is done off-chain and only hash values are verified on-chain, encryption methods like GCM that allow integrity verification are suitable. This prevents plaintext tampering off-chain and enables lightweight verification of its legitimacy on-chain.

### Can Other Encryption Methods Be Used?

Yes.

The contract proposed in this standard does not depend on the encryption method. The contract deals only with the following information:

- Encrypted byte sequence (`encryptedData`)
- Corresponding plaintext hash (`plaintextHash`)

Therefore, even if the encryption method is changed from AES-256-GCM to something else, verification is still possible as long as the hash of the plaintext obtained after decryption matches.

Here are examples of other encryption methods that could be adopted:

- ChaCha20-Poly1305
    
    A lightweight, fast encryption method that performs particularly well in mobile environments. It provides authenticated encryption like AES-GCM. In terms of security, it's sometimes rated equal to or better than AES-GCM.
    
- AES-CTR + HMAC
    
    An approach that uses AES in CTR (counter) mode for encryption and HMAC (Hash-based Message Authentication Code) for tamper detection. It's sometimes adopted as an alternative in environments where GCM cannot be used.
    
- RSA-OAEP
    
    One of the asymmetric encryption (public key encryption) methods. It uses a key pair (public key and private key) for encryption and decryption. While secure, it's heavy processing, tends to increase file size, and is not suitable for frequent communications or storage.
    
- ECIES (Elliptic Curve Integrated Encryption Scheme)
    
    A hybrid method based on Elliptic Curve Cryptography (ECC) that allows processing combining both encryption and signatures. It works well with ECDSA and is used in contexts such as ZK (Zero-Knowledge Proofs) and confidential tokens.
    

### Why Register Articles Divided Into Chapters, Sections, and Items?

Registering an entire articles of incorporation document at once may not be possible if it's too long for a smart contract.

Additionally, longer documents increase gas costs.

To avoid this risk, the articles are divided and registered on the smart contract.

When part of the articles needs to be amended, only the changed sections need to be updated on the smart contract, saving gas fees.

Token holders who want to view only part of the articles can retrieve just the relevant portion from the contract.

### Integrity Verification with Merkle Root

We calculate and store a `versionRoot` based on all `plaintextHash` values.

This is effective for checking whether the entire articles have been tampered with, not just individual chapters (articles, sections, items).

When changes are made, `updateChapter()` is executed and a new `versionRoot` is recorded.

### Reason for Registering Executor and Voter Addresses

This is not mandatory.

However, recording this information on the smart contract makes it possible to know who served as Executor and who participated in voting, which can be useful in situations where this information is needed.

### Flow

The following explains the flow from encryption of articles of incorporation to decryption by NFT holders.

#### [1] Encryption of Articles by Administrators (Off-chain)

- Administrators prepare each chapter (article, section, item) of the articles of incorporation.
- For each chapter, the following process is executed:
    - Determine the `plaintext`.
    - Randomly generate a `masterSalt` (different for each chapter).
    - Generate a decryption key:

```jsx
key = keccak256(encode([location, masterSalt, userAddress, ephemeralSalt]))
```

- At this stage, the decryptor's address is set to the administrator's address.
- Encrypt using `AES-256-GCM` to obtain `encryptedData`.
- `plaintextHash = keccak256(plaintext)`.
- `masterSaltHash = keccak256(masterSalt)`.
- Deploy the AOI contract and pass the information prepared earlier.

#### [2] Derivation of Decryption Key by User (NFT Holder) (Off-chain)

- User specifies the chapter (location) of the articles they want to view and generates an `ephemeralSalt` (disposable random value).
- Derive the decryption key by combining their own `userAddress` with `location`, `masterSalt`, and `ephemeralSalt`.

```jsx
key = keccak256(encode([location, masterSalt, userAddress, ephemeralSalt]))
```

#### [3] Verify Decryption Key Integrity On-chain

- Verify using one of the following functions with the `masterSalt` and `ephemeralSalt` derived off-chain:
    - `verifyDecryptionKeyForHolder(location, ephemeralSalt, masterSalt)`
        
        → Check if the hash calculated from masterSalt matches the registered `masterSaltHash`.
        
        → Check if the `ephemeralSalt` is not already used.
        
        → Check if the address is an NFT holder.
        
- After successful verification, execute `setEphemeralSalt(ephemeralSalt)` to the contract to invalidate that `ephemeralSalt` (preventing reuse).

#### [4] Decryption (Off-chain)

- Retrieve `encryptedData` using `getEncryptedItem(location)`.
- Decrypt using `AES-256-GCM` with the derived `key` and `ephemeralSalt`.
- Compare the decryption result with `plaintextHash` (stored on-chain).
    - If they match, it confirms that the data is **legitimate and unaltered**.

#### [5] Updating Articles of Incorporation (On-chain)

- Conduct a vote in the Governance contract to execute the following process:
    - Update the articles information by passing an array of structures containing the following information through the `updateChapter()` function:
        - `location` (structured identifier of article, section, item)
        - `encryptedData`
        - `plaintextHash`
        - `masterSaltHash`
- Generate a Merkle Root from all `plaintextHash` values and save it as `versionRoot`.
- The `ChapterUpdated` event is emitted, transparently recording the change history.

### EIP712

EIP712 can also be used for Executor verification.
You can use any signature verification method you prefer.

## Security Considerations

### Collision of ephemeralSalt (Lack of Randomness)

ephemeralSalt is treated as a one-time random number, but if it's not sufficiently random, there's a risk that someone else could use the same salt to generate a decryption key.

Countermeasures include:

- Generate salt using a cryptographically secure random generator (CSPRNG) of at least 32 bytes.
- Recommend using low-collision generation methods like `crypto.randomBytes(32)` rather than UUID v4.

### Leakage of masterSalt

`masterSalt` is part of the material for the decryption key. If this leaks externally, there's a possibility that a third party could know the decryption key if a user's `address` and `ephemeralSalt` match.

Countermeasures include:

- Keep `masterSalt` itself strictly confidential (e.g., in secure key storage like KMS, HSM) and don't pass it to clients.
- Frequent regeneration/rotation of `masterSalt`.

### Hash Collision Attack (plaintextHash)

While `keccak256` used for `plaintextHash` is a powerful hash, if collisions become feasible in the future, there's a danger that malicious third parties could give the same hash to tampered data.

Countermeasures include:

- `keccak256` is currently considered secure and no issues exist.
- Design to allow upgrading the hash algorithm in anticipation of future security degradation, or make the contract upgradeable.

### Intentional Reuse of Plaintext

Using the same plaintext in multiple locations can lead to reuse of `encryptedData` or `plaintextHash`, potentially enabling pattern guessing or similarity analysis (e.g., if Article 1 and Article 2 have the same text).

Countermeasures include:

- Always use different IVs (initialization vectors) during encryption (mandatory with AES-GCM).
- Ensure encryption results differ each time even if the plaintext is the same.

### User Private Key Protection (Decryption Process)

The decryption process is performed with a derived key using the user's address, but because the decryption process depends on the client side, it is subject to device security and key management status.

Countermeasures include:

- Perform decryption processing locally.
- For decryption in browsers or mobile apps, utilize secure environments (e.g., Secure Enclave).
- Minimize the time keys or decryption processes remain in memory.

### Inconsistency Between On-chain and Off-chain

Since the contract only holds hash values, if the off-chain encryption/decryption logic deviates from the specification, there's a risk of verification failure, inability to view content, or believing incorrect content.

Countermeasures include:

- Standardize off-chain processing through libraries and shared code.
- Manage versionId when changing specifications to prevent confusion with old versions.

## Copyright

Copyright and related rights waived via [CC0](https://chatgpt.com/LICENSE.md).
