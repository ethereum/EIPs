// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {ERC165} from "openzeppelin-contracts/utils/introspection/ERC165.sol";
import {Counters} from "openzeppelin-contracts/utils/Counters.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";


abstract contract ERC4973 is ERC165, IERC721Metadata, IERC4973 {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _bonds;
  mapping(uint256 => string) private _tokenURIs;

  constructor(
    string memory name_,
    string memory symbol_
  ) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _bonds[tokenId] != address(0);
  }

  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = _bonds[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function _mint(
    string calldata uri
  ) internal virtual returns (uint256) {
    uint256 tokenId = _tokenIds.current();
    _bonds[tokenId] = msg.sender;
    _tokenURIs[tokenId] = uri;
    _tokenIds.increment();
    emit Transfer(address(0), msg.sender, tokenId);
    return tokenId;
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner  = ownerOf(tokenId);

    delete _bonds[tokenId];
    delete _tokenURIs[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }
}
