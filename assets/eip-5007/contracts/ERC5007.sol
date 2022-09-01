// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5007.sol";

abstract contract ERC5007 is ERC721, IERC5007 {
    struct TimeNftInfo {
        uint64 startTime;
        uint64 endTime;
    }

    mapping(uint256 => TimeNftInfo) internal _timeNftMapping;

    /**
     * @dev See {IERC5007-startTime}.
     */
    function startTime(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint64) {
        require(_exists(tokenId), "ERC5007: invalid tokenId");
        return _timeNftMapping[tokenId].startTime;
    }

    /**
     * @dev See {IERC5007-endTime}.
     */
    function endTime(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint64) {
        require(_exists(tokenId), "ERC5007: invalid tokenId");
        return _timeNftMapping[tokenId].endTime;
    }

    /**
     * @dev mint a new time NFT.
     *
     * Requirements:
     *
     * - `tokenId_` must not exist.
     * - `to_` cannot be the zero address.
     * - `endTime_` should be equal or greater than `startTime_`
     */
    function _mintTimeNft(
        address to_,
        uint256 tokenId_,
        uint64 startTime_,
        uint64 endTime_
    ) internal virtual {
        require(endTime_ >= startTime_, 'ERC5007: invalid endTime');
        _mint(to_, tokenId_);
        TimeNftInfo storage info = _timeNftMapping[tokenId_];
        info.startTime = startTime_;
        info.endTime = endTime_;
    }


    /**
     * @dev Destroys `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _timeNftMapping[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool) {
        return
            interfaceId == type(IERC5007).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
