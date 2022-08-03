// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from './LibDiamond.sol';

library LibTest5 {
    // deprecated struct
    struct Test3FacetStorage {
        // owner of the contract
        address contractOwner;
    }

    struct Test4FacetStorage {
        // owner of the contract
        address contractOwner;
    }

    function test4FacetStorage() internal returns (Test4FacetStorage storage store) {
        bytes32[] memory storagePositions = LibDiamond.contractStoragePositions();
        bytes32 currentPosition = storagePositions[storagePositions.length - 1];
        assembly {
            store.slot := currentPosition
        }
    }

    function test4FacetDeprecatedStorage() internal returns (Test3FacetStorage storage store) {
        bytes32[] memory storagePositions = LibDiamond.contractStoragePositions();
        bytes32 currentPosition = storagePositions[0]; // previous storage pointer
        assembly {
            store.slot := currentPosition
        }
    }

    function _getDataUpgraded() internal returns(address[2] memory ownerAddresses) {
        return [test4FacetStorage().contractOwner, test4FacetDeprecatedStorage().contractOwner];
    }

    function _setDataUpgraded(address _newOwner) internal {
        test4FacetStorage().contractOwner = _newOwner;
    }
}
