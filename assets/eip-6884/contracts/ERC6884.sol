// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC6884 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Delegated(address indexed from, address indexed to, uint256 indexed tokenId, uint256 duration);
    event Regained(uint256 indexed tokenId);
    event Restored(uint256 indexed tokenId);

    mapping(uint256 => address) private _users;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    address private _origin;
    mapping(uint256 => uint256) private _expirations;

    function origin() public view returns (address) {
        return _origin;
    }

    function expiration(uint256 tokenId) public view returns (uint256) {
        return _expirations[tokenId];
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return IERC721(_origin).balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return IERC721(_origin).ownerOf(tokenId);
    }

    function userOf(uint256 tokenId) public view virtual returns (address) {
        return _expirations[tokenId] == 0 ? ownerOf(tokenId) : _users[tokenId];
    }

    constructor(address origin_) {
        require(
            IERC721(origin_).supportsInterface(type(IERC721).interfaceId),
            "ERC6884: INVALID_ERC721"
        );
        _origin = origin_;
    }

    function approve(address spender, uint256 tokenId) public virtual {
        address user = userOf(tokenId);
        require(
            msg.sender == user || _operatorApprovals[user][msg.sender],
            "ERC6884: NOT_AUTHORIZED"
        );

        _tokenApprovals[tokenId] = spender;
        emit Approval(user, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function delegate(address to, uint256 tokenId, uint256 duration) public virtual {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
            _operatorApprovals[owner][msg.sender] ||
            _tokenApprovals[tokenId] == msg.sender,
            "ERC6884: NOT_AUTHORIZED"
        );

        _transfer(owner, to, tokenId);

        uint256 expiration_ = block.timestamp + duration;
        _expirations[tokenId] = expiration_;
        emit Delegated(owner, to, tokenId, duration);
    }

    function regain(uint256 tokenId) public virtual {
        require(_expirations[tokenId] != 0, "ERC6884: NOT_REGAINABLE");
        require(_expirations[tokenId] < block.timestamp, "ERC6884: NOT_EXPIRED");

        address user = userOf(tokenId);
        address owner = ownerOf(tokenId);
        _transfer(user, owner, tokenId);

        delete _expirations[tokenId];
        emit Regained(tokenId);
    }

    function restore(uint256 tokenId) public virtual {
        address user = userOf(tokenId);
        require(
            msg.sender == user ||
            _operatorApprovals[user][msg.sender] ||
            _tokenApprovals[tokenId] == msg.sender,
            "ERC6884: NOT_AUTHORIZED"
        );

        address owner = ownerOf(tokenId);
        _transfer(user, owner, tokenId);

        delete _expirations[tokenId];
        emit Restored(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(userOf(tokenId) == from, "ERC6884: INVALID_SENDER");
        require(to != address(0), "ERC6884: ZERO_ADDRESS");

        delete _tokenApprovals[tokenId];

        _users[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
}