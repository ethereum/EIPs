// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @dev Library version has been tested with version 5.0.0.
import {Proxy} from "openzeppelin-contracts/contracts/proxy/Proxy.sol";

import {ERC0000Utils} from "./ERC0000Utils.sol";
import {IDictionary} from "../dictionary/IDictionary.sol";

/**
 * @title Proxy Contract
 */
contract ERC0000Proxy is Proxy {
    /**
     * @notice Specification 2.2.1
     */
    constructor(address dictionary, bytes memory _data) payable {
        ERC0000Utils.upgradeDictionaryToAndCall(dictionary, _data);
    }

    /**
     * @notice Specification 2.2.2
     * @dev Return the implementation address corresponding to the function selector.
     */
    function _implementation() internal view override returns (address) {
        return IDictionary(ERC0000Utils.getDictionary()).getImplementation(msg.sig);
    }
}
