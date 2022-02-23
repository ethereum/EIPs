pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IAssembleContract} from "./IAssembleContract.sol";

/**
 * @title PropertyContract
 * @notice A contract that stores property values.
 */
contract PropertyContract is ERC721 {
    /**
     * @notice A variable that stores the object of `AssembleContract`.
     */
    IAssembleContract public assembleContract;

    // Storing property values corresponding to each number of storage. (tokenId -> attr[])
    mapping(uint256 => uint256[]) private _attrs;

    /**
     * @dev `name_` and `symbol_` are passed to ERC-721, and in case of `assembleContractAddr_`, the `setAssembleContract` function is used.
     */
    constructor(string memory name_, string memory symbol_, address assembleContractAddr_) ERC721(name_, symbol_) {
        setAssembleContract(assembleContractAddr_);
    }

    /**
     * @dev See {IAssembleContract-getImage}
     */
    function getImage(uint256 tokenId_) public view virtual returns (string memory) {
        return assembleContract.getImage(_attrs[tokenId_]);
    }

    /**
     * @param newAssembleContractAddr_ Address value of `AssembleContract` to be changed.
     * @dev If later changes or extensions are unnecessary, write directly to `constructor` without implementing the function.
     */
    function setAssembleContract(address newAssembleContractAddr_) public virtual {
        assembleContract = IAssembleContract(newAssembleContractAddr_);
    }

    /**
     * @param tokenId_ The token ID for which you want to set the attribute value.
     * @dev Set the attribute value of the corresponding `tokenId_` sequentially according to the number of asset storage.
     */
    function _setAttr(uint256 tokenId_) internal virtual {
        for (uint256 idx=0; idx < assembleContract.getStorageCount(); idx++) {
            uint256 newValue = 0;

            /// @dev Implement the property value setting logic.
            
            _attrs[tokenId_].push(newValue);  
        }
    }
}