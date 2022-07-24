// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IFactory {

    /// View funcs
    /// NFT token address
    function v1() external view returns (address);
    /// UniswapV2Factory address
    function v2Factory() external view returns (address);
    /// Address of wrapped eth
    function WETH() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);

    /// Getters
    /// Get Config of CDP
    function vaultCodeHash() external pure returns (bytes32);
    function createVault(address collateral_, address debt_, uint256 amount_, address recipient) external returns (address vault, uint256 id);
    function getVault(uint vaultId_) external view returns (address);
    
    /// Event
    event VaultCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, uint8 cDecimals);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
}