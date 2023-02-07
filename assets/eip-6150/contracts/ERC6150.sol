// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./interfaces/IERC6150.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC6150 is ERC721, IERC6150 {
    mapping(uint256 => uint256) private _parentOf;
    mapping(uint256 => uint256[]) private _childrenOf;
    mapping(uint256 => uint256) private _indexInChildrenArray;

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
            interfaceId == type(IERC6150).interfaceId ||
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
        if (tokenId > 0) {
            _requireMinted(tokenId);
        }
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

    function _getIndexInChildrenArray(
        uint256 tokenId
    ) internal view virtual returns (uint256) {
        return _indexInChildrenArray[tokenId];
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
            "ERC6150: tokenIds.length != datas.length"
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
        require(tokenId > 0, "ERC6150: tokenId is zero");
        if (parentId != 0)
            require(_exists(parentId), "ERC6150: parentId doesn't exist");

        _beforeMintWithParent(to, parentId, tokenId);

        _parentOf[tokenId] = parentId;
        _indexInChildrenArray[tokenId] = _childrenOf[parentId].length;
        _childrenOf[parentId].push(tokenId);

        _safeMint(to, tokenId, data);
        emit Minted(msg.sender, to, parentId, tokenId);

        _afterMintWithParent(to, parentId, tokenId);
    }

    function _safeBurn(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "ERC6150: tokenId doesn't exist");
        require(isLeaf(tokenId), "ERC6150: tokenId is not a leaf");

        uint256 parent = _parentOf[tokenId];
        uint256 lastTokenIndex = _childrenOf[parent].length - 1;
        uint256 targetTokenIndex = _indexInChildrenArray[tokenId];
        uint256 lastIndexToken = _childrenOf[parent][lastTokenIndex];
        if (lastTokenIndex > targetTokenIndex) {
            _childrenOf[parent][targetTokenIndex] = lastIndexToken;
            _indexInChildrenArray[lastIndexToken] = targetTokenIndex;
        }

        delete _childrenOf[parent][lastIndexToken];
        delete _indexInChildrenArray[tokenId];
        delete _parentOf[tokenId];

        _burn(tokenId);
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
