// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5218.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract RightsManagement is IERC5218, ERC721URIStorage, Ownable {
  struct License {
    bool active; // whether the current license is active
    uint256 tokenId;
    uint256 parentLicenseId;
    address licenseHolder;
    string uri;
    address revoker;
  }
  mapping(uint256 => License) private _licenses;
  mapping(uint256 => uint256) private _licenseIds;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenCounter;
  Counters.Counter private _licenseCounter;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
    return
      interfaceId == type(IERC5218).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function isLicenseActive(uint256 licenseId) public view virtual override(IERC5218) returns (bool) {
    if (licenseId == 0) return false;
    while (licenseId != 0) {
      if (!_licenses[licenseId].active) return false;
      licenseId = _licenses[licenseId].parentLicenseId;
    }
    return true;
  }

  modifier isActiveLicense(uint256 licenseId) {
    require(isLicenseActive(licenseId), "The queried license is not active");
    _;
  }

  function getLicenseTokenId(uint256 licenseId) public view virtual override(IERC5218) isActiveLicense(licenseId) returns (uint256) {
    return _licenses[licenseId].tokenId;   
  }

  function getParentLicenseId(uint256 licenseId) public view virtual override(IERC5218) isActiveLicense(licenseId) returns (uint256) {        
    return _licenses[licenseId].parentLicenseId;
  }

  function getLicenseHolder(uint256 licenseId) public view virtual override(IERC5218) isActiveLicense(licenseId) returns (address) {
    return _licenses[licenseId].licenseHolder;
  }

  function getLicenseURI(uint256 licenseId) public view virtual override(IERC5218) isActiveLicense(licenseId) returns (string memory) {
    return _licenses[licenseId].uri;
  }

  function getLicenseRevoker(uint256 licenseId) public view virtual override(IERC5218) isActiveLicense(licenseId) returns (address) {
    return _licenses[licenseId].revoker;
  }

  function getLicenseIdByTokenId(uint256 tokenId) public view virtual override(IERC5218) returns (uint256) {
    require (_exists(tokenId), "The token doesn't exist");
    return _licenseIds[tokenId];
  }

  function safeMint(
    address recipient,
    string memory tokenURI,
    string memory licenseURI,
    address licenseRevoker
  ) 
    public virtual onlyOwner
    returns (uint256)
  {
    return safeMint(recipient, tokenURI, licenseURI, licenseRevoker, "");
  }

  function safeMint(
    address recipient,
    string memory tokenURI,
    string memory licenseURI,
    address licenseRevoker,
    bytes memory _data
  )
    public virtual onlyOwner
    returns (uint256)
  {
    _tokenCounter.increment();
    uint256 newItemId = _tokenCounter.current();

    _safeMint(recipient, newItemId, _data);
    _setTokenURI(newItemId, tokenURI);
    _createLicense(newItemId, 0, recipient, licenseURI, licenseRevoker);

    return newItemId;
  }

  function safeIssue(
    address recipient,
    uint256 tokenId,
    string memory licenseURI,
    address licenseRevoker
  )
    public virtual
    returns (uint256)
  {
    return safeIssue(recipient, tokenId, licenseURI, licenseRevoker, "");
  }

  function safeIssue(
    address recipient,
    uint256 tokenId,
    string memory licenseURI,
    address licenseRevoker,
    bytes memory data
  )
    public virtual
    returns (uint256)
  {
    require(_licenseIds[tokenId] == 0, "The token has an active license");
    require(ownerOf(tokenId) == owner(), "The creator doesn't own the NFT");

    uint256 licenseId = createLicense(tokenId, 0, owner(), licenseURI, licenseRevoker);
    safeTransferFrom(owner(), recipient, tokenId, data);

    return licenseId;
  }

  function createLicense(
    uint256 tokenId,
    uint256 parentLicenseId,
    address licenseHolder,
    string memory uri,
    address revoker
  ) 
    public virtual override(IERC5218)
    returns (uint256)
  {
    require(_exists(tokenId), "The NFT doesn't exists");
    require(parentLicenseId == 0 || isLicenseActive(parentLicenseId), "The parent license is not active");
    require(parentLicenseId != 0 || getLicenseIdByTokenId(tokenId) == 0, "The NFT already has a root license");
    require(
        (parentLicenseId == 0 && msg.sender == owner()) || 
        (parentLicenseId != 0 && msg.sender == _licenses[parentLicenseId].licenseHolder),
        "Sender is not eligible to grant a new license"
        );

    return _createLicense(tokenId, parentLicenseId, licenseHolder, uri, revoker);
  }

  function revokeLicense(uint256 licenseId) public virtual override(IERC5218) {
    require(isLicenseActive(licenseId), "The license is not active");
    require(msg.sender == _licenses[licenseId].revoker, "The msg sender is not an eligible revoker");

    if (_licenses[licenseId].parentLicenseId == 0) {
      _transfer(ownerOf(_licenses[licenseId].tokenId), owner(), _licenses[licenseId].tokenId);
    }

    _revokeLicense(licenseId);
  }

  function transferSublicense(uint256 licenseId, address licenseHolder) public virtual override(IERC5218) {
    require(isLicenseActive(licenseId), "The license is not active");
    require(_licenses[licenseId].parentLicenseId != 0, "The license is a root license");
    require(msg.sender == _licenses[licenseId].licenseHolder, "The msg sender is not the license holder");

    _updateLicenseHolder(licenseId, licenseHolder);
  }
  
  function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
    require(_licenseIds[tokenId] != 0 && isLicenseActive(_licenseIds[tokenId]), "The token has no active license tethered to it");
    require(_licenses[_licenseIds[tokenId]].licenseHolder == ownerOf(tokenId), "The license holder and the NFT owner are inconsistent");

    super._transfer(from, to, tokenId);
    _updateLicenseHolder(_licenseIds[tokenId], to);
  }

  function _updateLicenseHolder(uint256 licenseId, address licenseHolder) internal virtual {
    _licenses[licenseId].licenseHolder = licenseHolder;
    emit TransferLicense(licenseId, licenseHolder);
  }

  function _createLicense(
    uint256 tokenId,
    uint256 parentLicenseId,
    address licenseHolder,
    string memory uri,
    address revoker
  )
    internal virtual
    returns (uint256)
  {
    _licenseCounter.increment();
    uint256 licenseId = _licenseCounter.current();

    _licenses[licenseId].active = true;
    _licenses[licenseId].tokenId = tokenId;
    _licenses[licenseId].parentLicenseId = parentLicenseId; // tyler: it seems like a security problem that children are able to overwrite their parents
    _licenses[licenseId].licenseHolder = licenseHolder;
    _licenses[licenseId].uri = uri;
    _licenses[licenseId].revoker = revoker;

    if (parentLicenseId == 0) {
      _licenseIds[tokenId] = licenseId;
    }

    emit CreateLicense(licenseId, tokenId, parentLicenseId, licenseHolder, uri, revoker);
    return licenseId;
  }

  function _revokeLicense(uint256 licenseId) internal virtual {
    if (_licenses[licenseId].parentLicenseId == 0) {
      _licenseIds[_licenses[licenseId].tokenId] = 0;
    }

    delete _licenses[licenseId];

    emit RevokeLicense(licenseId);
  }
}



