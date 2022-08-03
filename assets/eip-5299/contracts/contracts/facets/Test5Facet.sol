// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibTest5} from '../libraries/LibTest5.sol';

contract Test5Facet {
    function getOldDataUpgraded() external returns(address[2] memory ownerAddresses){
        return LibTest5._getDataUpgraded();
    }

    function setOldDataUpgraded(address newOwner) external {
        LibTest5._setDataUpgraded(newOwner);
    }
}
