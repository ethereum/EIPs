// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract ERC7015 is EIP712 {
  error Invalid_Signature();
  event CreatorAttribution(
    bytes32 structHash,
    string domainName,
    string version,
    address creator,
    bytes signature
  );

  function _validateSignature(
    bytes32 structHash,
    bytes memory signature
  ) internal {
    // recover the signer from the provided signature
    address signer = _recoverSigner(structHash, signature);
    // ensure the signer is authorized to create signatures.
    // this is contract specific and should be implemented by the contract
    // inheriting this one
    if (!isAuthorizedToCreate(signer)) revert Invalid_Signature();

    // emit the CreatorAttribution event
    emit CreatorAttribution(
      structHash,
      // get the eip712 name and version from the base EIP712 contract,
      // which would have been defined in the constructor of the contract
      // inheriting from this one.
      _EIP712Name(),
      _EIP712Version(),
      signer,
      signature
    );
  }

  function _recoverSigner(
    bytes32 structHash,
    bytes memory signature
  ) internal view returns (address) {
    // build eip-712 hashed digest from the provided structHash
    bytes32 digest = _hashTypedDataV4(structHash);

    // recover the signer of the signature provided against the digest
    return ECDSA.recover(digest, signature);
  }

  // should be implemented by the contract inheriting this one to determine
  // if the signer is an authorized creator
  function isAuthorizedToCreate(address signer) internal virtual returns (bool);
}
