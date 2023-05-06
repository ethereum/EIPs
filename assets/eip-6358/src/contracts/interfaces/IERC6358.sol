// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Omniverse transaction data structure
 * @member nonce: The number of the o-transactions. If the current nonce of an omniverse account is `k`, the valid nonce of this o-account in the next o-transaction is `k+1`. 
 * @member chainId: The chain where the o-transaction is initiated
 * @member initiateSC: The contract address from which the o-transaction is first initiated
 * @member from: The Omniverse account which signs the o-transaction
 * @member payload: The encoded bussiness logic data, which is maintained by the developer
 * @member signature: The signature of the above informations. 
 */
struct ERC6358TransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiateSC;
    bytes from;
    bytes payload;
    bytes signature;
}

/**
 * @notice Interface of the ERC Omniverse-DLT
 */
interface IERC6358 {
    /**
     * @notice Emitted when a o-transaction which has nonce `nonce` and was signed by user `pk` is sent by calling {sendOmniverseTransaction}
     */
    event TransactionSent(bytes pk, uint256 nonce);

    /**
     * @notice Sends an omniverse transaction 
     * @dev 
     * Note: MUST implement the validation of the `_data.signature`
     * Note: A map maintaining the omniverse account and the related transaction nonce is RECOMMENDED  
     * Note: MUST implement the validation of the `_data.nonce` according to the current account nonce
     * Note: MUST implement the validation of the `_data. payload`
     * Note: This interface is just for sending an omniverse transaction, and the execution MUST NOT be within this interface 
     * Note: The actual execution of an omniverse transaction is RECOMMENDED to be in another function and MAY be delayed for a time,
     * which is determined all by who publishes an O-DLT token
     * @param _data: the omniverse transaction data with type {ERC6358TransactionData}
     * See more information in the defination of {ERC6358TransactionData}
     *
     * Emit a {TransactionSent} event
     */
    function sendOmniverseTransaction(ERC6358TransactionData calldata _data) external;

    /**
     * @notice Get the number of omniverse transactions sent by user `_pk`, 
     * which is also the valid `nonce` of a new omniverse transactions of user `_pk` 
     * @param _pk: Omniverse account to be queried
     * @return The number of omniverse transactions sent by user `_pk`
     */
    function getTransactionCount(bytes memory _pk) external view returns (uint256);

    /**
     * @notice Get the transaction data `txData` and timestamp `timestamp` of the user `_use` at a specified nonce `_nonce`
     * @param _user Omniverse account to be queried
     * @param _nonce The nonce to be queried
     * @return Returns the transaction data `txData` and timestamp `timestamp` of the user `_use` at a specified nonce `_nonce`
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external view returns (ERC6358TransactionData memory, uint256);

    /**
     * @notice Get the chain ID
     * @return Returns the chain ID
     */
    function getChainId() external view returns (uint32);
}