---
eip: <to be assigned>
title: The Extendable Pattern
description: A development pattern for modular, re-usable, flexible smart contracts
author: Chris Chung (@0xpApaSmURf)
discussions-to: <URL>
status: Draft
type: Standards Track
category (*only required for Standards Track): ERC
created: 2022-06-09
requires: 165
---

## Simple Summary

A smart contract development pattern for extendable, upgradeable, re-usable contracts.

## Abstract

This standard specifies a design pattern for the development of Extendable contracts which acquire their functionality from modular units known as Extensions.

An Extendable contract is initially empty and is "extended" with Extensions, giving the contract its functions, that can be replaced or removed to either upgrade or deprecate certain functionality.

We specify a standard for:

* Creating an "Extendable" contract
* Creating modular "Extensions"
* Extending a contract with an Extension
* Managing an "Extendable" contract's implementations through Extensions

## Motivation

The growing set of on-chain use-cases have been witnessed by a similar advent of growing complexity in smart contracts. As the space matures and newer building blocks emerge, the vast composition of different applications has led to large smart contract stacks and cross dependencies between them. Many of these applications handle significant amount of funds or similar degrees of social impact that can affect large numbers of users.

As heightened composability leads to greater complexity, it is important that this added complexity does not serve to obfuscate and deteriorate the safety and security of the smart contracts that are built. Smart contracts should remain easily manageable, readable, and understood such that the transparent nature of open-sourcing such code is also supported by its ease of take-up. Users must be able to inspect code and discern the way it functions to elevate trustlessness.

Certain primitives will start to emerge as building block commons that much of the smart contract development will use to build upon, including standards such as ERC20. These code artifacts are frequently re-deployed to a network where such code has already been deployed countless times. Such primitives are, as of yet, not re-used on-chain despite the degree of replication and re-use that they are subject to.

Using Extendable benefits from:
* Static contract address: Extendable contracts always have the same address even through upgrades
* Re-usability: Code can be re-used instead of redeployed if contracts share similar functionality
* Modularity: Separation of concerns and units of code allow for better granular organisation of contracts
* Flexibility: Contracts can be future-proof and adapt with addition or removal of features as required

## Extendable<>Extension Architecture Overview

The Extendable framework is a developer-focused design pattern facilitating the implementation of evolving smart contracts through extending.

An Extendable contract at its most basic, is an empty smart contract that contains no functionality aside from the ability to be extended.

Extending an Extendable contract allows you to attach Extensions to it, giving it the ability to gain features and functions to be called by users. An Extension is a separate, standalone smart contract that contains functional logic that can be re-used by various other contracts.

![Extendable architecture](../assets/eip-xxxx/architecture.png)

### Extendable

The core Extendable contract keeps track of its Extensions through a set of mappings.

![Extendable mapping Extensions](../assets/eip-xxxx/mapping.png)

#### Extending

When it is extended with an Extension, it records the Extension address against the interface that the Extension implements as a key-value pair. The extended contract now is marked to implement the interface implemented by the Extension. By extending more Extensions, the Extendable contract can have an evolving and growing interface as a collection of all Extensions that it has.

![Extending](../assets/eip-xxxx/extend.png)

#### Calling functions

When a function is called, the Extendable contract identifies which Extension contains the desired functionality and performs a delegatecall.

![Delegating](../assets/eip-xxxx/delegate.png)

Delegatecalls allow one contract to execute the function of another contract as if the original contract itself has the function. It shifts the context of the execution of the function to that of the delegator, but using the function logic of the delegatee.

![Delegating call flow](../assets/eip-xxxx/delegation.png)

#### Accessing state variables

Accessing storage variables are done using slot assignment. Each Extension that has functions that use storage variables imports the storage that they intend to interact with as a "storage module" library. Such a library defines the variables and exposes a function that returns them. When defining a library, the assigned slot address where the variables exist must be chosen with strict uniqueness in mind, else risks the security of the contract. An Extendable contract may have several different storage modules and each one will exist at its assigned slot.

![Storage slot address](../assets/eip-xxxx/addressing.png)

Each Extendable contract owns its own addressable storage space, and Extensions, when called, will access the current context's contract when interacting with contract state. This allows Extensions to share storage module definitions as the variables themselves will indexed against each Extendable contract instance during execution.

![Storage slot access](../assets/eip-xxxx/access.png)

---

As a reminder, this document serves to define a set of conceptual primitives and their associated building blocks to allow developers to follow an approach for writing extendable smart contracts. The reference implementation can be found [here](https://github.com/violetprotocol/extendable/).

## Specification

The core specification contains the main primitive generalisations of the Extendable pattern's building blocks. Any reference implementations or utilities that enhance the framework for developers is included in the [appendix](#appendix).

### Terminology

Extendable - Refers to the
Extension - 
Storage Library - 
Extend - 
Retract - 
Replace - 
Delegatecall -
Function Selector - 

### ERC165 Singleton

All Extensions MUST implement ERC165. This is done indirectly through each Extension performing external calls to a contract singleton that contains all the ERC165 functionality. The ERC165 Singleton is called by Extensions via delegatecall.

```solidity
/**
 * @dev The basic ERC165 interface that must be implemented
 */
interface IERC165 {
    /**
     * @notice Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     * @param interfaceId bytes4 identifier for an interface
     * @return `true` if the contract implements `interfaceId`, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) external returns (bool);
}


/**
 * @dev Storage based implementation of the {IERC165} interface.
 * @notice This is not strictly part of EIP-165 but is included to facilitate use
 */
interface IERC165Register {
    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     * @param interfaceId bytes4 identifier for the interface to be registered
     */
    function registerInterface(bytes4 interfaceId) external;
}

/** 
 * @title ERC165 Singleton
 * @author 0xpapasmurf
 * @notice This contract is the official implementation of the ERC165 Singleton.
 * @notice For more details, see https://eips.ethereum.org/EIPS/eip-xxxx
 */
contract ERC165Logic is IERC165, IERC165Register {
    /**
     * @dev Records its own contract address during construction
     */
    address private self;
    constructor() {
        self = address(this);
    }

    /**
     * @dev Restricts calls to functions using this modifier to only come from
     * delegatecalls.
     */
    modifier onlyDelegated {
        require(address(this) != self, "ERC165Logic: undelegated calls disallowed");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) override(IERC165) public onlyDelegated virtual returns (bool) {
        ERC165State storage state = ERC165Storage._getState();
        return state._supportedInterfaces[interfaceId] || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165Register-registerInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     * - should only be callable by other extensions of the same contract
     */
    function registerInterface(bytes4 interfaceId) override(IERC165Register) public onlyDelegated {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");

        ERC165State storage state = ERC165Storage._getState();
        state._supportedInterfaces[interfaceId] = true;
    }
}
```

#### Deployment

Deployment of the ERC165 Singleton is achieved through [EIP-2470](https://eips.ethereum.org/EIPS/eip-2470). This deployment only needs to be done once per chain.

Submit a transaction with a call to the `deploy(bytes _initCode, bytes32 _salt)` function of the EIP-2470 singleton factory at address `0xce0042B868300000d44A59004Da54A005ffdcf9f` with the following parameters:

`_initCode`: 
```
0x608060405234801561001057600080fd5b50306000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555061068c806100606000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c806301ffc9a71461003b578063214cdb801461006b575b600080fd5b610055600480360381019061005091906103d4565b610087565b60405161006291906104ac565b60405180910390f35b610085600480360381019061008091906103d4565b6101f6565b005b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163073ffffffffffffffffffffffffffffffffffffffff161415610119576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610110906104e7565b60405180910390fd5b600061012361036a565b9050806000016000847bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060009054906101000a900460ff16806101ee57507f01ffc9a7000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916837bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b915050919050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163073ffffffffffffffffffffffffffffffffffffffff161415610285576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161027c906104e7565b60405180910390fd5b63ffffffff60e01b817bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614156102ee576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102e5906104c7565b60405180910390fd5b60006102f861036a565b90506001816000016000847bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060006101000a81548160ff0219169083151502179055505050565b600080307f5d17bc13b7729fc587de98637dd16967b7d6c922cdeb6ebec28ede1e3f0b4a5d6040516020016103a0929190610480565b6040516020818303038152906040528051906020012090508091505090565b6000813590506103ce8161063f565b92915050565b6000602082840312156103e657600080fd5b60006103f4848285016103bf565b91505092915050565b61040e61040982610518565b61058c565b82525050565b61041d8161052a565b82525050565b61043461042f82610536565b61059e565b82525050565b6000610447601c83610507565b9150610452826105c7565b602082019050919050565b600061046a602983610507565b9150610475826105f0565b604082019050919050565b600061048c82856103fd565b60148201915061049c8284610423565b6020820191508190509392505050565b60006020820190506104c16000830184610414565b92915050565b600060208201905081810360008301526104e08161043a565b9050919050565b600060208201905081810360008301526105008161045d565b9050919050565b600082825260208201905092915050565b60006105238261056c565b9050919050565b60008115159050919050565b6000819050919050565b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610597826105a8565b9050919050565b6000819050919050565b60006105b3826105ba565b9050919050565b60008160601b9050919050565b7f4552433136353a20696e76616c696420696e7465726661636520696400000000600082015250565b7f4552433136354c6f6769633a20756e64656c6567617465642063616c6c73206460008201527f6973616c6c6f7765640000000000000000000000000000000000000000000000602082015250565b61064881610540565b811461065357600080fd5b5056fea264697066735822122080fb526b761687b7b75efe0d7981709097bc281657d9f657c1862b9826cf526664736f6c63430008040033
```

`_salt`: `0x0000000000000000000000000000000000000000000000000000000000000000`

#### Destination Address

A successful deployment will result in an ERC165 Singleton contract deployed at `0x16c940672fa7820c36b2123e657029d982629070`.

### Extension Contracts

A custom Extension MUST inherit `Extension`.

`Extension` MUST use `0x16C940672fA7820C36b2123E657029d982629070` as the constant address for the ERC165 Singleton.

`Extension` MUST implement `supportsInterface` and `registerInterface` as delegatecalls to the ERC165 Singleton.

`Extension` MUST implement a constructor that calls `registerInterface` to register implementations using the `getInterface` function's output.

`Extension` MUST revert with custom error `ExtensionNotImplemented` in the `fallback` function.

`Extension` MUST inherit [`CallerContext`](#callercontext).


```
pragma solidity ^0.8.4;

struct Interface {
    bytes4 interfaceId;
    bytes4[] functions;
}

/**
 * @dev Interface for Extension
*/
interface IExtension {
    /**
     * @dev Returns a full view of the functional interface of the extension
     *
     * Must return a list of the functions in the interface of your custom Extension
     * in the same format and syntax as in the interface itself as a string, 
     * escaped-newline separated.
     *
     * Intent is to allow developers that want to integrate with an Extendable contract
     * that will have a constantly evolving interface, due to the nature of Extendables,
     * to be able to easily inspect and query for the current state of the interface and
     * integrate with it.
     *
     * See {ExtendLogic-getSolidityInterface} for an example.
    */
    function getSolidityInterface() external pure returns(string memory);

    /**
     * @dev Returns the interface IDs that are implemented by the Extension
     *
     * These are full interface IDs and ARE NOT function selectors. Full interface IDs are
     * XOR'd function selectors of an interface. For example the interface ID of the ERC721
     * interface is 0x80ac58cd determined by the XOR or all function selectors of the interface.
     * 
     * If an interface only consists of a single function, then the interface ID is identical
     * to that function selector.
     * 
     * Provides a simple abstraction from the developer for any custom Extension to 
     * be EIP-165 compliant out-of-the-box simply by implementing this function. 
     *
     * Excludes any functions either already described by other interface definitions
     * that are not developed on top of this backbone i.e. EIP-165, IExtension
    */
    function getInterface() external returns(Interface[] memory interfaces);
}

/**
 * @title Base Extension
 * @notice The base Extension contract that must be inherited by any contract in order to become an Extension. 
 * @dev Implements ERC165 by making calls to the ERC165 Singleton
 */
abstract contract Extension is CallerContext, IExtension, IERC165, IERC165Register {
    address constant ERC165LogicAddress = 0x16C940672fA7820C36b2123E657029d982629070;

    /**
     * @dev Constructor registers your custom Extension interface under EIP-165:
     *      https://eips.ethereum.org/EIPS/eip-165
    */
    constructor() {
        Interface[] memory interfaces = getInterface();
        for (uint256 i = 0; i < interfaces.length; i++) {
            Interface memory iface = interfaces[i];
            registerInterface(iface.interfaceId);

            for (uint256 j = 0; j < iface.functions.length; j++) {
                registerInterface(iface.functions[j]);
            }
        }

        registerInterface(type(IExtension).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId) external override virtual returns(bool) {
        (bool success, bytes memory result) = ERC165LogicAddress.delegatecall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId));

        if (!success) {
            assembly {
                revert(result, returndatasize())
            }
        }

        return abi.decode(result, (bool));
    }

    function registerInterface(bytes4 interfaceId) public override virtual {
        (bool success, ) = ERC165LogicAddress.delegatecall(abi.encodeWithSignature("registerInterface(bytes4)", interfaceId));

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Unidentified function signature calls to any Extension reverts with
     *      ExtensionNotImplemented error
    */
    function _fallback() internal virtual {
        revert ExtensionNotImplemented();
    }

    /**
     * @dev Fallback function passes to internal _fallback() logic
    */
    fallback() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Payable fallback function passes to internal _fallback() logic
    */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Virtual override declaration of getFunctionSelectors() function to silence compiler
     *
     * Must be implemented in inherited contract.
    */
    function getInterface() override public virtual returns(Interface[] memory);
}
```

See [here for all default Extensions](#default-extensions) that are the reference implementation of the core features.

#### Custom Extensions

By inheriting `Extension` a custom Extension MUST also define and implement a custom interface.

A custom Extension MUST implement `getSolidityInterface` and `getInterface` functions. These are introspection functions that allow other contracts or users to inspect what interface is implemented by the Extension. Crucially, it is used by Extendable during extending to determine what interface it will inherit and which contract implements it.

`getSolidityInterface` MUST be implemented such that it returns a list of new-line character `\n`-appended function declarations, similar to that in interface definitions.

`getInterface` MUST be implemented such that it returns an array of the `Interface` struct, containing so-formatted structure of the interface that your Extension implements.

#### Example Custom Extension Implementation

```solidity
// Your interface definition
interface IYourExtension {
    function returnString() external returns(string memory);
    function returnUint256() external returns(uint256);
}

// Your Extension boilerplate
abstract contract YourExtension is IYourExtension, Extension {

    // Returns the functions as declared in the interface definition, each appended with `\n`
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function returnString() external returns(string memory);\n"
            "function returnUint256() external returns(uint256);\n";
    }

    // Returns the interfaceId and function selectors of your interface definition as a struct
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = IYourExtension.returnString.selector;
        functions[1] = IYourExtension.returnUint256.selector;

        interfaces[0] = Interface(type(IYourExtension).interfaceId, functions);
    }
}

// Your Extension custom function implementation
contract YourExtensionImplementation is YourExtension {
    function returnString() public pure override returns(string memory) {
        return "Hello world!";
    }

    function returnUint256() public pure override returns(uint256) {
        return 42;
    }
}
```

### Storage Module

Custom Extensions may require state variable access through storage module libraries.

Storage variables MUST be defined as part of a struct.

Storage libraries MUST define a unique slot for storage variables to be written to.

Storage libraries MUST define a `_getState` function that returns the storage variables located at the defined slot.

```solidity
pragma solidity ^0.8.4;

/**
 * @dev Define your storage variables into a struct like below
**/
struct YourStruct {
    string text;
    uint number;
}

/**
 * @dev Your storage variable struct is accessible by all your extensions
 *      using the library pattern below.
**/
library YourStorage {
    // This is used in combination with delegator address to locate your struct in storage
    // Choose something that is human readable/understandable and unique to avoid potential
    // collisions with other potential storage libraries used by the same delegator
    bytes32 constant private STORAGE_NAME = keccak256("your_unique_storage_identifier");

    function _getState()
        internal 
        view
        returns (YourStruct storage state) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            state.slot := position
        }
    }
}
```

#### Using Storage Module

Extensions access storage variables by importing storage libraries and calling `_getState` in functions that require those variables.

Using the example Extension:

```solidity
pragma solidity ^0.8.4;

import "YourStorage.sol";

contract YourExtensionImplementation is YourExtension {
    function returnString() public pure override returns(string memory) {
        YourStruct storage state = YourStorage._getState();
        return state.text;
    }

    function returnUint256() public pure override returns(uint256) {
        YourStruct storage state = YourStorage._getState();
        return state.number;
    }
}
```

### Extendable Contract

The Extendable contract is the core artifact of building Extendable smart contracts.

A contract MUST inherit `Extendable` to be extendable by Extensions.

`ExtendLogic` MUST be deployed prior to the deployment of any Extendable contract.

```solidity
pragma solidity ^0.8.4;

/**
 * @dev  ExtensionNotImplemented error is emitted by Extendable and Extensions
 *       where no implementation for a specified function signature exists
 *       in the contract
*/
error ExtensionNotImplemented();

/**
 * @dev  Utility library for contracts to catch custom errors
 *       Pass in a return `result` from a call, and the selector for your error message
 *       and the `catchCustomError` function will return `true` if the error was found
 *       or `false` otherwise
*/
library Errors {
    function catchCustomError(bytes memory result, bytes4 errorSelector) internal pure returns(bool) {
        bytes4 caught;
        assembly {
            caught := mload(add(result, 0x20))
        }

        return caught == errorSelector;
    }
}

/**
 * @dev Storage struct used to hold state for Extendable contracts
 */
struct ExtendableState {
    // Array of full interfaceIds extended by the Extendable contract instance
    bytes4[] implementedInterfaceIds;

    // Array of function selectors extended by the Extendable contract instance
    mapping(bytes4 => bytes4[]) implementedFunctionsByInterfaceId;

    // Mapping of interfaceId/functionSelector to the extension address that implements it
    mapping(bytes4 => address) extensionContracts;
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library ExtendableStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:extendable-state");

    function _getState()
        internal 
        view
        returns (ExtendableState storage extendableState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            extendableState.slot := position
        }
    }
}

/**
 * @dev Storage struct used to hold state for CallerContext
 */
struct CallerState {
    // Stores a list of callers in the order they are received
    // The current caller context is always the last-most address
    address[] callerStack;
}

/**
 * @dev Storage library to access storage slot for the CallerState struct
 */
library CallerContextStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:caller-state");

    function _getState()
        internal 
        view
        returns (CallerState storage callerState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            callerState.slot := position
        }
    }
}

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  @title Core module for the Extendable framework
 *  
 *  Inherit this contract to make your contracts Extendable!
 *
 *  Your contract can perform ad-hoc addition or removal of functions
 *  which allows modularity, re-use, upgrade, and extension of your
 *  deployed contracts. You can make your contract immutable by removing
 *  the ability for it to be extended.
 *
 *  Constructor initialises owner-based permissioning to manage
 *  extending, where only the `owner` can extend the contract.
 *  
 *  You may change this constructor or use extension replacement to
 *  use a different permissioning pattern for your contract.
 *
 *  Requirements:
 *      - ExtendLogic contract must already be deployed
 */
contract Extendable {
    /**
     * @dev Contract constructor initialising the first extension `ExtendLogic`
     *      to allow the contract to be extended.
     *
     * This implementation assumes that the `ExtendLogic` being used also uses
     * an ownership pattern that only allows `owner` to extend the contract.
     * 
     * This constructor sets the owner of the contract and extends itself
     * using the ExtendLogic extension.
     *
     * To change owner or ownership mode, your contract must be extended with the
     * PermissioningLogic extension, giving it access to permissioning management.
     */
    constructor(address extendLogic) {
        // wrap main constructor logic in pre/post fallback hooks for callstack registration
        _beforeFallback();

        // extend extendable contract with the first extension: extend, using itself in low-level call
        (bool extendSuccess, ) = extendLogic.delegatecall(abi.encodeWithSignature("extend(address)", extendLogic));

        // check that initialisation tasks were successful
        require(extendSuccess, "failed to initialise extension");

        _afterFallback();
    }
    
    /**
     * @dev Delegates function calls to the specified `delegatee`.
     *
     * Performs a delegatecall to the `delegatee` with the incoming transaction data
     * as the input and returns the result. The transaction data passed also includes 
     * the function signature which determines what function is attempted to be called.
     * 
     * If the `delegatee` returns a ExtensionNotImplemented error, the `delegatee` is
     * an extension that does not implement the function to be called.
     *
     * Otherwise, the function execution fails/succeeds as determined by the function 
     * logic and returns as such.
     */
    function _delegate(address delegatee) internal virtual returns(bool) {
        _beforeFallback();
        
        bytes memory out;
        (bool success, bytes memory result) = delegatee.delegatecall(msg.data);

        _afterFallback();

        // copy all returndata to `out` once instead of duplicating copy for each conditional branch
        assembly {
            returndatacopy(out, 0, returndatasize())
        }

        // if the delegatecall execution did not succeed
        if (!success) {
            // check if failure was due to an ExtensionNotImplemented error
            if (Errors.catchCustomError(result, ExtensionNotImplemented.selector)) {
                // cleanly return false if error is caught
                return false;
            } else {
                // otherwise revert, passing in copied full returndata
                assembly {
                    revert(out, returndatasize())
                }
            }
        } else {
            // otherwise end execution and return the copied full returndata
            assembly {
                return(out, returndatasize())
            }
        }
    }
    
    /**
     * @dev Internal fallback function logic that attempts to delegate execution
     *      to extension contracts
     *
     * Initially attempts to locate an interfaceId match with a function selector
     * which are extensions that house single functions (singleton extensions)
     *
     * If no implementations are found that match the requested function signature,
     * returns ExtensionNotImplemented error
     */
    function _fallback() internal virtual {
        ExtendableState storage state = ExtendableStorage._getState();

        // if an extension exists that matches in the functionsig
        if (state.extensionContracts[msg.sig] != address(0x0)) {
            // call it
            _delegate(state.extensionContracts[msg.sig]);
        } else {                                                 
            revert ExtensionNotImplemented();
        }
    }

    /**
     * @dev Default fallback function to catch unrecognised selectors.
     *
     * Used in order to perform extension lookups by _fallback().
     *
     * Core fallback logic sandwiched between caller context work.
     */
    fallback() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Payable fallback function to catch unrecognised selectors with ETH payments.
     *
     * Used in order to perform extension lookups by _fallback().
     */
    receive() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Virtual hook that is called before _fallback().
     */
    function _beforeFallback() internal virtual {
        CallerState storage state = CallerContextStorage._getState();
        state.callerStack.push(msg.sender);
    }
    
    /**
     * @dev Virtual hook that is called after _fallback().
     */
    function _afterFallback() internal virtual {
        CallerState storage state = CallerContextStorage._getState();
        state.callerStack.pop();
    }
}
```

#### Usage

To use `Extendable`:

```solidity
contract YourExtendableContract is Extendable {}
```

Deploy it using the default `Extendable` constructor `constructor(address extendLogic)` by passing it the address of the `ExtendLogic` contract.

Then to extend it, call the `extend(address extension)` function on your deployed Extendable contract, passing it the address of any Extension logic contract.



The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

## Backwards Compatibility

All resulting Extendable contracts behave identically to 'normal' smart contracts. Interacting with an Extendable contract is no different to interacting with other smart contracts. To aid such an interaction, using the introspection function `getSolidityInterface` on an Extension or the `getFullInterface` function provided by `ExtendLogic` will return the interface of the contract to be used as a contract ABI. These introspection routines and interface implementations have been crafted to ensure that the contracts behave exactly the same to avoid any functional difference.

## Reference Implementation
The reference implementation can be found [here](https://github.com/violetprotocol/extendable).

## Security Considerations
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Appendix

### Default Extensions

The default extensions that SHOULD be used as is defined are:

* [ExtendLogic](#extendlogic-extension)
* [RetractLogic](#retractlogic-extension)
* [ReplaceLogic](#replacelogic-extension)

An additional extension that MAY be used as is defined is:

* PermissioningLogic

This is because of a specific ownership pattern that may not be desirable to be used in all cases but is a default that we apply to our reference implementation.

#### ExtendLogic Extension

ExtendLogic is the primary function of all Extendable contracts.

It is deployed first and used by Extendables to extend itself with the ability to extend, which allows it to extend itself with other Extensions.

`ExtendLogic` MUST implement `Extension`.

`ExtendLogic` MUST use `ExtendableStorage`.
`ExtendLogic` MAY use `PermissioningStorage`.

The `extend` function body MUST be used as is, but if a different permissioning model is used, the modifier `onlyOwnerOrSelf` can be changed.

```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface for ExtendLogic extension
*/
interface IExtendLogic {
    /**
     * @dev Emitted when `extension` is successfully extended
     */
    event Extended(address extension);
    
    /**
     * @dev Emitted when extend() is called and contract owner has not been set
     */
    event OwnerInitialised(address newOwner);

    /**
     * @dev Extend function to extend your extendable contract with new logic
     *
     * Integrate with ExtendableStorage to persist state
     *
     * Sets the known implementor of each function of `extension` as the current call context
     * contract.
     *
     * Emits `Extended` event upon successful extending.
     *
     * Requirements:
     *  - `extension` contract must implement EIP-165.
     *  - `extension` must inherit IExtension
     *  - Must record the `extension` by both its interfaceId and address
     *  - The functions of `extension` must not already be extended by another attached extension
    */
    function extend(address extension) external;

    /**
     * @dev Returns a string-formatted representation of the full interface of the current
     *      Extendable contract as an interface named IExtended
     *
     * Expects `extension.getSolidityInterface` to return interface-compatible syntax with line-separated
     * function declarations including visibility, mutability and returns.
    */
    function getFullInterface() external view returns(string memory fullInterface);

    /**
     * @dev Returns an array of interfaceIds that are currently implemented by the current
     *      Extendable contract
    */
    function getExtensionsInterfaceIds() external view returns(bytes4[] memory);
    /**
     * @dev Returns an array of function selectors that are currently implemented by the current
     *      Extendable contract
    */
    function getExtensionsFunctionSelectors() external view returns(bytes4[] memory);

    /**
     * @dev Returns an array of all extension addresses that are currently attached to the
     *      current Extendable contract
    */
    function getExtensionAddresses() external view returns(address[] memory);
}

/**
 * @dev Abstract Extension for ExtendLogic
*/
abstract contract ExtendExtension is IExtendLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function extend(address extension) external;\n"
                "function getFullInterface() external view returns(string memory);\n"
                "function getExtensionsInterfaceIds() external view returns(bytes4[] memory);\n"
                "function getExtensionsFunctionSelectors() external view returns(bytes4[] memory);\n"
                "function getExtensionAddresses() external view returns(address[] memory);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](5);
        functions[0] = IExtendLogic.extend.selector;
        functions[1] = IExtendLogic.getFullInterface.selector;
        functions[2] = IExtendLogic.getExtensionsInterfaceIds.selector;
        functions[3] = IExtendLogic.getExtensionsFunctionSelectors.selector;
        functions[4] = IExtendLogic.getExtensionAddresses.selector;

        interfaces[0] = Interface(
            type(IExtendLogic).interfaceId,
            functions
        );
    }
}

/**
 * @dev Reference implementation for ExtendLogic which defines the logic to extend
 *      Extendable contracts
 *
 * Uses PermissioningLogic owner pattern to control extensibility. Only the `owner`
 * can extend using this logic.
 *
 * Modify this ExtendLogic extension to change the way that your contract can be
 * extended: public extendability; DAO-based extendability; governance-vote-based etc.
*/
contract ExtendLogic is ExtendExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner` or the current contract
    */
    modifier onlyOwnerOrSelf {
        initialise();
    
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner || _lastCaller() == address(this), "unauthorised");
        _;
    }

    /**
     * @dev see {IExtendLogic-extend}
     *
     * Uses PermissioningLogic implementation with `owner` checks.
     *
     * Restricts extend to `onlyOwnerOrSelf`.
     *
     * If `owner` has not been initialised, assume that this is the initial extend call
     * during constructor of Extendable and instantiate `owner` as the caller.
     *
     * If any single function in the extension has already been extended by another extension,
     * revert the transaction.
    */
    function extend(address extension) override public virtual onlyOwnerOrSelf {
        require(extension.code.length > 0, "Extend: address is not a contract");

        IERC165 erc165Extension = IERC165(extension);
        try erc165Extension.supportsInterface(bytes4(0x01ffc9a7)) returns(bool erc165supported) {
            require(erc165supported, "Extend: extension does not implement eip-165");
            require(erc165Extension.supportsInterface(type(IExtension).interfaceId), "Extend: extension does not implement IExtension");
        } catch (bytes memory) {
            revert("Extend: extension does not implement eip-165");
        }

        IExtension ext = IExtension(payable(extension));

        Interface[] memory interfaces = ext.getInterface();
        registerInterfaces(interfaces, extension);

        emit Extended(extension);
    }

    /**
     * @dev see {IExtendLogic-getFullInterface}
    */
    function getFullInterface() override public view returns(string memory fullInterface) {
        ExtendableState storage state = ExtendableStorage._getState();

        uint numberOfInterfacesImplemented = state.implementedInterfaceIds.length;
        for (uint i = 0; i < numberOfInterfacesImplemented; i++) {
            bytes4 interfaceId = state.implementedInterfaceIds[i];
            IExtension logic = IExtension(state.extensionContracts[interfaceId]);
            fullInterface = string(abi.encodePacked(fullInterface, logic.getSolidityInterface()));
        }

        // TO-DO optimise this return to a standardised format with comments for developers
        return string(abi.encodePacked("interface IExtended {\n", fullInterface, "}"));
    }

    /**
     * @dev see {IExtendLogic-getExtensionsInterfaceIds}
    */
    function getExtensionsInterfaceIds() override public view returns(bytes4[] memory) {
        ExtendableState storage state = ExtendableStorage._getState();
        return state.implementedInterfaceIds;
    }

    /**
     * @dev see {IExtendLogic-getExtensionsFunctionSelectors}
    */
    function getExtensionsFunctionSelectors() override public view returns(bytes4[] memory functionSelectors) {
        ExtendableState storage state = ExtendableStorage._getState();
        bytes4[] storage implementedInterfaces = state.implementedInterfaceIds;
        
        uint256 numberOfFunctions = 0;
        for (uint256 i = 0; i < implementedInterfaces.length; i++) {
                numberOfFunctions += state.implementedFunctionsByInterfaceId[implementedInterfaces[i]].length;
        }

        functionSelectors = new bytes4[](numberOfFunctions);
        uint256 counter = 0;
        for (uint256 i = 0; i < implementedInterfaces.length; i++) {
            uint256 functionNumber = state.implementedFunctionsByInterfaceId[implementedInterfaces[i]].length;
            for (uint256 j = 0; j < functionNumber; j++) {
                functionSelectors[counter] = state.implementedFunctionsByInterfaceId[implementedInterfaces[i]][j];
                counter++;
            }
        }
    }

    /**
     * @dev see {IExtendLogic-getExtensionAddresses}
    */
    function getExtensionAddresses() override public view returns(address[] memory) {
        ExtendableState storage state = ExtendableStorage._getState();
        address[] memory addresses = new address[](state.implementedInterfaceIds.length);
        
        for (uint i = 0; i < state.implementedInterfaceIds.length; i++) {
            bytes4 interfaceId = state.implementedInterfaceIds[i];
            addresses[i] = state.extensionContracts[interfaceId];
        }
        return addresses;
    }

    /**
     * @dev Sets the owner of the contract to the tx origin if unset
     *
     * Used by Extendable during first extend to set deployer as the owner that can
     * extend the contract
    */
    function initialise() internal {
        RoleState storage state = Permissions._getState();

        // Set the owner to the transaction sender if owner has not been initialised
        if (state.owner == address(0x0)) {
            state.owner = _lastCaller();
            emit OwnerInitialised(_lastCaller());
        }
    }

    function registerInterfaces(Interface[] memory interfaces, address extension) internal {
        ExtendableState storage state = ExtendableStorage._getState();

        // Record each interface as implemented by new extension, revert if a function is already implemented by another extension
        uint256 numberOfInterfacesImplemented = interfaces.length;
        for (uint256 i = 0; i < numberOfInterfacesImplemented; i++) {
            bytes4 interfaceId = interfaces[i].interfaceId;
            address implementer = state.extensionContracts[interfaceId];

            require(
                implementer == address(0x0),
                string(abi.encodePacked("Extend: interface ", Strings.toHexString(uint256(uint32(interfaceId)), 4)," is already implemented by ", Strings.toHexString(implementer)))
            );

            registerFunctions(interfaceId, interfaces[i].functions, extension);
            state.extensionContracts[interfaceId] = extension;
            state.implementedInterfaceIds.push(interfaceId);
        }
    }

    function registerFunctions(bytes4 interfaceId, bytes4[] memory functionSelectors, address extension) internal {
        ExtendableState storage state = ExtendableStorage._getState();

        // Record each function as implemented by new extension, revert if a function is already implemented by another extension
        uint256 numberOfFunctions = functionSelectors.length;
        for (uint256 i = 0; i < numberOfFunctions; i++) {
            address implementer = state.extensionContracts[functionSelectors[i]];

            require(
                implementer == address(0x0),
                string(abi.encodePacked("Extend: function ", Strings.toHexString(uint256(uint32(functionSelectors[i])), 4)," is already implemented by ", Strings.toHexString(implementer)))
            );

            state.extensionContracts[functionSelectors[i]] = extension;
            state.implementedFunctionsByInterfaceId[interfaceId].push(functionSelectors[i]);
        }
    }
}
```

#### RetractLogic Extension

RetractLogic is an Extension that _removes_ an Extension from an Extendable.

`RetractLogic` MUST implement `Extension`.

`RetractLogic` MUST use `ExtendableStorage`.
`RetractLogic` MAY use `PermissioningStorage`.
`RetractLogic` SHOULD emit a `Retracted(address extension)` event upon successful `retract` call.

The `retract` function body MUST be used as is, but if a different permissioning model is used, the modifier `onlyOwnerOrSelf` can be changed.

```solidity

pragma solidity ^0.8.4;

/**
 * @dev Interface for RetractLogic extension
*/
interface IRetractLogic {
    /**
     * @dev Emitted when `extension` is successfully removed
     */
    event Retracted(address extension);

    /**
     * @dev Removes an extension from your Extendable contract
     *
     * Requirements:
     * - `extension` must be an attached extension
    */
    function retract(address extension) external;
}

/**
 * @dev Abstract Extension for RetractLogic
*/
abstract contract RetractExtension is IRetractLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function retract(address extension) external;\n";
    }

    /**
     * @dev see {IExtension-getImplementedInterfaces}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IRetractLogic.retract.selector;

        interfaces[0] = Interface(
            type(IRetractLogic).interfaceId,
            functions
        );
    }
}

/**
 * @dev Reference implementation for RetractLogic which defines the logic to remove Extensions from
 *      Extendable contracts
*/
contract RetractLogic is RetractExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
    */
    modifier onlyOwnerOrSelf {
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner || _lastCaller() == address(this), "unauthorised");
        _;
    }

    /**
     * @dev see {IRetractLogic-retract}
    */
    function retract(address extension) override external virtual onlyOwnerOrSelf {
        ExtendableState storage state = ExtendableStorage._getState();

        // Search for extension in interfaceIds
        uint256 numberOfInterfacesImplemented = state.implementedInterfaceIds.length;
        bool hasMatch;

        // we start with index 1 and reduce by one due to line 43 shortening the array
        // we need to decrement the counter if we shorten the array, but uint cannot be < 0
        for (uint i = 1; i < numberOfInterfacesImplemented + 1; i++) {
            uint256 decrementedIndex = i - 1;
            bytes4 interfaceId = state.implementedInterfaceIds[decrementedIndex];
            address currentExtension = state.extensionContracts[interfaceId];

            // Check if extension matches the one we are looking for
            if (currentExtension == extension) {
                hasMatch = true;
                // Remove interface implementor
                delete state.extensionContracts[interfaceId];
                state.implementedInterfaceIds[decrementedIndex] = state.implementedInterfaceIds[numberOfInterfacesImplemented - 1];
                state.implementedInterfaceIds.pop();

                // Remove function selector implementor
                uint256 numberOfFunctionsImplemented = state.implementedFunctionsByInterfaceId[interfaceId].length;
                for (uint j = 0; j < numberOfFunctionsImplemented; j++) {
                    bytes4 functionSelector = state.implementedFunctionsByInterfaceId[interfaceId][j];
                    delete state.extensionContracts[functionSelector];
                }
                delete state.implementedFunctionsByInterfaceId[interfaceId];

                numberOfInterfacesImplemented--;
                i--;
            }
        }

        if (!hasMatch) {
            revert("Retract: specified extension is not an extension of this contract, cannot retract");
        }

        emit Retracted(extension);
    }
}
```

#### ReplaceLogic Extension

ReplaceLogic is an Extension that _removes_ an Extension and _extends_ another to an Extendable.

`ReplaceLogic` MUST implement `Extension`.

`ReplaceLogic` MUST use `RetractLogic`.
`ReplaceLogic` MUST use `ExtendLogic`.
`ReplaceLogic` SHOULD emit a `Replaced(address oldExtension, address newExtension)` event upon successful `replace` call.

The `replace` function body MUST be used as is, but if a different permissioning model is used, the modifier `onlyOwner` can be changed.

The `replace` function uses a combination of the retract and extend extensions, re-using their logic for removing and adding extensions to avoid replicating code, and also avoiding potential issues introduced with new code. If used to replace the `ExtendLogic` extension, the below implementation ensures that the replacement implements an identical interface to ensure that the extend functionality is not mistakenly lost. The reference implementation repository also includes a `StrictReplaceLogic` which restricts all replacements to identical interfaces in the case where you want to strictly enforce an implementation change, but not an interface change.

```solidity
pragma solidity ^0.8.4;

/**
 * @dev Interface for ReplaceLogic extension
*/
interface IReplaceLogic {
    /**
     * @dev Emitted when `extension` is successfully extended
     */
    event Replaced(address oldExtension, address newExtension);

    /**
     * @dev Replaces `oldExtension` with `newExtension`
     *
     * Performs consecutive execution of retract and extend.
     * First the old extension is retracted using RetractLogic.
     * Second the new extension is attached using ExtendLogic.
     *
     * Since replace does not add any unique functionality aside from a
     * composition of two existing functionalities, it is best to make use
     * of those functionalities, hence the re-use of RetractLogic and 
     * ExtendLogic.
     * 
     * However, if custom logic is desired, exercise caution during 
     * implementation to avoid conflicting methods for add/removing extensions
     *
     * Requirements:
     * - `oldExtension` must be an already attached extension
     * - `newExtension` must be a contract that implements IExtension
    */
    function replace(address oldExtension, address newExtension) external;
}

/**
 * @dev Abstract Extension for RetractLogic
*/
abstract contract ReplaceExtension is IReplaceLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function replace(address oldExtension, address newExtension) external;\n";
    }
    /**
     * @dev see {IExtension-getInterfaceId}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IReplaceLogic.replace.selector;

        interfaces[0] = Interface(
            type(IReplaceLogic).interfaceId,
            functions
        );
    }
}

/**
 * @dev Reference implementation for ReplaceLogic which defines a basic extension
 *      replacement algorithm.
*/
contract ReplaceLogic is ReplaceExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
    */
    modifier onlyOwner {
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner, "unauthorised");
        _;
    }

    /**
     * @dev see {IReplaceLogic-replace} Replaces any old extension with any new extension.
     *
     * Uses RetractLogic to remove old and ExtendLogic to add new.
     *
     * If ExtendLogic is being replaced, ensure that the new extension implements IExtendLogic
     * and use low-level calls to extend.
    */
    function replace(address oldExtension, address newExtension) public override virtual onlyOwner {
        // Initialise both prior to state change for safety
        IRetractLogic retractLogic = IRetractLogic(payable(address(this)));
        IExtendLogic extendLogic = IExtendLogic(payable(address(this)));

        // Remove old extension by using current retract logic instead of implementing conflicting logic
        retractLogic.retract(oldExtension);

        // Attempt to extend with new extension
        try extendLogic.extend(newExtension) {
            // success
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory err) { // if it fails, check if this is due to extend being replaced
            if (Errors.catchCustomError(err, ExtensionNotImplemented.selector)) { // make sure this is a not implemented error due to removal of Extend
                require(newExtension.code.length > 0, "Replace: new extend address is not a contract");

                IExtension old = IExtension(payable(oldExtension));
                IExtension newEx = IExtension(payable(newExtension));

                Interface[] memory oldInterfaces = old.getInterface();
                Interface[] memory newInterfaces = newEx.getInterface();

                // require the interfaceIds implemented by the old extension is equal to the new one
                bytes4 oldFullInterface = oldInterfaces[0].interfaceId;
                bytes4 newFullInterface = newInterfaces[0].interfaceId;

                for (uint256 i = 1; i < oldInterfaces.length; i++) {
                    oldFullInterface = oldFullInterface ^ oldInterfaces[i].interfaceId;
                }

                for (uint256 i = 1; i < newInterfaces.length; i++) {
                    newFullInterface = newFullInterface ^ newInterfaces[i].interfaceId;
                }
                
                require(
                    newFullInterface == oldFullInterface, 
                    "Replace: ExtendLogic interface of new does not match old, please only use identical ExtendLogic interfaces"
                );
                
                // use raw delegate call to re-extend the extension because we have just removed the Extend function
                (bool extendSuccess, ) = newExtension.delegatecall(abi.encodeWithSignature("extend(address)", newExtension));
                require(extendSuccess, "Replace: failed to replace extend");
            } else {
                uint errLen = err.length;
                assembly {
                    revert(err, errLen)
                }
            }
        }

        emit Replaced(oldExtension, newExtension);
    }
}
```

#### PermissioningLogic Extension

PermissioningLogic is an OPTIONAL Extension that provides an ownership pattern for Extendable contracts. It is the default permissioning model used by Extendable.

`PermissioningLogic` MUST implement `Extension`.

`PermissioningLogic` MUST use `PermissioningStorage`.

To implement a different permissioning model, define a new `PermissioningStorage` variable structure to add different roles.

```solidity
pragma solidity ^0.8.4;

/**
 * @dev Interface for PermissioningLogic extension
*/
interface IPermissioningLogic {
    /**
     * @dev Emitted when `owner` is updated in any way
     */
    event OwnerUpdated(address newOwner);

    /**
     * @dev Initialises the `owner` of the contract as `msg.sender`
     *
     * Requirements:
     * - `owner` cannot already be assigned
    */
    function init() external;

    /**
     * @notice Updates the `owner` to `newOwner`
    */
    function updateOwner(address newOwner) external;

    /**
     * @notice Give up ownership of the contract.
     * Proceed with extreme caution as this action is irreversible!!
     *
     * Requirements:
     * - can only be called by the current `owner`
    */
    function renounceOwnership() external;

    /**
     * @notice Returns the current `owner`
    */
    function getOwner() external view returns(address);
}

/**
 * @dev Abstract Extension for PermissioningLogic
*/
abstract contract PermissioningExtension is IPermissioningLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function init() external;\n"
                "function updateOwner(address newOwner) external;\n"
                "function renounceOwnership() external;\n"
                "function getOwner() external view returns(address);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override virtual public returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](4);
        functions[0] = IPermissioningLogic.init.selector;
        functions[1] = IPermissioningLogic.updateOwner.selector;
        functions[2] = IPermissioningLogic.renounceOwnership.selector;
        functions[3] = IPermissioningLogic.getOwner.selector;

        interfaces[0] = Interface(
            type(IPermissioningLogic).interfaceId,
            functions
        );
    }
}

/**
 * @dev Reference implementation for PermissioningLogic which defines the logic to control
 *      and define ownership of contracts
 *
 * Records address as `owner` in the PermissionStorage module. Modifications and access to 
 * the module affect the state wherever it is accessed by Extensions and can be read/written
 * from/to by other attached extensions.
 *
 * Currently used by the ExtendLogic reference implementation to restrict extend permissions
 * to only `owner`. Uses a common function from the storage library `_onlyOwner()` as a
 * modifier replacement. Can be wrapped in a modifier if preferred.
*/
contract PermissioningLogic is PermissioningExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
    */
    modifier onlyOwner {
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner, "unauthorised");
        _;
    }

    /**
     * @dev see {IPermissioningLogic-init}
    */
    function init() override public {
        RoleState storage state = Permissions._getState();
        require(state.owner == address(0x0), "PermissioningLogic: already initialised"); // make sure owner has yet to be set for delegator
        state.owner = _lastCaller();

        emit OwnerUpdated(_lastCaller());
    }

    /**
     * @dev see {IPermissioningLogic-updateOwner}
    */
    function updateOwner(address newOwner) override public onlyOwner {
        require(newOwner != address(0x0), "new owner cannot be the zero address");
        RoleState storage state = Permissions._getState();
        state.owner = newOwner;

        emit OwnerUpdated(newOwner);
    }

    /**
     * @dev see {IPermissioningLogic-renounceOwnership}
    */
    function renounceOwnership() override public onlyOwner {
        address NULL_ADDRESS = 0x000000000000000000000000000000000000dEaD;
        RoleState storage state = Permissions._getState();
        state.owner = NULL_ADDRESS;

        emit OwnerUpdated(NULL_ADDRESS);
    }

    /**
     * @dev see {IPermissioningLogic-getOwner}
    */
    function getOwner() override public view returns(address) {
        RoleState storage state = Permissions._getState();
        return(state.owner);
    }
}
```

### Default Storage Modules

#### ExtendableStorage

This is the reference implementation of `ExtendableStorage` that MUST be used by `Extendable`, `ExtendLogic` and `RetractLogic`.

```solidity
pragma solidity ^0.8.4;

/**
 * @dev Storage struct used to hold state for Extendable contracts
 */
struct ExtendableState {
    // Array of full interfaceIds extended by the Extendable contract instance
    bytes4[] implementedInterfaceIds;

    // Array of function selectors extended by the Extendable contract instance
    mapping(bytes4 => bytes4[]) implementedFunctionsByInterfaceId;

    // Mapping of interfaceId/functionSelector to the extension address that implements it
    mapping(bytes4 => address) extensionContracts;
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library ExtendableStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:extendable-state");

    function _getState()
        internal 
        view
        returns (ExtendableState storage extendableState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            extendableState.slot := position
        }
    }
}
```

#### PermissioningStorage

This is the reference implementation of `ExtendableStorage` that MUST be used by `Extendable`, `ExtendLogic` and `RetractLogic`.

```solidity
pragma solidity ^0.8.4;

/**
 * @dev Storage struct used to hold state for Permissioning roles
 */
struct RoleState {
    address owner;
    // Can add more for DAOs/multisigs or more complex role capture for example:
    // address admin;
    // address manager:
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library Permissions {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:permissions-state");

    function _getState()
        internal 
        view
        returns (RoleState storage roleState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            roleState.slot := position
        }
    }
}
```

### Utilities

#### CallerContext

Usage of `msg.sender` MUST NOT be used in Extension contracts. This is replaced by more expressive `_lastExternalCaller` and `_lastCaller` functions made available by the `CallerContext` contract.

`Extension` inherits `CallerContext`. This contract keeps track of the current caller in the callstack and exposes functions that allow inspection of the current execution's source, ignoring delegatecalls.

```solidity
pragma solidity ^0.8.4;

struct CallerState {
    // Stores a list of callers in the order they are received
    // The current caller context is always the last-most address
    address[] callerStack;
}

library CallerContextStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:caller-state");

    function _getState()
        internal 
        view
        returns (CallerState storage callerState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            callerState.slot := position
        }
    }
}

/**
 * @dev CallerContext contract provides Extensions with proper caller-scoped contexts.
 *      Inherit this contract with your Extension to make use of caller references.
 *
 * `msg.sender` may not behave as developer intends when using within Extensions as many
 * calls may be exchanged between intra-contract extensions which result in a `msg.sender` as self.
 * Instead of using `msg.sender`, replace it with 
 *      - `_lastExternalCaller()` for the most recent caller in the call chain that is external to this contract
 *      - `_lastCaller()` for the most recent caller
 *
 * CallerContext provides a deep callstack to track the caller of the Extension/Extendable contract
 * at any point in the execution cycle.
 *
*/
contract CallerContext {
    /**
     * @dev Returns the most recent caller of this contract that came from outside this contract.
     *
     * Used by extensions that require fetching msg.sender that aren't cross-extension calls.
     * Cross-extension calls resolve msg.sender as the current contract and so the actual
     * caller context is obfuscated.
     * 
     * This function should be used in place of `msg.sender` where external callers are read.
     */
    function _lastExternalCaller() internal view returns(address) {
        CallerState storage state = CallerContextStorage._getState();

        for (uint i = state.callerStack.length - 1; i >= 0; i--) {
            address lastSubsequentCaller = state.callerStack[i];
            if (lastSubsequentCaller != address(this)) {
                return lastSubsequentCaller;
            }
        }

        revert("_lastExternalCaller: end of stack");
    }

    /**
     * @dev Returns the most recent caller of this contract.
     *
     * Last caller may also be the current contract.
     *
     * If the call is directly to the contract, without passing an Extendable, return `msg.sender` instead
     */
    function _lastCaller() internal view returns(address) {
        CallerState storage state = CallerContextStorage._getState();
        if (state.callerStack.length > 0)
            return state.callerStack[state.callerStack.length - 1];
        else
            return msg.sender;
    }
}
```

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).