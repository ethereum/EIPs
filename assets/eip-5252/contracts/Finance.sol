// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IERC20Minimal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IFinance.sol";
import "./interfaces/IABT.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Minimal.sol";
import "./interfaces/IStablecoin.sol";
import "./libraries/Initializable.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../governance/interfaces/IGovernance.sol";

contract Fiannce is IFinance, Initializable {
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
  ) external override initializer {
    financeId = financeId_;
    collateral = collateral_;
    debt = debt_;
    abt = abt_;
    borrow = amount_;
    WETH = weth_;
    manager = manager_;
    factory = msg.sender;
    lastUpdated = block.timestamp;
    createdAt = block.timestamp;
    ex_sfr = IVaultManager(manager).getSFR(collateral_);
  }
  
  function depositCollateralNative() external payable override onlyVaultOwner {
    require(collateral == WETH, "Vault: collateral is not a native asset");
    // wrap deposit
    IWETH(WETH).deposit{ value: msg.value }();
    emit DepositCollateral(financeId, msg.value);
  }

  function depositCollateral(uint256 amount_) external override onlyVaultOwner {
    TransferHelper.safeTransferFrom(
      collateral,
      msg.sender,
      address(this),
      amount_
    );
    emit DepositCollateral(financeId, amount_);
  }

  /// Withdraw collateral as native currency
  function withdrawCollateralNative(uint256 amount_)
    external
    virtual
    override
    onlyVaultOwner
  {
    require(collateral == WETH, "Vault: collateral is not a native asset");
    if (borrow != 0) {
      uint256 result = IERC20Minimal(collateral).balanceOf(address(this)) -
        amount_;
      require(
        IVaultManager(manager).isValidCDP(collateral, debt, result, borrow),
        "Vault: below MCR"
      );
    }
    // unwrap collateral
    IWETH(WETH).withdraw(amount_);
    // send withdrawn native currency
    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    emit WithdrawCollateral(financeId, amount_);
  }

  function withdrawCollateral(uint256 amount_)
    external
    override
    onlyVaultOwner
  {
    require(
      IERC20Minimal(collateral).balanceOf(address(this)) >= amount_,
      "Vault: Not enough collateral"
    );
    if (borrow != 0) {
      uint256 test = IERC20Minimal(collateral).balanceOf(address(this)) -
        amount_;
      require(
        IVaultManager(manager).isValidCDP(collateral, debt, test, borrow) ==
          true,
        "Vault: below MCR"
      );
    }
    TransferHelper.safeTransfer(collateral, msg.sender, amount_);
    emit WithdrawCollateral(financeId, amount_);
  }

  function borrowMore(uint256 cAmount_, uint256 dAmount_)
    external
    override
    onlyVaultOwner
  {
    // get vault balance
    uint256 deposits = IERC20Minimal(collateral).balanceOf(address(this));
    // check position
    require(
      IVaultManager(manager).isValidCDP(
        collateral,
        debt,
        cAmount_ + deposits,
        borrow + dAmount_
      ),
      "IP"
    ); // Invalid Position
    // check rebased supply of stablecoin
    require(IVaultManager(manager).isValidSupply(dAmount_), "RB"); // Rebase limited mtr borrow
    /// mint mtr to the sender, prevent bypass by confirming minting right after rebase limit check
    IStablecoin(debt).mintFromVault(factory, financeId, msg.sender, dAmount_);
    // set new borrow amount before transfer; prevention for reentrant pattern
    borrow += dAmount_;
    // transfer collateral to the vault, manage collateral from there
    TransferHelper.safeTransferFrom(
      collateral,
      msg.sender,
      address(this),
      cAmount_
    );
    emit BorrowMore(financeId, cAmount_, dAmount_, borrow);
  }

  function borrowMoreNative(uint256 dAmount_) external payable onlyVaultOwner {
    // get vault balance
    uint256 deposits = IERC20Minimal(WETH).balanceOf(address(this));
    // check position
    require(
      IVaultManager(manager).isValidCDP(
        collateral,
        debt,
        msg.value + deposits,
        borrow + dAmount_
      ),
      "IP"
    ); // Invalid Position
    // check rebased supply of stablecoin
    require(IVaultManager(manager).isValidSupply(dAmount_), "RB"); // Rebase limited mtr borrow
    // mint mtr to the sender, prevent bypass by confirming minting right after rebase limit check
    IStablecoin(debt).mintFromVault(factory, financeId, msg.sender, dAmount_);
    // set new borrow amount before balance update; prevention for reentrant pattern
    borrow += dAmount_;
    // wrap native currency
    IWETH(WETH).deposit{ value: address(this).balance }();
    emit BorrowMore(financeId, msg.value, dAmount_, borrow);
  }

  function payDebt(uint256 amount_) external override onlyVaultOwner {
    // calculate debt with interest
    uint256 fee = _calculateFee();
    require(amount_ != 0, "Vault: amount is zero");
    // send MTR to the vault
    TransferHelper.safeTransferFrom(debt, msg.sender, address(this), amount_);
    // blockchain eventually calculates more interest than input as finalization is asynchronous
    // adjust precision on zeroing borrow balance
    uint256 left = (borrow + fee) - amount_ <= amount_ / 1e6
      ? FeeHelper._sendFee(manager, debt, amount_, amount_ - borrow)
      : FeeHelper._sendFee(manager, debt, amount_, fee);
    _burnMTRFromVault(left);
    // set new borrow amount
    borrow -= left;
    // reset last updated timestamp
    lastUpdated = block.timestamp;
    emit PayBack(financeId, borrow, fee, amount_);
  }

  function closeVault(uint256 amount_) external override onlyVaultOwner {
    // calculate debt with interest
    uint256 fee = _calculateFee();
    // blockchain eventually calculates more interest than input as finalization is asynchronous
    // adjust precision

    // send MTR to the vault
    TransferHelper.safeTransferFrom(debt, msg.sender, address(this), amount_);
    // Check the amount if it satisfies to close the vault, otherwise revert
    require(
      fee + borrow <= amount_ + IERC20Minimal(debt).balanceOf(address(this)),
      "Vault: not enough balance to payback"
    );
    // send fee to the pool
    uint256 left = FeeHelper._sendFee(manager, debt, amount_, fee);
    // burn mtr debt with interest
    _burnMTRFromVault(left);
    // burn vault nft
    _burnabtFromVault();
    // send remainder back to sender
    uint256 remainderD = IERC20Minimal(debt).balanceOf(address(this));
    uint256 remainderC = IERC20Minimal(collateral).balanceOf(address(this));
    TransferHelper.safeTransfer(debt, msg.sender, remainderD);
    TransferHelper.safeTransfer(collateral, msg.sender, remainderC);
    emit CloseVault(financeId, amount_, remainderC, remainderD, fee);
    // send remaining balance if collateral is native currency
    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
  }

  function _burnabtFromVault() internal {
    Iabt(abt).burnFromVault(financeId);
  }

  function _burnMTRFromVault(uint256 amount_) internal {
    IStablecoin(debt).burn(amount_);
  }

  function _calculateFee() public view returns (uint256) {
    uint256 assetValue = IVaultManager(manager).getAssetValue(debt, borrow);
    uint256 expiary = IVaultManager(manager).getExpiary(collateral);
    // Check if interest is retroactive or not
    uint256 sfr = block.timestamp - createdAt > expiary
      ? IVaultManager(manager).getSFR(collateral)
      : ex_sfr;
    /// (duration in months with 18 precision) * (sfr * assetValue/100(with 5decimals))
    // get duration in months with decimal in height for predictive measures with asynchronous finalization
    uint256 duration = ((block.timestamp - lastUpdated) * 1e18) /
      2592000 +
      3600;
    // remove precision then apply sfr with decimals
    uint256 durationV = (duration * assetValue) / 1e18;
    // divide with decimals in price
    return (durationV * sfr) / 10000000;
  }

  function activate(address strategy) external {
    // check if strategy is registered in vault manager
    require(IVaultManager(manager).strategies(keccak256(abi.encodePacked(collateral, strategy))), "Vault: not a strategy");
    address poe = IStrategy(strategy).poe();
    address feeToken = IGovernance(poe).govToken();
    uint256 fee = IGovernance(poe).fee();
    // take fees
    TransferHelper.safeTransferFrom(feeToken, msg.sender, address(this), fee);
    IGovernance(strategy).poe(financeId, msg.sender, fee);
    // send collateral to strategy
    TransferHelper.safeApprove(collateral, strategy, IERC20Minimal(collateral).balanceOf(address(this)));
    address conversion = IStrategy(strategy).activate(financeId, IERC20Minimal(collateral).balanceOf(address(this)));
    collateral = conversion;
  }

  function deActivate(address strategy) external {
    // check if strategy is registered in vault manager
    require(IVaultManager(manager).strategies(keccak256(abi.encodePacked(collateral, strategy))), "Vault: not a strategy");
    address reversion = IStrategy(strategy).deactivate(financeId, IERC20Minimal(collateral).balanceOf(address(this)));
    collateral = reversion;
  }

  function outstandingPayment() external view override returns (uint256) {
    return _calculateFee() + borrow;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }
}