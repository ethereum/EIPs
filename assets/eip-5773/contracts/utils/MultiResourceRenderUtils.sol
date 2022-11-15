// SPDX-License-Identifier: Apache-2.0

import "../IMultiResource.sol";

pragma solidity ^0.8.15;

/**
 * @dev Extra utility functions for composing RMRK resources.
 */

contract MultiResourceRenderUtils {
    uint16 private constant _LOWEST_POSSIBLE_PRIORITY = 2**16 - 1;

    struct ActiveResource {
        uint64 id;
        uint16 priority;
        string metadata;
    }

    struct PendingResource {
        uint64 id;
        uint128 acceptRejectIndex;
        uint64 overwritesResourceWithId;
        string metadata;
    }

    function getActiveResources(address target, uint256 tokenId)
        public
        view
        virtual
        returns (ActiveResource[] memory)
    {
        IMultiResource target_ = IMultiResource(target);

        uint64[] memory resources = target_.getActiveResources(tokenId);
        uint16[] memory priorities = target_.getActiveResourcePriorities(
            tokenId
        );
        uint256 len = resources.length;
        if (len == 0) {
            revert("Token has no resources");
        }

        ActiveResource[] memory activeResources = new ActiveResource[](len);
        string memory metadata;
        for (uint256 i; i < len; ) {
            metadata = target_.getResourceMetadata(tokenId, resources[i]);
            activeResources[i] = ActiveResource({
                id: resources[i],
                priority: priorities[i],
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return activeResources;
    }

    function getPendingResources(address target, uint256 tokenId)
        public
        view
        virtual
        returns (PendingResource[] memory)
    {
        IMultiResource target_ = IMultiResource(target);

        uint64[] memory resources = target_.getPendingResources(tokenId);
        uint256 len = resources.length;
        if (len == 0) {
            revert("Token has no resources");
        }

        PendingResource[] memory pendingResources = new PendingResource[](len);
        string memory metadata;
        uint64 overwritesResourceWithId;
        for (uint256 i; i < len; ) {
            metadata = target_.getResourceMetadata(tokenId, resources[i]);
            overwritesResourceWithId = target_.getResourceOverwrites(
                tokenId,
                resources[i]
            );
            pendingResources[i] = PendingResource({
                id: resources[i],
                acceptRejectIndex: uint128(i),
                overwritesResourceWithId: overwritesResourceWithId,
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return pendingResources;
    }

    /**
     * @notice Returns resource metadata strings for the given ids
     *
     * Requirements:
     *
     * - `resourceIds` must exist.
     */
    function getResourcesById(
        address target,
        uint256 tokenId,
        uint64[] calldata resourceIds
    ) public view virtual returns (string[] memory) {
        IMultiResource target_ = IMultiResource(target);
        uint256 len = resourceIds.length;
        string[] memory resources = new string[](len);
        for (uint256 i; i < len; ) {
            resources[i] = target_.getResourceMetadata(tokenId, resourceIds[i]);
            unchecked {
                ++i;
            }
        }
        return resources;
    }

    /**
     * @notice Returns the resource metadata with the highest priority for the given token
     */
    function getTopResourceMetaForToken(address target, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        IMultiResource target_ = IMultiResource(target);
        uint16[] memory priorities = target_.getActiveResourcePriorities(
            tokenId
        );
        uint64[] memory resources = target_.getActiveResources(tokenId);
        uint256 len = priorities.length;
        if (len == 0) {
            revert("Token has no resources");
        }

        uint16 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
        uint64 maxPriorityResource;
        for (uint64 i; i < len; ) {
            uint16 currentPrio = priorities[i];
            if (currentPrio < maxPriority) {
                maxPriority = currentPrio;
                maxPriorityResource = resources[i];
            }
            unchecked {
                ++i;
            }
        }
        return target_.getResourceMetadata(tokenId, maxPriorityResource);
    }
}
