// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "../ERC5725.sol";

contract LinearVestingNFT is ERC5725 {
    using SafeERC20 for IERC20;

    struct VestDetails {
        IERC20 payoutToken; /// @dev payout token
        uint256 payout; /// @dev payout token remaining to be paid
        uint128 startTime; /// @dev when vesting starts
        uint128 endTime; /// @dev when vesting end
        uint128 cliff; /// @dev duration in seconds of the cliff in which tokens will be begin releasing
    }
    mapping(uint256 => VestDetails) public vestDetails; /// @dev maps the vesting data with tokenIds

    /// @dev tracker of current NFT id
    uint256 private _tokenIdTracker;

    /**
     * @dev See {IERC5725}.
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @notice Creates a new vesting NFT and mints it
     * @dev Token amount should be approved to be transferred by this contract before executing create
     * @param to The recipient of the NFT
     * @param amount The total assets to be locked over time
     * @param startTime When the vesting starts in epoch timestamp
     * @param duration The vesting duration in seconds
     * @param cliff The cliff duration in seconds
     * @param token The ERC20 token to vest over time
     */
    function create(
        address to,
        uint256 amount,
        uint128 startTime,
        uint128 duration,
        uint128 cliff,
        IERC20 token
    ) public virtual {
        require(startTime >= block.timestamp, "startTime cannot be on the past");
        require(to != address(0), "to cannot be address 0");
        require(cliff <= duration, "duration needs to be more than cliff");

        uint256 newTokenId = _tokenIdTracker;

        vestDetails[newTokenId] = VestDetails({
            payoutToken: token,
            payout: amount,
            startTime: startTime,
            endTime: startTime + duration,
            cliff: startTime + cliff
        });

        _tokenIdTracker++;
        _mint(to, newTokenId);
        IERC20(payoutToken(newTokenId)).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev See {IERC5725}.
     */
    function vestedPayoutAtTime(
        uint256 tokenId,
        uint256 timestamp
    ) public view override(ERC5725) validToken(tokenId) returns (uint256 payout) {
        if (timestamp < _cliff(tokenId)) {
            return 0;
        }
        if (timestamp > _endTime(tokenId)) {
            return _payout(tokenId);
        }
        return (_payout(tokenId) * (timestamp - _startTime(tokenId))) / (_endTime(tokenId) - _startTime(tokenId));
    }

    /**
     * @dev See {ERC5725}.
     */
    function _payoutToken(uint256 tokenId) internal view override returns (address) {
        return address(vestDetails[tokenId].payoutToken);
    }

    /**
     * @dev See {ERC5725}.
     */
    function _payout(uint256 tokenId) internal view override returns (uint256) {
        return vestDetails[tokenId].payout;
    }

    /**
     * @dev See {ERC5725}.
     */
    function _startTime(uint256 tokenId) internal view override returns (uint256) {
        return vestDetails[tokenId].startTime;
    }

    /**
     * @dev See {ERC5725}.
     */
    function _endTime(uint256 tokenId) internal view override returns (uint256) {
        return vestDetails[tokenId].endTime;
    }

    /**
     * @dev Internal function to get the cliff time of a given linear vesting NFT
     *
     * @param tokenId to check
     * @return uint256 the cliff time in seconds
     */
    function _cliff(uint256 tokenId) internal view returns (uint256) {
        return vestDetails[tokenId].cliff;
    }
}
