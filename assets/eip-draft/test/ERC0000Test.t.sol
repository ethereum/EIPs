// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";

import {Dictionary} from "../src/dictionary/Dictionary.sol";
import {IDictionary} from "../src/dictionary/IDictionary.sol";
import {ERC0000Proxy} from "../src/proxy/ERC0000Proxy.sol";
import {ERC0000Utils} from "../src/proxy/ERC0000Utils.sol";

/// @dev Library version has been tested with version 5.0.0.
import {StorageSlot} from "openzeppelin-contracts/contracts/utils/StorageSlot.sol";

/// @dev A Harness Contract to retrieve the admin address declared as internal.
contract DictionaryHarness is Dictionary {
    constructor(address _admin) Dictionary(_admin) {}

    function getAdmin() public view returns (address) {
        return admin;
    }
}

/**
    @title A Test Contract to verify Dictionary and Proxy compliance with specifications with forge-std/Test
 */
contract ERC0000Test is Test {
    /// @dev Due to a bug in Solidity, we are redefining the events from the external interface file that cannot be read.
    event ImplementationUpgraded(bytes4 indexed functionSelector, address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    address admin = makeAddr("ADMIN");
    address dictionary;
    address proxy;

    function setUp() public {
        dictionary = address(new Dictionary(admin));
        proxy = address(new ERC0000Proxy(address(dictionary), bytes("")));
    }

    /**
     *  Dictionary
     *    (1) MUST implement `setImplementation(bytes4 functionSelector, address implementation)`
     *      (1.1) that stores a mapping of function selectors to implementation contract addresses
     *      (1.2) and SHOULD notify changes to mappings through events
     *      (1.3) and is RECOMMENDED to verify that the implemented contract contains a function with
     *            the same function selector as the one registered for the implementation
     *    (2) MUST implement `getImplementation(bytes4 functionSelector)`
     *    (3) SHOULD store an admin account address with rights to modify the mapping
     *      (3.1) and SHOULD notidy changes to the admin address through events
     *    (4) is RECOMMENDED to implement
     *      (4.1) `supportsInterface(bytes4 interfaceID)` as defined in ERC-165
     *      (4.2) `supportsInterfaces()` to return a list of registered interfaceIDs
     */

    /**
        @notice Verify (1), (2)
     */
    function test_Dictionary_Success_setImplementation_getImplementation(bytes4 _fuzz_functionSelector, address _fuzz_implementation) public {
        /// @dev Exclude precompiles & console
        vm.assume(uint256(uint160(_fuzz_implementation)) > 10);
        vm.assume(_fuzz_implementation != 0x000000000000000000636F6e736F6c652e6c6f67);

        if (_fuzz_implementation.code.length == 0 &&
            _isNotTestContracts(_fuzz_implementation)
        ) {
            deployCodeTo("Dummy.sol", _fuzz_implementation);
        }

        vm.prank(admin);
        vm.expectEmit();
        emit ImplementationUpgraded(_fuzz_functionSelector, _fuzz_implementation);
        Dictionary(dictionary).setImplementation(_fuzz_functionSelector, _fuzz_implementation);

        assertEq(Dictionary(dictionary).getImplementation(_fuzz_functionSelector), _fuzz_implementation);
    }
    function test_Dictionary_Revert_setImplementation_WithEmptyCode(bytes4 _fuzz_functionSelector, address _fuzz_implementation) public {
        vm.assume(_fuzz_implementation.code.length == 0);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IDictionary.InvalidImplementation.selector, _fuzz_implementation));
        Dictionary(dictionary).setImplementation(_fuzz_functionSelector, _fuzz_implementation);
    }

    /**
        @notice Verify (3)
     */
    function test_Dictionary_Success_constructor_setAdmin(address _fuzz_admin) public {
        vm.expectEmit();
        emit AdminChanged(address(0), _fuzz_admin);
        DictionaryHarness _dictionary = new DictionaryHarness(_fuzz_admin);
        assertEq(_dictionary.getAdmin(), _fuzz_admin);
    }
    function test_Dictionary_Revert_setImplementation_NotAdmin(bytes4 _fuzz_functionSelector, address _fuzz_implementation, address _fuzz_admin) public {
        vm.assume(_fuzz_admin != admin);
        vm.prank(_fuzz_admin);
        vm.expectRevert(abi.encodeWithSelector(IDictionary.InvalidAccess.selector, _fuzz_admin));
        Dictionary(dictionary).setImplementation(_fuzz_functionSelector, _fuzz_implementation);
    }

    /**
        @notice Verify (4)
     */
    function test_Dictionary_Success_supportsInterface(bytes4 _fuzz_functionSelector, address _fuzz_implementation) public {
        test_Dictionary_Success_setImplementation_getImplementation(_fuzz_functionSelector, _fuzz_implementation);
        assertTrue(Dictionary(dictionary).supportsInterface(_fuzz_functionSelector));
    }
    function test_Dictionary_Success_supportsInterfaces(bytes4[100] calldata _fuzz_functionSelector, address[100] calldata _fuzz_implementation) public {
        for (uint i; i < _fuzz_functionSelector.length;) {
            test_Dictionary_Success_setImplementation_getImplementation(_fuzz_functionSelector[i], _fuzz_implementation[i]);
            unchecked {
                ++i;
            }
        }

        bytes4[] memory interfaces = Dictionary(dictionary).supportsInterfaces();
        if (interfaces.length == _fuzz_functionSelector.length) {
            for (uint i; i < _fuzz_functionSelector.length;) {
                assertEq(interfaces[i], _fuzz_functionSelector[i]);
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint i; i < interfaces.length;) {
                bool isMatch;
                for (uint j; j < _fuzz_functionSelector.length;) {
                    if (interfaces[i] == _fuzz_functionSelector[j]) {
                        isMatch = true;
                        break;
                    }
                    unchecked {
                        ++j;
                    }
                }
                assertTrue(isMatch);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     *  Proxy
     *    (1) MUST store the Dictionary address
     *      (1.1) and SHOULD notify changes the Dictionary address
     *    (2) MUST delegatecall to the implementation contract obtained using the Dictionary's
     *        `getImplementation(bytes4 functionSelector)` for all interactions
     */

    /**
        @notice Verify (1)
     */
    function test_Proxy_Success_constructor_setDictionary(address _fuzz_dictionary) public {
        /// @dev Exclude precompiles & console
        vm.assume(uint256(uint160(_fuzz_dictionary)) > 10);
        vm.assume(_fuzz_dictionary != 0x000000000000000000636F6e736F6c652e6c6f67);

        if (_fuzz_dictionary.code.length == 0 &&
            _isNotTestContracts(_fuzz_dictionary) &&
            _fuzz_dictionary != address(dictionary)
        ) {
            deployCodeTo("Dummy.sol", _fuzz_dictionary);
        }

        vm.expectEmit();
        emit ERC0000Utils.DictionaryUpgraded(_fuzz_dictionary);
        address _proxy = address(new ERC0000Proxy(_fuzz_dictionary, bytes("")));
        assertEq(
            address(uint160(uint256(vm.load(_proxy, ERC0000Utils.DICTIONARY_SLOT)))),
            _fuzz_dictionary
        );
    }
    function test_Proxy_Revert_constructor_seteDictionary_withEmptyDictionary(address _fuzz_dictionary) public {
        vm.assume(
            _isNotTestContracts(_fuzz_dictionary) &&
            _fuzz_dictionary != address(dictionary) &&
            _fuzz_dictionary != address(proxy)
        );
        vm.expectRevert(abi.encodeWithSelector(ERC0000Utils.ERC0000InvalidDictionary.selector, _fuzz_dictionary));
        new ERC0000Proxy(_fuzz_dictionary, bytes(""));
    }

    /**
        @notice Verify (2)
     */
    function test_Proxy_Success_delegatecall_AllCallsAreForwardedToDictionary(bytes calldata _fuzz_data, address _fuzz_implementation) public {
        vm.assume(_fuzz_data.length >= 4 && bytes4(_fuzz_data) != bytes4(""));
        test_Dictionary_Success_setImplementation_getImplementation(bytes4(_fuzz_data), _fuzz_implementation);

        vm.expectCall(dictionary, abi.encodeWithSelector(Dictionary.getImplementation.selector, bytes4(_fuzz_data)));
        vm.expectCall(_fuzz_implementation, _fuzz_data);
        proxy.call(_fuzz_data);
    }
    function test_Proxy_Revert_delegatecall_UnregisteredImplementation(bytes4 _fuzz_functionSelector, address _fuzz_implementation, bytes calldata _fuzz_calldata) public {
        test_Dictionary_Success_setImplementation_getImplementation(bytes4(_fuzz_functionSelector), _fuzz_implementation);

        vm.assume(_fuzz_functionSelector != bytes4(_fuzz_calldata));

        vm.expectCall(dictionary, abi.encodeWithSelector(Dictionary.getImplementation.selector, bytes4(_fuzz_calldata)));
        vm.expectRevert(abi.encodeWithSelector(IDictionary.ImplementationNotFound.selector, bytes4(_fuzz_calldata)));
        proxy.call(_fuzz_calldata);
    }

    function _isNotTestContracts(address addr) internal pure returns (bool) {
        return (
            addr != address(console2) &&
            addr != address(vm)
        );
    }
}
