// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * Interface for smart contracts wishing to receive ownership of ERC4365 tokens.
 */
interface IERC4365Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC4365 token type.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC4365Mint(address,address,uint256,uint256,bytes)"))`.
     *
     * @param minter The address which initiated minting (i.e. msg.sender).
     * @param id The ID of the token being transferred.
     * @param amount The amount of tokens being transferred.
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onERC4365Mint(address,uint256,uint256,bytes)"))` if minting is allowed.
     */
    function onERC4365Mint(
        address minter,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of multiple ERC4365 token types.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC4365BatchMint(address,address,uint256[],uint256[],bytes)"))`.
     *
     * @param minter The address which initiated minting (i.e. msg.sender).
     * @param ids An array containing ids of each token being transferred (order and length must match values array).
     * @param amounts An array containing amounts of each token being transferred (order and length must match ids array).
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onERC4365BatchMint(address,uint256[],uint256[],bytes)"))` if minting is allowed.
     */
    function onERC4365BatchMint(
        address minter,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}


