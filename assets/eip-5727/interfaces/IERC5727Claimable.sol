// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

interface IERC5727Claimable is IERC5727 {
    /**
     * @notice Emitted when a token is claimed by `to`.
     * @param to The new owner of the token
     * @param tokenId The token claimed
     * @param amount The amount of the token claimed
     */
    event Claimed(address indexed to, uint256 indexed tokenId, uint256 amount);

    /**
     * @notice Claim the token with `tokenId` and `signature`.
     * @dev MUST revert if the signature is invalid.
     * @param to The new owner of the token
     * @param tokenId The token claimed
     * @param amount The amount of the token claimed
     * @param slot The slot to claim the token in
     * @param burnAuth The burn authorization of the token
     * @param data The additional data used to claim the token
     * @param proof The proof to claim the token
     */
    function claim(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 slot,
        BurnAuth burnAuth,
        address verifier,
        bytes calldata data,
        bytes32[] calldata proof
    ) external;
}
