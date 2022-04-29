// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

interface IActionRegistry {
    function register(string memory name, uint256 namespace) external;

    function lookup(string memory name, uint256 namespace)
        external
        view
        returns (uint256);

    function reverseLookup(uint256 key, uint256 namespace)
        external
        view
        returns (string memory);
}

contract ActionRegistry {
    mapping(uint256 => mapping(string => uint256)) _lookup;
    mapping(uint256 => mapping(uint256 => string)) _reverseLookup;
    mapping(uint256 => uint256) _namespaces;

    function register(string memory name, uint256 namespace) external {
        uint256 key = _namespaces[namespace];
        key << 1;
        _lookup[namespace][name] = key;
        _reverseLookup[namespace][key] = name;
    }

    function lookup(string memory name, uint256 namespace)
        external
        view
        returns (uint256)
    {
        return _lookup[namespace][name];
    }

    function reverseLookup(uint256 key, uint256 namespace)
        external
        view
        returns (string memory)
    {
        return _reverseLookup[namespace][key];
    }
}

interface IERCxxxxDefinable {
    /// @notice Returns a bit-array of ORd action definitions, and
    /// the namespace used for the action encoding.
    /// @dev Actions and unique action-sequences can be registered
    /// with
    /// @param tokenId The token to define
    function definition(uint256 tokenId)
        external
        view
        returns (
            address registry,
            uint256 namespace,
            bytes32 def
        );
}
