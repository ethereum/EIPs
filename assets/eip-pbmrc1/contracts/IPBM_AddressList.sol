// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title PBM Address list Interface. 
/// @notice The PBM address list stores and manages whitelisted merchants/redeemers and blacklisted address for the PBMs 
interface IPBMAddressList {

    /// @notice Checks if the address is one of the blacklisted addresses
    /// @param address The address to query
    /// @return bool_ True if address is blacklisted, else false
    function isBlacklisted(address address) external returns (bool bool_) ; 

    /// @notice Checks if the address is one of the whitelisted merchant/redeemer addresses
    /// @param address The address to query
    /// @return bool_ True if the address is in merchant/redeemer whitelist and is NOT a blacklisted address, otherwise false.
    function isMerchant(address address) external returns (bool bool_) ; 
    
    /// @notice Event emitted when the Merchant/Redeemer List is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of merchant wallet addresses that was just added or removed from Merchant/Redeemer whitelist
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event MerchantList(string action, address[] addresses, string metadata);
    
    /// @notice Event emitted when the Blacklist is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses An array of wallet addresses that was just added or removed from address blacklist
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event Blacklist(string action, address[] addresses, string metadata);
}