// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Authors: Francesco Sullo <francesco@sullo.co>

/**
 * @title IClusteredERC721
 * @dev IClusteredERC721 interface allows managing clusters or sub-collections of ERC721 tokens within a single contract
    ERC165 InterfaceId = 0x8a7bc8c2
 */
interface IClusteredERC721 {
  /**
   * @dev Emitted when a new cluster is added
   */
  event ClusterAdded(uint256 indexed clusterId, string name, string symbol, string baseTokenURI, uint256 size, address owner);

  /**
   * @dev Emitted when ownership of a cluster is transferred
   */
  event ClusterOwnershipTransferred(uint256 indexed clusterId, address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Gets the id of the cluster to which a token belongs
   * @param tokenId ID of the token
   * @return uint256 ID of the cluster to which the token belongs
   */
  function clusterOf(uint256 tokenId) external view returns (uint256);

  /**
   * @notice Gets the name of a cluster
   * @param clusterId ID of the cluster
   * @return string Name of the cluster
   */
  function nameOf(uint256 clusterId) external view returns (string memory);

  /**
   * @notice Gets the symbol of a cluster
   * @param clusterId ID of the cluster
   * @return string Symbol of the cluster
   */
  function symbolOf(uint256 clusterId) external view returns (string memory);

  /**
   * @notice Gets the range of token IDs that are included in a specific cluster
   * @param clusterId ID of the cluster
   * @return (uint256, uint256) Start and end of the token ID range
   */
  function rangeOf(uint256 clusterId) external view returns (uint256, uint256);

  /**
   * @notice Gets the owner of a cluster
   * @param clusterId ID of the cluster
   * @return address Owner of the cluster
   */
  function clusterOwner(uint256 clusterId) external view returns (address);

  /**
   * @notice Gets how many clusters have been added
   * @return uint256 Total number of clusters
   */
  function clustersCount() external view returns (uint256);

  /**
   * @notice Adds a new cluster
   * @dev The ClusterAdded event MUST be emitted upon successful execution
   * @param name Name of the cluster
   * @param symbol Symbol of the cluster
   * @param baseTokenURI Base Token URI of the cluster
   * @param size Size of the cluster (number of tokens)
   * @param clusterOwner Address of the cluster owner
   */
  function addCluster(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 size,
    address clusterOwner
  ) external;

  /**
   * @notice Transfers ownership of a cluster
   * @dev The ClusterOwnershipTransferred event MUST be emitted upon successful execution
   * @param clusterId ID of the cluster
   * @param newOwner Address of the new owner
   */
  function transferClusterOwnership(uint256 clusterId, address newOwner) external;

  /**
   * @notice Gets the normalized token ID for a token
   * @dev The normalized token ID is the token ID within the cluster, starting from 1
   * @param tokenId ID of the token
   * @return uint256 Normalized token ID
   */
  function normalizedTokenId(uint256 tokenId) external view returns (uint256);
}
