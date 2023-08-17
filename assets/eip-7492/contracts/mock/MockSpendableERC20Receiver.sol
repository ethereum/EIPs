// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

import {ERC20SpendableReceiver, IERC20SpendableReceiver} from "../ERC20SpendableReceiver.sol";

contract MockSpendableERC20Receiver is ERC20SpendableReceiver {
  event AmountStaked(uint256 stake, string message, uint256 stakeDays);

  mapping(address => uint256) public stakedAmount;

  constructor(
    address spendableToken_
  ) ERC20SpendableReceiver(spendableToken_) {}

  /**
   *
   * @dev function to be called on receive.
   *
   */
  function _handleSpend(
    address spender_,
    uint256 spent_,
    bytes memory arguments_
  ) internal override returns (bytes memory returnArguments_) {
    string memory message;
    uint256 stakingDays;

    if (arguments_.length != 0) {
      (message, stakingDays) = abi.decode(arguments_, (string, uint256));
    }

    stakedAmount[spender_] += spent_;

    emit AmountStaked(spent_, message, stakingDays);

    returnArguments_ = abi.encode(spender_, spent_, true);

    return (returnArguments_);
  }
}
