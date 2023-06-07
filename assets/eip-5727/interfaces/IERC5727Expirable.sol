//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";
import "../../ERC5643/interfaces/IERC5643.sol";

/**
 * @title ERC5727 Soulbound Token Expirable Interface
 * @dev This extension allows soulbound tokens to be expirable and renewable.
 */
interface IERC5727Expirable is IERC5727, IERC5643 {
    /**
     * @notice Set the expiry date of a token.
     * @dev MUST revert if the `tokenId` token does not exist.
     *      MUST revert if the `date` is in the past.
     * @param tokenId The token whose expiry date is set
     * @param expiration The expire date to set
     * @param isRenewable Whether the token is renewable
     */
    function setExpiration(
        uint256 tokenId,
        uint64 expiration,
        bool isRenewable
    ) external;
}
