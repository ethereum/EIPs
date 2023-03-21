// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Interface proposal for Redeemable tokens.
 * Note: The ERC-165 identifier for this interface is 0x9d1da9d1. 
 */
interface IERC4365 is IERC165 {
    /**
     * @dev Emitted when `amount` tokens of token type `id` are minted to `to` by `minter`.
     */
    event MintSingle(address indexed minter, address indexed to, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {MintSingle} events, where `minter` and `to` is the same for all token types.
     */
    event MintBatch(address indexed minter, address indexed to, uint256[] ids, uint256[] amounts);

    /**
     * @dev Emitted when `amount` tokens of token type `id` owned by `owner` are burned by `burner`.
     */
    event BurnSingle(address indexed burner, address indexed owner, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {BurnSingle} events, where `owner` and `burner` is the same for all token types.
     */
    event BurnBatch(address indexed burner, address indexed owner, uint256[] ids, uint256[] amounts);

    /**
     * @dev Emitted when `amount` of tokens of token type `id` are redeemed in `account`.
     */
    event Redeem(address indexed account, uint256 indexed id, uint256 amount);

    /**
     * @dev Returns the balance of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the balance of `account` for a batch of token `ids`.
     */
    function balanceOfBatch(address account, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Returns the balance of multiple `accounts` for a batch of token `ids`.
     * This is equivalent to calling {balanceOfBatch} for several accounts in just one call.
     *
     * Requirements:
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBundle(address[] calldata accounts, uint256[][] calldata ids) 
        external 
        view 
        returns (uint256[][] memory);

    /**
     * @dev Returns the balance of tokens of token type `id` redeemed by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOfRedeemed(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the balance of `account` for a batch of redeemed token `ids`.
     */
    function balanceOfRedeemedBatch(address account, uint256[] calldata ids) external view returns (uint256[] memory);

     /**
     * @dev Returns the balance of multiple `accounts` for a batch of redeemed token `ids`.
     * This is equivalent to calling {balanceOfRedeemedBatch} for several accounts in just one call.
     *
     * Requirements:
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfRedeemedBundle(address[] calldata accounts, uint256[][] calldata ids) 
        external 
        view 
        returns (uint256[][] memory);

    /**
     * Redeem `amount` of token type `id` owned by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `amount` together with `account` balance of redeemed token of token type `id` 
     * cannot exceed `account` balance of token type `id`. 
     */
    function redeem (address account, uint256 id, uint256 amount, bytes memory data) external;
}
