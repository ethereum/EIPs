pragma solidity ^0.8.0;

import "contracts/interface/IToken.sol";
import "contracts/interface/IIdentityRegistry.sol";

contract FundStorage {

    struct Dividend{
        uint256 Token;
        uint256 StableCoin;
        uint256 Fiat;
    }

    mapping(address => uint) public managementFee;
    mapping(address => Dividend) public dividend;

    string public fundName;
    string public issuerName;
    string public fundCurrency;

    address public fundManagerAddress;
    address public token;
    address public apiConsumer;
    address public stableCoin;
    address public factory;

    uint256 public assetType;
    uint256 public termOfFund;
    uint256 public targetAUM;
    uint256 public AssetUnderManagement;
    uint256 public NAVLaunchPrice;
    uint256 public NAVLatestPrice;
    uint256 public dividendCycle;
    uint256 public issueDate;
    uint256 public iRR;
}