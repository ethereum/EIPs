// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IFinance {
    event DepositFundNative(uint256 vaultID, uint256 amount);
    event WithdrawFundNative(uint256 vaultID, uint256 amount);
    /// Getters
    /// Address of a factory
    function  factory() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);
    function influencer() external view returns (address);
    /// Address of account bound token
    function abt() external view returns (address);
    /// Finance global identifier
    function financeId() external view returns (uint256);
    /// Finance Last Updated Date
    function lastUpdated() external view returns (uint256);
    /// Finance creation date
    function createdAt() external view returns (uint256);
    /// address of wrapped eth
    function  WETH() external view returns (address);
    /// deposit amount of finance account
    function deposit() external view returns (uint256);
    
    /// Functions
    function initialize(
    address manager_,
    uint256 financeId_,
    address abt_,
    uint256 amount_,
    address weth_
    ) external;
    
}
