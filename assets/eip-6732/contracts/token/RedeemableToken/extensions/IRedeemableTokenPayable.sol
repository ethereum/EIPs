// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IRedeemableToken.sol";

/**
 * @dev Proposal of an interface for Redeemable Tokens with a price.
 */
interface IRedeemableTokenPayable is IRedeemableToken {
    /**
     * @dev Sets the price `amount` for the token of token type `id`.
     */
    function setPrice(uint256 id, uint256 amount) external;

    /**
     * @dev [Batched] version of {setPrice}.
     */
    function setBatchPrices(uint256[] memory ids, uint256[] memory amounts) external;

    /**
     * @dev Returns the price for the token type `id`.
     */
    function price(uint256 id) external view returns (uint256);
}
