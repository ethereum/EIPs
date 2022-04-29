// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

interface IERCxxxxDefinableList {
    /// @notice Returns a bit-array of ORd action definitions, and
    /// the namespace used for the action encoding.
    /// @dev Actions
    /// @param tokenId The token to define
    function supportedActions(uint256 tokenId)
        external
        view
        returns (string[] memory names);
}
