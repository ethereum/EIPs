// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from './LibDiamond.sol';

library LibTest3 {
    struct Test3FacetStorage {
        // owner of the contract
        address contractOwner;
    }

    function test3FacetStorage() internal view returns (Test3FacetStorage storage store) {
        bytes32[] memory storagePositions = LibDiamond.contractStoragePositions();
        bytes32 currentPosition = storagePositions[storagePositions.length - 1];
        assembly {
            store.slot := currentPosition
        }
    }

    function _getData() internal view returns(address) {
        return test3FacetStorage().contractOwner;
    }

    function _setData(address _newOwner) internal {
        test3FacetStorage().contractOwner = _newOwner;
    }
}
