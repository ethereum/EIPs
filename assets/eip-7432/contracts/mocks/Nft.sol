// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

contract Nft is ERC721 {
  using Strings for uint256;
 
  constructor() ERC721('Nft', 'NFT') {}

  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }

  function tokenURI(uint256 tokenId) public pure override returns (string memory) {
      return string(abi.encodePacked('https://example.com/', tokenId.toString()));
  }
}
