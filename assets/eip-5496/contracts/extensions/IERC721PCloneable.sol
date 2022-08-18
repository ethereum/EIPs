// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC721PCloneable {
    event PrivilegeCloned(uint tokenId, uint privId, address from, address to);
    function clonePrivilege(uint tokenId, uint privId, address referrer) external returns (bool);
}