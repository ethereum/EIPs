// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Lockable Extension for ERC721
/// @dev Interface for the Lockable extension
/// @author StreamNFT 

interface IERC7066{
    
    /**
     * @dev Emitted when locker is set for token `id` 
     */
    event SetLocker (uint256 indexed id, address _locker);

    /**
     * @dev Emitted when locker is removed for token `id` 
     */
    event RemoveLocker (uint256 indexed id);

    /**
     * @dev Emitted when `id` token is locked
     */
    event Lock (uint256 indexed id);

    /**
     * @dev Emitted when `id` token is unlocked
     */
    event Unlock (uint256 indexed id);

    /**
     * @dev Gives the `_locker` address permission to lock if msg.sender is owner
     */
    function setLocker(uint256 id, address _locker) external;

    /**
     * @dev Purge the permission to lock if `id` is `unlocked` and msg.sender is owner
     */
    function removeLocker(uint256 id) external;

   /**
     * @dev Lock the token `id` if msg.sender is locker or approved
     */
    function lock(uint256 id) external;

    /**
     * @dev Unlocks the token `id` if msg.sender is locker or approved
     */
    function unlock(uint256 id) external;

    /**
     * @dev Tranfer and lock the token if the msg.sender is locker or approved
     */
    function transferAndLock(uint256 id, address from, address to, address _locker) external;

    /**
     * @dev Returns the wallet, that is stated as unlocking wallet for the `id` token.
     * If address(0) returned, that means token is not locked. Any other result means token is locked.
     */
    function lockerOf(uint256 id) external view returns (address);

}