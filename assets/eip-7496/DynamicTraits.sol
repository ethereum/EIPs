// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERC7496} from "./interfaces/IERC7496.sol";

abstract contract DynamicTraits is IERC7496 {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    ///@notice Thrown when trying to delete a trait that has not been set
    error TraitNotSet(uint256 tokenId, bytes32 traitKey);
    ///@notice Thrown when trying to set a trait explicitly to the zero value hash
    error TraitCannotBeZeroValueHash();
    ///@notice Thrown when a new trait value is not different from the existing value
    error TraitValueUnchanged();

    bytes32 constant ZERO_VALUE = keccak256("DYNAMIC_TRAITS_ZERO_VALUE");
    ///@notice An enumerable set of all trait keys that have been set
    EnumerableSet.Bytes32Set internal _traitKeys;
    ///@notice A mapping of token ID to a mapping of trait key to trait value
    mapping(uint256 tokenId => mapping(bytes32 traitKey => bytes32 traitValue)) internal _traits;
    ///@notice An offchain string URI that points to a JSON file containing trait labels
    string internal _traitLabelsURI;

    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 trait) external virtual;
    function deleteTrait(bytes32 traitKey, uint256 tokenId) external virtual;

    /**
     * @notice Get the value of a trait for a given token ID. Reverts if the trait is not set.
     * @param traitKey The trait key to get the value of
     * @param tokenId The token ID to get the trait value for
     */
    function getTraitValue(bytes32 traitKey, uint256 tokenId) public view virtual returns (bytes32) {
        bytes32 value = _traits[tokenId][traitKey];
        // Revert if the trait is not set
        if (value == bytes32(0)) {
            revert TraitNotSet(tokenId, traitKey);
        } else if (value == ZERO_VALUE) {
            // check for zero value hash; return 0 if so
            return bytes32(0);
        } else {
            // otherwise return normal value
            return value;
        }
    }

    /**
     * @notice Get the values of a trait for a given list of token IDs. Reverts if the trait is not set on any single token.
     * @param traitKey The trait key to get the value of
     * @param tokenIds The token IDs to get the trait values for
     */
    function getTraitValues(bytes32 traitKey, uint256[] calldata tokenIds)
        external
        view
        virtual
        returns (bytes32[] memory traitValues)
    {
        uint256 length = tokenIds.length;
        bytes32[] memory result = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            result[i] = getTraitValue(traitKey, tokenId);
        }
        return result;
    }

    /**
     * @notice Get the total number of trait keys that have been set
     */
    function getTotalTraitKeys() external view virtual returns (uint256) {
        return _traitKeys.length();
    }

    /**
     * @notice Get the trait key at a given index
     * @param index The index of the trait key to get
     */
    function getTraitKeyAt(uint256 index) external view virtual returns (bytes32 traitKey) {
        return _traitKeys.at(index);
    }

    /**
     * @notice Get the trait keys that have been set. May revert if there are too many trait keys.
     */
    function getTraitKeys() external view virtual returns (bytes32[] memory traitKeys) {
        return _traitKeys._inner._values;
    }

    /**
     * @notice Get the URI for the trait labels
     */
    function getTraitLabelsURI() external view virtual returns (string memory labelsURI) {
        return _traitLabelsURI;
    }

    /**
     * @notice Set the value of a trait for a given token ID. If newTrait is bytes32(0), sets the zero value hash.
     *         Reverts if the trait value is the zero value hash.
     * @param traitKey The trait key to set the value of
     * @param tokenId The token ID to set the trait value for
     * @param newTrait The new trait value to set
     */
    function _setTrait(bytes32 traitKey, uint256 tokenId, bytes32 newTrait) internal {
        bytes32 existingValue = _traits[tokenId][traitKey];

        if (newTrait == bytes32(0)) {
            newTrait = ZERO_VALUE;
        } else if (newTrait == ZERO_VALUE) {
            revert InvalidTraitValue(traitKey, newTrait);
        }

        if (existingValue == newTrait) {
            revert TraitValueUnchanged();
        }

        // no-op if exists
        _traitKeys.add(traitKey);

        _traits[tokenId][traitKey] = newTrait;

        emit TraitUpdated(traitKey, tokenId, newTrait);
    }

    /**
     * @notice Delete the value of a trait for a given token ID.
     * @param traitKey The trait key to delete the value of
     * @param tokenId The token ID to delete the trait value for
     */
    function _deleteTrait(bytes32 traitKey, uint256 tokenId) internal {
        bytes32 existingValue = _traits[tokenId][traitKey];
        if (existingValue == bytes32(0)) {
            revert TraitValueUnchanged();
        }

        _traits[tokenId][traitKey] = bytes32(0);
        emit TraitUpdated(traitKey, tokenId, bytes32(0));
    }

    /**
     * @notice Set the URI for the trait labels
     * @param uri The new URI to set
     */
    function _setTraitLabelsURI(string calldata uri) internal virtual {
        _traitLabelsURI = uri;
        emit TraitLabelsURIUpdated(uri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC7496).interfaceId;
    }
}