//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC3525MintableUpgradeable.sol";

contract ERC3525BurnableUpgradeable is ERC3525MintableUpgradeable {
    function burn(uint256 tokenId_) external {
        require(_msgSender() == ERC3525Upgradeable.ownerOf(tokenId_), "only owner");
        ERC3525Upgradeable._burn(tokenId_);
    }
}
