// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

contract Initializable {
    bool private _initialized = false;

    modifier initializer() {
        // solhint-disable-next-line reason-string
        require(!_initialized);
        _;
        _initialized = true;
    }

    function initialized() external view returns (bool) {
        return _initialized;
    }
}
