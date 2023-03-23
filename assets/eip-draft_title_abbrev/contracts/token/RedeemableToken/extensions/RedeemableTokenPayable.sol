// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRedeemableTokenPayable.sol";
import "../RedeemableToken.sol";

/**
 * @dev See {IRedeemableTokenPayable}.
 */
abstract contract RedeemableTokenPayable is RedeemableToken {
    // Optional mapping for token price. 
    mapping(uint256 => uint256) private _price;

    /**
     * @dev Pubicly Exposes {_setPrice}.
     */
    function setPrice(uint256 id, uint256 amount) external {
        _setPrice(id, amount);
    }

    /**
     * @dev Pubicly Exposes {_setBatchPrices}.
     */
    function setBatchPrices(uint256[] memory ids, uint256[] memory amounts) external {
        _setBatchPrices(ids, amounts);
    }

    /**
     * @dev See {IRedeemableTokenPayable-price}.
     */
    function price(uint256 id) public view virtual returns (uint256) {
        uint256 amount = _price[id];
        require(amount != 0, "RedeemableTokenPay: no price set");
        return amount;
    }

    /**
     * @dev Sets the price for the tokens of token type `id`.
     */
    function _setPrice(uint256 id, uint256 amount) internal virtual {
        _price[id] = amount;
    }

    /**
     * @dev [Batched] version of {_setPrice}.
     */
    function _setBatchPrices(uint256[] memory ids, uint256[] memory amounts) internal {
        require(ids.length == amounts.length, "RedeemableTokenSupply: ids and amounts length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            _setPrice(ids[i], amounts[i]);
        }
    }
}
