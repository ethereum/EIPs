// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/// @title          ERC-165 Standard Interface Detection
/// @dev            See https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice     Query if a contract implements an interface
    /// @param      interfaceID The interface identifier, as specified in ERC-165
    /// @dev        Interface identification is specified in ERC-165. This function
    ///             uses less than 30,000 gas.
    /// @return     `true` if the contract implements `interfaceID` and
    ///             `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title          ERC-4835 Heirarchal Domains Standard
/// @author         Pandapip1
/// @dev            https://eips.ethereum.org/EIPS/eip-4835
///                 The ERC-165 identifier for this interface is 0x12E2.
interface IDomain is IERC165 {
    //// CRUD

    /// @notice     Query if a domain has a subdomain with a given name
    /// @param      name The subdomain to query
    /// @return     `true` if the domain has a subdomain with the given name, `false` otherwise
    function hasDomain(string memory name) external view returns (bool);

    /// @notice     Fetch the subdomain with a given name
    /// @dev        This should revert is `hasDomain(name)` is `false`
    /// @param      name The subdomain to fetch
    /// @return     The subdomain with the given name
    function getDomain(string memory name) external view returns (IDomain);
    
    /// @notice     Update a subdomain with a given name
    /// @dev        This should revert if `canSetDomain(msg.sender, name, pointer)` is `false`
    /// @param      name The subdomain name to be created/updated
    /// @param      subdomain The subdomain to set
    function setDomain(string memory name, IDomain subdomain) external;

    /// @notice     Delete the subdomain with a given name
    /// @dev        This should revert is `hasDomain(name)` is `false` or if
    ///             `canDeleteDomain(msg.sender, name, this)` is `false`
    /// @param      name The subdomain to delete
    function deleteDomain(string memory name) external;


    //// Access Control

    /// @notice     Get if an account can update or create a subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `hasDomain(name)` is `true`
    ///             and `getDomain(name).canUpdateSubdomain(msg.sender, this, subdomain)` is `false`,
    ///             or if `subdomain.canPointSubdomain(msg.sender, name, this) is `false`
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canSetDomain(address updater, string memory name, IDomain subdomain) external view returns (bool);
    
    /// @notice     Get if an account can move the subdomain away from the current domain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @param      newSubdomain The domain that will be set next
    /// @return     Whether an account can update the subdomain
    function canSetSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) external view returns (bool);

    /// @notice     Get if an account can point this domain as a subdomain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @return     Whether an account can update the subdomain
    function canPointSubdomain(address updater, string memory name, IDomain parent) external view returns (bool);

    /// @notice     Get if an account can delete the subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `hasDomain(name)` is `true` and
    ///             `getDomain(name).canDeleteSubdomain(msg.sender, name, this)` is `false`
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @return     Whether an account can delete the subdomain
    function canDeleteDomain(address updater, string memory name) external view returns (bool);
    
    /// @notice     Get if an account can point this domain as a subdomain
    /// @dev        May be called by `canDeleteDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @param      parent The parent domain
    /// @return     Whether an account can delete the subdomain
    function canDeleteSubdomain(address updater, string memory name, IDomain parent) external view returns (bool);
}
