---
eip: <to be assigned>
title: Expandable Onchain SVG Images Storage Structure
description: It is a Expandable Onchain SVG Images Storage Structure Model on the Ethereum.
author: <To be assigned>, Soohan Park <725psh@gmail.com>
discussions-to: https://ethereum-magicians.org/t/expandable-onchain-svg-images-storage-structure/8330
status: Draft
type: Standards Track
category: ERC
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
requires: 721
---

## Simple Summary
이더리움에서 확장 가능한 온체인 SVG 이미지 저장 구조 모델입니다.

  

## Abstract
이 표준 제안은 이더리움 온체인 상에 이미지를 영구적으로 보존하고 변조를 방지하며, 나아가 더 큰 용량의 이미지를 저장할 수 있고 확장 가능한 SVG 이미지 분산 저장 구조 모델입니다.

SVG 이미지를 태그 단위로 분산 저장하여 온체인 상에서 더 큰 용량의 SVG 이미지를 저장할 수 있도록 설계한 구조입니다.

이 EIP에서 제시하는 구조는 아래와 같이 총 3개의 레이어로 구성되어 있습니다.

![StructureDiagram.jpg](./StructureDiagram.jpg)

> **Storage Layer ─** SVG 이미지를 태그별로 분산 저장하는 컨트랙트 레이어.  
> **Assemble Layer ─** 'Storage Layer Contract'에 저장되어 있는 태그들을 조합하여 SVG 이미지를 생성하는 컨트랙트 레이어.  
> **Property Layer ─** 어떠한 SVG 태그를 사용할 지, 그에 대한 속성값이 저장되어 있는 컨트랙트 레이어.  

위 3개의 레이어별 컨트랙트들이 서로 상호작용하며 큰 크기의 SVG 이미지를 유연하게 저장하고 활용할 수 있도록 설계하였습니다.

또한, 아래와 같이 Assemble Layer의 컨트랙트를 조정하여 Onchain NFT Images Storage를 구성할 수 있습니다.

- A storage with expandability by allowing additional deployment on Storage Layer's contracts
- A storage with immutability after initial deployment

추가적으로, 이 표준 제안은 EIP-721 표준과의 호환성에 중점을 두고 있지만, 이에 국한되지는 않습니다.



## Motivation
대다수의 NFT 프로젝트들은 자신들의 NFT 메타데이터와 컨텐츠들을 이더리움 네트워크가 아닌 중앙 집중식 서버에 보관하고 있습니다. 이 방법은 NFT의 컨텐츠를 표시하는 가장 저렴하고 손쉬운 방법이지만, NFT의 메타데이터나 컨텐츠가 손상되거나 손실될 위험이 존재합니다. <u>또한, IPFS의 경우에도 컨텐츠의 변조를 방지할 수는 있지만, 컨텐츠를 저장하고 있는 노드가 없는 경우 컨텐츠가 손실될 수도 있습니다.</u>

이 문제를 해결하기 위해 대부분 NFT메타데이터를 이더리움 온체인으로 저장합니다. 그러나 한 컨트랙트에 배포 가능한 최대 크기는 24KB이기 때문에 단순한 도형 ─원이나 사각형─ 으로 표현할 수 밖에 없습니다.

우리는 고품질의 NFT 메타데이터를 생성하고 소유하기 위해 NFT 메타데이터를 저장하는 보다 안전한 방법인 이 모델을 제안합니다.

  

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

이 EIP에서 제안하는 모델의 3개의 레이어에 대해 각각 구체적으로 설명하려 합니다.

기능과 역할에 따라 레이어를 구분 짓고 이를 각기 다른 컨트랙트로 배포한 뒤, 이 컨트랙트들을 논리적으로 연결하여 하나의 큰 저장 공간을 갖는 컨트랙트처럼 활용되도록 구성하였습니다.

### Storage Layer

SVG 이미지를 태그별로 분산하여 저장하는 컨트랙트 레이어입니다.

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

이 Storage Layer's contracts들은 배포된 이후 오직 저장된 SVG 이미지 태그를 Assemble Layer로 전달해주는 역할만 수행할 수 있습니다.

우리는 데이터 오염을 고려해야하기 때문에 `setAsset`과 같은 기능을 구현하지 않았습니다. **(SHOULD)** 따라서, SVG 이미지 태그를 등록하는 것은 컨트랙트를 배포할 때만 가능하며, 추후 변경이 필요한 경우 새로운 컨트랙트를 배포하는 것을 추천합니다. **(RECOMMENDED)**

### Assemble Layer

저장되어 있는 태그들을 조합하여 이미지를 생성하는 미들맨 역할의 컨트랙트 레이어입니다.

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

Assemble Layer의 컨트랙트에 새로운 Storage Layer 컨트랙트를 추가하는 함수인 `addStorage(address)` 기능은 인터페이스에 포함되어 있지 않습니다. 왜냐하면, 우리는 각 레이어가 서로 격리되어 있기를 원하기 때문입니다.

e.g. `addStorage(address)` 함수는 다음과 같이 구현할 수 있습니다.

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

어떠한 SVG 태그 값들을 가져올 지에 대한 속성 값이 저장되어 있는 컨트랙트 레이어입니다.

사용자는 Property Layer를 통해 저장된 이미지에 접근할 수 있으며, EIP-721 혹은 이 외의 규격들에 대한 상속 역시 이 레이어에서 하게 됩니다.

아래의 함수들은 Property Layer's contract에서 구현해야 할 주요 함수들에 대한 설명입니다.

- `getImage(uint256)`: 저장한 SVG 이미지를 가져오는 함수입니다. `tokenId_`에 해당하는 속성값들을 가져와 Assemble Layer 인터페이스의 getImage를 호출합니다.

    ```solidity
    /**
    * @dev See {IAssembleContract-getImage}
    */
    function getImage(uint256 tokenId_) public view virtual returns (string memory) {
        return assembleContract.getImage(_attrs[tokenId_]);
    }
    ```

- `setAssembleContract(address)`: Assemble Layer's Contract를 설정하는 함수입니다. 만약, 최초 배포 후 변경이 불가능한 immutable storage 로 활용하고자 한다면, 해당 함수를 제거하면 됩니다.

    ```solidity
    /**
    * @param newAssembleContractAddr_ Address value of `AssembleContract` to be changed.
    * @dev If later changes or extensions are unnecessary, write directly to `constructor` without implementing the function.
    */
    function setAssembleContract(address newAssembleContractAddr_) public virtual {
        assembleContract = IAssembleContract(newAssembleContractAddr_);
    }
    ```

- `_setAttr(uint256)`: 어떠한 SVG 이미지 태그를 불러올 것인지 속성값을 설정해주는 함수입니다. 어떻게 속성값을 설정해줄지에 대한 로직은 반드시 활용하고자 하는 방향에 맞춰 별도로 구현해주어야 합니다. (**MUST**)

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

우리가 콘텐츠를 영구적이고 변조 불가능하게 보관하는 가장 좋은 방법은 <u>변조 혹은 유실될 수 있는 중앙 집중식 서버나 IPFS가 아닌,</u> 온체인 상에 저장하는 것입니다. SVG 형식과 같이 콘텐츠의 용량을 줄이기 위해 다양한 확장들이 나왔지만, 대부분의 콘텐츠들은 아직 수 MB 이상의 크기를 가지고 있습니다. 이 EIP를 통해 수십 KB에서 수 MB에 이르는 큰 크기의 SVG 이미지들을 온체인 상에 안전하게 저장할 수 있는 하나의 솔루션을 제공하고자 합니다.

### Cost Efficiency

이 EIP에서 제안하는 방식은 많은 수의 컨트랙트 배포를 필요로 합니다. 따라서, 저장하고자 하는 SVG 이미지의 수가 적거나, 하나의 컨트랙트에 모두 포함시킬 수 있을만큼 크기가 작은 경우에는 이 EIP를 활용하는 것을 다시 한 번 검토해볼 필요가 있습니다.

### Expandable

이 EIP에서는 **데이터 오염을 방지하기 위해** 아래와 같이 **확장 가능성**에 대해 약간의 제한을 두었습니다.

- Storage Layer에 속하는 컨트랙트들을 **WRITE ONLY ONCE**로 설정하였습니다. SVG 이미지 태그들을 직접 저장하고 있는 곳이므로, 데이터 오염을 방지하기 위해 첫 배포시에만 값을 설정할 수 있도록 하였습니다. 만약, 값에 대한 수정이 필요한 경우 새로운 컨트랙트를 배포해야 합니다.
- Assemble Layer와 Storage Layer를 서로 연결할 때는 **APPEND ONLY**로 설정하였습니다. 확장성은 유지하되, 기존에 연결된 컨트랙트들은 변경되지 않도록 설계하여 데이터 오염을 최소화하고자 하였습니다. 



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

  

## Security Considerations
There are no known security considerations for this EIP.

  

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
