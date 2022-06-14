// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
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
}

contract NonAuthorizedCaller {
  function burn(address collection, uint256 tokenId) external {
    AccountBoundToken abt = AccountBoundToken(collection);
    abt.burn(tokenId);
  }
}

contract ERC4973Test is Test {
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
    address to = address(this);
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    abt.burn(tokenId);
  }

  function testBurnAsNonAuthorizedAccount() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    address to = address(this);
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    assertEq(abt.tokenURI(tokenId), tokenURI);

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("burn: sender must be owner"));

    nac.burn(address(abt), tokenId);
  }

  function testBurnNonExistentTokenId() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    address to = address(this);
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    assertEq(abt.tokenURI(tokenId), tokenURI);

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("ownerOf: token doesn't exist"));

    nac.burn(address(abt), 1337);
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

