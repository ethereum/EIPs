// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "./interface/IERCX.sol";

/// @title cryptosharing
/// @author Kimos
/// @notice cryptosharing

contract ERCX is IERCX , ERC721 {
    
    // Mapping from tokenId to user address
    mapping(uint256 => address) private _users;

    // Mapping user address to token usable count
    mapping(address => uint256) private _balancesOfUser;
    
     // Mapping from tokenId to approved address
    mapping(uint256 => address) private _tokenUserApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_ , symbol_){
        
    }
    
    /*
     *@dev see{IERCX-approveUser}
     */
    function approveUser(address to, uint256 tokenId) public virtual override{
        address user = ERCX.userOf(tokenId);
        require(to != user, "ERCX: approval to current user");

        require(
            _isApprovedOrUser(_msgSender(), tokenId),
            "ERCX: approve caller is not user"
        );

        _approveUser(to, tokenId);
    }
    
    /**
     * @dev Approve `to` to operate on `tokenId` tokenUser.
     *
     * Emits a {ApprovalUser} event.
     */
    function _approveUser(address to, uint256 tokenId) internal virtual {
        _tokenUserApprovals[tokenId] = to;
        emit ApprovalUser(ERC721.ownerOf(tokenId), to, tokenId);
    }
    
    /*
     *@dev see{IERCX-getApprovedUser}
     */
    function getApprovedUser(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERCX: approved query for nonexistent token");

        return _tokenUserApprovals[tokenId];
    }
    
    /*
     *@dev see{IERCX-balanceOfUser}
     */
    function balanceOfUser(address user) public view virtual override returns (uint256) {
        require(user != address(0), "ERCX: balance query for the zero address");
        return _balancesOfUser[user];
    }
    
    /*
     *@dev see{IERCX-userOf}
     */
    function userOf(uint256 tokenId) public view virtual override returns (address) {
        address user = _users[tokenId];
        require(user != address(0), "ERCX: user query for nonexistent token");
        return user;
    }
    
    /*
     *@dev see{IERCX-safeTranserUserFrom}
     */
    function safeTransferUserFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferUserFrom(from, to, tokenId, "");
    }
    
    /*
     *@dev see{IERCX-safeTransferUserFrom}
     */
    function safeTransferUserFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrUser(_msgSender(), tokenId) || _isApprovedOrOwner(_msgSender(),tokenId), "ERCX: transfer caller is not user or owner nor approved");
        _safeTransferUser(from, to, tokenId, _data);
    }

    /*
     *@dev see{IERCX-safeTransfferAllFrom}
     */
    function safeTransferAllFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferAllFrom(from, to, tokenId, "");
    }
    
    /*
     *@dev see{IERCX-safeTransferAllFrom}
     */
    function safeTransferAllFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(),tokenId),"ERCX: transfer caller is not owner nor approved");
        safeTransferUserFrom(from, to, tokenId, "");
        safeTransferFrom(from, to, tokenId, "");
    }
    
    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId` tokenUser.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrUser(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(ERC721._exists(tokenId), "ERCX: operator query for nonexistent token");
        address user = ERCX.userOf(tokenId);
        return (spender == user || spender == getApprovedUser(tokenId) );
    }
    
    /**
     * @dev Safely transfers `tokenId` tokenUser from `from` to `to`
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be used or owned by 'from' 
     *
     * Emits a {TransferUser} event.
     */
    function _safeTransferUser(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transferUser(from, to, tokenId);
    }
    
    /**
     * @dev Transfers `tokenId` tokenUser from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be used or owned by 'from' 
     *
     * Emits a {TransferUser} event.
     */
    function _transferUser(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERCX.userOf(tokenId) == from || ERC721.ownerOf(tokenId) == from, "ERCX: transfer of token that is not use");
        require(to != address(0), "ERCX: transfer to the zero address");
        address user = userOf(tokenId);
        _beforeTokenTransferUser(user, to, tokenId);

        // Clear approvals from the previous owner
        _approveUser(address(0), tokenId);
        
        _balancesOfUser[user] -= 1;
        _balancesOfUser[to] += 1;
        _users[tokenId] = to;

        emit TransferUser(from, to, tokenId);
    }
    
    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} and a {TransferUser} event.
     */
    function _safeMint(address to , uint256 tokenId) internal virtual override{
        require(to != address(0), "ERCX: mint to the zero address");

        _beforeTokenTransferUser(address(0), to, tokenId);

        _balancesOfUser[to] += 1;
        _users[tokenId] = to;
        super._safeMint(to,tokenId);
        emit TransferUser(address(0), to, tokenId);
    }
    
    /**
     * @dev Destroys `tokenId` token and its use right.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {TransferUser} and a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override{
        super._burn();

        address user = userOf(tokenId);

        _beforeTokenTransferUser(user, address(0), tokenId);
        // Clear approvals
        _approveUser(address(0), tokenId);

        _balancesOfUser[user] -= 1;
        delete _users[tokenId];

        emit TransferUser(user, address(0), tokenId);
    }

    /**
     * @dev Hook that is called before any tokenUser transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` token use right will be
     * transferred to `to`.
     *
     */
    function _beforeTokenTransferUser(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    
}
