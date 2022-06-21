// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC5006 is IERC165 {

    /**
     * @dev Logged when the user of a NFT is changed 
     *
     * Requirements:
     *
     * - `operator` msg.sender
     * - `from` the address that change usage rights from 
     * - `to`  the address that change usage rights to 
     * - `id`  token id
     * - `value` token amount
     */
    event UpdateUser(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens of token type `id` used by `user`.
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     */
    function balanceOfUser(address user, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of frozen tokens of token type `id` by `owner`.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     */
    function frozenOfOwner(address owner, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of tokens of token type `id` used by `user`.
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     * - `owner` cannot be the zero address.
     */ 
    function balanceOfUserFromOwner(
        address user,
        address owner,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev set the `user` of a NFT
     *
     * Requirements:
     *
     * - `user` The new user of the NFT, the zero address indicates there is no user
     * - `amount` The new user could use
     */ 
    function setUser(
        address owner,
        address user,
        uint256 id,
        uint256 amount
    ) external;
}
