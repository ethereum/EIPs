// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Spendable} from "../ERC20Spendable.sol";

contract MockSpendableERC20 is ERC20, ERC20Spendable {
  constructor(
    address initialHolder_,
    uint256 intialBalance_
  ) ERC20("MockSpendable", "MSPEND") {
    _mint(initialHolder_, intialBalance_);
  }
}
