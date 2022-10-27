//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Metadata Interface
 * @dev This extension allows querying the metadata of soulbound tokens.
 */
interface IERC5727Metadata is IERC5727 {
    /**
     * @notice Get the name of the contract.
     * @return The name of the contract
     */
    function name() external view returns (string memory);

    /**
     * @notice Get the symbol of the contract.
     * @return The symbol of the contract
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Get the URI of a token.
     * @dev MUST revert if the `tokenId` token does not exist.
     * @param tokenId The token whose URI is queried for
     * @return The URI of the `tokenId` token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Get the URI of the contract.
     * @return The URI of the contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Get the URI of a slot.
     * @dev MUST revert if the `slot` does not exist.
     * @param slot The slot whose URI is queried for
     * @return The URI of the `slot`
     */
    function slotURI(uint256 slot) external view returns (string memory);
}
