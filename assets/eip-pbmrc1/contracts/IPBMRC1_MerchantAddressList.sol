// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Stores a list of all merchant addresses that accept PBM as a payment scheme
/// @notice This interface defines a scheme to manage whitelisted and blacklisted merchant addresses.
/// Implementers will define the appropriate logic to whitelist or blacklist specific merchant addresses.
interface IPBMRC1_MerchantAddressList {

    /// @notice Adds wallet addresses to the blacklist, preventing them from receiving PBM tokens.
    /// @param addresses An array of wallet addresses to be blacklisted.
    /// @param metadata Optional comments or notes about the blacklisted addresses.
    function blacklistAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Removes wallet addresses from the blacklist, allowing them to receive PBM tokens.
    /// @param addresses An array of wallet addresses to be removed from the blacklist.
    /// @param metadata Optional comments or notes about the removed addresses.
    function unBlacklistAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Checks if an address is blacklisted.
    /// @param _address The address in question.
    /// @return True if the address is blacklisted, otherwise false.
    function isBlacklisted(address _address) external returns (bool);

    /// @notice Registers merchant wallet addresses to differentiate between users and merchants.
    /// @dev The 'unwrapTo' function is called when invoking the PBM 'safeTransferFrom' function for valid merchant addresses.
    /// @param addresses An array of merchant wallet addresses to be added.
    /// @param metadata Optional comments or notes about the added addresses.
    function addMerchantAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Unregisters wallet addresses from the merchant list.
    /// @dev Removes the specified wallet addresses from the list of recognized merchants.
    /// @param addresses An array of merchant wallet addresses to be removed.
    /// @param metadata Optional comments or notes about the removed addresses.
    function removeMerchantAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Checks if an address is a whitelisted merchant.
    /// @param _address The address in question.
    /// @return True if the address is a merchant that is not blacklisted, otherwise false.
    function isMerchant(address _address) external returns (bool);

    /// @notice Event emitted when the Merchant List is edited.
    /// @param action Tags "add" or "remove" for the action type.
    /// @param addresses An array of merchant wallet addresses.
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event MerchantList(string action, address[] addresses, string metadata);

    /// @notice Event emitted when the Blacklist is edited.
    /// @param action Tags "add" or "remove" for the action type.
    /// @param addresses An array of wallet addresses.
    /// @param metadata Optional comments or notes about the added or removed addresses.
    event Blacklist(string action, address[] addresses, string metadata);

}
