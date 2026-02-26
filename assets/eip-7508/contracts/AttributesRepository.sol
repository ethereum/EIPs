// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IERC7508.sol";

/**
 * @title ERC-7508 Public On-Chain NFT Attributes Repository
 * @author Steven Pineda, Jan Turk
 * @notice Implementation smart contract of the ERC-7508 Public On-Chain NFT Attributes Repository
 */
contract AttributesRepository is IERC7508 {
    bytes32 public immutable DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                "ERC-7508: Public On-Chain NFT Attributes Repository",
                "1",
                block.chainid,
                address(this)
            )
        );
    bytes32 public immutable SET_UINT_ATTRIBUTE_TYPEHASH =
        keccak256(
            "setUintAttribute(address collection,uint256 tokenId,string memory key,uint256 value)"
        );
    bytes32 public immutable SET_STRING_ATTRIBUTE_TYPEHASH =
        keccak256(
            "setStringAttribute(address collection,uint256 tokenId,string memory key,string memory value)"
        );
    bytes32 public immutable SET_BOOL_ATTRIBUTE_TYPEHASH =
        keccak256(
            "setBoolAttribute(address collection,uint256 tokenId,string memory key,bool value)"
        );
    bytes32 public immutable SET_BYTES_ATTRIBUTE_TYPEHASH =
        keccak256(
            "setBytesAttribute(address collection,uint256 tokenId,string memory key,bytes memory value)"
        );
    bytes32 public immutable SET_ADDRESS_ATTRIBUTE_TYPEHASH =
        keccak256(
            "setAddressAttribute(address collection,uint256 tokenId,string memory key,address value)"
        );

    mapping(address collection => mapping(uint256 keyId => AccessType accessType))
        private _parameterAccessType;
    mapping(address collection => mapping(uint256 keyId => address specificAddress))
        private _parameterSpecificAddress;
    mapping(address collection => IssuerSetting issuerSetting) private _issuerSettings;
    mapping(address collection => mapping(address collaborator => bool isCollaborator)) private _collaborators;

    // For keys, we use a mapping from strings to IDs.
    // The purpose is to store unique string keys only once, since they are more expensive.
    mapping(string key => uint256 keyId) private _keysToIds;
    uint256 private _totalAttributes;

    // For strings, we also use a mapping from strings to IDs, together with a reverse mapping
    // The purpose is to store unique string values only once, since they are more expensive,
    // and storing only IDs.
    mapping(address collection => uint256 numberOfStringValues) private _totalStringValues;
    mapping(address collection => mapping(string stringValue => uint256 stringId)) private _stringValueToId;
    mapping(address collection => mapping(uint256 stringId => string stringValue)) private _stringIdToValue;
    mapping(address collection => mapping(uint256 tokenId => mapping(uint256 stringKeyId => uint256 stringValueId)))
        private _stringValueIds;

    mapping(address collection => mapping(uint256 tokenId => mapping(uint256 addressKeyId => address addressValue)))
        private _addressValues;
    mapping(address collection => mapping(uint256 tokenId => mapping(uint256 bytesKeyId => bytes bytesValue)))
        private _bytesValues;
    mapping(address collection => mapping(uint256 tokenId => mapping(uint256 uintKeyId => uint256 uintValue)))
        private _uintValues;
    mapping(address collection => mapping(uint256 tokenId => mapping(uint256 boolKeyId => bool boolValue)))
        private _boolValues;

    struct IssuerSetting {
        bool registered;
        bool useOwnable;
        address issuer;
    }

    /// Used to signal that the smart contract interacting with the repository does not implement Ownable pattern.
    error OwnableNotImplemented();
    /// Used to signal that the caller is not the issuer of the collection.
    error NotCollectionIssuer();
    /// Used to signal that the collaborator and collaborator rights array are not of equal length.
    error CollaboratorArraysNotEqualLength();
    /// Used to signal that the collection is not registered in the repository yet.
    error CollectionNotRegistered();
    /// Used to signal that the collection is already registered in the repository.
    error CollectionAlreadyRegistered();
    /// Used to signal that the caller is not aa collaborator of the collection.
    error NotCollectionCollaborator();
    /// Used to signal that the caller is not the issuer or a collaborator of the collection.
    error NotCollectionIssuerOrCollaborator();
    /// Used to signal that the caller is not the owner of the token.
    error NotTokenOwner();
    /// Used to signal that the caller is not the specific address allowed to manage the attribute.
    error NotSpecificAddress();
    /// Used to signal that the presigned message's signature is invalid.
    error InvalidSignature();
    /// Used to signal that the presigned message's deadline has expired.
    error ExpiredDeadline();

    /**
     * @inheritdoc IERC7508
     */
    function registerAccessControl(
        address collection,
        address issuer,
        bool useOwnable
    ) external onlyUnregisteredCollection(collection) {
        (bool ownableSuccess, bytes memory ownableReturn) = collection.call(
            abi.encodeWithSignature("owner()")
        );

        if (address(uint160(uint256(bytes32(ownableReturn)))) == address(0)) {
            revert OwnableNotImplemented();
        }
        if (
            ownableSuccess &&
            address(uint160(uint256(bytes32(ownableReturn)))) != msg.sender
        ) {
            revert NotCollectionIssuer();
        }

        IssuerSetting storage issuerSetting = _issuerSettings[collection];
        issuerSetting.registered = true;
        issuerSetting.issuer = issuer;
        issuerSetting.useOwnable = useOwnable;

        emit AccessControlRegistration(
            collection,
            issuer,
            msg.sender,
            useOwnable
        );
    }

    /**
     * @inheritdoc IERC7508
     */
    function manageAccessControl(
        address collection,
        string memory key,
        AccessType accessType,
        address specificAddress
    ) external onlyRegisteredCollection(collection) onlyIssuer(collection) {
        uint256 parameterId = _getIdForKey(key);

        _parameterAccessType[collection][parameterId] = accessType;
        _parameterSpecificAddress[collection][parameterId] = specificAddress;

        emit AccessControlUpdate(collection, key, accessType, specificAddress);
    }

    /**
     * @inheritdoc IERC7508
     */
    function manageCollaborators(
        address collection,
        address[] memory collaboratorAddresses,
        bool[] memory collaboratorAddressAccess
    ) external onlyRegisteredCollection(collection) onlyIssuer(collection) {
        if (collaboratorAddresses.length != collaboratorAddressAccess.length) {
            revert CollaboratorArraysNotEqualLength();
        }
        for (uint256 i; i < collaboratorAddresses.length; ) {
            _collaborators[collection][
                collaboratorAddresses[i]
            ] = collaboratorAddressAccess[i];
            emit CollaboratorUpdate(
                collection,
                collaboratorAddresses[i],
                collaboratorAddressAccess[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function isCollaborator(
        address collaborator,
        address collection
    ) external view returns (bool) {
        return _collaborators[collection][collaborator];
    }

    /**
     * @inheritdoc IERC7508
     */
    function isSpecificAddress(
        address specificAddress,
        address collection,
        string memory key
    ) external view returns (bool) {
        return
            _parameterSpecificAddress[collection][_keysToIds[key]] ==
            specificAddress;
    }

    /**
     * @notice Modifier to check if the caller is authorized to call the function.
     * @dev If the authorization is set to TokenOwner and the tokenId provided is of the non-existent token, the
     *  execution will revert with `ERC721InvalidTokenId` rather than `NotTokenOwner`.
     * @dev The tokenId parameter is only needed for the TokenOwner authorization type, other authorization types ignore
     *  it.
     * @param collection The address of the collection.
     * @param key Key of the attribute.
     * @param tokenId The ID of the token.
     */
    modifier onlyAuthorizedCaller(
        address collection,
        string memory key,
        uint256 tokenId
    ) {
        _onlyAuthorizedCaller(msg.sender, collection, key, tokenId);
        _;
    }

    /**
     * @notice Modifier to check if the collection is registered.
     * @param collection Address of the collection.
     */
    modifier onlyRegisteredCollection(address collection) {
        if (!_issuerSettings[collection].registered) {
            revert CollectionNotRegistered();
        }
        _;
    }

    /**
     * @notice Modifier to check if the collection is not registered.
     * @param collection Address of the collection.
     */
    modifier onlyUnregisteredCollection(address collection) {
        if (_issuerSettings[collection].registered) {
            revert CollectionAlreadyRegistered();
        }
        _;
    }

    /**
     * @notice Modifier to check if the caller is the issuer of the collection.
     * @param collection Address of the collection.
     */
    modifier onlyIssuer(address collection) {
        if (_issuerSettings[collection].useOwnable) {
            if (Ownable(collection).owner() != msg.sender) {
                revert NotCollectionIssuer();
            }
        } else if (_issuerSettings[collection].issuer != msg.sender) {
            revert NotCollectionIssuer();
        }
        _;
    }

    /**
     * @notice Function to check if the caller is authorized to mamage a given parameter.
     * @param collection The address of the collection.
     * @param key Key of the attribute.
     * @param tokenId The ID of the token.
     */
    function _onlyAuthorizedCaller(
        address caller,
        address collection,
        string memory key,
        uint256 tokenId
    ) private view {
        AccessType accessType = _parameterAccessType[collection][
            _keysToIds[key]
        ];

        if (
            accessType == AccessType.Issuer &&
            ((_issuerSettings[collection].useOwnable &&
                Ownable(collection).owner() != caller) ||
                (!_issuerSettings[collection].useOwnable &&
                    _issuerSettings[collection].issuer != caller))
        ) {
            revert NotCollectionIssuer();
        } else if (
            accessType == AccessType.Collaborator &&
            !_collaborators[collection][caller]
        ) {
            revert NotCollectionCollaborator();
        } else if (
            accessType == AccessType.IssuerOrCollaborator &&
            ((_issuerSettings[collection].useOwnable &&
                Ownable(collection).owner() != caller) ||
                (!_issuerSettings[collection].useOwnable &&
                    _issuerSettings[collection].issuer != caller)) &&
            !_collaborators[collection][caller]
        ) {
            revert NotCollectionIssuerOrCollaborator();
        } else if (
            accessType == AccessType.TokenOwner &&
            IERC721(collection).ownerOf(tokenId) != caller
        ) {
            revert NotTokenOwner();
        } else if (
            accessType == AccessType.SpecificAddress &&
            !(_parameterSpecificAddress[collection][_keysToIds[key]] == caller)
        ) {
            revert NotSpecificAddress();
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function getStringTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (string memory) {
        uint256 idForValue = _stringValueIds[collection][tokenId][
            _keysToIds[key]
        ];
        return _stringIdToValue[collection][idForValue];
    }

    /**
     * @inheritdoc IERC7508
     */
    function getUintTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (uint256) {
        return _uintValues[collection][tokenId][_keysToIds[key]];
    }

    /**
     * @inheritdoc IERC7508
     */
    function getBoolTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (bool) {
        return _boolValues[collection][tokenId][_keysToIds[key]];
    }

    /**
     * @inheritdoc IERC7508
     */
    function getAddressTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (address) {
        return _addressValues[collection][tokenId][_keysToIds[key]];
    }

    /**
     * @inheritdoc IERC7508
     */
    function getBytesTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (bytes memory) {
        return _bytesValues[collection][tokenId][_keysToIds[key]];
    }

    /**
     * @inheritdoc IERC7508
     */
    function getTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory stringKeys,
        string[] memory uintKeys,
        string[] memory boolKeys,
        string[] memory addressKeys,
        string[] memory bytesKeys
    )
        external
        view
        returns (
            StringAttribute[] memory stringAttributes,
            UintAttribute[] memory uintAttributes,
            BoolAttribute[] memory boolAttributes,
            AddressAttribute[] memory addressAttributes,
            BytesAttribute[] memory bytesAttributes
        )
    {
        stringAttributes = getStringTokenAttributes(
            collection,
            tokenId,
            stringKeys
        );

        uintAttributes = getUintTokenAttributes(collection, tokenId, uintKeys);

        boolAttributes = getBoolTokenAttributes(collection, tokenId, boolKeys);

        addressAttributes = getAddressTokenAttributes(
            collection,
            tokenId,
            addressKeys
        );

        bytesAttributes = getBytesTokenAttributes(
            collection,
            tokenId,
            bytesKeys
        );
    }

    /**
     * @inheritdoc IERC7508
     */
    function getStringTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory stringKeys
    ) public view returns (StringAttribute[] memory) {
        uint256 stringLen = stringKeys.length;

        StringAttribute[] memory stringAttributes = new StringAttribute[](
            stringLen
        );

        for (uint i; i < stringLen; ) {
            stringAttributes[i] = StringAttribute({
                key: stringKeys[i],
                value: _stringIdToValue[collection][
                    _stringValueIds[collection][tokenId][
                        _keysToIds[stringKeys[i]]
                    ]
                ]
            });
            unchecked {
                ++i;
            }
        }

        return stringAttributes;
    }

    /**
     * @inheritdoc IERC7508
     */
    function getUintTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory uintKeys
    ) public view returns (UintAttribute[] memory) {
        uint256 uintLen = uintKeys.length;

        UintAttribute[] memory uintAttributes = new UintAttribute[](uintLen);

        for (uint i; i < uintLen; ) {
            uintAttributes[i] = UintAttribute({
                key: uintKeys[i],
                value: _uintValues[collection][tokenId][_keysToIds[uintKeys[i]]]
            });
            unchecked {
                ++i;
            }
        }

        return uintAttributes;
    }

    /**
     * @inheritdoc IERC7508
     */
    function getBoolTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory boolKeys
    ) public view returns (BoolAttribute[] memory) {
        uint256 boolLen = boolKeys.length;

        BoolAttribute[] memory boolAttributes = new BoolAttribute[](boolLen);

        for (uint i; i < boolLen; ) {
            boolAttributes[i] = BoolAttribute({
                key: boolKeys[i],
                value: _boolValues[collection][tokenId][_keysToIds[boolKeys[i]]]
            });
            unchecked {
                ++i;
            }
        }

        return boolAttributes;
    }

    /**
     * @inheritdoc IERC7508
     */
    function getAddressTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory addressKeys
    ) public view returns (AddressAttribute[] memory) {
        uint256 addressLen = addressKeys.length;

        AddressAttribute[] memory addressAttributes = new AddressAttribute[](
            addressLen
        );

        for (uint i; i < addressLen; ) {
            addressAttributes[i] = AddressAttribute({
                key: addressKeys[i],
                value: _addressValues[collection][tokenId][
                    _keysToIds[addressKeys[i]]
                ]
            });
            unchecked {
                ++i;
            }
        }

        return addressAttributes;
    }

    /**
     * @inheritdoc IERC7508
     */
    function getBytesTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory bytesKeys
    ) public view returns (BytesAttribute[] memory) {
        uint256 bytesLen = bytesKeys.length;

        BytesAttribute[] memory bytesAttributes = new BytesAttribute[](bytesLen);

        for (uint i; i < bytesLen; ) {
            bytesAttributes[i] = BytesAttribute({
                key: bytesKeys[i],
                value: _bytesValues[collection][tokenId][
                    _keysToIds[bytesKeys[i]]
                ]
            });
            unchecked {
                ++i;
            }
        }

        return bytesAttributes;
    }

    /**
     * @inheritdoc IERC7508
     */
    function prepareMessageToPresignUintAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        uint256 value,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    SET_UINT_ATTRIBUTE_TYPEHASH,
                    collection,
                    tokenId,
                    key,
                    value,
                    deadline
                )
            );
    }

    /**
     * @inheritdoc IERC7508
     */
    function prepareMessageToPresignStringAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        string memory value,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    SET_STRING_ATTRIBUTE_TYPEHASH,
                    collection,
                    tokenId,
                    key,
                    value,
                    deadline
                )
            );
    }

    /**
     * @inheritdoc IERC7508
     */
    function prepareMessageToPresignBoolAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bool value,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    SET_BOOL_ATTRIBUTE_TYPEHASH,
                    collection,
                    tokenId,
                    key,
                    value,
                    deadline
                )
            );
    }

    /**
     * @inheritdoc IERC7508
     */
    function prepareMessageToPresignBytesAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bytes memory value,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    SET_BYTES_ATTRIBUTE_TYPEHASH,
                    collection,
                    tokenId,
                    key,
                    value,
                    deadline
                )
            );
    }

    /**
     * @inheritdoc IERC7508
     */
    function prepareMessageToPresignAddressAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        address value,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR,
                    SET_ADDRESS_ATTRIBUTE_TYPEHASH,
                    collection,
                    tokenId,
                    key,
                    value,
                    deadline
                )
            );
    }

    /**
     * @inheritdoc IERC7508
     */
    function setUintAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        uint256 value
    ) external onlyAuthorizedCaller(collection, key, tokenId) {
        _uintValues[collection][tokenId][_getIdForKey(key)] = value;
        emit UintAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function setStringAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        string memory value
    ) external onlyAuthorizedCaller(collection, key, tokenId) {
        _stringValueIds[collection][tokenId][
            _getIdForKey(key)
        ] = _getStringIdForValue(collection, value);
        emit StringAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function setBoolAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bool value
    ) external onlyAuthorizedCaller(collection, key, tokenId) {
        _boolValues[collection][tokenId][_getIdForKey(key)] = value;
        emit BoolAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function setBytesAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bytes memory value
    ) external onlyAuthorizedCaller(collection, key, tokenId) {
        _bytesValues[collection][tokenId][_getIdForKey(key)] = value;
        emit BytesAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function setAddressAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        address value
    ) external onlyAuthorizedCaller(collection, key, tokenId) {
        _addressValues[collection][tokenId][_getIdForKey(key)] = value;
        emit AddressAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function setStringAttributes(
        address collection,
        uint256 tokenId,
        StringAttribute[] memory attributes
    ) external onlyAuthorizedCaller(collection, "", tokenId) {
        for (uint256 i = 0; i < attributes.length; ) {
            _stringValueIds[collection][tokenId][
                _getIdForKey(attributes[i].key)
            ] = _getStringIdForValue(collection, attributes[i].value);
            emit StringAttributeUpdated(
                collection,
                tokenId,
                attributes[i].key,
                attributes[i].value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function setUintAttributes(
        address collection,
        uint256 tokenId,
        UintAttribute[] memory attributes
    ) external onlyAuthorizedCaller(collection, "", tokenId) {
        for (uint256 i = 0; i < attributes.length; ) {
            _uintValues[collection][tokenId][
                _getIdForKey(attributes[i].key)
            ] = attributes[i].value;
            emit UintAttributeUpdated(
                collection,
                tokenId,
                attributes[i].key,
                attributes[i].value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function setBoolAttributes(
        address collection,
        uint256 tokenId,
        BoolAttribute[] memory attributes
    ) external onlyAuthorizedCaller(collection, "", tokenId) {
        for (uint256 i = 0; i < attributes.length; ) {
            _boolValues[collection][tokenId][
                _getIdForKey(attributes[i].key)
            ] = attributes[i].value;
            emit BoolAttributeUpdated(
                collection,
                tokenId,
                attributes[i].key,
                attributes[i].value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function setAddressAttributes(
        address collection,
        uint256 tokenId,
        AddressAttribute[] memory attributes
    ) external onlyAuthorizedCaller(collection, "", tokenId) {
        for (uint256 i = 0; i < attributes.length; ) {
            _addressValues[collection][tokenId][
                _getIdForKey(attributes[i].key)
            ] = attributes[i].value;
            emit AddressAttributeUpdated(
                collection,
                tokenId,
                attributes[i].key,
                attributes[i].value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function setBytesAttributes(
        address collection,
        uint256 tokenId,
        BytesAttribute[] memory attributes
    ) external onlyAuthorizedCaller(collection, "", tokenId) {
        for (uint256 i = 0; i < attributes.length; ) {
            _bytesValues[collection][tokenId][
                _getIdForKey(attributes[i].key)
            ] = attributes[i].value;
            emit BytesAttributeUpdated(
                collection,
                tokenId,
                attributes[i].key,
                attributes[i].value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function setTokenAttributes(
        address collection,
        uint256 tokenId,
        StringAttribute[] memory stringAttributes,
        UintAttribute[] memory uintAttributes,
        BoolAttribute[] memory boolAttributes,
        AddressAttribute[] memory addressAttributes,
        BytesAttribute[] memory bytesAttributes
    ) external onlyAuthorizedCaller(collection, "", tokenId) {
        for (uint256 i = 0; i < stringAttributes.length; ) {
            _stringValueIds[collection][tokenId][
                _getIdForKey(stringAttributes[i].key)
            ] = _getStringIdForValue(collection, stringAttributes[i].value);
            emit StringAttributeUpdated(
                collection,
                tokenId,
                stringAttributes[i].key,
                stringAttributes[i].value
            );
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < uintAttributes.length; ) {
            _uintValues[collection][tokenId][
                _getIdForKey(uintAttributes[i].key)
            ] = uintAttributes[i].value;
            emit UintAttributeUpdated(
                collection,
                tokenId,
                uintAttributes[i].key,
                uintAttributes[i].value
            );
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < boolAttributes.length; ) {
            _boolValues[collection][tokenId][
                _getIdForKey(boolAttributes[i].key)
            ] = boolAttributes[i].value;
            emit BoolAttributeUpdated(
                collection,
                tokenId,
                boolAttributes[i].key,
                boolAttributes[i].value
            );
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < addressAttributes.length; ) {
            _addressValues[collection][tokenId][
                _getIdForKey(addressAttributes[i].key)
            ] = addressAttributes[i].value;
            emit AddressAttributeUpdated(
                collection,
                tokenId,
                addressAttributes[i].key,
                addressAttributes[i].value
            );
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < bytesAttributes.length; ) {
            _bytesValues[collection][tokenId][
                _getIdForKey(bytesAttributes[i].key)
            ] = bytesAttributes[i].value;
            emit BytesAttributeUpdated(
                collection,
                tokenId,
                bytesAttributes[i].key,
                bytesAttributes[i].value
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IERC7508
     */
    function presignedSetUintAttribute(
        address setter,
        address collection,
        uint256 tokenId,
        string memory key,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) {
            revert ExpiredDeadline();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        DOMAIN_SEPARATOR,
                        SET_UINT_ATTRIBUTE_TYPEHASH,
                        collection,
                        tokenId,
                        key,
                        value,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(digest, v, r, s);
        if (signer != setter) {
            revert InvalidSignature();
        }
        _onlyAuthorizedCaller(signer, collection, key, tokenId);

        _uintValues[collection][tokenId][_getIdForKey(key)] = value;
        emit UintAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function presignedSetStringAttribute(
        address setter,
        address collection,
        uint256 tokenId,
        string memory key,
        string memory value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) {
            revert ExpiredDeadline();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        DOMAIN_SEPARATOR,
                        SET_STRING_ATTRIBUTE_TYPEHASH,
                        collection,
                        tokenId,
                        key,
                        value,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(digest, v, r, s);
        if (signer != setter) {
            revert InvalidSignature();
        }
        _onlyAuthorizedCaller(signer, collection, key, tokenId);

        _stringValueIds[collection][tokenId][
            _getIdForKey(key)
        ] = _getStringIdForValue(collection, value);
        emit StringAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function presignedSetBoolAttribute(
        address setter,
        address collection,
        uint256 tokenId,
        string memory key,
        bool value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) {
            revert ExpiredDeadline();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        DOMAIN_SEPARATOR,
                        SET_BOOL_ATTRIBUTE_TYPEHASH,
                        collection,
                        tokenId,
                        key,
                        value,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(digest, v, r, s);
        if (signer != setter) {
            revert InvalidSignature();
        }
        _onlyAuthorizedCaller(signer, collection, key, tokenId);

        _boolValues[collection][tokenId][_getIdForKey(key)] = value;
        emit BoolAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function presignedSetBytesAttribute(
        address setter,
        address collection,
        uint256 tokenId,
        string memory key,
        bytes memory value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) {
            revert ExpiredDeadline();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        DOMAIN_SEPARATOR,
                        SET_BYTES_ATTRIBUTE_TYPEHASH,
                        collection,
                        tokenId,
                        key,
                        value,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(digest, v, r, s);
        if (signer != setter) {
            revert InvalidSignature();
        }
        _onlyAuthorizedCaller(signer, collection, key, tokenId);

        _bytesValues[collection][tokenId][_getIdForKey(key)] = value;
        emit BytesAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @inheritdoc IERC7508
     */
    function presignedSetAddressAttribute(
        address setter,
        address collection,
        uint256 tokenId,
        string memory key,
        address value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) {
            revert ExpiredDeadline();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        DOMAIN_SEPARATOR,
                        SET_ADDRESS_ATTRIBUTE_TYPEHASH,
                        collection,
                        tokenId,
                        key,
                        value,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(digest, v, r, s);
        if (signer != setter) {
            revert InvalidSignature();
        }
        _onlyAuthorizedCaller(signer, collection, key, tokenId);

        _addressValues[collection][tokenId][_getIdForKey(key)] = value;
        emit AddressAttributeUpdated(collection, tokenId, key, value);
    }

    /**
     * @notice Used to get the Id for a key. If the key does not exist, a new ID is created.
     *  IDs are shared among all tokens and types
     * @dev The ID of 0 is not used as it represents the default value.
     * @param key The attribute key
     * @return The ID of the key
     */
    function _getIdForKey(string memory key) internal returns (uint256) {
        if (_keysToIds[key] == 0) {
            _totalAttributes++;
            _keysToIds[key] = _totalAttributes;
            return _totalAttributes;
        } else {
            return _keysToIds[key];
        }
    }

    /**
     * @notice Used to get the ID for a string value. If the value does not exist, a new ID is created.
     * @dev IDs are shared among all tokens and used only for strings.
     * @param collection Address of the collection being checked for string ID
     * @param value The attribute value
     * @return The id for the string value
     */
    function _getStringIdForValue(
        address collection,
        string memory value
    ) internal returns (uint256) {
        if (_stringValueToId[collection][value] == 0) {
            _totalStringValues[collection]++;
            _stringValueToId[collection][value] = _totalStringValues[
                collection
            ];
            _stringIdToValue[collection][
                _totalStringValues[collection]
            ] = value;
            return _totalStringValues[collection];
        } else {
            return _stringValueToId[collection][value];
        }
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC7508).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
