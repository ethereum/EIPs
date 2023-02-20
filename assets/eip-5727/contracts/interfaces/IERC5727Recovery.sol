// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Recovery Interface
 * @dev This extension allows recovering soulbound tokens from an address provided its signature.
 */
interface IERC5727Recovery is IERC5727 {
    /**
     * @notice Recover the tokens of `owner` with `signature`.
     * @dev MUST revert if the signature is invalid.
     * @param owner The owner whose tokens are recovered
     * @param signature The signature signed by the `owner`
     */
    function recover(address owner, bytes memory signature) external;
}
