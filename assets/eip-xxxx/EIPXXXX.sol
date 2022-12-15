pragma solidity ^0.8.0;

abstract contract ERCXXXX is ERC721, IERCXXXXX {
    mapping(uint256 => uint256) private _parentOf;
    mapping(uint256 => uint256[]) private _childrenOf;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERCXXXX).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function parentOf(
        uint256 tokenId
    ) public view virtual override returns (uint256 parentId) {
        _requireMinted(tokenId);
        parentId = _parentOf[tokenId];
    }

    function childrenOf(
        uint256 tokenId
    ) public view virtual override returns (uint256[] memory childrenIds) {
        _requireMinted(tokenId);
        childrenIds = _childrenOf[tokenId];
    }

    function isRoot(
        uint256 tokenId
    ) public view virtual override returns (bool) {
        _requireMinted(tokenId);
        return _parentOf[tokenId] == 0;
    }

    function isLeaf(
        uint256 tokenId
    ) public view virtual override returns (bool) {
        _requireMinted(tokenId);
        return _childrenOf[tokenId].length == 0;
    }

    function _safeBatchMintWithParent(
        address to,
        uint256 parentId,
        uint256[] memory tokenIds
    ) internal virtual {
        _safeBatchMintWithParent(
            to,
            parentId,
            tokenIds,
            new bytes[](tokenIds.length)
        );
    }

    function _safeBatchMintWithParent(
        address to,
        uint256 parentId,
        uint256[] memory tokenIds,
        bytes[] memory datas
    ) internal virtual {
        require(
            tokenIds.length == datas.length,
            "ERCXXXX: tokenIds.length != datas.length"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMintWithParent(to, parentId, tokenIds[i], datas[i]);
        }
    }

    function _safeMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId
    ) internal virtual {
        _safeMintWithParent(to, parentId, tokenId, "");
    }

    function _safeMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        require(tokenId > 0, "ERCXXXX: tokenId is zero");
        if (parentId != 0)
            require(_exists(parentId), "ERCXXXX: parentId doesn't exists");

        _beforeMintWithParent(to, parentId, tokenId);

        _parentOf[tokenId] = parentId;
        _childrenOf[parentId].push(tokenId);

        _safeMint(to, tokenId, data);
        emit Minted(msg.sender, to, parentId, tokenId);

        _afterMintWithParent(to, parentId, tokenId);
    }

    function _beforeMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId
    ) internal virtual {}

    function _afterMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId
    ) internal virtual {}
}
