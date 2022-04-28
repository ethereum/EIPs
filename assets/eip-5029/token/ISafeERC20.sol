// SPDX-Licence-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import './IERC20.sol';
import '../common/IERC165.sol';

// the EIP-165 interfaceId for this interface is 0x534f5876

interface ISafeERC20 is IERC20, IERC165 {
  function safeTransfer(address to, uint256 amount) external returns(bool);
  function safeTransfer(address to, uint256 amount, bytes memory data) external returns(bool);
  function safeTransferFrom(address from, address to, uint256 amount) external returns(bool);
  function safeTransferFrom(address from, address to, uint256 amount, bytes memory data) external returns(bool);
}
