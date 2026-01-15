// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;
import { ABDKMath64x64 } from "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./BaseRestorableSalary.sol";
import "./DAOInterface.sol";

/// Salary system with a "DAO" that can assign attorneys to restore lost Ethereum accounts.
/// @author Victor Porton
/// @notice Not audited, not enough tested.
contract SalaryWithDAO is BaseRestorableSalary {
    using ABDKMath64x64 for int128;

    /// The DAO interface.
    DAOInterface public daoPlugin;

    /// When set to true, your account can't be moved to new address (by the DAO).
    ///
    /// By default new users are not under DAO control to avoid front-running of resigning control
    /// by an evil DAO.
    ///
    /// Mapping (current address => under control)
    mapping (address => bool) public underDAOControl;

    /// Mapping (current address => account has at least one salary).
    mapping (address => bool) public accountHasSalary;

    // DAO share will be zero to prevent theft by voters and because it can be done instead by future voting.
    // int128 public daoShare = int128(0).div(1); // zero by default

    /// Constructor.
    /// @param _daoPlugin The DAO interface.
    /// @param _uri The ERC-1155 token URI.
    constructor(DAOInterface _daoPlugin, string memory _uri)
        BaseRestorableSalary(_uri)
    {
        daoPlugin = _daoPlugin;
    }

    /// Create an oracle for caclcualting salary amounts.
    function createOracle() external returns (uint64) {
        return _createOracle();
    }

    /// Register a salary recipient.
    ///
    /// Can be called both before or after the oracle finish. However registering after the finish is useless.
    ///
    /// Anyone can register anyone (useful for robots registering a person).
    ///
    /// Registering another person is giving him money against his will (forcing to hire bodyguards, etc.),
    /// but if one does not want, he can just not associate this address with his identity in his publications.
    /// @param _customer The original address.
    /// @param _oracleId The oracle ID.
    /// @param _underDAOControl If the registered address will be under DAO control.
    /// @param _data The current data.
    function registerCustomer(address _customer, uint64 _oracleId, bool _underDAOControl, bytes calldata _data)
        virtual public returns (uint256)
    {
        address _orig = _originalAddress(_customer);
        // Auditor: Check that this value is set to false, when (and if) necessary.
        accountHasSalary[_customer] = true;
        underDAOControl[_customer] = _underDAOControl; // We don't trigger and event to reduce gas usage.
        return super._registerCustomer(_orig, _oracleId, _data);
    }

    /// A user can agree for DAO control. Then his account can be restored by DAO for the expense
    /// of the DAO assigned personnel or software being able to steal his funds.
    ///
    /// Be extremely careful calling this method: If you refuse and lose your key, your funds are lost!
    ///
    /// Fishers may trick one to resign mistakenly. However, it's no much worse than just fishing for
    /// withdrawing the salary token, because a user could just register anew and notify traders/oracles
    /// that it's the same person.
    function setDAOControl(bool _underControl) public {
        address _orig = _originalAddress(msg.sender);
        require(accountHasSalary[_orig], "Cannot resign account receiving a salary.");
        underDAOControl[_orig] = _underControl; // We don't trigger and event to reduce gas usage.
    }

    /// The DAO can replace itself.
    function setDAO(DAOInterface _daoPlugin) public onlyDAO {
        daoPlugin = _daoPlugin;
    }

    /// Set the token URI.
    function setURI(string memory _newuri) public onlyDAO {
        _setURI(_newuri);
    }

    // Overrides ///

    function checkAllowedRestoreAccount(address _oldAccount, address _newAccount)
        public virtual override isUnderDAOControl(_oldAccount)
    {
        daoPlugin.checkAllowedRestoreAccount(_oldAccount, _newAccount);
    }

    /// Allow the user to unrestore by himself?
    /// We won't not allow it to `_oldAccount` because it may be a stolen private key.
    /// We could allow it to `_newAccount`, but this makes no much sense, because
    /// it would only prevent the user to do a theft by himself, let only DAO could be allowed to do.
    function checkAllowedUnrestoreAccount(address _oldAccount, address _newAccount)
        public virtual override isUnderDAOControl(_oldAccount)
    {
        daoPlugin.checkAllowedUnrestoreAccount(_oldAccount, _newAccount);
    }

    // Internal //

    function _isDAO() internal view returns (bool) {
        return msg.sender == address(daoPlugin);
    }

    // Modifiers //

    modifier onlyDAO() {
        require(_isDAO(), "Only DAO can do.");
        _;
    }

    /// @param _customer The current address.
    modifier isUnderDAOControl(address _customer) {
        require(underDAOControl[_customer], "Not under DAO control.");
        _;
    }
}
