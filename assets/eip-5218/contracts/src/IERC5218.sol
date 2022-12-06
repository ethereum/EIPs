// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title EIP-5218: NFT Rights Management
interface IERC5218 is IERC721 {

  /// @dev This emits when a new license is created by any mechanism.
  event CreateLicense(uint256 _licenseId, uint256 _tokenId, uint256 _parentLicenseId, address _licenseHolder, string _uri, address _revoker);
 
  /// @dev This emits when a license is revoked. Note that under some
  ///  license terms, the sublicenses may be `implicitly` revoked following the
  ///  revocation of some ancestral license. In that case, your smart contract
  ///  may only emit this event once for the ancestral license, and the revocation
  ///  of all its sublicenses can be implied without consuming additional gas.
  event RevokeLicense(uint256 _licenseId);
 
  /// @dev This emits when the a license is transferred to a new holder. The
  ///  root license of an NFT should be transferred with the NFT in an ERC721
  ///  `transfer` function call. 
  event TransferLicense(uint256 _licenseId, address _licenseHolder);
  
  /// @notice Check if a license is active.
  /// @dev A non-existing or revoked license is inactive and this function must
  ///  return `false` upon it. Under some license terms, a license may become
  ///  inactive because some ancestral license has been revoked. In that case,
  ///  this function should return `false`.
  /// @param _licenseId The identifier for the queried license
  /// @return Whether the queried license is active
  function isLicenseActive(uint256 _licenseId) external view returns (bool);

  /// @notice Retrieve the token identifier a license was issued upon.
  /// @dev Throws unless the license is active.
  /// @param _licenseId The identifier for the queried license
  /// @return The token identifier the queried license was issued upon
  function getLicenseTokenId(uint256 _licenseId) external view returns (uint256);

  /// @notice Retrieve the parent license identifier of a license.
  /// @dev Throws unless the license is active. If a license doesn't have a
  ///  parent license, return a special identifier not referring to any license 
  ///  (such as 0).
  /// @param _licenseId The identifier for the queried license
  /// @return The parent license identifier of the queried license
  function getParentLicenseId(uint256 _licenseId) external view returns (uint256);

  /// @notice Retrieve the holder of a license.
  /// @dev Throws unless the license is active.   
  /// @param _licenseId The identifier for the queried license
  /// @return The holder address of the queried license
  function getLicenseHolder(uint256 _licenseId) external view returns (address);

  /// @notice Retrieve the URI of a license.
  /// @dev Throws unless the license is active.   
  /// @param _licenseId The identifier for the queried license
  /// @return The URI of the queried license
  function getLicenseURI(uint256 _licenseId) external view returns (string memory);

  /// @notice Retrieve the revoker address of a license.
  /// @dev Throws unless the license is active.   
  /// @param _licenseId The identifier for the queried license
  /// @return The revoker address of the queried license
  function getLicenseRevoker(uint256 _licenseId) external view returns (address);

  /// @notice Retrieve the root license identifier of an NFT.
  /// @dev Throws unless the queried NFT exists. If the NFT doesn't have a root
  ///  license tethered to it, return a special identifier not referring to any
  ///  license (such as 0).   
  /// @param _tokenId The identifier for the queried NFT
  /// @return The root license identifier of the queried NFT
  function getLicenseIdByTokenId(uint256 _tokenId) external view returns (uint256);
  
  /// @notice Create a new license.
  /// @dev Throws unless the NFT `_tokenId` exists. Throws unless the parent
  ///  license `_parentLicenseId` is active, or `_parentLicenseId` is a special
  ///  identifier not referring to any license (such as 0) and the NFT
  ///  `_tokenId` doesn't have a root license tethered to it. Throws unless the
  ///  message sender is eligible to create the license, i.e., either the
  ///  license to be created is a root license and `msg.sender` is the NFT owner,
  ///  or the license to be created is a sublicense and `msg.sender` is the holder
  ///  of the parent license. 
  /// @param _tokenId The identifier for the NFT the license is issued upon
  /// @param _parentLicenseId The identifier for the parent license
  /// @param _licenseHolder The address of the license holder
  /// @param _uri The URI of the license terms
  /// @param _revoker The revoker address
  /// @return The identifier of the created license
  function createLicense(uint256 _tokenId, uint256 _parentLicenseId, address _licenseHolder, string memory _uri, address _revoker) external returns (uint256);

  /// @notice Revoke a license.
  /// @dev Throws unless the license is active and the message sender is the
  ///  eligible revoker. This function should be used for revoking both root
  ///  licenses and sublicenses. Note that if a root license is revoked, the
  ///  NFT should be transferred back to its creator.
  /// @param _licenseId The identifier for the queried license
  function revokeLicense(uint256 _licenseId) external;
  
  /// @notice Transfer a sublicense.
  /// @dev Throws unless the sublicense is active and `msg.sender` is the license
  ///  holder. Note that the root license of an NFT should be tethered to and
  ///  transferred with the NFT. Whenever an NFT is transferred by calling the
  ///  ERC721 `transfer` function, the holder of the root license should be
  ///  changed to the new NFT owner.
  /// @param _licenseId The identifier for the queried license
  /// @param _licenseHolder The new license holder
  function transferSublicense(uint256 _licenseId, address _licenseHolder) external;
}

