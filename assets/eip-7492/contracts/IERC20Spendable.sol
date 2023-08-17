// SPDX-License-Identifier: MIT
// Omnus Contracts v3
// https://omn.us/spendable
// https://github.com/omnus/ERC20Spendable
// npm: @omnus/ERC20Spendable

pragma solidity ^0.8.19;

/**
 * @title IERC20Spendable.sol
 *
 * @author omnus
 * https://omn.us
 *
 * @dev Implementation of {IERC20Spendable} interface.
 *
 * {ERC20Spendable} allows ERC20s to operate as 'spendable' items, i.e. an ERC20 token that
 * can trigger an action on another contract at the same time as being transfered. Similar to ERC677
 * and the hooks in ERC777, but with more of an empasis on interoperability (returned values) than
 * ERC677 and specifically scoped interaction rather than the general hooks of ERC777.
 *
 * For more detailed notes please see our guide https://omn.us/how-to-implement-erc20-spendable
 */

interface IERC20Spendable {
  /// @dev Error {ERC20SpendableInvalidReveiver} The called contract does not support ERC20Spendable.
  error ERC20SpendableInvalidReveiver(address receiver);

  /// @dev Event {SpendReceipt} issued on successful return from the {ERC20SpendableReceiver} call.
  event SpendReceipt(
    address spender,
    address receiver,
    uint256 amount,
    bytes sentArguments,
    bytes returnedArguments
  );

  /**
   * @dev {spend} Allows the transfer of the owners token to the receiver, a call on the receiver,
   * and then the return of information from the receiver back up the call stack.
   *
   * Overloaded method - call this if you are not specifying any arguments.
   *
   * @param receiver_ The receiving address for this token spend. Contracts must implement
   * ERCSpendableReceiver to receive spendadle tokens. For more detail see {ERC20SpendableReceiver}.
   * @param spent_ The amount of token being spent. This will be transfered as part of this call and
   * provided as an argument on the call to {onERC20SpendableReceived} on the {ERC20SpendableReceiver}.
   */
  function spend(address receiver_, uint256 spent_) external;

  /**
   * @dev {spend} Allows the transfer of the owners token to the receiver, a call on the receiver, and
   * the return of information from the receiver back up the call stack.
   *
   * Overloaded method - call this to specify a bytes argument.
   *
   * @param receiver_ The receiving address for this token spend. Contracts must implement
   * ERCSpendableReceiver to receive spendadle tokens. For more detail see {ERC20SpendableReceiver}.
   * @param spent_ The amount of token being spent. This will be transfered as part of this call and
   * provided as an argument on the call to {onERC20SpendableReceived} on the {ERC20SpendableReceiver}.
   * @param arguments_ Bytes argument to send with the call. See {mock} contracts for details on encoding
   * and decoding arguments from bytes.
   */
  function spend(
    address receiver_,
    uint256 spent_,
    bytes memory arguments_
  ) external;
}
