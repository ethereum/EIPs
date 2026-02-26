// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERC5008.sol";

contract ERC5008Demo is ERC5008{

    constructor(string memory name_, string memory symbol_)ERC5008(name_, symbol_){
    }

    /// @notice mint a new NFT
    /// @param to  The owner of the new token
    /// @param tokenId  The id of the new token
    function mint(address to, uint256 tokenId) public {
       _mint(to, tokenId);
    }

    function getInterfaceId() public pure returns (bytes4) {
        return type(IERC5008).interfaceId;
    }
}
