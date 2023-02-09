// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Delegate Interface
 * @dev This extension allows delegation of (batch) minting and revocation of tokens to operator(s).
 */
interface IERC5727Delegate is IERC5727 {
    /**
     * @notice Delegate a one-time minting right to `operator` for `delegateRequestId` delegate request.
     * @dev MUST revert if the caller does not have the right to delegate.
     * @param operator The owner to which the minting right is delegated
     * @param delegateRequestId The delegate request describing the owner, value and slot of the token to mint
     */
    function mintDelegate(address operator, uint256 delegateRequestId) external;

    /**
     * @notice Delegate one-time minting rights to `operators` for corresponding delegate request in `delegateRequestIds`.
     * @dev MUST revert if the caller does not have the right to delegate.
     *   MUST revert if the length of `operators` and `delegateRequestIds` do not match.
     * @param operators The owners to which the minting right is delegated
     * @param delegateRequestIds The delegate requests describing the owner, value and slot of the tokens to mint
     */
    function mintDelegateBatch(
        address[] memory operators,
        uint256[] memory delegateRequestIds
    ) external;

    /**
     * @notice Delegate a one-time revoking right to `operator` for `tokenId` token.
     * @dev MUST revert if the caller does not have the right to delegate.
     * @param operator The owner to which the revoking right is delegated
     * @param tokenId The token to revoke
     */
    function revokeDelegate(address operator, uint256 tokenId) external;

    /**
     * @notice Delegate one-time minting rights to `operators` for corresponding token in `tokenIds`.
     * @dev MUST revert if the caller does not have the right to delegate.
     *   MUST revert if the length of `operators` and `tokenIds` do not match.
     * @param operators The owners to which the revoking right is delegated
     * @param tokenIds The tokens to revoke
     */
    function revokeDelegateBatch(
        address[] memory operators,
        uint256[] memory tokenIds
    ) external;

    /**
     * @notice Mint a token described by `delegateRequestId` delegate request as a delegate.
     * @dev MUST revert if the caller is not delegated.
     * @param delegateRequestId The delegate requests describing the owner, value and slot of the token to mint.
     */
    function delegateMint(uint256 delegateRequestId) external;

    /**
     * @notice Mint tokens described by `delegateRequestIds` delegate request as a delegate.
     * @dev MUST revert if the caller is not delegated.
     * @param delegateRequestIds The delegate requests describing the owner, value and slot of the tokens to mint.
     */
    function delegateMintBatch(uint256[] memory delegateRequestIds) external;

    /**
     * @notice Revoke a token as a delegate.
     * @dev MUST revert if the caller is not delegated.
     * @param tokenId The token to revoke.
     */
    function delegateRevoke(uint256 tokenId) external;

    /**
     * @notice Revoke multiple tokens as a delegate.
     * @dev MUST revert if the caller is not delegated.
     * @param tokenIds The tokens to revoke.
     */
    function delegateRevokeBatch(uint256[] memory tokenIds) external;

    /**
     * @notice Create a delegate request describing the `owner`, `value` and `slot` of a token.
     * @param owner The owner of the delegate request.
     * @param value The value of the delegate request.
     * @param slot The slot of the delegate request.
     * @return delegateRequestId The id of the delegate request
     */
    function createDelegateRequest(
        address owner,
        uint256 value,
        uint256 slot
    ) external returns (uint256 delegateRequestId);

    /**
     * @notice Remove a delegate request.
     * @dev MUST revert if the delegate request does not exists.
     *   MUST revert if the caller is not the creator of the delegate request.
     * @param delegateRequestId The delegate request to remove.
     */
    function removeDelegateRequest(uint256 delegateRequestId) external;
}
