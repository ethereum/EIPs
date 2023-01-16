// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <ercref@zzn.im>
// DRAFTv1
// Source https://github.com/ercref/ercref-contracts/tree/main/ERCs/eip-5269
// Deployment https://goerli.etherscan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code
pragma solidity ^0.8.9;

interface IERC5269 {
  event OnSupportEIP(
      address indexed caller, // when emitted with `address(0x0)` means all callers.
      uint256 indexed majorEIPIdentifier,
      bytes32 indexed minorEIPIdentifier, // 0 means the entire EIP
      bytes32 eipStatus,
      bytes extraData
  );

  /// @dev The core method of EIP/ERC Interface Detection
  /// @param caller, a `address` value of the address of a caller being queried whether the given EIP is supported.
  /// @param majorEIPIdentifier, a `uint256` value and SHOULD BE the EIP number being queried. Unless superseded by future EIP, such EIP number SHOULD BE less or equal to (0, 2^32-1]. For a function call to `supportEIP`, any value outside of this range is deemed unspecified and open to implementation's choice or for future EIPs to specify.
  /// @param minorEIPIdentifier, a `bytes32` value reserved for authors of individual EIP to specify. For example the author of [EIP-721](/EIPS/eip-721) MAY specify `keccak256("ERC721Metadata")` or `keccak256("ERC721Metadata.tokenURI")` as `minorEIPIdentifier` to be quired for support. Author could also use this minorEIPIdentifier to specify different versions, such as EIP-712 has its V1-V4 with different behavior.
  /// @param extraData, a `bytes` for [EIP-5750](/EIPS/eip-5750) for future extensions.
  /// @return eipStatus a bytes32 indicating the status of EIP the contract supports.
  ///                    - For FINAL EIPs, it MUST return `keccak256("FINAL")`.
  ///                    - For non-FINAL EIPs, it SHOULD return `keccak256("DRAFT")`.
  ///                      During EIP procedure, EIP authors are allowed to specify their own
  ///                      eipStatus other than `FINAL` or `DRAFT` at their discretion such as `keccak256("DRAFTv1")`
  ///                      or `keccak256("DRAFT-option1")`and such value of eipStatus MUST be documented in the EIP body
  function supportEIP(
    address caller,
    uint256 majorEIPIdentifier,
    bytes32 minorEIPIdentifier,
    bytes calldata extraData)
  external view returns (bytes32 eipStatus);
}
