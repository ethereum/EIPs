// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IERC20Minimal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IFinance.sol";
import "./interfaces/IABT.sol";
import "./interfaces/IWETH.sol";
import "./libraries/Initializable.sol";

contract Finance is IFinance, Initializable {
  /// Address of a manager
  address public override manager;
  /// Address of a factory
  address public override factory;
  /// Address of debt;
  address public override debt;
  /// Address of vault ownership registry
  address public override abt;
  /// Vault global identifier
  uint256 public override financeId;
  /// Address of wrapped eth
  address public override WETH;
  /// Vault Creation Date
  uint256 public override createdAt;
  /// Vault Last Updated Date
  uint256 public override lastUpdated;

  modifier onlyVaultOwner() {
    require(
      IABT(abt).ownerOf(financeId) == msg.sender,
      "Finance: Finance is not owned by you"
    );
    _;
  }

  // called once by the factory at time of deployment
  function initialize(
    address manager_,
    uint256 financeId_,
    address abt_,
    uint256 amount_,
    address weth_
  ) external initializer {
    financeId = financeId_;
    abt = abt_;
    WETH = weth_;
    manager = manager_;
    factory = msg.sender;
    lastUpdated = block.timestamp;
    createdAt = block.timestamp;
  }
  
  function depositNative() external payable onlyVaultOwner {
    // wrap deposit
    IWETH(WETH).deposit{ value: msg.value }();
    emit DepositCollateral(financeId, msg.value);
  }

  /// Withdraw collateral as native currency
  function withdrawNative(uint256 amount_)
    external
    virtual
    override
    onlyVaultOwner
  {
    // unwrap collateral
    IWETH(WETH).withdraw(amount_);
    // send withdrawn native currency
    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    emit WithdrawCollateral(financeId, amount_);
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }
}