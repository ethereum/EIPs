// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5773 {
    event AssetSet(uint64 assetId);

    event AssetAddedToTokens(
        uint256[] tokenId,
        uint64 indexed assetId,
        uint64 indexed replacesId
    );

    event AssetAccepted(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed replacesId
    );

    event AssetRejected(uint256 indexed tokenId, uint64 indexed assetId);

    event AssetPrioritySet(uint256 indexed tokenId);

    event ApprovalForAssets(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllForAssets(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external;

    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external;

    function rejectAllAssets(uint256 tokenId, uint256 maxRejections) external;

    function setPriority(
        uint256 tokenId,
        uint16[] calldata priorities
    ) external;

    function getActiveAssets(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    function getPendingAssets(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    function getActiveAssetPriorities(
        uint256 tokenId
    ) external view returns (uint16[] memory);

    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) external view returns (uint64);

    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) external view returns (string memory);

    function approveForAssets(address to, uint256 tokenId) external;

    function getApprovedForAssets(
        uint256 tokenId
    ) external view returns (address);

    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) external;

    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) external view returns (bool);
}
