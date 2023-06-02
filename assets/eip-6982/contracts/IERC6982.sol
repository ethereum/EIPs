// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// ERC165 interfaceId 0x6b61a747
interface IERC6982 {
  // MUST be emitted when the contract is deployed,
  // defining the default status of any token that will be minted.
  // If the default status of any token changes for any reason,
  // this event MUST be emitted again to update the default status.
  event DefaultLocked(bool locked);

  // MUST be emitted any time the status of a specific token changes.
  event Locked(uint256 indexed tokenId, bool locked);

  // Returns the default status of the tokens.
  function defaultLocked() external view returns (bool);

  // Returns the status of the token.
  // If no special event occurred for a tokenId, it MUST return what
  // defaultLocked() returns.
  // It MUST revert if the token does not exist.
  function locked(uint256 tokenId) external view returns (bool);
}
