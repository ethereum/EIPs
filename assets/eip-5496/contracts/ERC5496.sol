// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC5496.sol";

contract ERC5496 is ERC721, IERC5496 {
    struct PrivilegeRecord {
        address user;
        uint256 expiresAt;
    }
    struct PrivilegeStorage {
        uint lastExpiresAt;
        // privId => PrivilegeRecord
        mapping(uint => PrivilegeRecord) privilegeEntry;
    }

    uint public privilegeTotal;
    // tokenId => PrivilegeStorage
    mapping(uint => PrivilegeStorage) public privilegeBook;
    mapping(address => mapping(address => bool)) private privilegeDelegator;

    constructor(string memory name_, string memory symbol_)
    ERC721(name_,symbol_)
    {
    
    }

    function setPrivilege(
        uint tokenId,
        uint privId,
        address user,
        uint64 expires
    ) external virtual {
        require((hasPrivilege(tokenId, privId, ownerOf(tokenId)) && _isApprovedOrOwner(msg.sender, tokenId)) || _isDelegatorOrHolder(msg.sender, tokenId, privId), "ERC721: transfer caller is not owner nor approved");
        require(expires < block.timestamp + 30 days, "expire time invalid");
        require(privId < privilegeTotal, "invalid privilege id");
        privilegeBook[tokenId].privilegeEntry[privId].user = user;
        if (_isApprovedOrOwner(msg.sender, tokenId)) {
            privilegeBook[tokenId].privilegeEntry[privId].expiresAt = expires;
            if (privilegeBook[tokenId].lastExpiresAt < expires) {
                privilegeBook[tokenId].lastExpiresAt = expires;
            }
        }
        emit PrivilegeAssigned(tokenId, privId, user, uint64(privilegeBook[tokenId].privilegeEntry[privId].expiresAt));
    }

    function hasPrivilege(
        uint256 tokenId,
        uint256 privId,
        address user
    ) public virtual view returns(bool) {
        if ( privilegeBook[tokenId].privilegeEntry[privId].expiresAt >=  block.timestamp ){
            return privilegeBook[tokenId].privilegeEntry[privId].user == user;
        }
        return ownerOf(tokenId) == user;
    }

    function privilegeExpires(
        uint256 tokenId,
        uint256 privId
    ) public virtual view returns(uint256){
        return privilegeBook[tokenId].privilegeEntry[privId].expiresAt;
    }

    function _setPrivilegeTotal(
        uint total
    ) internal {
        emit PrivilegeTotalChanged(total, privilegeTotal);
        privilegeTotal = total;
    }

    function getPrivilegeInfo(uint tokenId, uint privId) external view returns(address user, uint256 expiresAt) {
        return (privilegeBook[tokenId].privilegeEntry[privId].user, privilegeBook[tokenId].privilegeEntry[privId].expiresAt);
    }

    function setDelegator(address delegator, bool enabled) external {
        privilegeDelegator[msg.sender][delegator] = enabled;
    }

    function _isDelegatorOrHolder(address delegator, uint256 tokenId, uint privId) internal virtual view returns (bool) {
        address holder = privilegeBook[tokenId].privilegeEntry[privId].user;
        return (delegator == holder || privilegeDelegator[holder][delegator]);
    }

    function supportsInterface(bytes4 interfaceId) public override virtual view returns (bool) {
        return interfaceId == type(IERC5496).interfaceId || super.supportsInterface(interfaceId);
    }
}
