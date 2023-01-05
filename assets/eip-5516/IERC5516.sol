// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.4;

/**
    @title Soulbound, Multi-Token standard.
    @notice Interface of the EIP-5516
    Note: The ERC-165 identifier for this interface is 0x8314f22b.
 */

interface IERC5516 {
    /**
     * @dev Emitted when `account` claims or rejects pending tokens under `ids[]`.
     */
    event TokenClaimed(
        address indexed operator,
        address indexed account,
        bool[] actions,
        uint256[] ids
    );

    /**
     * @dev Emitted when `from` transfers token under `id` to every address at `to[]`.
     */
    event TransferMulti(
        address indexed operator,
        address indexed from,
        address[] to,
        uint256 amount,
        uint256 id
    );

    /**
     * @dev Get tokens owned by a given address.
     */
    function tokensFrom(address from) external view returns (uint256[] memory);

    /**
     * @dev Get tokens awaiting to be claimed by a given address.
     */
    function pendingFrom(address from) external view returns (uint256[] memory);

    /**
     * @dev Claims or Reject pending `id`.
     *
     * Requirements:
     * - `account` must have a pending token under `id` at the moment of call.
     * - `account` must not own a token under `id` at the moment of call.
     *
     * Emits a {TokenClaimed} event.
     *
     */
    function claimOrReject(
        address account,
        uint256 id,
        bool action
    ) external;

    /**
     * @dev Claims or Reject pending tokens under `ids[]`.
     *
     * Requirements for each `id` `action` pair:
     * - `account` must have a pending token under `id` at the moment of call.
     * - `account` must not own a token under `id` at the moment of call.
     *
     * Emits a {TokenClaimed} event.
     *
     */
    function claimOrRejectBatch(
        address account,
        uint256[] memory ids,
        bool[] memory actions
    ) external;

    /**
     * @dev Transfers `id` token from `from` to every address at `to[]`.
     *
     * Requirements:
     *
     * - `from` MUST be the creator(minter) of `id`.
     * - All addresses in `to[]` MUST be non-zero.
     * - All addresses in `to[]` MUST have the token `id` under `_pendings`.
     * - All addresses in `to[]` MUST not own a token type under `id`.
     *
     * Emits a {TransfersMulti} event.
     *
     */
    function batchTransfer(
        address from,
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
    
}
