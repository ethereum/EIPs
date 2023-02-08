// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

interface IERC6059 {
    struct DirectOwner {
        uint256 tokenId;
        address ownerAddress;
        bool isNft;
    }

    event NestTransfer(
        address indexed from,
        address indexed to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 indexed tokenId
    );

    event ChildProposed(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    event ChildAccepted(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    event AllChildrenRejected(uint256 indexed tokenId);

    event ChildTransferred(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId,
        bool fromPending
    );

    struct Child {
        uint256 tokenId;
        address contractAddress;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function directOwnerOf(
        uint256 tokenId
    ) external view returns (address, uint256, bool);

    function burn(
        uint256 tokenId,
        uint256 maxRecursiveBurns
    ) external returns (uint256);

    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) external;

    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) external;

    function rejectAllChildren(
        uint256 parentId,
        uint256 maxRejections
    ) external;

    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) external;

    function childrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    function pendingChildrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    function childOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) external;
}
