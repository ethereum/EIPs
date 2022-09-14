// SPDX-License-Identifier: CC0-1.0
// EPSProxy Contracts v1.8.0 (epsproxy/contracts/examples/EPSExample721.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@epsproxy/contracts/Proxiable.sol";

contract EPSExample721 is ERC721, ERC721Burnable, Ownable, Proxiable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;
  bool hasMinted;

  mapping (address => bool) minterHasMinted;
  uint256 constant MAX_SUPPLY = 10000;

  constructor(address _epsRegisterAddress) 
    ERC721("EPSExample721", "EPS721") 
    Proxiable(_epsRegisterAddress) {
  }

  /** 
  * @dev This address hasn't minted already
  */ 
  modifier hasNotAlreadyMinted(address _receivedAddress) {
    require(minterHasMinted[_receivedAddress] != true, "Address has already minted, allocation exhausted");
    _;
  }

  modifier isProxyAddress(address _receivedAddress) {
    require(proxyRecordExists(_receivedAddress), "Only a proxy address can mint this token - go to app.epsproxy.com");
    _;
  }

  modifier supplyNotExhausted() {
    require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached - cannot be minted");
    _;
  }

  function _baseURI() internal pure override returns (string memory) {
      return "https://epsproxy.com/test/";
  }

  function totalSupply() public pure returns (uint256) {
    return (MAX_SUPPLY);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  function proxyMint() external hasNotAlreadyMinted(msg.sender) isProxyAddress(msg.sender) supplyNotExhausted() {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMintProxied(msg.sender, tokenId);
    minterHasMinted[msg.sender] = true; 
  }

  function _burn(uint256 tokenId) internal override(ERC721) {
    super._burn(tokenId);
  }

  /**
  * @dev call safemint after determining the delivery address.
  */
  function _safeMintProxied(address _to, uint256 _tokenId) internal virtual {
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_to);
    _safeMint(delivery, _tokenId);
  }

  /**
  * @dev call safemint after determining the delivery address IF we have been passed a bool indicating
  * that a proxied address is in use. This function should be used in conjunction with an off-chain call
  * to _proxyRecordExists that determines if a proxy address is in use. This saves gas for anyone who is
  * NOT using a proxy as we do not needlessly check for proxy details.
  */
  function safeMintProxiedSwitch(address _to, uint256 _tokenId, bool _isProxied) internal virtual {
    if (_isProxied) {
      _safeMintProxied(_to, _tokenId);
    }
    else {
      _safeMint(_to, _tokenId);
    }
  }
}