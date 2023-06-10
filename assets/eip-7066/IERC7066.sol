// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Lockable Extension for ERC721
/// @dev Interface for the Lockable extension
/// @author StreamNFT 

interface IERC7066{
    
    /**
     * @dev Emitted when locker is set for tokenId
     */
    event SetLocker (uint256 indexed tokenId, address _locker);

    /**
     * @dev Emitted when locker is removed for tokenId
     */
    event RemoveLocker (uint256 indexed tokenId);

    /**
     * @dev Emitted when tokenId is locked
     */
    event Lock (uint256 indexed tokenId);

    /**
     * @dev Emitted when tokenId is unlocked
     */
    event Unlock (uint256 indexed tokenId);

    /**
     * @dev Gives the `_locker` address permission to lock if msg.sender is owner
     */
    function setLocker(uint256 tokenId, address _locker) external;

    /**
     * @dev Purge the permission to lock if tokenId is `unlocked` and msg.sender is owner
     */
    function removeLocker(uint256 tokenId) external;

   /**
     * @dev Lock the tokenId if msg.sender is locker or approved
     */
    function lock(uint256 tokenId) external;

    /**
     * @dev Unlocks the tokenId if msg.sender is locker or approved
     */
    function unlock(uint256 tokenId) external;

    /**
     * @dev Tranfer and lock the token if the msg.sender is locker or approved
     */
    function transferAndLock(uint256 tokenId, address from, address to, address _locker) external;

    /**
     * @dev Returns the wallet, that is stated as unlocking wallet for the tokenId.
     * If address(0) returned, that means token is not locked. Any other result means token is locked.
     */
    function lockerOf(uint256 tokenId) external view returns (address);

}