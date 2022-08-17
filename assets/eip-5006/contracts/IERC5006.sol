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
    /**
     * @dev Emitted when {createUserRecord} are called.
     */
    event CreateUserRecord(
        uint256 indexed recordId,
        uint256 tokenId,
        uint256 amount,
        address owner,
        address user,
        uint64 expiry
    );
    /**
     * @dev Emitted when {deleteUserRecord} are called.
     */
    event DeleteUserRecord(uint256 indexed recordId);

    /**
     * @dev Returns the amount of tokens of token type `id` can used by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function usableBalanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of frozen tokens of token type `id` by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function frozenBalanceOf(address account, uint256 id)
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
     * Emits an {CreateUserRecord} event indicating the updated record.
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
     * @dev Atomically delete `record` by the caller.
     *
     * Emits an {DeleteUserRecord} event indicating delete the record.
     *
     * Requirements:
     *
     * - the caller must have allowance.
     */
    function deleteUserRecord(uint256 recordId) external;
}
