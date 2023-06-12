// SPDX-License-Identifier: CC0-1.0

import "../IERC5773.sol";

pragma solidity ^0.8.15;

/**
 * @dev Extra utility functions for composing RMRK assets.
 */

contract MultiAssetRenderUtils {
    uint64 private constant _LOWEST_POSSIBLE_PRIORITY = 2 ** 16 - 1;

    struct ActiveAsset {
        uint64 id;
        uint64 priority;
        string metadata;
    }

    struct PendingAsset {
        uint64 id;
        uint128 acceptRejectIndex;
        uint64 overwritesAssetWithId;
        string metadata;
    }

    function getActiveAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ActiveAsset[] memory) {
        IERC5773 target_ = IERC5773(target);

        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert("Token has no assets");
        }

        ActiveAsset[] memory activeAssets = new ActiveAsset[](len);
        string memory metadata;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            activeAssets[i] = ActiveAsset({
                id: assets[i],
                priority: priorities[i],
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return activeAssets;
    }

    function getPendingAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (PendingAsset[] memory) {
        IERC5773 target_ = IERC5773(target);

        uint64[] memory assets = target_.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert("Token has no assets");
        }

        PendingAsset[] memory pendingAssets = new PendingAsset[](len);
        string memory metadata;
        uint64 overwritesAssetWithId;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            overwritesAssetWithId = target_.getAssetReplacements(
                tokenId,
                assets[i]
            );
            pendingAssets[i] = PendingAsset({
                id: assets[i],
                acceptRejectIndex: uint128(i),
                overwritesAssetWithId: overwritesAssetWithId,
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return pendingAssets;
    }

    /**
     * @notice Returns asset metadata strings for the given ids
     *
     * Requirements:
     *
     * - `assetIds` must exist.
     */
    function getAssetsById(
        address target,
        uint256 tokenId,
        uint64[] calldata assetIds
    ) public view virtual returns (string[] memory) {
        IERC5773 target_ = IERC5773(target);
        uint256 len = assetIds.length;
        string[] memory assets = new string[](len);
        for (uint256 i; i < len; ) {
            assets[i] = target_.getAssetMetadata(tokenId, assetIds[i]);
            unchecked {
                ++i;
            }
        }
        return assets;
    }

    /**
     * @notice Returns the asset metadata with the highest priority for the given token
     */
    function getTopAssetMetaForToken(
        address target,
        uint256 tokenId
    ) external view returns (string memory) {
        IERC5773 target_ = IERC5773(target);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint256 len = priorities.length;
        if (len == 0) {
            revert("Token has no assets");
        }

        uint64 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
        uint64 maxPriorityAsset;
        for (uint64 i; i < len; ) {
            uint64 currentPrio = priorities[i];
            if (currentPrio < maxPriority) {
                maxPriority = currentPrio;
                maxPriorityAsset = assets[i];
            }
            unchecked {
                ++i;
            }
        }
        return target_.getAssetMetadata(tokenId, maxPriorityAsset);
    }
}
