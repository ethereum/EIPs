// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {IERC165} from "openzeppelin-contracts/utils/introspection/IERC165.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";
import {ERC4973} from "./ERC4973.sol";

contract AccountboundToken is ERC4973 {
  constructor() ERC4973("Name", "Symbol") {}

  function mint(
    string calldata uri
  ) external returns (uint256) {
    return super._mint(uri);
  }

  function burn(uint256 tokenId) external {
    super._burn(tokenId);
  }
}

contract ERC4973Test is DSTest {
  AccountboundToken abt;

  function setUp() public {
    abt = new AccountboundToken();
  }

  function testIERC165() public {
    assertTrue(abt.supportsInterface(type(IERC165).interfaceId));
  }

  function testIERC721Metadata() public {
    assertTrue(abt.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC4973() public {
    assertTrue(abt.supportsInterface(type(IERC4973).interfaceId));
    assertEq(type(IERC4973).interfaceId, 0x0);
  }

  function testCheckMetadata() public {
    assertEq(abt.name(), "Name");
    assertEq(abt.symbol(), "Symbol");
  }

  function testMint() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = abt.mint(tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
  }

  function testMintAndBurn() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = abt.mint(tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), address(this));
    abt.burn(tokenId);
  }

  function testFailRequestingNonExistentTokenURI() public view {
    abt.tokenURI(1337);
  }

  function testFailGetBonderOfNonExistentTokenId() public view {
    abt.ownerOf(1337);
  }
}

