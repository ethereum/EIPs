// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {IERC165} from "./interfaces/IERC165.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";
import {ERC4973} from "./ERC4973.sol";

contract AccountBoundToken is ERC4973 {
  constructor() ERC4973("Name", "Symbol") {}

  function mint(
    address to,
    uint256 tokenId,
    string calldata uri
  ) external returns (uint256) {
    return super._mint(to, tokenId, uri);
  }

  function burn(uint256 tokenId) external {
    super._burn(tokenId);
  }
}

contract ERC4973Test is DSTest {
  AccountBoundToken abt;

  function setUp() public {
    abt = new AccountBoundToken();
  }

  function testIERC165() public {
    assertTrue(abt.supportsInterface(type(IERC165).interfaceId));
  }

  function testIERC721Metadata() public {
    assertTrue(abt.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC4973() public {
    assertTrue(abt.supportsInterface(type(IERC4973).interfaceId));
  }

  function testCheckMetadata() public {
    assertEq(abt.name(), "Name");
    assertEq(abt.symbol(), "Symbol");
  }

  function testMint() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(msg.sender, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), msg.sender);
  }

  function testMintToExternalAddress() public {
    address thirdparty = address(1337);
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(thirdparty, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), thirdparty);
  }

  function testMintAndBurn() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(msg.sender, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), msg.sender);
    abt.burn(tokenId);
  }

  function testFailToMintTokenToPreexistingTokenId() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(msg.sender, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), msg.sender);
    abt.mint(msg.sender, tokenId, tokenURI);
  }

  function testFailRequestingNonExistentTokenURI() public view {
    abt.tokenURI(1337);
  }

  function testFailGetBonderOfNonExistentTokenId() public view {
    abt.ownerOf(1337);
  }
}

