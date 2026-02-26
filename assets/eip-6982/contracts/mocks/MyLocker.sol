// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "../IERC721Lockable.sol";

contract MyLocker {
  function lock(address asset, uint256 id) public {
    IERC721Lockable(asset).lock(id);
  }

  function unlock(address asset, uint256 id) public {
    IERC721Lockable(asset).unlock(id);
  }
}
