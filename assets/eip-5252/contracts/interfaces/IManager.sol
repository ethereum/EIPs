pragma solidity ^0.8.0;

interface IManager {
    function factory() external view returns (address);
    function influencer() external view returns (address);
    function getExampleConfig(address something) external view returns (uint);
    event ConfigInitialized(address something, uint example);
    event FinanceCreated(uint id, address weth, address sender, address finance, uint input);
}
