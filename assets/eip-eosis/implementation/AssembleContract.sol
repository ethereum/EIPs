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