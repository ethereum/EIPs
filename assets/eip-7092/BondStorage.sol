// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.18;

contract BondStorage {
    struct Bond {
        string isin;
        string name;
        string symbol;
        address currency;
        address currencyOfCoupon;
        uint8 decimals;
        uint256 denomination;
        uint256 issueVolume;
        uint256 couponRate;
        uint256 couponType;
        uint256 couponFrequency;
        uint256 issueDate;
        uint256 maturityDate;
        uint256 dayCountBasis;
    }

    struct Issuer {
        string name;
        string email;
        string country;
        string headquarters;
        string issuerType;
        string creditRating;
        uint256 carbonCredit;
        address issuerAddress;
    }

    struct IssueData {
        address investor;
        uint256 principal;
    }

    enum BondStatus {UNREGISTERED, SUBMITTED, ISSUED, REDEEMED}

    mapping(string => Bond) internal _bond;
    mapping(string => Issuer) internal _issuer;
    mapping(address => uint256) internal _principals;
    mapping(address => mapping(address => uint256)) internal _approvals;

    string internal bondISIN;
    string internal _countryOfIssuance;

    BondStatus internal _bondStatus;
    IssueData[] internal _listOfInvestors;

    address internal _bondManager;

    modifier onlyBondManager {
        require(msg.sender == _bondManager, "BondStorage: ONLY_BOND_MANAGER");
        _;
    }
    
    event BondIssued(IssueData[] _issueData, Bond _bond);
    event BondRedeemed();

    function bondStatus() external view returns(BondStatus) {
        return _bondStatus;
    }

    function listOfInvestors() external view returns(IssueData[] memory) {
        return _listOfInvestors;
    }

    function bondInfo() public view returns(Bond memory) {
        return _bond[bondISIN];
    }
    
    function issuerInfo() public view returns(Issuer memory) {
        return _issuer[bondISIN];
    }
}
