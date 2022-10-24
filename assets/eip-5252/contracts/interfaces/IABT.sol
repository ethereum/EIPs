// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IABT {
    function mint(address to) external;
    function burn(uint256 tokenId_) external;
    function exists(uint256 tokenId_) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function factory() external view returns (address factory);
}
