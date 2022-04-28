// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import '../common/IERC165.sol';

interface IERC20Receiver is IERC165 {
  function onERC20Received(
    address _operator,
    address _from,
    uint256 _amount,
    bytes memory _data
  ) external returns(bytes4);
}