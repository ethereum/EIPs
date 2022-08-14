// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./IERC721Bound.sol";

interface IPreimage {
    /**
     * @dev Returns if the `tokenId` token of preimage is locked. [MUST]
     */
    function isLocked(uint256 tokenId) external view returns (bool);

    /**
     * @dev Opensea-contract-level metadata. [OPTIONAL]
     * Details: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() external view returns (string memory);
}

/**
 * @dev This implements an optional extension of {ERC5058} defined in the EIP.
 * The bound token is exactly the same as the locked token metadata, the bound token can be transferred,
 * but it is guaranteed that only one bound token and the original token can be traded in the market at
 * the same time. When the original token lock expires, the bound token must be destroyed.
 */
contract ERC721Bound is ERC721Enumerable, IERC2981, IERC721Bound {
    address private _preimage;

    string private _contractURI;

    string private _baseTokenURI;

    constructor(
        address preimage_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        _preimage = preimage_;
    }

    /**
     * @dev Throws if called by any account other than the preimage.
     */
    modifier onlyPreimage() {
        require(_preimage == msg.sender, "ERC721Bound: caller is not the preimage");
        _;
    }

    function preimage() public view virtual override returns (address) {
        return _preimage;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return super.tokenURI(tokenId);
        }

        return IERC721Metadata(_preimage).tokenURI(tokenId);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        return IERC2981(_preimage).royaltyInfo(tokenId, salePrice);
    }

    /**
     * @dev See {IPreimage-contractURI}.
     */
    function contractURI() public view returns (string memory) {
        if (bytes(_contractURI).length > 0) {
            return _contractURI;
        }

        if (IERC165(_preimage).supportsInterface(IPreimage.contractURI.selector)) {
            return IPreimage(_preimage).contractURI();
        }

        return "";
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory baseTokenURI) public virtual override onlyPreimage {
        _baseTokenURI = baseTokenURI;
    }

    // @dev Sets the contract URI.
    function setContractURI(string memory uri) public virtual override onlyPreimage {
        _contractURI = uri;
    }

    /**
     * @dev Mints bound `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * caller must be preimage contract.
     *
     * Emits a {Transfer} event.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyPreimage {
        _safeMint(to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * caller must be preimage contract.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public virtual override onlyPreimage {
        _burn(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            require(IPreimage(_preimage).isLocked(tokenId), "ERC721Bound: token mint while preimage not locked");
        }
        if (to == address(0)) {
            require(!IPreimage(_preimage).isLocked(tokenId), "ERC721Bound: token burn while preimage locked");
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Bound).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == IPreimage.contractURI.selector ||
            super.supportsInterface(interfaceId);
    }
}
