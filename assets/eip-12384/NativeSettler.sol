// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IVenue} from "./IVenue.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}

/// @dev What a fee destination has to be: a staking pool, not a wallet.
interface IStakePool {
    function square() external view returns (IERC20);
    function sync(address token) external returns (uint256, uint256);
}

/// @title NativeSettler: reference fees become native, and both halves become stake.
/// @notice A token cannot take ETH from its sender at transfer time, so IERC12384 tokens pay
///         their fee in kind, all of it here. Anyone then settles a token: what has landed is
///         sold for ETH through the token's own market (the same venue adapters the scooper
///         uses). Half of the ETH goes to the chain's sink, an ownerless contract that can only
///         hold (on L1, only stake). Half is wrapped and handed to the stake pool the deployer
///         fixed, which must be a pool and nothing else. Nothing is burned. Nobody owns this.
contract NativeSettler is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10_000;
    /// @notice A settlement must clear spot less this much, or it waits for a better block.
    uint256 public constant MAX_IMPACT_BPS = 500;
    /// @notice The chain's half: an ownerless sink that only holds.
    address payable public immutable sink;

    IVenue[] public venues;
    IStakePool public immutable pool;
    IWETH public immutable weth;

    event Settled(address indexed token, address indexed venue, uint256 sold, uint256 ethOut, uint256 sunk, uint256 staked);

    error NoMarket();
    error NotAPool();
    error Nothing();

    constructor(IVenue[] memory venues_, IStakePool pool_, IWETH weth_, address payable sink_) {
        // the destination has to answer as a pool; a wallet or an EOA cannot
        if (address(pool_.square()) == address(0)) revert NotAPool();
        if (sink_ == address(0) || sink_.code.length == 0) revert NotAPool();
        sink = sink_;
        for (uint256 i = 0; i < venues_.length; i++) {
            venues.push(venues_[i]);
        }
        pool = pool_;
        weth = weth_;
    }

    receive() external payable {}

    function venueCount() external view returns (uint256) {
        return venues.length;
    }

    /// @notice Tokens landed here and not yet settled.
    function pending(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function venueFor(address token) public view returns (IVenue) {
        for (uint256 i = 0; i < venues.length; i++) {
            if (venues[i].canSell(token)) return venues[i];
        }
        return IVenue(address(0));
    }

    /// @notice Settle up to `amount` of `token` (0 = everything held). Anyone may call.
    function settle(address token, uint256 amount) external nonReentrant returns (uint256 ethOut) {
        uint256 held = IERC20(token).balanceOf(address(this));
        if (amount == 0 || amount > held) amount = held;
        if (amount == 0) revert Nothing();
        IVenue v = venueFor(token);
        if (address(v) == address(0)) revert NoMarket();
        uint256 minOut = amount * v.spot(token) / 1e18 * (BPS - MAX_IMPACT_BPS) / BPS;
        IERC20(token).forceApprove(address(v), amount);
        uint256 before = address(this).balance;
        v.sell(token, amount, minOut);
        ethOut = address(this).balance - before;
        require(ethOut >= minOut, "slip");
        uint256 sunk = ethOut / 2;
        uint256 staked = ethOut - sunk;
        (bool ok,) = sink.call{value: sunk}("");
        require(ok, "sink");
        weth.deposit{value: staked}();
        IERC20(address(weth)).safeTransfer(address(pool), staked);
        pool.sync(address(weth));
        emit Settled(token, address(v), amount, ethOut, sunk, staked);
    }
}
