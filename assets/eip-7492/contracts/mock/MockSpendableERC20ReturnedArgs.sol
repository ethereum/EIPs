// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Spendable} from "../ERC20Spendable.sol";

contract MockSpendableERC20ReturnedArgs is ERC20, ERC20Spendable {
  event Receipt(address spender, uint256 spent, bool flag);

  constructor(
    address initialHolder_,
    uint256 intialBalance_
  ) ERC20("MockSpendable", "MSPEND") {
    _mint(initialHolder_, intialBalance_);
  }

  /**
   *
   * @dev function to be called on receive.
   *
   */
  function _handleReceipt(bytes memory returnedArguments_) internal override {
    address spender;
    uint256 spent;
    bool flag;

    if (returnedArguments_.length != 0) {
      (spender, spent, flag) = abi.decode(
        returnedArguments_,
        (address, uint256, bool)
      );
    }

    emit Receipt(spender, spent, flag);
  }
}
