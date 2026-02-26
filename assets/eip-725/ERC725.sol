pragma solidity ^0.8.8;

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding [ERC165] standard.
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC165 is IERC165 {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC173 {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC725X is IERC165 {
    /**
     * @notice Emitted when deploying a contract
     * @param operationType The opcode used to deploy the contract (CREATE or CREATE2)
     * @param contractAddress The created contract address
     * @param value The amount of native tokens (in Wei) sent to fund the created contract address
     * @param salt The salt used in case of CREATE2. Will be bytes32(0) in case of CREATE operation
     */
    event ContractCreated(
        uint256 indexed operationType,
        address indexed contractAddress,
        uint256 indexed value,
        bytes32 salt
    );

    /**
     * @notice Emitted when calling an address (EOA or contract)
     * @param operationType The low-level call opcode used to call the `to` address (CALL, STATICALL or DELEGATECALL)
     * @param target The address to call. `target` will be unused if a contract is created (operation types 1 and 2).
     * @param value The amount of native tokens transferred with the call (in Wei)
     * @param selector The first 4 bytes (= function selector) of the data sent with the call
     */
    event Executed(
        uint256 indexed operationType,
        address indexed target,
        uint256 indexed value,
        bytes4 selector
    );

    /**
     * @param operationType The operation type used: CALL = 0; CREATE = 1; CREATE2 = 2; STATICCALL = 3; DELEGATECALL = 4
     * @param target The address of the EOA or smart contract.  (unused if a contract is created via operation type 1 or 2)
     * @param value The amount of native tokens to transfer (in Wei)
     * @param data The call data, or the creation bytecode of the contract to deploy
     *
     * @dev Generic executor function to:
     *
     * - send native tokens to any address.
     * - interact with any contract by passing an abi-encoded function call in the `data` parameter.
     * - deploy a contract by providing its creation bytecode in the `data` parameter.
     *
     * Requirements:
     *
     * - SHOULD only be callable by the owner of the contract set via ERC173.
     * - if a `value` is provided, the contract MUST have at least this amount in its balance to execute successfully.
     * - if the operation type is STATICCALL or DELEGATECALL, `value` SHOULD be 0.
     * - `target` SHOULD be address(0) when deploying a contract.
     *
     * Emits an {Executed} event, when a call is made with `operationType` 0 (CALL), 3 (STATICCALL) or 4 (DELEGATECALL)
     * Emits a {ContractCreated} event, when deploying a contract with `operationType` 1 (CREATE) or 2 (CREATE2)
     */
    function execute(
        uint256 operationType,
        address target,
        uint256 value,
        bytes memory data
    ) external payable returns (bytes memory);

    /**
     * @param operationsType The list of operations type used: CALL = 0; CREATE = 1; CREATE2 = 2; STATICCALL = 3; DELEGATECALL = 4
     * @param targets The list of addresses to call. `targets` will be unused if a contract is created (operation types 1 and 2).
     * @param values The list of native token amounts to transfer (in Wei)
     * @param datas The list of call data, or the creation bytecode of the contract to deploy
     *
     * @dev Generic batch executor function to:
     *
     * - send native tokens to any address.
     * - interact with any contract by passing an abi-encoded function call in the `datas` parameter.
     * - deploy a contract by providing its creation bytecode in the `datas` parameter.
     *
     * Requirements:
     *
     * - The length of the parameters provided MUST be equal
     * - SHOULD only be callable by the owner of the contract set via ERC173.
     * - if a `values` is provided, the contract MUST have at least this amount in its balance to execute successfully.
     * - if the operation type is STATICCALL or DELEGATECALL, `values` SHOULD be 0.
     * - `targets` SHOULD be address(0) when deploying a contract.
     *
     * Emits an {Executed} event, when a call is made with `operationType` 0 (CALL), 3 (STATICCALL) or 4 (DELEGATECALL)
     * Emits a {ContractCreated} event, when deploying a contract with `operationType` 1 (CREATE) or 2 (CREATE2)
     */
    function executeBatch(
        uint256[] memory operationsType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable returns (bytes[] memory);
}

// ERC165 INTERFACE IDs
bytes4 constant _INTERFACEID_ERC725X = 0x7545acac;

// ERC725X OPERATION TYPES
uint256 constant OPERATION_0_CALL = 0;
uint256 constant OPERATION_1_CREATE = 1;
uint256 constant OPERATION_2_CREATE2 = 2;
uint256 constant OPERATION_3_STATICCALL = 3;
uint256 constant OPERATION_4_DELEGATECALL = 4;

/**
 * @dev reverts when trying to send more native tokens `value` than available in current `balance`.
 * @param balance the balance of the ERC725X contract.
 * @param value the amount of native tokens sent via `ERC725X.execute(...)`.
 */
error ERC725X_InsufficientBalance(uint256 balance, uint256 value);

/**
 * @dev reverts when the `operationTypeProvided` is none of the default operation types available.
 * (CALL = 0; CREATE = 1; CREATE2 = 2; STATICCALL = 3; DELEGATECALL = 4)
 */
error ERC725X_UnknownOperationType(uint256 operationTypeProvided);

/**
 * @dev the `value` parameter (= sending native tokens) is not allowed when making a staticcall
 * via `ERC725X.execute(...)` because sending native tokens is a state changing operation.
 */
error ERC725X_MsgValueDisallowedInStaticCall();

/**
 * @dev the `value` parameter (= sending native tokens) is not allowed when making a delegatecall
 * via `ERC725X.execute(...)` because msg.value is persisting.
 */
error ERC725X_MsgValueDisallowedInDelegateCall();

/**
 * @dev reverts when passing a `to` address while deploying a contract va `ERC725X.execute(...)`
 * whether using operation type 1 (CREATE) or 2 (CREATE2).
 */
error ERC725X_CreateOperationsRequireEmptyRecipientAddress();

/**
 * @dev reverts when contract deployment via `ERC725X.execute(...)` failed.
 * whether using operation type 1 (CREATE) or 2 (CREATE2).
 */
error ERC725X_ContractDeploymentFailed();

/**
 * @dev reverts when no contract bytecode was provided as parameter when trying to deploy a contract
 * via `ERC725X.execute(...)`, whether using operation type 1 (CREATE) or 2 (CREATE2).
 */
error ERC725X_NoContractBytecodeProvided();

/**
 * @dev reverts when there is not the same number of operation, to addresses, value, and data.
 */
error ERC725X_ExecuteParametersLengthMismatch();

contract ERC725X is ERC173, ERC165, IERC725X {
    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_ERC725X ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC725X
     */
    function execute(
        uint256 operationType,
        address target,
        uint256 value,
        bytes memory data
    ) public payable virtual onlyOwner returns (bytes memory) {
        if (address(this).balance < value) {
            revert ERC725X_InsufficientBalance(address(this).balance, value);
        }
        return _execute(operationType, target, value, data);
    }

    /**
     * @inheritdoc IERC725X
     */
    function executeBatch(
        uint256[] memory operationsType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas
    ) public payable virtual onlyOwner returns (bytes[] memory result) {
        if (
            operationsType.length != targets.length ||
            (targets.length != values.length || values.length != datas.length)
        ) revert ERC725X_ExecuteParametersLengthMismatch();

        result = new bytes[](operationsType.length);
        for (uint256 i = 0; i < operationsType.length; i++) {
            if (address(this).balance < values[i])
                revert ERC725X_InsufficientBalance(
                    address(this).balance,
                    values[i]
                );

            result[i] = _execute(
                operationsType[i],
                targets[i],
                values[i],
                datas[i]
            );
        }
    }

    function _execute(
        uint256 operationType,
        address target,
        uint256 value,
        bytes memory data
    ) internal virtual returns (bytes memory) {
        // CALL
        if (operationType == OPERATION_0_CALL) {
            return _executeCall(target, value, data);
        }

        // Deploy with CREATE
        if (operationType == uint256(OPERATION_1_CREATE)) {
            if (target != address(0))
                revert ERC725X_CreateOperationsRequireEmptyRecipientAddress();
            return _deployCreate(value, data);
        }

        // Deploy with CREATE2
        if (operationType == uint256(OPERATION_2_CREATE2)) {
            if (target != address(0))
                revert ERC725X_CreateOperationsRequireEmptyRecipientAddress();
            return _deployCreate2(value, data);
        }

        // STATICCALL
        if (operationType == uint256(OPERATION_3_STATICCALL)) {
            if (value != 0) revert ERC725X_MsgValueDisallowedInStaticCall();
            return _executeStaticCall(target, data);
        }

        // DELEGATECALL
        //
        // WARNING! delegatecall is a dangerous operation type! use with EXTRA CAUTION
        //
        // delegate allows to call another deployed contract and use its functions
        // to update the state of the current calling contract.
        //
        // this can lead to unexpected behaviour on the contract storage, such as:
        // - updating any state variables (even if these are protected)
        // - update the contract owner
        // - run selfdestruct in the context of this contract
        //
        if (operationType == uint256(OPERATION_4_DELEGATECALL)) {
            if (value != 0) revert ERC725X_MsgValueDisallowedInDelegateCall();
            return _executeDelegateCall(target, data);
        }

        revert ERC725X_UnknownOperationType(operationType);
    }

    /**
     * @dev perform low-level call (operation type = 0)
     * @param target The address on which call is executed
     * @param value The value to be sent with the call
     * @param data The data to be sent with the call
     * @return result The data from the call
     */
    function _executeCall(
        address target,
        uint256 value,
        bytes memory data
    ) internal virtual returns (bytes memory result) {
        emit Executed(OPERATION_0_CALL, target, value, bytes4(data));

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );
        result = Address.verifyCallResult(
            success,
            returnData,
            "ERC725X: Unknown Error"
        );
    }

    /**
     * @dev perform low-level staticcall (operation type = 3)
     * @param target The address on which staticcall is executed
     * @param data The data to be sent with the staticcall
     * @return result The data returned from the staticcall
     */
    function _executeStaticCall(address target, bytes memory data)
        internal
        virtual
        returns (bytes memory result)
    {
        emit Executed(OPERATION_3_STATICCALL, target, 0, bytes4(data));

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = target.staticcall(data);
        result = Address.verifyCallResult(
            success,
            returnData,
            "ERC725X: Unknown Error"
        );
    }

    /**
     * @dev perform low-level delegatecall (operation type = 4)
     * @param target The address on which delegatecall is executed
     * @param data The data to be sent with the delegatecall
     * @return result The data returned from the delegatecall
     */
    function _executeDelegateCall(address target, bytes memory data)
        internal
        virtual
        returns (bytes memory result)
    {
        emit Executed(OPERATION_4_DELEGATECALL, target, 0, bytes4(data));

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = target.delegatecall(data);
        result = Address.verifyCallResult(
            success,
            returnData,
            "ERC725X: Unknown Error"
        );
    }

    /**
     * @dev deploy a contract using the CREATE opcode (operation type = 1)
     * @param value The value to be sent to the contract created
     * @param creationCode The contract creation bytecode to deploy appended with the constructor argument(s)
     * @return newContract The address of the contract created as bytes
     */
    function _deployCreate(uint256 value, bytes memory creationCode)
        internal
        virtual
        returns (bytes memory newContract)
    {
        if (creationCode.length == 0) {
            revert ERC725X_NoContractBytecodeProvided();
        }

        address contractAddress;
        // solhint-disable no-inline-assembly
        assembly {
            contractAddress := create(
                value,
                add(creationCode, 0x20),
                mload(creationCode)
            )
        }

        if (contractAddress == address(0)) {
            revert ERC725X_ContractDeploymentFailed();
        }

        newContract = abi.encodePacked(contractAddress);
        emit ContractCreated(
            OPERATION_1_CREATE,
            contractAddress,
            value,
            bytes32(0)
        );
    }

    /**
     * @dev deploy a contract using the CREATE2 opcode (operation type = 2)
     * @param value The value to be sent to the contract created
     * @param creationCode The contract creation bytecode to deploy appended with the constructor argument(s) and a bytes32 salt
     * @return newContract The address of the contract created as bytes
     */
    function _deployCreate2(uint256 value, bytes memory creationCode)
        internal
        virtual
        returns (bytes memory newContract)
    {
        bytes32 salt = BytesLib.toBytes32(
            creationCode,
            creationCode.length - 32
        );
        bytes memory bytecode = BytesLib.slice(
            creationCode,
            0,
            creationCode.length - 32
        );

        address contractAddress;
        require(
            address(this).balance >= value,
            "Create2: insufficient balance"
        );
        require(creationCode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            contractAddress := create2(
                value,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }
        require(contractAddress != address(0), "Create2: Failed on deploy");

        newContract = abi.encodePacked(contractAddress);
        emit ContractCreated(OPERATION_2_CREATE2, contractAddress, value, salt);
    }
}

/**
 * @title The interface for ERC725Y General data key/value store
 * @dev ERC725Y provides the ability to set arbitrary data key/value pairs that can be changed over time
 * It is intended to standardise certain data key/value pairs to allow automated read and writes
 * from/to the contract storage
 */
interface IERC725Y is IERC165 {
    /**
     * @notice Emitted when data at a key is changed
     * @param dataKey The data key which data value is set
     * @param dataValue The data value to set
     */
    event DataChanged(bytes32 indexed dataKey, bytes dataValue);

    /**
     * @notice Gets singular data at a given `dataKey`
     * @param dataKey The key which value to retrieve
     * @return dataValue The data stored at the key
     */
    function getData(bytes32 dataKey)
        external
        view
        returns (bytes memory dataValue);

    /**
     * @notice Gets array of data for multiple given keys
     * @param dataKeys The array of keys which values to retrieve
     * @return dataValues The array of data stored at multiple keys
     */
    function getDataBatch(bytes32[] memory dataKeys)
        external
        view
        returns (bytes[] memory dataValues);

    /**
     * @notice Sets singular data for a given `dataKey`
     * @param dataKey The key to retrieve stored value
     * @param dataValue The value to set
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32 dataKey, bytes memory dataValue) external;

    /**
     * @param dataKeys The array of data keys for values to set
     * @param dataValues The array of values to set
     * @dev Sets array of data for multiple given `dataKeys`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setDataBatch(bytes32[] memory dataKeys, bytes[] memory dataValues)
        external;
}

// ERC165 INTERFACE IDs
bytes4 constant _INTERFACEID_ERC725Y = 0x629aa694;

/**
 * @dev reverts when there is not the same number of elements in the lists of data keys and data values
 * when calling setData(bytes32[],bytes[]).
 * @param dataKeysLength the number of data keys in the bytes32[] dataKeys
 * @param dataValuesLength the number of data value in the bytes[] dataValue
 */
error ERC725Y_DataKeysValuesLengthMismatch(
    uint256 dataKeysLength,
    uint256 dataValuesLength
);

contract ERC725Y is ERC173, ERC165, IERC725Y {
    // overrides

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_ERC725Y ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Map the dataKeys to their dataValues
     */
    mapping(bytes32 => bytes) internal _store;

    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32 dataKey)
        public
        view
        virtual
        returns (bytes memory dataValue)
    {
        dataValue = _getData(dataKey);
    }

    /**
     * @inheritdoc IERC725Y
     */
    function getDataBatch(bytes32[] memory dataKeys)
        public
        view
        virtual
        returns (bytes[] memory dataValues)
    {
        dataValues = new bytes[](dataKeys.length);

        for (uint256 i = 0; i < dataKeys.length; i++) {
            dataValues[i] = _getData(dataKeys[i]);
        }

        return dataValues;
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32 dataKey, bytes memory dataValue)
        public
        virtual
        onlyOwner
    {
        _setData(dataKey, dataValue);
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setDataBatch(bytes32[] memory dataKeys, bytes[] memory dataValues)
        public
        virtual
        onlyOwner
    {
        if (dataKeys.length != dataValues.length) {
            revert ERC725Y_DataKeysValuesLengthMismatch(
                dataKeys.length,
                dataValues.length
            );
        }

        for (uint256 i = 0; i < dataKeys.length; i++) {
            _setData(dataKeys[i], dataValues[i]);
        }
    }

    function _getData(bytes32 dataKey)
        internal
        view
        virtual
        returns (bytes memory dataValue)
    {
        return _store[dataKey];
    }

    function _setData(bytes32 dataKey, bytes memory dataValue)
        internal
        virtual
    {
        _store[dataKey] = dataValue;
        emit DataChanged(dataKey, dataValue);
    }
}

contract ERC725 is ERC725X, ERC725Y {
    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC725X, ERC725Y)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_ERC725X ||
            interfaceId == _INTERFACEID_ERC725Y ||
            super.supportsInterface(interfaceId);
    }
}

// external needed libraries

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

library Address {
    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
