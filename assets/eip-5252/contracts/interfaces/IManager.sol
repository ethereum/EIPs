pragma solidity ^0.8.0;

interface IManager {
    event ConfigInitialized(address something, uint example);
    event FinanceCreated(uint id, address weth, address sender, address finance, uint input);
}