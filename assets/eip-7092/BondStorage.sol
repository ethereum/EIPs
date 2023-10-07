// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

contract BondStorage {
    struct Bond {
        string isin;
        string name;
        string symbol;
        address currency;
        uint256 denomination;
        uint256 issueVolume;
        uint256 couponRate;
        uint256 issueDate;
        uint256 maturityDate;
    }

    struct Issuer {
        address issuerAddress;
        string name;
        string email;
        string country;
        string issuerType;
        string creditRating;
        uint256 carbonCredit;
    }

    struct IssueData {
        address investor;
        uint256 principal;
    }

    enum BondStatus {UNREGISTERED, SUBMITTED, ISSUED, REDEEMED}

    mapping(string => Bond) internal _bonds;
    mapping(string => Issuer) internal _issuer;
    mapping(address => uint256) internal _principals;
    mapping(address => mapping(address => uint256)) internal _allowed;

    string internal bondISIN;

    BondStatus internal _bondStatus;
    IssueData[] internal _listOfInvestors;

    address internal _bondManager;

    modifier onlyBondManager {
        require(msg.sender == _bondManager, "BondStorage: ONLY_BOND_MANAGER");
        _;
    }
    
    event BondIssued(IssueData[] _issueData, Bond _bond);
    event BondRedeemed();
}
