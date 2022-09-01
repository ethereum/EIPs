// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5496 {
    event PrivilegeAssigned(uint tokenId, uint privId, address user, uint64 expires);
    event PrivilegeTransfer(uint tokenId, uint privId, address from, address to);
    event PrivilegeTotalChanged(uint newTotal, uint oldTotal);
    function setPrivilege(uint256 tokenId, uint privId, address user, uint64 expires) external;
    function privilegeExpires(uint256 tokenId, uint256 privId) external view returns(uint256);
    function hasPrivilege(uint256 tokenId, uint256 privId, address user) external view returns(bool);
}
