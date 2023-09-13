// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

// based on open zeppelin implementation - allows verifying signatures intended for other chains
abstract contract GenericEIP712 {
  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;

  bytes32 private immutable _HASHED_NAME;
  bytes32 private immutable _HASHED_VERSION;
  bytes32 private immutable _TYPE_HASH;

  constructor(string memory name, string memory version) {
    bytes32 hashedName = keccak256(bytes(name));
    bytes32 hashedVersion = keccak256(bytes(version));
    bytes32 typeHash = keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    _HASHED_NAME = hashedName;
    _HASHED_VERSION = hashedVersion;
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
      typeHash,
      hashedName,
      hashedVersion,
      block.chainid,
      address(this)
    );
    _CACHED_THIS = address(this);
    _TYPE_HASH = typeHash;
  }

  function _domainSeparatorV4(uint256 chainId, address implementation) internal view returns (bytes32) {
    // return the cached domain separator for the original chain
    if (implementation == _CACHED_THIS && chainId == _CACHED_CHAIN_ID) {
      return _CACHED_DOMAIN_SEPARATOR;
    } else {
      // build a domain separator for another chain
      return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, chainId, implementation);
    }
  }

  function _buildDomainSeparator(
    bytes32 typeHash,
    bytes32 nameHash,
    bytes32 versionHash,
    uint256 chainId,
    address implementation
  ) private view returns (bytes32) {
    return keccak256(abi.encode(typeHash, nameHash, versionHash, chainId, implementation));
  }

  function _hashTypedDataV4(bytes32 structHash, uint256 chainId, address implementation)
    internal
    view
    virtual
    returns (bytes32)
  {
    return ECDSA.toTypedDataHash(_domainSeparatorV4(chainId, implementation), structHash);
  }
}
