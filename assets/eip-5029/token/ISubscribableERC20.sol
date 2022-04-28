// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ISafeERC20.sol";

interface ISubscribableERC20 is ISafeERC20 {

    /////////////////
    //// GETTERS ////
    /////////////////

    /// @notice             Gets the number of tokens that are sent per block from `from` to `to`
    /// @param  from        The address sending tokens
    /// @param  to          The address receiving tokens
    /// @return amount      The amount of tokens being sent
    function subscription(address from, address to) external view returns (uint256 amount);


    /// @notice             Gets the maximum number of tokens that can be sent per block from `from` to `to`
    /// @param  from        The address sending tokens
    /// @param  to          The address receiving tokens
    /// @return allowance   The maximum value of `amount` in `updateSubscription`
    function subscriptionAllowance(address from, address to) external view returns (uint256 allowance);

    /// @notice             Gets if the balance is larger than or equal to the amount paid each block
    /// @param  subscriber  The account paying
    /// @return active      Whether or not the account is able to pay
    function subscriptionActive(address subscriber) external view returns (bool active);

    /////////////////
    //// SETTERS ////
    /////////////////

    /// @notice             Sets the subscription allowance to `amount`
    /// @param  to          The address receiving tokens
    /// @param  amount      The amount to send/approve each block
    function subscribe(address to, uint256 amount) external;


    /// @notice             Sets the subscription allowance to `amount`, and performs validation
    /// @param  to          The address receiving tokens
    /// @param  amount      The amount to send/approve each block
    function safeSubscribe(address to, uint256 amount) external;


    /// @notice             Sets the subscription allowance to `amount`, and performs validation
    /// @param  to          The address receiving tokens
    /// @param  amount      The amount to send/approve each block
    /// @param  data        Data to provide to `onERC20Subscribed`
    function safeSubscribe(address to, uint256 amount, bytes memory data) external;


    /// @notice             Sets the subscription amount to `amount`
    /// @param  from        The address sending tokens
    /// @param  amount      The amount to send/approve each block. If greater than the allowance, then only the allowance will be sent
    /// @return authed      `true` if `amount` is less than or equal to the authorization.
    function updateSubscription(address from, uint256 amount) external returns (bool authed);

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice             Emitted when the subscription amount is changed
    /// @param  from        The address sending tokens
    /// @param  to          The address receiving tokens
    /// @param  amount      The amount sent each block
    event Subscription(address indexed from, address indexed to, uint256 amount);


    /// @notice             Emitted when the subscription allowance is changed
    /// @param  from        The address sending tokens
    /// @param  to          The address receiving tokens
    /// @param  amount      The maximum amount sent each block
    event SubscriptionApproval(address indexed from, address indexed to, uint256 amount);
}
