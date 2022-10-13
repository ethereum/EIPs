// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * Contract that exposes the needed erc20 token functions
 */

abstract contract IERC721 {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenaId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) public virtual view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);

    function approve(address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId)
    public virtual view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;
    function isApprovedForAll(address owner, address operator)
    public virtual view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;


}