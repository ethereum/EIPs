// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5006 {
    struct UserRecord {
        uint256 tokenId;
        address owner;
        uint64 amount;
        address user;
        uint64 expiry;
    }

    event DeleteUserRecord(uint256 recordId);

    event CreateUserRecord(
        uint256 recordId,
        uint256 tokenId,
        uint256 amount,
        address owner,
        address user,
        uint64 expiry
    );

    /**
     * @dev Returns the amount of tokens of token type `id` used by `user`.
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     */
    function usableBalanceOf(address user, uint256 id)
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
    function frozenBalanceOf(address owner, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the record.
     *
     * This record changes when {createUserRecord} or {deleteUserRecord} are called.
     */
    function userRecordOf(uint256 recordId)
        external
        view
        returns (UserRecord memory);

    /**
     * @dev Authorizes the user can use specific id NFTs * amount till expiry.
     *
     * Emits an {CreateUserRecord} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance.
     */
    function createUserRecord(
        address owner,
        address user,
        uint256 id,
        uint64 amount,
        uint64 expiry
    ) external returns (uint256);

    /**
     * @dev Atomically delte `record` by the caller.
     *
     * Emits an {DeleteUserRecord} event.
     *
     * Requirements:
     *
     * - the caller must have allowance.
     */
    function deleteUserRecord(uint256 recordId) external;
}
