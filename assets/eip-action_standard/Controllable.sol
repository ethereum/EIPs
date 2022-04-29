// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import "./IControllable.sol";

contract Controllable is IControllable {
    mapping(address => mapping(bytes4 => bool)) private _approvedControllers;

    function approveController(address sender, bytes4 action)
        external
        virtual
        returns (bool)
    {
        _approvedControllers[sender][action] = true;
        return true;
    }

    function revokeController(address sender, bytes4 action)
        external
        virtual
        returns (bool)
    {
        delete _approvedControllers[sender][action];
        return true;
    }

    function isApprovedController(address sender, bytes4 action)
        external
        view
        returns (bool)
    {
        return _isApprovedController(sender, action);
    }

    function _isApprovedController(address sender, bytes4 action)
        internal
        view
        returns (bool)
    {
        if (_approvedControllers[sender][action]) {
            return true;
        }
        if (_approvedControllers[sender][""]) {
            return true;
        }
        return false;
    }
}
