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