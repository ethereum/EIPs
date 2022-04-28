// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC20Receiver.sol";

interface IERC20Subscriber is IERC20Receiver {
    /// @dev                `updateSubscription` MAY be safely called from this function,
    ///                     because it does not re-call `onERC20Subscribed`. This is the 
    ///                     RECOMMENDED way to automatically accept subscriptions.
    ///                     This MUST return the function selector, `0xTODO`.
    function onERC20Subscribed(address from, uint256 amount, bytes memory data) external returns(bytes4);
}