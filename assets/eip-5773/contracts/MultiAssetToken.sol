// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.15;

import "./IERC5773.sol";
import "./library/MultiAssetLib.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MultiAssetToken is Context, IERC721, IERC5773 {
    using MultiAssetLib for uint256;
    using MultiAssetLib for uint64[];
    using MultiAssetLib for uint128[];
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

    // Mapping from token ID to approved address for assets
    mapping(uint256 => address) internal _tokenApprovalsForAssets;

    // Mapping from owner to operator approvals for assets
    mapping(address => mapping(address => bool))
        internal _operatorApprovalsForAssets;

    //mapping of uint64 Ids to asset object
    mapping(uint64 => string) internal _assets;

    //mapping of tokenId to new asset, to asset to be replaced
    mapping(uint256 => mapping(uint64 => uint64)) private _assetReplacements;

    //mapping of tokenId to all assets
    mapping(uint256 => uint64[]) internal _activeAssets;

    //mapping of tokenId to an array of asset priorities
    mapping(uint256 => uint64[]) internal _activeAssetPriorities;

    //Double mapping of tokenId to active assets
    mapping(uint256 => mapping(uint64 => bool)) private _tokenAssets;

    //mapping of tokenId to all assets by priority
    mapping(uint256 => uint64[]) internal _pendingAssets;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    ////////////////////////////////////////
    //        ERC-721 COMPLIANCE
    ////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
            interfaceId == type(IERC5773).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
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
        require(to != owner, "MultiAsset: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "MultiAsset: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function approveForAssets(address to, uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "MultiAsset: approval to current owner");
        require(
            _msgSender() == owner ||
                isApprovedForAllForAssets(owner, _msgSender()),
            "MultiAsset: approve caller is not owner nor approved for all"
        );
        _approveForAssets(to, tokenId);
    }

    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        require(
            _exists(tokenId),
            "MultiAsset: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function getApprovedForAssets(
        uint256 tokenId
    ) public view virtual returns (address) {
        require(
            _exists(tokenId),
            "MultiAsset: approved query for nonexistent token"
        );
        return _tokenApprovalsForAssets[tokenId];
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAllForAssets(_msgSender(), operator, approved);
    }

    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovalsForAssets[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "MultiAsset: transfer caller is not owner nor approved"
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
            "MultiAsset: transfer caller is not owner nor approved"
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
            "MultiAsset: transfer to non ERC721 Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        require(
            _exists(tokenId),
            "MultiAsset: approved query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _isApprovedForAssetsOrOwner(
        address user,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        require(
            _exists(tokenId),
            "MultiAsset: approved query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAllForAssets(owner, user) ||
            getApprovedForAssets(tokenId) == user);
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
            "MultiAsset: transfer to non ERC721 Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "MultiAsset: mint to the zero address");
        require(!_exists(tokenId), "MultiAsset: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        // WARNING: If you intend to allow the reminting of a burned token, you
        // might want to clean the assets for the token, that is:
        // _pendingAssets, _activeAssets, _assetReplacements
        // _activeAssetPriorities and _tokenAssets.
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);

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
            "MultiAsset: transfer from incorrect owner"
        );
        require(to != address(0), "MultiAsset: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);

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

    function _approveForAssets(address to, uint256 tokenId) internal virtual {
        _tokenApprovalsForAssets[tokenId] = to;
        emit ApprovalForAssets(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "MultiAsset: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _setApprovalForAllForAssets(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "MultiAsset: approve to caller");
        _operatorApprovalsForAssets[owner][operator] = approved;
        emit ApprovalForAllForAssets(owner, operator, approved);
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
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "MultiAsset: transfer to non ERC721 Receiver implementer"
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
    //                ASSETS
    ////////////////////////////////////////

    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external virtual {
        require(
            index < _pendingAssets[tokenId].length,
            "MultiAsset: index out of bounds"
        );
        require(
            _isApprovedForAssetsOrOwner(_msgSender(), tokenId),
            "MultiAsset: not owner or approved"
        );
        require(
            assetId == _pendingAssets[tokenId][index],
            "MultiAsset: Unexpected asset"
        );

        _beforeAcceptAsset(tokenId, index, assetId);
        uint64 replacesId = _assetReplacements[tokenId][assetId];
        uint256 replaceIndex;
        bool replacefound;
        if (replacesId != uint64(0))
            (replaceIndex, replacefound) = _activeAssets[tokenId].indexOf(
                replacesId
            );

        if (replacefound) {
            // We don't want to remove and then push a new asset.
            // This way we also keep the priority of the original resource
            _activeAssets[tokenId][replaceIndex] = assetId;
            delete _tokenAssets[tokenId][replacesId];
        } else {
            // We use the current size as next priority, by default priorities would be [0,1,2...]
            _activeAssetPriorities[tokenId].push(
                uint64(_activeAssets[tokenId].length)
            );
            _activeAssets[tokenId].push(assetId);
            replacesId = uint64(0);
        }
        _pendingAssets[tokenId].removeItemByIndex(index);
        delete _assetReplacements[tokenId][assetId];

        emit AssetAccepted(tokenId, assetId, replacesId);
        _afterAcceptAsset(tokenId, index, assetId);
    }

    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external virtual {
        require(
            index < _pendingAssets[tokenId].length,
            "MultiAsset: index out of bounds"
        );
        require(
            _pendingAssets[tokenId].length > index,
            "MultiAsset: Pending asset index out of range"
        );
        require(
            _isApprovedForAssetsOrOwner(_msgSender(), tokenId),
            "MultiAsset: not owner or approved"
        );

        _beforeRejectAsset(tokenId, index, assetId);
        _pendingAssets[tokenId].removeItemByIndex(index);
        delete _tokenAssets[tokenId][assetId];
        delete _assetReplacements[tokenId][assetId];

        emit AssetRejected(tokenId, assetId);
        _afterRejectAsset(tokenId, index, assetId);
    }

    function rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) external virtual {
        require(
            _isApprovedForAssetsOrOwner(_msgSender(), tokenId),
            "MultiAsset: not owner or approved"
        );

        uint256 len = _pendingAssets[tokenId].length;
        if (len > maxRejections) revert("Unexpected number of assets");

        _beforeRejectAllAssets(tokenId);
        for (uint256 i; i < len; ) {
            uint64 assetId = _pendingAssets[tokenId][i];
            delete _assetReplacements[tokenId][assetId];
            unchecked {
                ++i;
            }
        }
        delete (_pendingAssets[tokenId]);

        emit AssetRejected(tokenId, uint64(0));
        _afterRejectAllAssets(tokenId);
    }

    function setPriority(
        uint256 tokenId,
        uint64[] memory priorities
    ) external virtual {
        uint256 length = priorities.length;
        require(
            length == _activeAssets[tokenId].length,
            "MultiAsset: Bad priority list length"
        );
        require(
            _isApprovedForAssetsOrOwner(_msgSender(), tokenId),
            "MultiAsset: not owner or approved"
        );

        _beforeSetPriority(tokenId, priorities);
        _activeAssetPriorities[tokenId] = priorities;

        emit AssetPrioritySet(tokenId);
        _afterSetPriority(tokenId, priorities);
    }

    function getActiveAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssets[tokenId];
    }

    function getPendingAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _pendingAssets[tokenId];
    }

    function getActiveAssetPriorities(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssetPriorities[tokenId];
    }

    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) public view virtual returns (uint64) {
        return _assetReplacements[tokenId][newAssetId];
    }

    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) public view virtual returns (string memory) {
        if (!_tokenAssets[tokenId][assetId])
            revert("MultiAsset: Token does not have asset");
        return _assets[assetId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        return "";
    }

    // To be implemented with custom guards

    function _addAssetEntry(uint64 id, string memory metadataURI) internal {
        require(id != uint64(0), "RMRK: Write to zero");
        require(bytes(_assets[id]).length == 0, "RMRK: asset already exists");

        _beforeAddAsset(id, metadataURI);
        _assets[id] = metadataURI;

        emit AssetSet(id);
        _afterAddAsset(id, metadataURI);
    }

    function _addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal {
        require(
            !_tokenAssets[tokenId][assetId],
            "MultiAsset: Asset already exists on token"
        );

        require(
            bytes(_assets[assetId]).length != 0,
            "MultiAsset: Asset not found in storage"
        );

        require(
            _pendingAssets[tokenId].length < 128,
            "MultiAsset: Max pending assets reached"
        );

        _beforeAddAssetToToken(tokenId, assetId, replacesAssetWithId);
        _tokenAssets[tokenId][assetId] = true;
        _pendingAssets[tokenId].push(assetId);

        if (replacesAssetWithId != uint64(0)) {
            _assetReplacements[tokenId][assetId] = replacesAssetWithId;
        }

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        emit AssetAddedToTokens(tokenIds, assetId, replacesAssetWithId);
        _afterAddAssetToToken(tokenId, assetId, replacesAssetWithId);
    }

    // HOOKS

    function _beforeAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    function _afterAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    function _beforeAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    function _beforeAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _afterAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _beforeRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _afterRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _beforeRejectAllAssets(uint256 tokenId) internal virtual {}

    function _afterRejectAllAssets(uint256 tokenId) internal virtual {}

    function _beforeSetPriority(
        uint256 tokenId,
        uint64[] memory priorities
    ) internal virtual {}

    function _afterSetPriority(
        uint256 tokenId,
        uint64[] memory priorities
    ) internal virtual {}
}
