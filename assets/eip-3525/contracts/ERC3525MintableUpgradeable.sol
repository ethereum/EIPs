//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC3525Upgradeable.sol";

contract ERC3525MintableUpgradeable is ERC3525Upgradeable {
    uint32 public nextTokenId = 1;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public initializer {
        ERC3525Upgradeable.__ERC3525_init(name_, symbol_, decimals_);
    }

    function mint(
        address minter_,
        uint256 slot_,
        uint256 value_
    ) external {
        ERC3525Upgradeable._mintValue(minter_, _createTokenId(), slot_, value_);
    }

    function _createTokenId() internal virtual override returns (uint256) {
        return nextTokenId++;
    }
}
