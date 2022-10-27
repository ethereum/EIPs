//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC5727.sol";
import "./interfaces/IERC5727Expirable.sol";

abstract contract ERC5727Expirable is IERC5727Expirable, ERC5727 {
    mapping(uint256 => uint256) private _expiryDate;

    function expiryDate(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 date = _expiryDate[tokenId];
        require(date != 0, "ERC5727Expirable: No expiry date set");
        return date;
    }

    function isExpired(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        uint256 date = _expiryDate[tokenId];
        require(date != 0, "ERC5727Expirable: No expiry date set");
        return date < block.timestamp;
    }

    function _setExpiryDate(uint256 tokenId, uint256 date)
        internal
        virtual
        onlyOwner
    {
        require(
            date > block.timestamp,
            "ERC5727Expirable: Expiry date cannot be in the past"
        );
        require(
            date > _expiryDate[tokenId],
            "ERC5727Expirable: Expiry date can only be extended"
        );
        _expiryDate[tokenId] = date;
    }

    function _setBatchExpiryDates(
        uint256[] memory tokenIds,
        uint256[] memory dates
    ) internal {
        require(
            tokenIds.length == dates.length,
            "ERC5727Expirable: Ids and token URIs length mismatch"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setExpiryDate(tokenIds[i], dates[i]);
        }
    }

    function _setBatchExpiryDates(uint256[] memory tokenIds, uint256 date)
        internal
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setExpiryDate(tokenIds[i], date);
        }
    }

    function setExpiryDate(uint256 tokenId, uint256 date) public onlyOwner {
        _setExpiryDate(tokenId, date);
    }

    function setBatchExpiryDates(
        uint256[] memory tokenIds,
        uint256[] memory dates
    ) public onlyOwner {
        _setBatchExpiryDates(tokenIds, dates);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC5727)
        returns (bool)
    {
        return
            interfaceId == type(IERC5727Expirable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
