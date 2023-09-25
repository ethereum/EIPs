// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// ERC165 interfaceId 0x6b61a747
interface IERC6982 {
  // This event MUST be emitted upon deployment of the contract, establishing
  // the default lock status for any tokens that will be minted in the future.
  // If the default lock status changes for any reason, this event
  // MUST be re-emitted to update the default status for all tokens.
  // Note that emitting a new DefaultLocked event does not affect the lock
  // status of any tokens for which a Locked event has previously been emitted.
  event DefaultLocked(bool locked);

  // This event MUST be emitted whenever the lock status of a specific token
  // changes, effectively overriding the default lock status for this token.
  event Locked(uint256 indexed tokenId, bool locked);

  // This function returns the current default lock status for tokens.
  // It reflects the value set by the latest DefaultLocked event.
  function defaultLocked() external view returns (bool);

  // This function returns the lock status of a specific token.
  // If no Locked event has been emitted for a given tokenId, it MUST return
  // the value that defaultLocked() returns, which represents the default
  // lock status.
  // This function MUST revert if the token does not exist.
  function locked(uint256 tokenId) external view returns (bool);
}
