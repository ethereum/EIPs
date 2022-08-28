// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5058Factory {
    event DeployedBound(address indexed preimage, address bound);

    function allBoundsLength() external view returns (uint256);

    function boundByIndex(uint256 index) external view returns (address);

    function existBound(address preimage) external view returns (bool);

    function boundOf(address preimage) external view returns (address);

    function boundDeploy(address preimage) external returns (address);
}
