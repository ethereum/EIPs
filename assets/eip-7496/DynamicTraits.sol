// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERC7496} from "./interfaces/IERC7496.sol";

abstract contract DynamicTraits is IERC7496 {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Thrown when a new trait value is not different from the existing value
    error TraitValueUnchanged();

    /// @notice An enumerable set of all trait keys that have been set
    EnumerableSet.Bytes32Set internal _traitKeys;

    /// @notice A mapping of token ID to a mapping of trait key to trait value
    mapping(uint256 tokenId => mapping(bytes32 traitKey => bytes32 traitValue)) internal _traits;

    /// @notice An offchain string URI that points to a JSON file containing trait metadata
    string internal _traitMetadataURI;

    /**
     * @notice Get the value of a trait for a given token ID.
     * @param tokenId The token ID to get the trait value for
     * @param traitKey The trait key to get the value of
     */
    function getTraitValue(uint256 tokenId, bytes32 traitKey) public view virtual returns (bytes32 traitValue) {
        traitValue = _traits[tokenId][traitKey];
    }

    /**
     * @notice Get the values of traits for a given token ID.
     * @param tokenId The token ID to get the trait values for
     * @param traitKeys The trait keys to get the values of
     */
    function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys)
        public
        view
        virtual
        returns (bytes32[] memory traitValues)
    {
        uint256 length = traitKeys.length;
        traitValues = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            bytes32 traitKey = traitKeys[i];
            traitValues[i] = getTraitValue(tokenId, traitKey);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get the URI for the trait metadata
     */
    function getTraitMetadataURI() external view virtual returns (string memory labelsURI) {
        return _traitMetadataURI;
    }

    /**
     * @notice Set the value of a trait for a given token ID. If newTrait is bytes32(0), sets the zero value hash.
     *         Reverts if the trait value is the zero value hash.
     * @param tokenId The token ID to set the trait value for
     * @param traitKey The trait key to set the value of
     * @param newValue The new trait value to set
     */
    function _setTrait(uint256 tokenId, bytes32 traitKey, bytes32 newValue) internal {
        bytes32 existingValue = _traits[tokenId][traitKey];

        if (existingValue == newValue) {
            revert TraitValueUnchanged();
        }

        // no-op if exists
        _traitKeys.add(traitKey);

        _traits[tokenId][traitKey] = newValue;

        emit TraitUpdated(traitKey, tokenId, newValue);
    }

    /**
     * @notice Set the URI for the trait metadata
     * @param uri The new URI to set
     */
    function _setTraitMetadataURI(string calldata uri) internal virtual {
        _traitMetadataURI = uri;
        emit TraitMetadataURIUpdated();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC7496).interfaceId;
    }
}
