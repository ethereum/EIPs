// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

struct LiqChangeNode {
    uint256 nextTimestamp;
    int256 amount;
}

struct Limiter {
    uint256 minLiqRetainedBps;
    uint256 limitBeginThreshold;
    int256 liqTotal;
    int256 liqInPeriod;
    uint256 listHead;
    uint256 listTail;
    mapping(uint256 tick => LiqChangeNode node) listNodes;
}
