// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IMultiResource {
    event ResourceSet(uint64 resourceId);

    event ResourceAddedToToken(
        uint256 indexed tokenId,
        uint64 indexed resourceId,
        uint64 indexed overwritesId
    );

    event ResourceAccepted(
        uint256 indexed tokenId,
        uint64 indexed resourceId,
        uint64 indexed overwritesId
    );

    event ResourceRejected(uint256 indexed tokenId, uint64 indexed resourceId);

    event ResourcePrioritySet(uint256 indexed tokenId);

    event ApprovalForResources(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllForResources(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function acceptResource(
        uint256 tokenId,
        uint256 index,
        uint64 resourceId
    ) external;

    function rejectResource(
        uint256 tokenId,
        uint256 index,
        uint64 resourceId
    ) external;

    function rejectAllResources(uint256 tokenId, uint256 maxRejections)
        external;

    function setPriority(uint256 tokenId, uint16[] calldata priorities)
        external;

    function getActiveResources(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    function getPendingResources(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    function getActiveResourcePriorities(uint256 tokenId)
        external
        view
        returns (uint16[] memory);

    function getResourceOverwrites(uint256 tokenId, uint64 newResourceId)
        external
        view
        returns (uint64);

    function getResourceMetadata(uint256 tokenId, uint64 resourceId)
        external
        view
        returns (string memory);

    // Approvals
    function approveForResources(address to, uint256 tokenId) external;

    function getApprovedForResources(uint256 tokenId)
        external
        view
        returns (address);

    function setApprovalForAllForResources(address operator, bool approved)
        external;

    function isApprovedForAllForResources(address owner, address operator)
        external
        view
        returns (bool);
}
