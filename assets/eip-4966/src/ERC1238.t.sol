// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";
import {IERC165} from "openzeppelin-contracts/utils/introspection/IERC165.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC1238} from "./interfaces/IERC1238.sol";
import {ERC1238} from "./ERC1238.sol";

contract SoulboundToken is ERC1238 {
  constructor() ERC1238("Name", "Symbol") {}

  function mint(
    string calldata uri
  ) external returns (uint256) {
    return super._mint(uri);
  }

  function burn(uint256 tokenId) external {
    super._burn(tokenId);
  }
}

contract ERC1238Test is DSTest {
  SoulboundToken sbt;

  function setUp() public {
    sbt = new SoulboundToken();
  }

  function testIERC165() public {
    assertTrue(sbt.supportsInterface(type(IERC165).interfaceId));
  }

  function testIERC721Metadata() public {
    assertTrue(sbt.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC1238() public {
    assertTrue(sbt.supportsInterface(type(IERC1238).interfaceId));
    assertEq(type(IERC1238).interfaceId, 0x0);
  }

  function testCheckMetadata() public {
    assertEq(sbt.name(), "Name");
    assertEq(sbt.symbol(), "Symbol");
  }

  function testMint() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = sbt.mint(tokenURI);
    assertEq(sbt.tokenURI(tokenId), tokenURI);
  }

  function testMintAndBurn() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = sbt.mint(tokenURI);
    assertEq(sbt.tokenURI(tokenId), tokenURI);
    assertEq(sbt.boundTo(tokenId), address(this));
    sbt.burn(tokenId);
  }

  function testFailRequestingNonExistentTokenURI() public view {
    sbt.tokenURI(1337);
  }

  function testFailGetBonderOfNonExistentTokenId() public view {
    sbt.boundTo(1337);
  }
}

