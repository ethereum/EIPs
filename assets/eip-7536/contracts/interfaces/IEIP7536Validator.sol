// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice This is the validator interface. It specifies the rules that needs to be fulfilled, and enforce the
 * fulfillment of these rules. The parent token holder is required to first register these rules onto a particular
 * edition, identified by the hash of the edition configuration (editionHash). When a collector wants to mint from
 * the edition, the collector will need to pass the validation by successfully calling the validate function.  
 * 
 * In the validation process, the collector will need to supply the basic information including initiator
 * (the address of the collector), editionHash, and some optional fullfilmentData.
 */
interface IValidator {

    /**
     * @dev Sets up the validator rules by the edition hash and the data for initialisation. This function will
     * decode the data back to the required parameters and sets up the rules that decides who can or cannot
     * mint a copy of the edition.
     *
     * @param editionHash The hash of the edition configuration
     * @param initData The data bytes for initialising the validation rules. Parameters are encoded into bytes
     */
    function setRules(
        bytes32 editionHash, 
        bytes calldata initData
    ) external;
    
    /**
     * @dev Supply the data that will be used to validate the fulfilment of the rules setup by the parent token holder.
     *
     * @param initiator the party who initiate vadiation
     * @param editionHash the hash of the edition configuration
     * @param conditionType the type of condition to validation
     * @param fullfilmentData the addtion data that is required for passing the validator rules
     */
    function validate(
        address initiator, 
        bytes32 editionHash,
        uint256 conditionType,
        bytes calldata fullfilmentData
    ) external payable;

}
