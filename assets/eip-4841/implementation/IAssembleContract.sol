pragma solidity ^0.8.0;

/**
 * @title IAssembleContract
 */
interface IAssembleContract {
    /**
     * @notice For each `StorageContract`, get the corresponding XML tag of SVG image and combine it and return it.
     * @param attrs_ Array of corresponding property values sequentially for each connected contract.
     * @return A complete SVG image in the form of a String.
     * @dev It runs the connected `StorageContract` in the registered order, gets XML tags of SVG image and combines it into one image.
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