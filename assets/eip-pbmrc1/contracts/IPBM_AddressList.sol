// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title PBM Address list Interface. 
/// @notice The PBM address list stores and manages whitelisted merchants and blacklisted address for the PBMs 
interface IPBMAddressList {

    /// @notice Checks if the address is one of the blacklisted addresses
    /// @param _address The address to query
    /// @return _bool True if address is blacklisted, else false
    function isBlacklisted(address _address) external returns (bool) ; 

    /// @notice Checks if the address is one of the whitelisted merchant
    /// @param _address The address to query
    /// @return _bool True if the address is a merchant that is NOT blacklisted, otherwise false.
    function isMerchant(address _address) external returns (bool) ; 
    
    /// @notice Event emitted when the Merchant List is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of merchant wallet addresses that was whitelisted
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event MerchantList(string _action, address[] _addresses, string _metadata);
    
    /// @notice Event emitted when the Blacklist is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of wallet addresses that was blacklisted
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event Blacklist(string _action, address[] _addresses, string _metadata);
}