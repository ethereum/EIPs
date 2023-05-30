// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// ERC165 interfaceId 0x6b61a747
interface IERC6982 {
  // MUST be emitted one time, when the contract is deployed,
  // defining the default status of any token that will be minted.
  event DefaultLocked(bool locked);

  // MUST be emitted any time the status changes.
  event Locked(uint256 indexed tokenId, bool locked);

  // Returns the default status of the tokens.
  function defaultLocked() external view returns (bool);

  // Returns the status of the token.
  // If no special event occurred, it MUST return what defaultLocked() returns.
  // It MUST revert if the token does not exist.
  function locked(uint256 tokenId) external view returns (bool);
}
