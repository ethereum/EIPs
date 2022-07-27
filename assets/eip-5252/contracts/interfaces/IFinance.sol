// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IFinance {
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event Borrow(uint256 vaultID, uint256 amount);
    event BorrowMore(uint256 vaultID, uint256 cAmount, uint256 dAmount, uint256 borrow);
    event PayBack(uint256 vaultID, uint256 borrow, uint256 paybackFee, uint256 amount);
    event CloseVault(uint256 vaultID, uint256 amount, uint256 remainderC, uint256 remainderD, uint256 closingFee);
    event Liquidated(uint256 vaultID, address collateral, uint256 amount, uint256 pairSentAmount);
    /// Getters
    /// Address of a manager
    function  factory() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);
    /// Address of debt;
    function  debt() external view returns (address);
    /// Address of vault ownership registry
    function  v1() external view returns (address);
    /// address of a collateral
    function  collateral() external view returns (address);
    /// Vault global identifier
    function vaultId() external view returns (uint);
    /// borrowed amount 
    function borrow() external view returns (uint256);
    /// created block timestamp
    function lastUpdated() external view returns (uint256);
    /// vault creation date
    function createdAt() external view returns (uint256);
    /// address of wrapped eth
    function  WETH() external view returns (address);
    /// Total debt amount with interest
    function outstandingPayment() external returns (uint256);
    /// V2 factory address for liquidation
    function v2Factory() external view returns (address);
    
    /// Functions
    function initialize(address manager_,
    uint256 vaultId_,
    address collateral_,
    address debt_,
    address v1_,
    uint256 amount_,
    address v2Factory_,
    address weth_
    ) external;
    function liquidate() external;
    function depositCollateralNative() payable external;
    function depositCollateral(uint256 amount_) external;
    function withdrawCollateralNative(uint256 amount_) external;
    function withdrawCollateral(uint256 amount_) external;
    function borrowMore(uint256 cAmount_, uint256 dAmount_) external;
    function payDebt(uint256 amount_) external;
    function closeVault(uint256 amount_) external;

}