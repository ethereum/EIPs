// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;
import "./BaseSalary.sol";

/// @title "Salary" that is paid one token per second using minted conditionals.
/// @author Victor Porton
/// @notice Not audited, not enough tested.
contract Salary is BaseSalary {
    /// @param _uri The ERC-1155 token URI.
    constructor(string memory _uri) BaseSalary(_uri) { }

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
    /// @param _data The current data.
    function registerCustomer(address _customer, uint64 _oracleId, bytes calldata _data)
        virtual public returns (uint256)
    {
        return _registerCustomer(_customer, _oracleId, _data);
    }
}