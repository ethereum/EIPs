// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './Distributor.sol';
import './interfaces/IEIP7536Validator.sol';

// interface IERC721 {
//     function ownerOf(uint256 tokenId) external view returns (address owner);
//     function balanceOf(address owner) external view returns (uint256);
// }

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

/**
 * @notice This contract is an implementation of the IValidator interface. It is used to enable minting 
 * of a child token with a fee charged. The parent token holder will need to setup rules for collectors
 * to follow before a child token is minted.
 */
contract Validator is IValidator {

    /**
    * @dev the fee to be paid before minting / extending a child token
    * 
    * @param feeToken The contract address of the fee token, i.e. USDT token contract address
    * @param mintAmount The token amount that is required for minting a child token
    * @param limit The maximum number of tokens that can be minted
    * @param start The starting time of the mint
    * @param time The duration of the mint
    */
    struct ValidationInfo {
        address feeToken;
        uint256 mintAmount;
        uint256 limit;
        uint64  start;
        uint64  time;
    }

    event SetRules(
        bytes32 editionHash,
        ValidationInfo validationInfo
    );
    
    mapping(bytes32 => ValidationInfo) private _validationInfo;
    mapping(bytes32 => uint256) private _count;

    IDistributor private _distributor;

    constructor (
        IDistributor distributor
    ) {
        _distributor = distributor;
    }

    modifier onlyDistributor {
        require(msg.sender == address(_distributor), "Validator: Invalid Sender");
        _;
    }

    /// @inheritdoc IValidator
    function setRules(bytes32 editionHash, bytes calldata initData) external override onlyDistributor {
        (ValidationInfo memory valInfo) = abi.decode(initData, (ValidationInfo));
        
        // require(valInfo.start > uint64(block.timestamp), "Validator: Invalid Start Time");
        _validationInfo[editionHash] = valInfo;
        emit SetRules(editionHash, valInfo);
    }
    
    /// @inheritdoc IValidator
    function validate(address to, bytes32 editionHash, uint256 conditionType, bytes calldata fullfilmentData) external payable override {
        _validateMint(to, editionHash);
        ++_count[editionHash];
    }
    
    // no reentrant**
    function _validateMint(
        address to,
        bytes32 editionHash
    ) internal {
        ValidationInfo memory valInfo = _validationInfo[editionHash];
        // check start time
        require(valInfo.start < uint64(block.timestamp), "Validator: Minting Period Not Started");

        // check deadline
        require(valInfo.time > uint64(block.timestamp) - valInfo.start, "Validator: Minting Period Ended");

        // check limit
        require(valInfo.limit > _count[editionHash], "Validator: Minting Limit Reached");

        // collect fees
        Distributor.Edition memory edition = Distributor(msg.sender).getEdition(editionHash);
        
        address primaryHolder = IERC721(edition.tokenContract).ownerOf(edition.tokenId);

        // address(0) is the native token
        if (valInfo.feeToken == address(0)) {
            require(msg.value >= valInfo.mintAmount, "Validator: Insufficient Native Tokens");
            payable(primaryHolder).transfer(valInfo.mintAmount);
        } else {
            IERC20(valInfo.feeToken).transferFrom(
                to,
                primaryHolder,
                valInfo.mintAmount
            );
        }
    }

    /**
    * @dev This function is called to get the validation rules for an edition
    *
    * @param editionHash the hash of the copy token
    * @return validationInfo the validation rules for the copy token
    */
    function getValidationInfo(
        bytes32 editionHash
    ) external view returns (ValidationInfo memory) {
        return _validationInfo[editionHash];
    }

    function getMintCount(
        bytes32 editionHash
    ) external view returns (uint256) {
        return _count[editionHash];
    }

}
