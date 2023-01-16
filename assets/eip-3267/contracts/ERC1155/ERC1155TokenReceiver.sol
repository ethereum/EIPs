// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;

import "./IERC1155TokenReceiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";

abstract contract ERC1155TokenReceiver is ERC165, IERC1155TokenReceiver {
    constructor() {
        _registerInterface(
            ERC1155TokenReceiver(0).onERC1155Received.selector ^
            ERC1155TokenReceiver(0).onERC1155BatchReceived.selector
        );
    }
}
