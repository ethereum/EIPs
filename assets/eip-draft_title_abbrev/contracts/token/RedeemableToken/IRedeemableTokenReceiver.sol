// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * Interface for smart contracts wishing to receive ownership of RedeemableToken tokens.
 */
interface IRedeemableTokenReceiver is IERC165 {
    /**
     * @dev Handles the receipt of a single RedeemableToken token type.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onRedeemableTokenMint(address,address,uint256,uint256,bytes)"))`.
     *
     * @param minter The address which initiated minting (i.e. msg.sender).
     * @param id The ID of the token being transferred.
     * @param amount The amount of tokens being transferred.
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onRedeemableTokenMint(address,uint256,uint256,bytes)"))` if minting is allowed.
     */
    function onRedeemableTokenMint(
        address minter,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of multiple RedeemableToken token types.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onRedeemableTokenBatchMint(address,address,uint256[],uint256[],bytes)"))`.
     *
     * @param minter The address which initiated minting (i.e. msg.sender).
     * @param ids An array containing ids of each token being transferred (order and length must match values array).
     * @param amounts An array containing amounts of each token being transferred (order and length must match ids array).
     * @param data Additional data with no specified format.
     * @return `bytes4(keccak256("onRedeemableTokenBatchMint(address,uint256[],uint256[],bytes)"))` if minting is allowed.
     */
    function onRedeemableTokenBatchMint(
        address minter,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}
