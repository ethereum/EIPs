// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC5050Sender.sol";
import "./ERC5050Receiver.sol";

contract ERC5050 is ERC5050Sender, ERC5050Receiver {
    function _registerAction(bytes4 action) internal {
        _registerReceivable(action);
        _registerSendable(action);
    }
}
