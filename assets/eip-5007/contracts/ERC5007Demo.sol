// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC5007.sol";

contract ERC5007Demo is ERC5007 {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){}

    /**
     * @dev  mint a new  time NFT
     *
     * Requirements:
     *
     * - `to_` cannot be the zero address.
     * - `tokenId_` must not exist.
     * - `endTime_` should be equal or greater than `startTime_`
     */
    function mint(
        address to_,
        uint256 tokenId_,
        uint64 startTime_,
        uint64 endTime_
    ) public {
        _mintTimeNft(to_, tokenId_, startTime_, endTime_);
    }

    /**
     * @dev Returns the interfaceId of IERC5007.
     */
    function getInterfaceId() public pure returns (bytes4) {
        return type(IERC5007).interfaceId;
    }
}
