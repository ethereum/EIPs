// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IFactory {

    /// View funcs
    /// NFT token address
    function abt() external view returns (address);
    /// Address of wrapped eth
    function WETH() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);

    /// Getters
    /// Get Config of CDP
    function financeCodeHash() external pure returns (bytes32);
    function createFinance(address weth, uint256 amount_, address recipient) external returns (address vault, uint256 id);
    function getFinance(uint financeId_) external view returns (address);
    
    /// Event
    event FinanceCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
}
