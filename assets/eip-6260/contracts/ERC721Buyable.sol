// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Buyable.sol";

/**
 * @title Onchain Buyable token
 * @author Aubay
 * @notice Put a token to sale onchain at the desired price.
 * @dev Make it possible to put a token to sale onchain and execute the transfer function
 * only if requirements are met without having to approve the token to any third party.
 */
abstract contract ERC721Buyable is ERC721, IERC721Buyable, Ownable {
    // Royalties to owner are to set in % (basis points per default but updatable inside `_royaltyDenominator()`, therefore 100% would be 10000)
    // Can only be reduced to avoid malicious manipulation
    uint256 internal _updatedRoyalty;
    bool private _firstRoyaltyUpdate = false;

    // Mapping from token ID to the desired selling price
    mapping(uint256 => uint256) public prices;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Buyable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Buyable-setPrice}.
     */
    function setPrice(uint256 _tokenId, uint256 _price)
        external
        virtual
        override
        onlyTokenOwner(_tokenId)
    {
        prices[_tokenId] = _price;
        emit UpdatePrice(_tokenId, _price);
    }

    /**
     * @dev See {IERC721Buyable-removeTokenSale}.
     */
    function removeTokenSale(uint256 _tokenId)
        external
        virtual
        override
        onlyTokenOwner(_tokenId)
    {
        delete prices[_tokenId];
        emit RemoveFromSale(_tokenId);
    }

    /**
     * @dev See {IERC721Buyable-buyToken}.
     */
    function buyToken(uint256 _tokenId) public payable virtual override {
        require(prices[_tokenId] != 0, "Token is not for sale");
        require(
            msg.value >= prices[_tokenId],
            "Insufficient funds to purchase this token"
        );

        address seller = ownerOf(_tokenId);
        address buyer = msg.sender;

        uint256 royalties = (msg.value * _royalty()) / _royaltyDenominator();

        emit Purchase(buyer, seller, msg.value);

        _safeTransfer(seller, buyer, _tokenId, "");

        if (seller == owner() || royalties == 0) {
            (bool success, ) = payable(seller).call{value: msg.value}("");
            require(success, "Something happened when paying the token owner");
        } else {
            _payRoyalties(royalties);
            (bool success, ) = payable(seller).call{
                value: msg.value - royalties
            }("");
            require(success, "Something happened when paying the token owner");
        }
    }

    /**
     * @dev The denominator to interpret the rate of royalties, defaults to 10000 so rate are expressed in basis points.
     * Base 10000, so 10000 = 100%, 0 = 0% , 2000 = 20%
     * May be customized with an override.
     */
    function _royaltyDenominator() internal pure virtual returns (uint256) {
        return 10000;
    }

    /**
     * @dev Royalty percentage per default at the contract creation expressed in basis points (per default between 0 and `_royaltyDenominator()`).
     * May be customized with an override.
     */
    function _defaultRoyalty() internal pure virtual returns (uint256) {
        return 1000;
    }

    /**
     * @dev Return the current royalty : default royalty if not updated, otherwise return the updated one.
     * @return royalty uint within the range of `_royaltyDenominator` associated with the token.
     */
    function _royalty() internal view virtual returns (uint256) {
        return _firstRoyaltyUpdate ? _updatedRoyalty : _defaultRoyalty();
    }

    /**
     * @dev See {IERC721Buyable-royaltyInfo}.
     */
    function royaltyInfo()
        external
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return (_royalty(), _royaltyDenominator());
    }

    /**
     * @dev See {IERC721Buyable-setRoyalty}.
     */
    function setRoyalty(uint256 _newRoyalty)
        external
        virtual
        override
        onlyOwner
    {
        require(
            _newRoyalty <= _royaltyDenominator(),
            "Royalty must be between 0 and _royaltyDenominator"
        );
        require(
            _newRoyalty < _royalty(),
            "New royalty must be lower than previous one"
        );

        _updatedRoyalty = _newRoyalty;

        if (!_firstRoyaltyUpdate) {
            _firstRoyaltyUpdate = true;
        }

        emit UpdateRoyalty(_newRoyalty);
    }

    /**
     * @dev Send to `_owner` of the contract a specific amount of ether as royalties.
     * @param _amount uint for the royalty payment.
     */
    function _payRoyalties(uint256 _amount) internal virtual {
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Something happened when paying the royalties");
    }

    /**
     * @dev Transfer `tokenId`. See {ERC721-_transfer}.
     * Remove the token with the ID `tokenId` from the sale.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        delete prices[tokenId];
        ERC721._transfer(from, to, tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     * Remove the token with the ID `tokenId` from the sale.
     */
    function _burn(uint256 tokenId) internal virtual override {
        delete prices[tokenId];
        ERC721._burn(tokenId);
    }

    /**
     * @dev Requirements:
     *
     * - Owner of `_tokenId` must be the caller
     *
     * @param _tokenId uint representing the token ID number.
     */
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You don't own this token"); // also implies that it exists
        _;
    }
}
