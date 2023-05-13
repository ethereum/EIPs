// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../ERC721LockableUpgradeable.sol";

//import "hardhat/console.sol";

contract ERC721LockableUpgradeableMock is ERC721LockableUpgradeable, UUPSUpgradeable {

  uint public latestTokenId;
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(string memory name, string memory symbol) public initializer {
    __ERC721Lockable_init(name, symbol, false);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function getInterfaceId() public pure returns (bytes4) {
    return type(IERC721Lockable).interfaceId;
  }

  function mint (address to, uint256 amount) public {
    for (uint256 i = 0; i < amount; i++) {
      // inefficient, but this is a mock :-)
      _safeMint(to, ++latestTokenId);
    }
  }
}
