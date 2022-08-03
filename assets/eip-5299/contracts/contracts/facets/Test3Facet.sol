// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibTest3} from '../libraries/LibTest3.sol';

contract Test3Facet {
    function getData() external view returns(address){
        return LibTest3._getData();
    }

    function setData(address newOwner) external {
        LibTest3._setData(newOwner);
    }
}
