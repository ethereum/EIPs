// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "./IDomain.sol";

/// @title          ERC-4835 Heirarchal Domains Standard (Enumerable Extension)
/// @author         Pandapip1
/// @dev            https://eips.ethereum.org/EIPS/eip-4835
interface IDomainEnumerable is IDomain {
    /// @notice     Query all subdomains. Must revert if the number of domains is unknown or infinite.
    /// @return     The subdomain with the given index.
    function subdomainByIndex(uint256 index) external view returns (string memory);
    
    /// @notice     Get the total number of subdomains. Must revert if the number of domains is unknown or infinite.
    /// @return     The total number of subdomains
    function totalSubdomains() external view returns (uint256);
}
