// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IMFNFT {
    function transfer(address to, uint256 tokenId, uint256 value) external returns (bool);

    function approve(address spender, uint256 tokenId, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 tokenId, uint256 value) external returns (bool);

    function totalSupply(uint256 tokenId) external view returns (uint256);

    function balanceOf(address who, uint256 tokenId) external view returns (uint256);

    function allowance(address owner, address spender, uint256 tokenId) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 tokenId, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 tokenId, uint256 value);
}