// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @dev Library version has been tested with version 5.0.0.
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

interface IDictionary is IERC165 {
    /**
     * @notice Specification 1.1
     */
    event ImplementationUpgraded(bytes4 indexed functionSelector, address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    error InvalidAccess(address sender);
    error ImplementationNotFound(bytes4 functionSelector);
    error InvalidImplementation(address implementation);

    /**
     * @notice Specification 1.2 & 3
     */
    function getImplementation(bytes4 functionSelector) external view returns (address);
    function setImplementation(bytes4 functionSelector, address implementation) external;
    function supportsInterfaces() external returns (bytes4[] memory);
}
