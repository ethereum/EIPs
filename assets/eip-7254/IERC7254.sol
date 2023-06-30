 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC7254 standard as defined in the EIP.
 */
interface IERC7254 {

    struct UserInformation {
        uint256 inReward;
        uint256 outReward;
        uint256 withdraw;
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when the add reward  of a `contributor` is set by
     * a call to {approve}.
     */
    event UpdateReward(address indexed contributor, uint256 value);

    /**
     * @dev Emitted when `value` tokens reward to
     * `caller`.
     *
     * Note that `value` may be zero.
     */
    event GetReward(address indexed owner, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns user information by `account`.
     */
    function informationOf(address account) external view  returns (UserInformation memory);

    /**
     * @dev Returns token reward.
     */
    function tokenReward() external view returns (address);


    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Add `amount` tokens .
     *
     * Returns a rewardPerShare.
     *
     * Emits a {UpdateReward} event.
     */
    function updateReward(uint256 amount) external returns(uint256);

    /**
     * @dev Returns the amount of reward by `account`.
     */
    function viewReward(address account) external returns (uint256);

    /**
     * @dev Moves reward to caller.
     *
     * Returns a amount value of reward.
     *
     * Emits a {GetReward} event.
     */
    function getReward() external returns(uint256);
}
