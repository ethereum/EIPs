// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./ERC5007.sol";
import "./IERC5007Composable.sol";

abstract contract ERC5007Composable is ERC5007, IERC5007Composable {
    mapping(uint256 => uint256) internal _rootIdMapping;

    /**
     * @dev See {IERC5007Composable-rootTokenId}.
     */
    function rootTokenId(uint256 tokenId)
        public
        view
        override
        returns (uint256 rootId)
    {
        require(_exists(tokenId), "ERC5007: invalid tokenId");
        rootId = _rootIdMapping[tokenId];
    }

    /**
     * @dev See {IERC5007Composable-split}.
     */
    function split(
        uint256 oldTokenId,
        uint256 newTokenId,
        address newTokenOwner,
        uint64 newTokenStartTime
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), oldTokenId),
            "ERC5007: caller is not owner nor approved"
        );

        uint64 oldTokenStartTime = _timeNftMapping[oldTokenId].startTime;
        uint64 oldTokenEndTime = _timeNftMapping[oldTokenId].endTime;
        require(
            oldTokenStartTime < newTokenStartTime &&
                newTokenStartTime <= oldTokenEndTime,
            "ERC5007: invalid newTokenStartTime"
        );

        _timeNftMapping[oldTokenId].endTime = newTokenStartTime - 1;
        uint64 newTokenEndTime = oldTokenEndTime;

        _mintTimeNftWithRootId(
            newTokenOwner,
            newTokenId,
            _rootIdMapping[oldTokenId],
            newTokenStartTime,
            newTokenEndTime
        );
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
            _rootIdMapping[firstTokenId] == _rootIdMapping[secondTokenId] &&
                firstToken.startTime <= firstToken.endTime &&
                (firstToken.endTime + 1) == secondToken.startTime &&
                secondToken.startTime <= secondToken.endTime,
            "ERC5007: invalid input data"
        );

        
        _mintTimeNftWithRootId(
            newTokenOwner,
            newTokenId,
            _rootIdMapping[firstTokenId],
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
    function _mintTimeNftWithRootId(
        address to_,
        uint256 tokenId_,
        uint256 rootId_,
        uint64 startTime_,
        uint64 endTime_
    ) internal virtual {
        require(_exists(rootId_), "ERC5007: invalid rootId_");
        super._mintTimeNft(to_, tokenId_, startTime_, endTime_);
        _rootIdMapping[tokenId_] = rootId_;
    }

    /**
     * @dev  mint a new common time NFT
     *
     * Requirements:
     *
     * - `to_` cannot be the zero address.
     * - `tokenId_` must not exist.
     * - `endTime_` should be equal or greater than `startTime_`
     */
    function _mintTimeNft(
        address to_,
        uint256 tokenId_,
        uint64 startTime_,
        uint64 endTime_
    ) internal virtual override {
        super._mintTimeNft(to_, tokenId_, startTime_, endTime_);

        _rootIdMapping[tokenId_] = tokenId_;
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
        delete _rootIdMapping[tokenId];
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
