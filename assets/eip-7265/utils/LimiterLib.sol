// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Limiter, LiqChangeNode} from "../static/Structs.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";

uint256 constant BPS_DENOMINATOR = 10000;

enum LimitStatus {
    Uninitialized,
    Inactive,
    Ok,
    Triggered
}

library LimiterLib {
    error InvalidMinimumLiquidityThreshold();
    error LimiterAlreadyInitialized();
    error LimiterNotInitialized();

    function init(Limiter storage limiter, uint256 minLiqRetainedBps, uint256 limitBeginThreshold) internal {
        if (minLiqRetainedBps == 0 || minLiqRetainedBps > BPS_DENOMINATOR) {
            revert InvalidMinimumLiquidityThreshold();
        }
        if (initialized(limiter)) revert LimiterAlreadyInitialized();
        limiter.minLiqRetainedBps = minLiqRetainedBps;
        limiter.limitBeginThreshold = limitBeginThreshold;
    }

    function updateParams(Limiter storage limiter, uint256 minLiqRetainedBps, uint256 limitBeginThreshold) internal {
        if (minLiqRetainedBps == 0 || minLiqRetainedBps > BPS_DENOMINATOR) {
            revert InvalidMinimumLiquidityThreshold();
        }
        if (!initialized(limiter)) revert LimiterNotInitialized();
        limiter.minLiqRetainedBps = minLiqRetainedBps;
        limiter.limitBeginThreshold = limitBeginThreshold;
    }

    function recordChange(Limiter storage limiter, int256 amount, uint256 withdrawalPeriod, uint256 tickLength)
        internal
    {
        // If token does not have a rate limit, do nothing
        if (!initialized(limiter)) {
            return;
        }

        uint256 currentTickTimestamp = getTickTimestamp(block.timestamp, tickLength);
        limiter.liqInPeriod += amount;

        uint256 listHead = limiter.listHead;
        if (listHead == 0) {
            // if there is no head, set the head to the new inflow
            limiter.listHead = currentTickTimestamp;
            limiter.listTail = currentTickTimestamp;
            limiter.listNodes[currentTickTimestamp] = LiqChangeNode({amount: amount, nextTimestamp: 0});
        } else {
            // if there is a head, check if the new inflow is within the period
            // if it is, add it to the head
            // if it is not, add it to the tail
            if (block.timestamp - listHead >= withdrawalPeriod) {
                sync(limiter, withdrawalPeriod);
            }

            // check if tail is the same as block.timestamp (multiple txs in same block)
            uint256 listTail = limiter.listTail;
            if (listTail == currentTickTimestamp) {
                // add amount
                limiter.listNodes[currentTickTimestamp].amount += amount;
            } else {
                // add to tail
                limiter.listNodes[listTail].nextTimestamp = currentTickTimestamp;
                limiter.listNodes[currentTickTimestamp] = LiqChangeNode({amount: amount, nextTimestamp: 0});
                limiter.listTail = currentTickTimestamp;
            }
        }
    }

    function sync(Limiter storage limiter, uint256 withdrawalPeriod) internal {
        sync(limiter, withdrawalPeriod, type(uint256).max);
    }

    function sync(Limiter storage limiter, uint256 withdrawalPeriod, uint256 totalIters) internal {
        uint256 currentHead = limiter.listHead;
        int256 totalChange = 0;
        uint256 iter = 0;

        while (currentHead != 0 && block.timestamp - currentHead >= withdrawalPeriod && iter < totalIters) {
            LiqChangeNode storage node = limiter.listNodes[currentHead];
            totalChange += node.amount;
            uint256 nextTimestamp = node.nextTimestamp;
            // Clear data
            limiter.listNodes[currentHead];
            currentHead = nextTimestamp;
            // forgefmt: disable-next-item
            unchecked {
                ++iter;
            }
        }

        if (currentHead == 0) {
            // If the list is empty, set the tail and head to current times
            limiter.listHead = block.timestamp;
            limiter.listTail = block.timestamp;
        } else {
            limiter.listHead = currentHead;
        }
        limiter.liqTotal += totalChange;
        limiter.liqInPeriod -= totalChange;
    }

    function status(Limiter storage limiter) internal view returns (LimitStatus) {
        if (!initialized(limiter)) {
            return LimitStatus.Uninitialized;
        }
        int256 currentLiq = limiter.liqTotal;

        // Only enforce rate limit if there is significant liquidity
        if (limiter.limitBeginThreshold > uint256(currentLiq)) {
            return LimitStatus.Inactive;
        }

        int256 futureLiq = currentLiq + limiter.liqInPeriod;
        // NOTE: uint256 to int256 conversion here is safe
        int256 minLiq = (currentLiq * int256(limiter.minLiqRetainedBps)) / int256(BPS_DENOMINATOR);

        return futureLiq < minLiq ? LimitStatus.Triggered : LimitStatus.Ok;
    }

    function initialized(Limiter storage limiter) internal view returns (bool) {
        return limiter.minLiqRetainedBps > 0;
    }

    function getTickTimestamp(uint256 t, uint256 tickLength) internal pure returns (uint256) {
        return t - (t % tickLength);
    }
}
