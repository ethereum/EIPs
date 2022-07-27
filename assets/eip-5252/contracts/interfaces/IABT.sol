// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IABT {
    function mint(address to) external;
    function burn(uint256 tokenId_) external;
    function burnFromVault(uint vaultId_) external;
    function exists(uint256 tokenId_) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}