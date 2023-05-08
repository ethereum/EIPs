// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC5725.sol";

abstract contract ERC5725 is IERC5725, ERC721 {
    using SafeERC20 for IERC20;

    /// @dev mapping for claimed payouts
    mapping(uint256 => uint256) /*tokenId*/ /*claimed*/
        internal _payoutClaimed;

    /**
     * @notice Checks if the tokenId exists and its valid
     * @param tokenId The NFT token id
     */
    modifier validToken(uint256 tokenId) {
        require(_exists(tokenId), "ERC5725: invalid token ID");
        _;
    }

    /**
     * @dev See {IERC5725}.
     */
    function claim(uint256 tokenId) external override(IERC5725) validToken(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not owner of NFT");
        uint256 amountClaimed = claimablePayout(tokenId);
        require(amountClaimed > 0, "ERC5725: No pending payout");

        emit PayoutClaimed(tokenId, msg.sender, amountClaimed);

        _payoutClaimed[tokenId] += amountClaimed;
        IERC20(payoutToken(tokenId)).safeTransfer(msg.sender, amountClaimed);
    }

    /**
     * @dev See {IERC5725}.
     */
    function vestedPayout(uint256 tokenId) public view override(IERC5725) returns (uint256 payout) {
        return vestedPayoutAtTime(tokenId, block.timestamp);
    }

    /**
     * @dev See {IERC5725}.
     */
    function vestedPayoutAtTime(uint256 tokenId, uint256 timestamp)
        public
        view
        virtual
        override(IERC5725)
        returns (uint256 payout);

    /**
     * @dev See {IERC5725}.
     */
    function vestingPayout(uint256 tokenId)
        public
        view
        override(IERC5725)
        validToken(tokenId)
        returns (uint256 payout)
    {
        return _payout(tokenId) - vestedPayout(tokenId);
    }

    /**
     * @dev See {IERC5725}.
     */
    function claimablePayout(uint256 tokenId)
        public
        view
        override(IERC5725)
        validToken(tokenId)
        returns (uint256 payout)
    {
        return vestedPayout(tokenId) - _payoutClaimed[tokenId];
    }

    /**
     * @dev See {IERC5725}.
     */
    function claimedPayout(uint256 tokenId)
        public
        view
        override(IERC5725)
        validToken(tokenId)
        returns (uint256 payout)
    {
        return _payoutClaimed[tokenId];
    }

    /**
     * @dev See {IERC5725}.
     */
    function vestingPeriod(uint256 tokenId)
        public
        view
        override(IERC5725)
        validToken(tokenId)
        returns (uint256 vestingStart, uint256 vestingEnd)
    {
        return (_startTime(tokenId), _endTime(tokenId));
    }

    /**
     * @dev See {IERC5725}.
     */
    function payoutToken(uint256 tokenId) public view override(IERC5725) validToken(tokenId) returns (address token) {
        return _payoutToken(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * IERC5725 interfaceId = 0x7c89676d
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool supported)
    {
        return interfaceId == type(IERC5725).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to get the payout token of a given vesting NFT
     *
     * @param tokenId on which to check the payout token address
     * @return address payout token address
     */
    function _payoutToken(uint256 tokenId) internal view virtual returns (address);

    /**
     * @dev Internal function to get the total payout of a given vesting NFT.
     * @dev This is the total that will be paid out to the NFT owner, including historical tokens.
     *
     * @param tokenId to check
     * @return uint256 the total payout of a given vesting NFT
     */
    function _payout(uint256 tokenId) internal view virtual returns (uint256);

    /**
     * @dev Internal function to get the start time of a given vesting NFT
     *
     * @param tokenId to check
     * @return uint256 the start time in epoch timestamp
     */
    function _startTime(uint256 tokenId) internal view virtual returns (uint256);

    /**
     * @dev Internal function to get the end time of a given vesting NFT
     *
     * @param tokenId to check
     * @return uint256 the end time in epoch timestamp
     */
    function _endTime(uint256 tokenId) internal view virtual returns (uint256);
}
