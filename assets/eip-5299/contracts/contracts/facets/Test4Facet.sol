// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibTest4} from '../libraries/LibTest4.sol';

contract Test4Facet {
    function getDataUpgraded() external view returns(address[2] memory ownerAddresses){
        return LibTest4._getDataUpgraded();
    }

    function setDataUpgraded(address newOwner) external {
        LibTest4._setDataUpgraded(newOwner);
    }
}
