// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IERC20Minimal.sol";

contract Manager is AccessControl, IManager {
    
    // Configs
    /// key: Collateral address, value: Liquidation Fee Ratio (LFR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => uint) internal ExampleConfig;
    
    address public override factory;
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initializeConfig(address something, uint example) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        ExampleConfig[something] = example;
        emit ConfigInitialized(something, example);  
    }
    
    function initialize(address stablecoin_, address factory_, address liquidator_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        factory = factory_;
    }

    function createFinanceNative(uint amount_) payable public returns(bool success) {
        address WETH = IFactory(factory).WETH();
        // check validity

        // create vault
        (address vlt, uint256 id) = IFactory(factory).createFinance(WETH, amount_, _msgSender());
        require(vlt != address(0), "VAULTMANAGER: FE"); // Factory error
        // wrap native currency
        IWETH(WETH).deposit{value: address(this).balance}();
        uint256 weth = IERC20Minimal(WETH).balanceOf(address(this));
        // then transfer collateral native currency to the finance contract, manage collateral from there.
        require(IWETH(WETH).transfer(vlt, weth)); 
        emit FinanceCreated(id, WETH, msg.sender, vlt, msg.value);
        return true;
    }
    

    function getExampleConfig(address something) external view override returns (uint) {
        return ExampleConfig[something];
    }
}

