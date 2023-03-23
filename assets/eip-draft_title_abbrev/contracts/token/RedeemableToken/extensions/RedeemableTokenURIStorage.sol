// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../RedeemableToken.sol";
import "../../../utils/introspection/ERC165.sol";
import "./IRedeemableTokenURIStorage.sol";

/**
 * @dev See {IRedeemableTokenURIStorage}.
 */
abstract contract RedeemableTokenURIStorage is ERC165, IRedeemableTokenURIStorage, RedeemableToken {
    // Optional mapping for token URIs.
    mapping(uint256 => string) private _tokenURIs;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RedeemableToken, ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IRedeemableTokenURIStorage).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRedeemableTokenURIStorage-tokenURI}.
     */
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        string memory _tokenURI = _tokenURIs[id];

        // Returns the token URI if there is a specific one set that overrides the base URI
        if (_isTokenURISet(id)) {
            return _tokenURI;
        }

        string memory base = baseURI();

        return base;
    }

    /**
     * @dev Sets `_tokenURI` as the token URI for the tokens of type `id`.
     */
    function _setTokenURI(uint256 id, string memory _tokenURI) internal virtual {
        _tokenURIs[id] = _tokenURI;

        emit URI(id, _tokenURI);
    }

    /**
     * @dev [Batched] version of {_setTokenURI}.
     */
    function _setBatchTokenURI(uint256[] memory ids, string[] memory tokenURIs) internal {
        uint256 idsLength = ids.length;
        require(idsLength == tokenURIs.length, "ERC1238Storage: ids and token URIs length mismatch");

        for (uint256 i = 0; i < idsLength; i++) {
            _setTokenURI(ids[i], tokenURIs[i]);
        }
    }

    /**
     * @dev Deletes the tokenURI for the tokens of type `id`.
     *
     * Requirements:
     *  - A token URI must be set.
     *
     *  Possible improvement:
     *  - The URI can only be deleted if all tokens of type `id` have been burned.
     */
    function _deleteTokenURI(uint256 id) internal virtual {
        if (_isTokenURISet(id)) {
            delete _tokenURIs[id];
        }
    }

    /**
     * @dev Returns whether a tokenURI is set or not for a specific `id` token type.
     */
    function _isTokenURISet(uint256 id) private view returns (bool) {
        return bytes(_tokenURIs[id]).length > 0;
    }
}
