// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "../ERC721Lockable.sol";

contract ERC721LockableMock is ERC721Lockable {

  uint public latestTokenId;

  constructor(string memory name, string memory symbol) ERC721Lockable(name, symbol, false) {}

  function mint (address to, uint256 amount) public {
    for (uint256 i = 0; i < amount; i++) {
      // inefficient, but this is a mock :-)
      _safeMint(to, ++latestTokenId);
    }
  }
}
