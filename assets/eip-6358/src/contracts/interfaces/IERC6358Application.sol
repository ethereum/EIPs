// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Interface of the omniverse application contract
 */
interface IERC6358Application {
    /**
     * @notice Emitted when a o-transaction which has nonce `nonce` and was signed by user `pk` is executed
     */
    event TransactionExecuted(bytes pk, uint256 nonce);

    /**
     * @notice From the `_payload`, calculate the raw data which is used to generate signature
     * @param _payload Original data committed by synchronizers, and stored in hostorical transaction list
     * @return Returns The raw data of `_payload`
     */
    function getPayloadRawData(bytes memory _payload) external pure returns (bytes memory);
}