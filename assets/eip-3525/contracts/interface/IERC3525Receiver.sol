// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title ERC3525 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers from ERC3525 contracts.
 * Note: the ERC-165 identifier for this interface is 0x009ce20b.
 */
interface IERC3525Receiver {
    /**
     * @notice Handle the receipt of an ERC3525 token value.
     * @dev An ERC3525 smart contract MUST call this function on the recipient contract after a 
     *  value transfer (i.e. `safeTransferFrom(uint256,uint256,uint256,bytes)`).
     *  MUST return 0x009ce20b (i.e. `bytes4(keccak256('onERC3525Received(address,uint256,uint256,
     *  uint256,bytes)'))`) if the transfer is accepted.
     *  MUST revert or return any value other than 0x009ce20b if the transfer is rejected.
     * @param _operator The address which triggered the transfer
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256('onERC3525Received(address,uint256,uint256,uint256,bytes)'))` 
     *  unless the transfer is rejected.
     */
    function onERC3525Received(address _operator, uint256 _fromTokenId, uint256 _toTokenId, uint256 _value, bytes calldata _data) external returns (bytes4);
}