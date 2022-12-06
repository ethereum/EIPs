// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.11;

import "./ERC721Consumable.sol";

contract ExampleToken is ERC721Consumable {

    uint256 public idCounter = 0;

    constructor() ERC721Consumable("ReferenceImpl", "RIMPL") { }

    // @notice Mints new NFT to msg.sender
    function mint() external returns (uint256) {
        idCounter++;
        _mint(msg.sender, idCounter);
        return idCounter;
    }
}
