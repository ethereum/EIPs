// SPDX-License-Identifier: MIT
// Omnus Contracts v3
// https://omn.us/spendable
// https://github.com/omnus/ERC20Spendable
// npm: @omnus/ERC20Spendable

pragma solidity 0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Spendable} from "./IERC20Spendable.sol";
import {IERC20SpendableReceiver} from "./IERC20SpendableReceiver.sol";

/**
 * @title ERC20Spendable.sol
 *
 * @author omnus
 * https://omn.us
 *
 * @dev Implementation of {ERC20Spendable}.
 *
 * {ERC20Spendable} allows ERC20s to operate as 'spendable' items, i.e. an ERC20 token that
 * can trigger an action on another contract at the same time as being transfered. Similar to ERC677
 * and the hooks in ERC777, but with more of an empasis on interoperability (returned values) than
 * ERC677 and specifically scoped interaction rather than the general hooks of ERC777.
 *
 * For more detailed notes please see our guide https://omn.us/how-to-implement-erc20-spendable
 */
abstract contract ERC20Spendable is Context, ERC20, IERC20Spendable {
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
  function spend(address receiver_, uint256 spent_) public virtual {
    spend(receiver_, spent_, "");
  }

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
  ) public virtual {
    /**
     * @dev Transfer tokens to the receiver contract IF this is a non-0 amount. Don't try and transfer 0,
     * which leavesopen the possibility that the call is free. If not, the function call after will fail
     * and revert. Why would a {spend} method call ever be free? For example, a service provider may be
     * taking their ERC20 token as payment for a service. But they want to offer it for free, perhaps for a
     * limited time. Under this situation the spend callcan be used in all cases, but sending 0 token while
     * it is free, removing the need for different interfaces.
     *
     * We use the standard ERC20 public transfer method for the transfer, which means two things:
     * 1) This can only be called by the token owner (but that is the entire point!)
     * 2) We inherit all of the security checks in this method (e.g. owner has sufficient balance etc.)
     */
    if (spent_ != 0) {
      transfer(receiver_, spent_);
    }

    /**
     * @dev Perform actions on the receiver and return arguments back up the callstack. In addition to allowing
     * the execution of the hook within the receiver, this call provides the same feature as onERC721Received
     * in the ERC721 standard.
     */
    if (receiver_.code.length > 0) {
      try
        IERC20SpendableReceiver(receiver_).onERC20SpendableReceived(
          _msgSender(),
          spent_,
          arguments_
        )
      returns (bytes4 retval, bytes memory returnedArguments) {
        if (
          retval != IERC20SpendableReceiver.onERC20SpendableReceived.selector
        ) {
          revert ERC20SpendableInvalidReveiver(receiver_);
        }
        emit SpendReceipt(
          _msgSender(),
          receiver_,
          spent_,
          arguments_,
          returnedArguments
        );
        /// @dev Handle returned values. Specify an override {_handleReceipt} method in your ERC20 contract if
        /// you wish to handle returned arguments.
        _handleReceipt(returnedArguments);
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert ERC20SpendableInvalidReveiver(receiver_);
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /**
   * @dev {_handleReceipt} Internal function called on completion of a call to {onERC20SpendableReceived}
   * on the {ERC20SpendableReceiver}.
   *
   * When making a token {ERC20Spendable} if you wish to process receipts you need to override
   * {_handleReceipt} in your contract. For an example, see {mock} contract {MockSpendableERC20ReturnedArgs}.
   *
   * @param returnedArguments_ Bytes argument to returned from the call. See {mock} contracts for details on
   * encoding and decoding arguments from bytes.
   */
  function _handleReceipt(bytes memory returnedArguments_) internal virtual {}

  /**
   * @dev See {IERC165-supportsInterface}. This can be used to determine if an ERC20 is ERC20Spendable. For
   * example, a DEX may check this value, and make use of a single {spend} transaction (rather than the current
   * model of [approve -> pull]) if the ERC20Spendable interface is supported.
   *
   * @param interfaceId_ The bytes4 interface identifier being checked.
   */
  function supportsInterface(
    bytes4 interfaceId_
  ) public view virtual returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return interfaceId_ == type(IERC20Spendable).interfaceId;
  }
}
