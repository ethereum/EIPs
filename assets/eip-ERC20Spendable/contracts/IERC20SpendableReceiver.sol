// SPDX-License-Identifier: MIT
// Omnus Contracts v3
// https://omn.us/spendable
// https://github.com/omnus/ERC20Spendable
// npm: @omnus/ERC20Spendable

pragma solidity ^0.8.19;

/**
 * @title IERC20SpendableReceiver.sol
 *
 * @author omnus
 * https://omn.us
 *
 * @dev Implementation of {IERC20SpendableReceiver} interface.
 *
 * {ERC20Spendable} allows ERC20s to operate as 'spendable' items, i.e. an ERC20 token that
 * can trigger an action on another contract at the same time as being transfered. Similar to ERC677
 * and the hooks in ERC777, but with more of an empasis on interoperability (returned values) than
 * ERC677 and specifically scoped interaction rather than the general hooks of ERC777.
 *
 * For more detailed notes please see our guide https://omn.us/how-to-implement-erc20-spendable
 */

interface IERC20SpendableReceiver {
  /// @dev Error {CallMustBeFromSpendableToken}. The call to this method can only be from a designated spendable token.
  error CallMustBeFromSpendableToken();

  /**
   * @dev {onERC20SpendableReceived} External function called by ERC20SpendableTokens. This
   * validates that the token is valid and then calls the internal {_handleSpend} method.
   * You must overried {_handleSpend} in your contract to perform processing you wish to occur
   * on token spend.
   *
   * This method will pass back the valid bytes4 selector and any bytes argument passed from
   * {_handleSpend}.
   *
   * @param spender_ The address spending the ERC20Spendable
   * @param spent_ The amount of token spent
   * @param arguments_ Bytes sent with the call
   */
  function onERC20SpendableReceived(
    address spender_,
    uint256 spent_,
    bytes memory arguments_
  ) external returns (bytes4 retval_, bytes memory returnArguments_);
}
