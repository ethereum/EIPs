// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Authors: Francesco Sullo <francesco@sullo.co>

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ClusteredNFT.sol";
import "./IERC7108Enumerable.sol";

//import "hardhat/console.sol";

// Reference implementation of ERC-7108

contract ClusteredNFTEnumerable is ClusteredNFT, IERC7108Enumerable, ERC721Enumerable {

  using Strings for uint256;

  constructor(string memory name, string memory symbol) ClusteredNFT(name, symbol) {}

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
  internal
  override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override( ClusteredNFT, ERC721Enumerable)
  returns (bool)
  {
    return type(IERC7108Enumerable).interfaceId == interfaceId
    || super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override(ClusteredNFT, ERC721) returns (string memory) {
    _requireMinted(tokenId);
    uint256 clusterId = _binarySearch(tokenId);
    string memory baseURI = clusters[clusterId].baseTokenURI;
    tokenId -= clusters[clusterId].firstTokenId - 1;
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function getInterfaceId() external pure virtual override returns(bytes4) {
    return type(IERC7108Enumerable).interfaceId;
  }

  // enumerable part

  function balanceOfWithin(address owner, uint256 clusterId) external view  override returns(uint) {
    uint256 balance = balanceOf(owner);
    if (balance != 0)  {
      uint result = 0;
      (uint256 start, uint end) = rangeOf(clusterId);
      for (uint256 i = 0; i < balance; i++) {
        uint256 tokenId = tokenOfOwnerByIndex(owner, i);
        if (tokenId >= start && tokenId <= end) {
          result++;
        }
      }
      balance = result;
    }
    return balance;
  }
}
