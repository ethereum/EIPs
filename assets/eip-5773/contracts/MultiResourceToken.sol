// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./IMultiResource.sol";
import "./library/MultiResourceLib.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MultiResourceToken is Context, IERC721, IMultiResource {
    using MultiResourceLib for uint256;
    using MultiResourceLib for uint64[];
    using MultiResourceLib for uint128[];
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to approved address for resources
    mapping(uint256 => address) internal _tokenApprovalsForResources;

    // Mapping from owner to operator approvals for resources
    mapping(address => mapping(address => bool))
        internal _operatorApprovalsForResources;

    //mapping of uint64 Ids to resource object
    mapping(uint64 => string) internal _resources;

    //mapping of tokenId to new resource, to resource to be replaced
    mapping(uint256 => mapping(uint64 => uint64)) private _resourceOverwrites;

    //mapping of tokenId to all resources
    mapping(uint256 => uint64[]) internal _activeResources;

    //mapping of tokenId to an array of resource priorities
    mapping(uint256 => uint16[]) internal _activeResourcePriorities;

    //Double mapping of tokenId to active resources
    mapping(uint256 => mapping(uint64 => bool)) private _tokenResources;

    //mapping of tokenId to all resources by priority
    mapping(uint256 => uint64[]) internal _pendingResources;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    ////////////////////////////////////////
    //        ERC-721 COMPLIANCE
    ////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IMultiResource).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "MultiResource: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "MultiResource: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function approveForResources(address to, uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "MultiResource: approval to current owner");
        require(
            _msgSender() == owner ||
                isApprovedForAllForResources(owner, _msgSender()),
            "MultiResource: approve caller is not owner nor approved for all"
        );
        _approveForResources(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "MultiResource: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function getApprovedForResources(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        require(
            _exists(tokenId),
            "MultiResource: approved query for nonexistent token"
        );
        return _tokenApprovalsForResources[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAllForResources(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAllForResources(_msgSender(), operator, approved);
    }

    function isApprovedForAllForResources(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _operatorApprovalsForResources[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "MultiResource: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "MultiResource: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "MultiResource: transfer to non ERC721 Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "MultiResource: approved query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _isApprovedForResourcesOrOwner(address user, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "MultiResource: approved query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAllForResources(owner, user) ||
            getApprovedForResources(tokenId) == user);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "MultiResource: transfer to non ERC721 Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "MultiResource: mint to the zero address");
        require(!_exists(tokenId), "MultiResource: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        // WARNING: If you intend to allow the reminting of a burned token, you
        // might want to clean the resources for the token, that is:
        // _pendingResources, _activeResources, _resourceOverwrites
        // _activeResourcePriorities and _tokenResources.
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _approveForResources(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "MultiResource: transfer from incorrect owner"
        );
        require(
            to != address(0),
            "MultiResource: transfer to the zero address"
        );

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _approveForResources(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _approveForResources(address to, uint256 tokenId)
        internal
        virtual
    {
        _tokenApprovalsForResources[tokenId] = to;
        emit ApprovalForResources(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "MultiResource: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _setApprovalForAllForResources(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "MultiResource: approve to caller");
        _operatorApprovalsForResources[owner][operator] = approved;
        emit ApprovalForAllForResources(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "MultiResource: transfer to non ERC721 Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    ////////////////////////////////////////
    //                RESOURCES
    ////////////////////////////////////////

    function acceptResource(
        uint256 tokenId,
        uint256 index,
        uint64 resourceId
    ) external virtual {
        require(
            index < _pendingResources[tokenId].length,
            "MultiResource: index out of bounds"
        );
        require(
            _isApprovedForResourcesOrOwner(_msgSender(), tokenId),
            "MultiResource: not owner or approved"
        );
        require(
            resourceId == _pendingResources[tokenId][index],
            "MultiResource: Unexpected resource"
        );

        _beforeAcceptResource(tokenId, index, resourceId);
        _pendingResources[tokenId].removeItemByIndex(index);

        uint64 overwrite = _resourceOverwrites[tokenId][resourceId];
        if (overwrite != uint64(0)) {
            // It could have been overwritten previously so it's fine if it's not found.
            // If it's not deleted (not found), we don't want to send it on the event
            if (!_activeResources[tokenId].removeItemByValue(overwrite))
                overwrite = uint64(0);
            else delete _tokenResources[tokenId][overwrite];
            delete (_resourceOverwrites[tokenId][resourceId]);
        }
        _activeResources[tokenId].push(resourceId);
        //Push 0 value of uint16 to array, e.g., uninitialized
        _activeResourcePriorities[tokenId].push(uint16(0));
        emit ResourceAccepted(tokenId, resourceId, overwrite);
        _afterAcceptResource(tokenId, index, resourceId);
    }

    function rejectResource(
        uint256 tokenId,
        uint256 index,
        uint64 resourceId
    ) external virtual {
        require(
            index < _pendingResources[tokenId].length,
            "MultiResource: index out of bounds"
        );
        require(
            _pendingResources[tokenId].length > index,
            "MultiResource: Pending resource index out of range"
        );
        require(
            _isApprovedForResourcesOrOwner(_msgSender(), tokenId),
            "MultiResource: not owner or approved"
        );

        _beforeRejectResource(tokenId, index, resourceId);
        _pendingResources[tokenId].removeItemByValue(resourceId);
        delete _tokenResources[tokenId][resourceId];
        delete _resourceOverwrites[tokenId][resourceId];

        emit ResourceRejected(tokenId, resourceId);
        _afterRejectResource(tokenId, index, resourceId);
    }

    function rejectAllResources(uint256 tokenId, uint256 maxRejections) external virtual {
        require(
            _isApprovedForResourcesOrOwner(_msgSender(), tokenId),
            "MultiResource: not owner or approved"
        );

        uint256 len = _pendingResources[tokenId].length;
        if (len > maxRejections) revert ("Unexpected number of resources");

        _beforeRejectAllResources(tokenId);
        for (uint256 i; i < len; ) {
            uint64 resourceId = _pendingResources[tokenId][i];
            delete _resourceOverwrites[tokenId][resourceId];
            unchecked {
                ++i;
            }
        }
        delete (_pendingResources[tokenId]);

        emit ResourceRejected(tokenId, uint64(0));
        _afterRejectAllResources(tokenId);
    }

    function setPriority(uint256 tokenId, uint16[] memory priorities)
        external
        virtual
    {
        uint256 length = priorities.length;
        require(
            length == _activeResources[tokenId].length,
            "MultiResource: Bad priority list length"
        );
        require(
            _isApprovedForResourcesOrOwner(_msgSender(), tokenId),
            "MultiResource: not owner or approved"
        );

        _beforeSetPriority(tokenId, priorities);
        _activeResourcePriorities[tokenId] = priorities;

        emit ResourcePrioritySet(tokenId);
        _afterSetPriority(tokenId, priorities);
    }

    function getActiveResources(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _activeResources[tokenId];
    }

    function getPendingResources(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _pendingResources[tokenId];
    }

    function getActiveResourcePriorities(uint256 tokenId)
        public
        view
        virtual
        returns (uint16[] memory)
    {
        return _activeResourcePriorities[tokenId];
    }

    function getResourceOverwrites(uint256 tokenId, uint64 newResourceId)
        public
        view
        virtual
        returns (uint64)
    {
        return _resourceOverwrites[tokenId][newResourceId];
    }

    function getResourceMetadata(uint256 tokenId, uint64 resourceId)
        public
        view
        virtual
        returns (string memory)
    {
        if (!_tokenResources[tokenId][resourceId])
            revert("MultiResource: Token does not have resource");
        return _resources[resourceId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        return "";
    }

    // To be implemented with custom guards

    function _addResourceEntry(uint64 id, string memory metadataURI) internal {
        require(id != uint64(0), "RMRK: Write to zero");
        require(
            bytes(_resources[id]).length == 0,
            "RMRK: resource already exists"
        );

        _beforeAddResource(id, metadataURI);
        _resources[id] = metadataURI;

        emit ResourceSet(id);
        _afterAddResource(id, metadataURI);
    }

    function _addResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) internal {
        require(
            !_tokenResources[tokenId][resourceId],
            "MultiResource: Resource already exists on token"
        );

        require(
            bytes(_resources[resourceId]).length != 0,
            "MultiResource: Resource not found in storage"
        );

        require(
            _pendingResources[tokenId].length < 128,
            "MultiResource: Max pending resources reached"
        );

        _beforeAddResourceToToken(tokenId, resourceId, overwrites);
        _tokenResources[tokenId][resourceId] = true;
        _pendingResources[tokenId].push(resourceId);

        if (overwrites != uint64(0)) {
            _resourceOverwrites[tokenId][resourceId] = overwrites;
        }

        emit ResourceAddedToToken(tokenId, resourceId, overwrites);
        _afterAddResourceToToken(tokenId, resourceId, overwrites);
    }

    // HOOKS

    function _beforeAddResource(uint64 id, string memory metadataURI)
        internal
        virtual
    {}

    function _afterAddResource(uint64 id, string memory metadataURI)
        internal
        virtual
    {}

    function _beforeAddResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) internal virtual {}

    function _afterAddResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) internal virtual {}

    function _beforeAcceptResource(
        uint256 tokenId,
        uint256 index,
        uint256 resourceId
    ) internal virtual {}

    function _afterAcceptResource(
        uint256 tokenId,
        uint256 index,
        uint256 resourceId
    ) internal virtual {}

    function _beforeRejectResource(
        uint256 tokenId,
        uint256 index,
        uint256 resourceId
    ) internal virtual {}

    function _afterRejectResource(
        uint256 tokenId,
        uint256 index,
        uint256 resourceId
    ) internal virtual {}

    function _beforeRejectAllResources(uint256 tokenId) internal virtual {}

    function _afterRejectAllResources(uint256 tokenId) internal virtual {}

    function _beforeSetPriority(uint256 tokenId, uint16[] memory priorities)
        internal
        virtual
    {}

    function _afterSetPriority(uint256 tokenId, uint16[] memory priorities)
        internal
        virtual
    {}
}
