// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.26;

/// @dev Where an old token can be sold for ETH. Stateless adapters; one per market type.
interface IVenue {
    /// @notice True if `token` has a market this venue can sell into right now.
    function canSell(address token) external view returns (bool);
    /// @notice ETH per whole token at spot, scaled 1e18.
    function spot(address token) external view returns (uint256);
    /// @notice Pull `amount` of `token` from the caller, sell it, send at least `minOut` ETH back to the caller.
    function sell(address token, uint256 amount, uint256 minOut) external returns (uint256 ethOut);
}

/// @dev Where ETH becomes $SQUARE.
interface IBuyer {
    /// @notice Spend msg.value on $SQUARE and send it to the caller.
    function buy(uint256 minOut) external payable returns (uint256 squareOut);
}
