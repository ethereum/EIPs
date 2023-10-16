// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IDictionary} from "./IDictionary.sol";

/**
    @title Dictionary Contract
 */
contract Dictionary is IDictionary {
    /**
     * @notice Specification 1.1
     */
    mapping(bytes4 functionSelector => address implementation) internal implementations;
    address internal admin;
    bytes4[] internal functionSelectorList;

    constructor(address _admin) {
        _setAdmin(_admin);
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert InvalidAccess(msg.sender);
        _;
    }

    /**
     * @notice Specification 1.2.1
     */
    function getImplementation(bytes4 functionSelector) external view returns (address) {
        address _impl = implementations[functionSelector];
        if (_impl == address(0)) revert ImplementationNotFound(functionSelector);
        return _impl;
    }

    /**
     * @notice Specification 1.2.2
     */
    function setImplementation(bytes4 functionSelector, address implementation) external onlyAdmin {
        if (implementation.code.length == 0) {
            revert InvalidImplementation(implementation);
        }

        // In the case of a new functionSelector, add to the functionSelectorList.
        bool hasSetFunctionSelector;
        for (uint i; i < functionSelectorList.length; ++i) {
            if (functionSelector == functionSelectorList[i]) {
                hasSetFunctionSelector = true;
            }
        }
        if (!hasSetFunctionSelector) functionSelectorList.push(functionSelector);

        // Add the pair of functionSelector and implementation address to the mapping.
        implementations[functionSelector] = implementation;

        // Notify the change of the mapping.
        emit ImplementationUpgraded(functionSelector, implementation);
    }

    /**
     * @notice Specification 3.1.1.1
     * @dev The interfaceId equals to the function selector
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return implementations[interfaceId] != address(0);
    }

    /**
     * @notice Specification 3.1.1.2
     */
    function supportsInterfaces() external view returns (bytes4[] memory) {
        return functionSelectorList;
    }

    function _setAdmin(address _newAdmin) private {
        address _prevAdmin = admin;
        admin = _newAdmin;

        /// @notice Specification 1.1
        emit AdminChanged(_prevAdmin, _newAdmin);
    }
}
