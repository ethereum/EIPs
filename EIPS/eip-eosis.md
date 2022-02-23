---
eip: <to be assigned>
title: Expandable Onchain SVG Images Storage Structure
description: It is a Expandable Onchain SVG Images Storage Structure Model on Ethereum.
author: KyungEun Kim <kkekke815@gmail.com>, Soohan Park <725psh@gmail.com>
discussions-to: https://ethereum-magicians.org/t/expandable-onchain-svg-images-storage-structure/8330
status: Draft
type: Standards Track
category: ERC
created: 2022-02-23
---



## Simple Summary
It is a Expandable Onchain SVG Images Storage Structure Model on Ethereum.



## Abstract
This standard proposal is a Expandable Onchain SVG Images Storage Structure Model on the Ethereum that permanently preserves images and prevents tampering, and can store larger-capacity images furthermore.

It is a structure designed to store SVG images with a larger capacity by distributed SVG images in units of tags on Ethereum.

The structure presented by this EIP consists of a total of three layers as shown below.

![StructureDiagram.jpg](../assets/eip-eosis/StructureDiagram.jpg)

> **Storage Layer ─** A contract layer that stores distributed SVG images by tags.  
> **Assemble Layer ─** A contract layer that creates SVG images by combining tags stored in the Storage Layer's contract.  
> **Property Layer ─** A contract layer that stores the attribute values for which SVG tag to use.  

It is designed to flexibly store and utilize larger capacity SVG images by interacting with the above three layer-by-layer contracts each other.

Also, you can configure the Onchain NFT Images Storage by adjusting the Assemble Layer's contract like below.

* A storage with expandability by allowing additional deployment on Storage Layer's contracts
* A storage with immutability after initial deployment

Additionally, this standard proposal focuses on, but is not limited to, compatibility with the [EIP-721](/EIPS/eip-721.md) standard.



## Motivation
Most NFT projects store their NFT metadata on a centralized server rather than on the Ethereum. Although this method is the cheapest and easiest way to store and display the content of the NFT, there is a risk of corruption or loss of the NFT's metadata. In addition, even in the case of IPFS, tampering of contents can be prevented, but contents could be lost if there is no node storing the contents.

To solve this problem, most NFT metadata is stored on Ethereum. However, it can only be expressed as a simple shape such as a circle or a rectangle, since one contract can be distributed 24KB size for maximum.

We propose this model *─ a more secure way to store NFT metadata ─*  to create and own high-quality of NFT metadata.



## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

We would like to explain each of the three layers of the proposed model in detail.

After classifying layers according to functions and roles and distributing them to different contracts, these contracts are logically connected to be used like a contract with one large storage space.

### Storage Layer
A contract layer that stores distributed SVG images by tags.

```solidity
pragma solidity ^0.8.0;

/**
 * @title IStorageContract
 * @dev A contract that returns stored assets (SVG image tags). `setAsset` is not implemented separately.
 * If the `setAsset` function exists, the value of the asset in the contract can be changed, and there is a possibility of data corruption.
 * Therefore, the value can be set only when the contract is created, and new contract distribution is recommended when changes are required.
 */
interface IStorageContract {
    /**
     * @notice Returns the SVG image tag corresponding to `assetId_`.
     * @param assetId_ Asset ID
     * @return A SVG image tag of type String.
     */
    function getAsset(uint256 assetId_) external view returns (string memory);
}
```

After these Storage Layer's contracts are deployed, they can only perform the role of delivering the saved SVG image tags to the Assemble Layer.

Since we **SHOULD** have to consider data contamination, we didn't implement the function of `setAsset`. Therefore, registering SVG image tags is only possible when deploying a contract, and it is **RECOMMENDED** to deploy a new contract if changes are required in the future.

### Assemble Layer
A contract layer that creates SVG images by combining tags stored in the Storage Layer's contract. 

```solidity
pragma solidity ^0.8.0;

/** 
 * @title IAssembleContract
 */
interface IAssembleContract {
    /**
     * @notice For each `StorageContract`, get the corresponding SVG image tag and combine it and return it.
     * @param attrs_ Array of corresponding property values sequentially for each connected contract.
     * @return A complete SVG image in the form of a String.
     * @dev It runs the connected `StorageContract` in the registered order, gets the SVG tag value and combines it into one image.
     * It should be noted that the order in which the asset storage contract is registered must be carefully observed.
     */
    function getImage(uint256[] memory attrs_) external view returns (string memory);

    /**
     * @notice Returns the count of connected Asset Storages.
     * @return Count of Asset Storage.
     * @dev Instead of storing the count of storage separately in `PropertyContract`, get the value through this function and use it.
     */
    function getStorageCount() external view returns (uint256);
}
```

The `addStorage(address)` function, add new Storage Layer's contract to Assemble Layer's contract, is not included the interface. Because, we would like to each layer to be isolated from each other.

e.g. The `addStorage(address)` function can be implemented like this:

```solidity
/**
 * @param storageAddr_ Address of `StorageContract`.
 * @dev If later changes or extensions are unnecessary, write directly to `constructor` without implementing the function.
 */
function addStorage(address storageAddr_) public virtual returns (uint256) {
    _assets.push(AssetStorage({
        addr: storageAddr_,
        stock: IStorageContract(storageAddr_)
    }));
    return _assets.length-1; // index
}
```

### Property Layer
A contract layer that stores the attribute values for which SVG tag to use. 

The user can access the saved image through the Property Layer, and inheritance of EIP-721 or other standards is also performed in this layer.

The following functions are descriptions of the main functions to be implemented in the Property Layer's contract.

- `getImage(uint256)`: This function gets the saved SVG image. Get the property values corresponding to `tokenId_` and call `getImage` of the Assemble Layer interface.

    ```solidity
    /**
    * @dev See {IAssembleContract-getImage}
    */
    function getImage(uint256 tokenId_) public view virtual returns (string memory) {
        return assembleContract.getImage(_attrs[tokenId_]);
    }
    ```

- `setAssembleContract(address)`: This function sets the Assemble Layer's Contract. If you want to use it as an Immutable Storage that cannot be changed after the initial deployment, you can remove the function.

    ```solidity
    /**
    * @param newAssembleContractAddr_ Address value of `AssembleContract` to be changed.
    * @dev If later changes or extensions are unnecessary, write directly to `constructor` without implementing the function.
    */
    function setAssembleContract(address newAssembleContractAddr_) public virtual {
        assembleContract = IAssembleContract(newAssembleContractAddr_);
    }
    ```

- `_setAttr(uint256)`: This is a function that sets the attribute value of which SVG image tag to load. The logic for how to set the property value **MUST** be implemented separately according to the direction to be used.

    ```solidity
    /**
    * @param tokenId_ The token ID for which you want to set the attribute value.
    * @dev Set the attribute value of the corresponding `tokenId_` sequentially according to the number of asset storage.
    */
    function _setAttr(uint256 tokenId_) internal virtual {
        for (uint256 idx=0; idx < assembleContract.getStorageCount(); idx++) {
            uint256 newValue = 0;
    
            /// @dev Implement the property value setting logic.
            
            _attrs[tokenId_].push(newValue);  
        }
    }
    ```



## Rationale

### Large Capacity Storage
The best way for us to keep our content permanent and tamper-proof is to store it on Ethereum, rather than on centralized servers or IPFS, where it can be tampered with or lost. Like the SVG format, various extensions have come out to reduce the size of the content, but most of the content still has a size of several MB or more. Through this EIP, we would like to provide a solution that can safely store SVG images in sizes ranging from tens of KB to several MB on Ethereum.

### Cost Efficiency
The protocol proposed by this EIP requires the deployment of a large number of contracts. Therefore, it is necessary to reconsider using this EIP if the number of SVG images you want to save is small or the size is small enough to include them all in one contract.

### Expandable
In this EIP, to prevent data contamination, we have placed some restrictions on **EXPANDABLE** as shown below.

- Storage Layer's contracts are set to **be written only once**. Since it is a place where SVG image tags are stored directly, values can only be set at the first deployment to prevent data contamination. If you need to modify the value, you need to deploy a new contract.
- When connecting the Storage Layer to the Assemble Layer, it is set to **be appended only**. By designing existing connected contracts not to change, we tried to minimize data contamination while maintaining scalability.



## Backwards Compatibility
There are no backward compatibility issues.



## Reference Implementation
### PropertyContract.sol
```solidity
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IAssembleContract} from "./IAssembleContract.sol";

/**
 * @title PropertyContract
 * @notice A contract that stores property values.
 */
contract PropertyContract is ERC721 {
    /**
     * @notice A variable that stores the object of `AssembleContract`.
     */
    IAssembleContract public assembleContract;

    // Storing property values corresponding to each number of storage. (tokenId -> attr[])
    mapping(uint256 => uint256[]) private _attrs;

    /**
     * @dev `name_` and `symbol_` are passed to ERC-721, and in case of `assembleContractAddr_`, the `setAssembleContract` function is used.
     */
    constructor(string memory name_, string memory symbol_, address assembleContractAddr_) ERC721(name_, symbol_) {
        setAssembleContract(assembleContractAddr_);
    }

    /**
     * @dev See {IAssembleContract-getImage}
     */
    function getImage(uint256 tokenId_) public view virtual returns (string memory) {
        return assembleContract.getImage(_attrs[tokenId_]);
    }

    /**
     * @param newAssembleContractAddr_ Address value of `AssembleContract` to be changed.
     * @dev If later changes or extensions are unnecessary, write directly to `constructor` without implementing the function.
     */
    function setAssembleContract(address newAssembleContractAddr_) public virtual {
        assembleContract = IAssembleContract(newAssembleContractAddr_);
    }

    /**
     * @param tokenId_ The token ID for which you want to set the attribute value.
     * @dev Set the attribute value of the corresponding `tokenId_` sequentially according to the number of asset storage.
     */
    function _setAttr(uint256 tokenId_) internal virtual {
        for (uint256 idx=0; idx < assembleContract.getStorageCount(); idx++) {
            uint256 newValue = 0;

            /// @dev Implement the property value setting logic.

            _attrs[tokenId_].push(newValue);  
        }
    }
}
```

### IAssembleContract.sol
```solidity
pragma solidity ^0.8.0;

/** 
 * @title IAssembleContract
 */
interface IAssembleContract {
    /**
     * @notice For each `StorageContract`, get the corresponding SVG image tag and combine it and return it.
     * @param attrs_ Array of corresponding property values sequentially for each connected contract.
     * @return A complete SVG image in the form of a String.
     * @dev It runs the connected `StorageContract` in the registered order, gets the SVG tag value and combines it into one image.
     * It should be noted that the order in which the asset storage contract is registered must be carefully observed.
     */
    function getImage(uint256[] memory attrs_) external view returns (string memory);

    /**
     * @notice Returns the count of connected Asset Storages.
     * @return Count of Asset Storage.
     * @dev Instead of storing the count of storage separately in `PropertyContract`, get the value through this function and use it.
     */
    function getStorageCount() external view returns (uint256);
}
```

### AssembleContract.sol
```solidity
pragma solidity ^0.8.0;

import {IAssembleContract} from "./IAssembleContract.sol";
import {IStorageContract} from "./IStorageContract.sol";

/**
 * @title AssembleContract
 * @notice A contract that assembles SVG images.
 */
contract AssembleContract is IAssembleContract {

    /**
     * @dev Asset storage structure. Stores the contract address value and the corresponding object.
     */
    struct AssetStorage {
        address addr;
        IStorageContract stock;
    }

    AssetStorage[] private _assets;

    /**
     * @dev Register address values of `StorageContract`. Pay attention to the order when registering.
     */
    constructor (address[] memory assetStorageAddrList_) {
        for (uint256 i=0; i < assetStorageAddrList_.length; i++) {
            addStorage(assetStorageAddrList_[i]);
        }
    }

    /**
     * @dev See {IAssembleContract-getImage}
     */
    function getImage(uint256[] memory attrs_) external view virtual override returns (string memory) {
        string memory imageString = "";

        imageString = string(abi.encodePacked(imageString, "<svg version='1.1' xmlns='http://www.w3.org/2000/svg'>"));

        for (uint256 i=0; i < attrs_.length; i++) {
            imageString = string(
                abi.encodePacked(
                    imageString,
                    _assets[i].stock.getAsset(attrs_[i])
                )
            );
        }

        imageString = string(abi.encodePacked(imageString, '</svg>'));

        return imageString;
    }

    /**
     * See {IAssembleContract-getStorageCount}
     */
    function getStorageCount() external view virtual override returns (uint256) {
        return _assets.length;
    }

    /**
     * @param storageAddr_ Address of `StorageContract`.
     * @dev If later changes or extensions are unnecessary, write directly to `constructor` without implementing the function.
     */
    function addStorage(address storageAddr_) public virtual returns (uint256) {
        _assets.push(AssetStorage({
            addr: storageAddr_,
            stock: IStorageContract(storageAddr_)
        }));
        return _assets.length-1; // index
    }
}
```

### IStorageContract.sol
```solidity
pragma solidity ^0.8.0;

/**
 * @title IStorageContract
 * @dev A contract that returns stored assets (SVG image tags). `setAsset` is not implemented separately.
 * If the `setAsset` function exists, the value of the asset in the contract can be changed, and there is a possibility of data corruption.
 * Therefore, the value can be set only when the contract is created, and new contract distribution is recommended when changes are required.
 */
interface IStorageContract {
    /**
     * @notice Returns the SVG image tag corresponding to `assetId_`.
     * @param assetId_ Asset ID
     * @return A SVG image tag of type String.
     */
    function getAsset(uint256 assetId_) external view returns (string memory);
}
```

### StorageContract.sol
```solidity
pragma solidity ^0.8.0;

import {IStorageContract} from "./IStorageContract.sol";

/**
 * @title StorageContract
 * @notice A contract that stores SVG image tags.
 * @dev See {IStorageContract}
 */
contract StorageContract is IStorageContract {

    // Asset List
    mapping(uint256 => string) private _assetList;

    /**
     * @dev Write the values of assets (SVG image tags) to be stored in this `StorageContract`.
     */
    constructor () {
        // Setting Assets such as  _assetList[1234] = "<circle ...";
    }

    /**
     * @dev See {IStorageContract-getAsset}
     */
    function getAsset(uint256 assetId_) external view override returns (string memory) {
        return _assetList[assetId_];
    }
}
```

You can also view these files in [here](../assets/eip-eosis/implementation/).



## Security Considerations
There are no known security considerations for this EIP.



## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
