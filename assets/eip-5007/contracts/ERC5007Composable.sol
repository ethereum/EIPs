// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./ERC5007.sol";
import "./IERC5007Composable.sol";

abstract contract ERC5007Composable is ERC5007, IERC5007Composable {
    mapping(uint256 => uint256) internal _assetIdMapping;

    /**
     * @dev See {IERC5007Composable-assetId}.
     */
    function assetId(uint256 tokenId) public view returns (uint256)
    {
        require(_exists(tokenId), "ERC5007: invalid tokenId");
        return _assetIdMapping[tokenId];
    }

    /**
     * @dev See {IERC5007Composable-split}.
     */
    function split(
        uint256 oldTokenId,
        uint256 newToken1Id,
        address newToken1Owner,
        uint256 newToken2Id,
        address newToken2Owner,        
        uint64 splitTime
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), oldTokenId), "ERC5007: caller is not owner nor approved");

        uint64 oldTokenStartTime = _timeNftMapping[oldTokenId].startTime;
        uint64 oldTokenEndTime = _timeNftMapping[oldTokenId].endTime;
        require(
            oldTokenStartTime <= splitTime &&
                splitTime < oldTokenEndTime,
            "ERC5007: invalid newTokenStartTime"
        );

        uint256 assetId_ = _assetIdMapping[oldTokenId];
        _mintTimeNftWithAssetId(
            newToken1Owner,
            newToken1Id,
            assetId_,
            oldTokenStartTime,
            splitTime
        );

        _mintTimeNftWithAssetId(
            newToken2Owner,
            newToken2Id,
            assetId_,
            splitTime + 1,
            oldTokenEndTime
        );

         _burn(oldTokenId);
    }

    /**
     * @dev See {IERC5007Composable-merge}.
     */
    function merge(
        uint256 firstTokenId,
        uint256 secondTokenId,
        address newTokenOwner,
        uint256 newTokenId
    ) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), firstTokenId) &&
                _isApprovedOrOwner(_msgSender(), secondTokenId),
            "ERC5007: caller is not owner nor approved"
        );

        TimeNftInfo memory firstToken = _timeNftMapping[firstTokenId];
        TimeNftInfo memory secondToken = _timeNftMapping[secondTokenId];
        require(
            _assetIdMapping[firstTokenId] == _assetIdMapping[secondTokenId] &&
                firstToken.startTime <= firstToken.endTime &&
                (firstToken.endTime + 1) == secondToken.startTime &&
                secondToken.startTime <= secondToken.endTime,
            "ERC5007: invalid data"
        );
        
        _mintTimeNftWithAssetId(
            newTokenOwner,
            newTokenId,
            _assetIdMapping[firstTokenId],
            firstToken.startTime,
            secondToken.endTime
        );

        _burn(firstTokenId);
        _burn(secondTokenId);
    }

    /**
     * @dev  mint a new common time NFT
     *
     * Requirements:
     *
     * - `to_` cannot be the zero address.
     * - `tokenId_` must not exist.
     * - `rootId_` must exist.
     * - `endTime_` should be equal or greater than `startTime_`
     */
    function _mintTimeNftWithAssetId(
        address to_,
        uint256 tokenId_,
        uint256 assetId_,
        uint64 startTime_,
        uint64 endTime_
    ) internal virtual {
        super._mintTimeNft(to_, tokenId_, startTime_, endTime_);
        _assetIdMapping[tokenId_] = assetId_;
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
        delete _assetIdMapping[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC5007Composable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
