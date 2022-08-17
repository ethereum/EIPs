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
     * @dev Returns the usable amount of `tokenId` tokens  by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function usableBalanceOf(address account, uint256 tokenId)
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
    function frozenBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the `UserRecord` of the `recordId` record..
     *
     * This record changes when {createUserRecord} or {deleteUserRecord} are called.
     */
    function userRecordOf(uint256 recordId)
        external
        view
        returns (UserRecord memory);

    /**
     * @dev Gives permission to `user` to use `amount` of `tokenId` token owned by `owner` until `expiry`.
     *
     * Emits a {CreateUserRecord} event indicating the updated record.
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     * - If the caller is not `owner`, it must be have been approved to spend ``owner``'s tokens via {setApprovalForAll}.
     * - `owner` must have a balance of tokens of type `id` of at least `amount`.
     */
    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint64 amount,
        uint64 expiry
    ) external returns (uint256);

    /**
     * @dev Atomically delete `record` by the caller.
     *
     * Emits a {DeleteUserRecord} event indicating delete the record.
     *
     * Requirements:
     *
     * - the caller must have allowance.
     */
    function deleteUserRecord(uint256 recordId) external;
}
