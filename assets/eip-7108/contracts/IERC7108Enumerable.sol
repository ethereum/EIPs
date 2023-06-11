// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Authors: Francesco Sullo <francesco@sullo.co>

/**
 * @title IERC7108Enumerable
 * @dev This is supposed to be used with ERC721Enumerable and ERC7108
 */
interface IERC7108Enumerable {

  /**
   * @notice Retrieves the balance of tokens a wallet owns within a specific cluster
   * @dev The balance is the number of tokens owned by the caller within the specified cluster.
      Note that due to potential computational complexity, this function could be gas-intensive,
      and therefore should only be called from dApps rather than internally
      or from other smart contracts.
   * @param owner The owner of the tokens
   * @param clusterId ID of the cluster
   * @return uint256 Balance of tokens within the cluster
   */
  function balanceOfWithin(address owner, uint256 clusterId) external view returns(uint);
}
