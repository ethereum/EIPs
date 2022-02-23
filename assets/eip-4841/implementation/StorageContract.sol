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