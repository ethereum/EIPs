// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "./KBT721.sol";

contract MyFirstKBT is KBT721 {
    constructor() KBT721("MyFirstKBT", "FirstKBT") {}

    function safeMint(
        address to,
        uint256 tokenId
    ) external virtual onlyOwner returns (bool) {
        _safeMint(to, tokenId);

        return true;
    }
}
