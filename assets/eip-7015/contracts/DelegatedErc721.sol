// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./EIP7015.sol";

contract DelegatedErc721 is ERC7015, ERC721, ERC721URIStorage, Ownable {
  error AlreadyMinted();
  error NotAuthorized();

  uint256 private _nextTokenId;

  bytes32 public constant TYPEHASH =
    keccak256("CreatorAttribution(string uri,uint256 nonce)");

  // mapping of signature nonce to if it has been minted
  mapping(uint256 => bool) public minted;

  constructor(
    address initialOwner
  ) EIP712("ERC7015", "1") ERC721("My Token", "TKN") Ownable(initialOwner) {}

  function delegatedSafeMint(
    address to,
    string memory uri,
    uint256 nonce,
    address creator,
    bytes calldata signature
  ) external {
    uint256 tokenId = _nextTokenId++;

    if (!isAuthorizedToCreate(creator)) revert NotAuthorized();

    // validate that the nonce has not been used
    if (minted[nonce]) revert AlreadyMinted();
    minted[nonce] = true;

    bytes32 structHash = keccak256(
      abi.encode(TYPEHASH, keccak256(bytes(uri)), nonce)
    );

    _validateSignature(structHash, creator, signature);

    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  // override required function to define if a signer is authorized to create
  function isAuthorizedToCreate(address signer) internal view returns (bool) {
    return signer == owner();
  }

  // The following functions are overrides required by Solidity.
  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
