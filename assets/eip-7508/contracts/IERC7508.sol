// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ERC-7508 Public On-Chain NFT Attributes Repository
 * @author Steven Pineda, Jan Turk
 * @notice Interface smart contract of Dynamic On-Chain Token Attributes Repository
 */
interface IERC7508 is IERC165 {
    /**
     * @notice A list of supported access types.
     * @return The `Issuer` type, where only the issuer can manage the parameter.
     * @return The `Collaborator` type, where only the collaborators can manage the parameter.
     * @return The `IssuerOrCollaborator` type, where only the issuer or collaborators can manage the parameter.
     * @return The `TokenOwner` type, where only the token owner can manage the parameters of their tokens.
     * @return The `SpecificAddress` type, where only specific addresses can manage the parameter.
     */
    enum AccessType {
        Issuer,
        Collaborator,
        IssuerOrCollaborator,
        TokenOwner,
        SpecificAddress
    }

    /**
     * @notice Structure used to represent a string attribute.
     * @return key The key of the attribute
     * @return value The value of the attribute
     */
    struct StringAttribute {
        string key;
        string value;
    }

    /**
     * @notice Structure used to represent an uint attribute.
     * @return key The key of the attribute
     * @return value The value of the attribute
     */
    struct UintAttribute {
        string key;
        uint256 value;
    }

    /**
     * @notice Structure used to represent a boolean attribute.
     * @return key The key of the attribute
     * @return value The value of the attribute
     */
    struct BoolAttribute {
        string key;
        bool value;
    }

    /**
     * @notice Structure used to represent an address attribute.
     * @return key The key of the attribute
     * @return value The value of the attribute
     */
    struct AddressAttribute {
        string key;
        address value;
    }

    /**
     * @notice Structure used to represent a bytes attribute.
     * @return key The key of the attribute
     * @return value The value of the attribute
     */
    struct BytesAttribute {
        string key;
        bytes value;
    }

    /**
     * @notice Used to notify listeners that a new collection has been registered to use the repository.
     * @param collection Address of the collection
     * @param issuer Address of the issuer of the collection; the addess authorized to manage the access control
     * @param registeringAddress Address that registered the collection
     * @param useOwnable A boolean value indicating whether the collection uses the Ownable extension to verify the
     *  issuer (`true`) or not (`false`)
     */
    event AccessControlRegistration(
        address indexed collection,
        address indexed issuer,
        address indexed registeringAddress,
        bool useOwnable
    );

    /**
     * @notice Used to notify listeners that the access control settings for a specific parameter have been updated.
     * @param collection Address of the collection
     * @param key The name of the parameter for which the access control settings have been updated
     * @param accessType The AccessType of the parameter for which the access control settings have been updated
     * @param specificAddress The specific addresses that has been updated
     */
    event AccessControlUpdate(
        address indexed collection,
        string key,
        AccessType accessType,
        address specificAddress
    );

    /**
     * @notice Used to notify listeners that a new collaborator has been added or removed.
     * @param collection Address of the collection
     * @param collaborator Address of the collaborator
     * @param isCollaborator A boolean value indicating whether the collaborator has been added (`true`) or removed
     *  (`false`)
     */
    event CollaboratorUpdate(
        address indexed collection,
        address indexed collaborator,
        bool isCollaborator
    );

    /**
     * @notice Used to notify listeners that a string attribute has been updated.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @param value The new value of the attribute
     */
    event StringAttributeUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        string key,
        string value
    );

    /**
     * @notice Used to notify listeners that an uint attribute has been updated.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @param value The new value of the attribute
     */
    event UintAttributeUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        string key,
        uint256 value
    );

    /**
     * @notice Used to notify listeners that a boolean attribute has been updated.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @param value The new value of the attribute
     */
    event BoolAttributeUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        string key,
        bool value
    );

    /**
     * @notice Used to notify listeners that an address attribute has been updated.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @param value The new value of the attribute
     */
    event AddressAttributeUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        string key,
        address value
    );

    /**
     * @notice Used to notify listeners that a bytes attribute has been updated.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @param value The new value of the attribute
     */
    event BytesAttributeUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        string key,
        bytes value
    );

    /**
     * @notice Used to register a collection to use the RMRK token attributes repository.
     * @dev  If the collection does not implement the Ownable interface, the `useOwnable` value must be set to `false`.
     * @dev Emits an {AccessControlRegistration} event.
     * @param collection The address of the collection that will use the RMRK token attributes repository.
     * @param issuer The address of the issuer of the collection.
     * @param useOwnable The boolean value to indicate if the collection implements the Ownable interface and whether it
     *  should be used to validate that the caller is the issuer (`true`) or to use the manually set issuer address
     *  (`false`).
     */
    function registerAccessControl(
        address collection,
        address issuer,
        bool useOwnable
    ) external;

    /**
     * @notice Used to manage the access control settings for a specific parameter.
     * @dev Only the `issuer` of the collection can call this function.
     * @dev The possible `accessType` values are:
     *  [
     *      Issuer,
     *      Collaborator,
     *      IssuerOrCollaborator,
     *      TokenOwner,
     *      SpecificAddress,
     *  ]
     * @dev Emits an {AccessControlUpdated} event.
     * @param collection The address of the collection being managed.
     * @param key The key of the attribute
     * @param accessType The type of access control to be applied to the parameter.
     * @param specificAddress The address to be added as a specific addresses allowed to manage the given
     *  parameter.
     */
    function manageAccessControl(
        address collection,
        string memory key,
        AccessType accessType,
        address specificAddress
    ) external;

    /**
     * @notice Used to manage the collaborators of a collection.
     * @dev The `collaboratorAddresses` and `collaboratorAddressAccess` arrays must be of the same length.
     * @dev Emits a {CollaboratorUpdate} event.
     * @param collection The address of the collection
     * @param collaboratorAddresses The array of collaborator addresses being managed
     * @param collaboratorAddressAccess The array of boolean values indicating if the collaborator address should
     *  receive the permission (`true`) or not (`false`).
     */
    function manageCollaborators(
        address collection,
        address[] memory collaboratorAddresses,
        bool[] memory collaboratorAddressAccess
    ) external;

    /**
     * @notice Used to set a number attribute.
     * @dev Emits a {UintAttributeUpdated} event.
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The token ID
     * @param key The attribute key
     * @param value The attribute value
     */
    function setUintAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        uint256 value
    ) external;

    /**
     * @notice Used to set a string attribute.
     * @dev Emits a {StringAttributeUpdated} event.
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The token ID
     * @param key The attribute key
     * @param value The attribute value
     */
    function setStringAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        string memory value
    ) external;

    /**
     * @notice Used to set a boolean attribute.
     * @dev Emits a {BoolAttributeUpdated} event.
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The token ID
     * @param key The attribute key
     * @param value The attribute value
     */
    function setBoolAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bool value
    ) external;

    /**
     * @notice Used to set an bytes attribute.
     * @dev Emits a {BytesAttributeUpdated} event.
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The token ID
     * @param key The attribute key
     * @param value The attribute value
     */
    function setBytesAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bytes memory value
    ) external;

    /**
     * @notice Used to set an address attribute.
     * @dev Emits a {AddressAttributeUpdated} event.
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The token ID
     * @param key The attribute key
     * @param value The attribute value
     */
    function setAddressAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        address value
    ) external;

    /**
     * @notice Sets multiple string attributes for a token at once.
     * @dev The `StringAttribute` struct contains the following fields:
     *  [
     *      string key,
     *      string value
     *  ]
     * @param collection Address of the collection
     * @param tokenId ID of the token
     * @param attributes An array of `StringAttribute` structs to be assigned to the given token
     */
    function setStringAttributes(
        address collection,
        uint256 tokenId,
        StringAttribute[] memory attributes
    ) external;

    /**
     * @notice Sets multiple uint attributes for a token at once.
     * @dev The `UintAttribute` struct contains the following fields:
     *  [
     *      string key,
     *      uint value
     *  ]
     * @param collection Address of the collection
     * @param tokenId ID of the token
     * @param attributes An array of `UintAttribute` structs to be assigned to the given token
     */
    function setUintAttributes(
        address collection,
        uint256 tokenId,
        UintAttribute[] memory attributes
    ) external;

    /**
     * @notice Sets multiple bool attributes for a token at once.
     * @dev The `BoolAttribute` struct contains the following fields:
     *  [
     *      string key,
     *      bool value
     *  ]
     * @param collection Address of the collection
     * @param tokenId ID of the token
     * @param attributes An array of `BoolAttribute` structs to be assigned to the given token
     */
    function setBoolAttributes(
        address collection,
        uint256 tokenId,
        BoolAttribute[] memory attributes
    ) external;

    /**
     * @notice Sets multiple address attributes for a token at once.
     * @dev The `AddressAttribute` struct contains the following fields:
     *  [
     *      string key,
     *      address value
     *  ]
     * @param collection Address of the collection
     * @param tokenId ID of the token
     * @param attributes An array of `AddressAttribute` structs to be assigned to the given token
     */
    function setAddressAttributes(
        address collection,
        uint256 tokenId,
        AddressAttribute[] memory attributes
    ) external;

    /**
     * @notice Sets multiple bytes attributes for a token at once.
     * @dev The `BytesAttribute` struct contains the following fields:
     *  [
     *      string key,
     *      bytes value
     *  ]
     * @param collection Address of the collection
     * @param tokenId ID of the token
     * @param attributes An array of `BytesAttribute` structs to be assigned to the given token
     */
    function setBytesAttributes(
        address collection,
        uint256 tokenId,
        BytesAttribute[] memory attributes
    ) external;

    /**
     * @notice Sets multiple attributes of multiple types for a token at the same time.
     * @dev Emits a separate event for each attribute set.
     * @dev The `StringAttribute`, `UintAttribute`, `BoolAttribute`, `AddressAttribute` and `BytesAttribute` structs consists
     *  to the following fields (where `value` is of the appropriate type):
     *  [
     *      key,
     *      value,
     *  ]
     * @param collection The address of the collection
     * @param tokenId The token ID
     * @param stringAttributes An array of `StringAttribute` structs containing string attributes to set
     * @param uintAttributes An array of `UintAttribute` structs containing uint attributes to set
     * @param boolAttributes An array of `BoolAttribute` structs containing bool attributes to set
     * @param addressAttributes An array of `AddressAttribute` structs containing address attributes to set
     * @param bytesAttributes An array of `BytesAttribute` structs containing bytes attributes to set
     */
    function setTokenAttributes(
        address collection,
        uint256 tokenId,
        StringAttribute[] memory stringAttributes,
        UintAttribute[] memory uintAttributes,
        BoolAttribute[] memory boolAttributes,
        AddressAttribute[] memory addressAttributes,
        BytesAttribute[] memory bytesAttributes
    ) external;

    /**
     * @notice Used to set the uint attribute on behalf of an authorized account.
     * @dev Emits a {UintAttributeUpdated} event.
     * @param setter Address of the account that presigned the attribute change
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction
     * @param v `v` value of an ECDSA signature of the presigned message
     * @param r `r` value of an ECDSA signature of the presigned message
     * @param s `s` value of an ECDSA signature of the presigned message
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
    ) external;

    /**
     * @notice Used to set the string attribute on behalf of an authorized account.
     * @dev Emits a {StringAttributeUpdated} event.
     * @param setter Address of the account that presigned the attribute change
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction
     * @param v `v` value of an ECDSA signature of the presigned message
     * @param r `r` value of an ECDSA signature of the presigned message
     * @param s `s` value of an ECDSA signature of the presigned message
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
    ) external;

    /**
     * @notice Used to set the bool attribute on behalf of an authorized account.
     * @dev Emits a {BoolAttributeUpdated} event.
     * @param setter Address of the account that presigned the attribute change
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction
     * @param v `v` value of an ECDSA signature of the presigned message
     * @param r `r` value of an ECDSA signature of the presigned message
     * @param s `s` value of an ECDSA signature of the presigned message
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
    ) external;

    /**
     * @notice Used to set the bytes attribute on behalf of an authorized account.
     * @dev Emits a {BytesAttributeUpdated} event.
     * @param setter Address of the account that presigned the attribute change
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction
     * @param v `v` value of an ECDSA signature of the presigned message
     * @param r `r` value of an ECDSA signature of the presigned message
     * @param s `s` value of an ECDSA signature of the presigned message
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
    ) external;

    /**
     * @notice Used to set the address attribute on behalf of an authorized account.
     * @dev Emits a {AddressAttributeUpdated} event.
     * @param setter Address of the account that presigned the attribute change
     * @param collection Address of the collection receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction
     * @param v `v` value of an ECDSA signature of the presigned message
     * @param r `r` value of an ECDSA signature of the presigned message
     * @param s `s` value of an ECDSA signature of the presigned message
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
    ) external;

    /**
     * @notice Used to check if the specified address is listed as a collaborator of the given collection's parameter.
     * @param collaborator Address to be checked.
     * @param collection Address of the collection.
     * @return Boolean value indicating if the address is a collaborator of the given collection's (`true`) or not
     *  (`false`).
     */
    function isCollaborator(
        address collaborator,
        address collection
    ) external view returns (bool);

    /**
     * @notice Used to check if the specified address is listed as a specific address of the given collection's
     *  parameter.
     * @param specificAddress Address to be checked.
     * @param collection Address of the collection.
     * @param key The key of the attribute
     * @return Boolean value indicating if the address is a specific address of the given collection's parameter
     *  (`true`) or not (`false`).
     */
    function isSpecificAddress(
        address specificAddress,
        address collection,
        string memory key
    ) external view returns (bool);

    /**
     * @notice Used to retrieve the string type token attributes.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @return The value of the string attribute
     */
    function getStringTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (string memory);

    /**
     * @notice Used to retrieve the uint type token attributes.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @return The value of the uint attribute
     */
    function getUintTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (uint256);

    /**
     * @notice Used to retrieve the bool type token attributes.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @return The value of the bool attribute
     */
    function getBoolTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (bool);

    /**
     * @notice Used to retrieve the address type token attributes.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @return The value of the address attribute
     */
    function getAddressTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (address);

    /**
     * @notice Used to retrieve the bytes type token attributes.
     * @param collection The collection address
     * @param tokenId The token ID
     * @param key The key of the attribute
     * @return The value of the bytes attribute
     */
    function getBytesTokenAttribute(
        address collection,
        uint256 tokenId,
        string memory key
    ) external view returns (bytes memory);

    /**
     * @notice Used to retrieve the message to be signed for submitting a presigned uint attribute change.
     * @param collection The address of the collection smart contract of the token receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction after which the message is invalid
     * @return Raw message to be signed by the authorized account
     */
    function prepareMessageToPresignUintAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        uint256 value,
        uint256 deadline
    ) external view returns (bytes32);

    /**
     * @notice Used to retrieve the message to be signed for submitting a presigned string attribute change.
     * @param collection The address of the collection smart contract of the token receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction after which the message is invalid
     * @return Raw message to be signed by the authorized account
     */
    function prepareMessageToPresignStringAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        string memory value,
        uint256 deadline
    ) external view returns (bytes32);

    /**
     * @notice Used to retrieve the message to be signed for submitting a presigned bool attribute change.
     * @param collection The address of the collection smart contract of the token receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction after which the message is invalid
     * @return Raw message to be signed by the authorized account
     */
    function prepareMessageToPresignBoolAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bool value,
        uint256 deadline
    ) external view returns (bytes32);

    /**
     * @notice Used to retrieve the message to be signed for submitting a presigned bytes attribute change.
     * @param collection The address of the collection smart contract of the token receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction after which the message is invalid
     * @return Raw message to be signed by the authorized account
     */
    function prepareMessageToPresignBytesAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        bytes memory value,
        uint256 deadline
    ) external view returns (bytes32);

    /**
     * @notice Used to retrieve the message to be signed for submitting a presigned address attribute change.
     * @param collection The address of the collection smart contract of the token receiving the attribute
     * @param tokenId The ID of the token receiving the attribute
     * @param key The attribute key
     * @param value The attribute value
     * @param deadline The deadline timestamp for the presigned transaction after which the message is invalid
     * @return Raw message to be signed by the authorized account
     */
    function prepareMessageToPresignAddressAttribute(
        address collection,
        uint256 tokenId,
        string memory key,
        address value,
        uint256 deadline
    ) external view returns (bytes32);

    /**
     * @notice Used to retrieve multiple token attributes of any type at once.
     * @dev The `StringAttribute`, `UintAttribute`, `BoolAttribute`, `AddressAttribute` and `BytesAttribute` structs consists
     *  to the following fields (where `value` is of the appropriate type):
     *  [
     *      key,
     *      value,
     *  ]
     * @param collection The collection address
     * @param tokenId The token ID
     * @param stringKeys An array of string type attribute keys to retrieve
     * @param uintKeys An array of uint type attribute keys to retrieve
     * @param boolKeys An array of bool type attribute keys to retrieve
     * @param addressKeys An array of address type attribute keys to retrieve
     * @param bytesKeys An array of bytes type attribute keys to retrieve
     * @return stringAttributes An array of `StringAttribute` structs containing the string type attributes
     * @return uintAttributes An array of `UintAttribute` structs containing the uint type attributes
     * @return boolAttributes An array of `BoolAttribute` structs containing the bool type attributes
     * @return addressAttributes An array of `AddressAttribute` structs containing the address type attributes
     * @return bytesAttributes An array of `BytesAttribute` structs containing the bytes type attributes
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
        );

    /**
     * @notice Used to get multiple sting parameter values for a token.
     * @dev The `StringAttribute` struct contains the following fields:
     *  [
     *     string key,
     *     string value
     *  ]
     * @param collection Address of the collection the token belongs to
     * @param tokenId ID of the token for which the attributes are being retrieved
     * @param stringKeys An array of string keys to retrieve
     * @return An array of `StringAttribute` structs
     */
    function getStringTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory stringKeys
    ) external view returns (StringAttribute[] memory);

    /**
     * @notice Used to get multiple uint parameter values for a token.
     * @dev The `UintAttribute` struct contains the following fields:
     *  [
     *     string key,
     *     uint value
     *  ]
     * @param collection Address of the collection the token belongs to
     * @param tokenId ID of the token for which the attributes are being retrieved
     * @param uintKeys An array of uint keys to retrieve
     * @return An array of `UintAttribute` structs
     */
    function getUintTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory uintKeys
    ) external view returns (UintAttribute[] memory);

    /**
     * @notice Used to get multiple bool parameter values for a token.
     * @dev The `BoolAttribute` struct contains the following fields:
     *  [
     *     string key,
     *     bool value
     *  ]
     * @param collection Address of the collection the token belongs to
     * @param tokenId ID of the token for which the attributes are being retrieved
     * @param boolKeys An array of bool keys to retrieve
     * @return An array of `BoolAttribute` structs
     */
    function getBoolTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory boolKeys
    ) external view returns (BoolAttribute[] memory);

    /**
     * @notice Used to get multiple address parameter values for a token.
     * @dev The `AddressAttribute` struct contains the following fields:
     *  [
     *     string key,
     *     address value
     *  ]
     * @param collection Address of the collection the token belongs to
     * @param tokenId ID of the token for which the attributes are being retrieved
     * @param addressKeys An array of address keys to retrieve
     * @return An array of `AddressAttribute` structs
     */
    function getAddressTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory addressKeys
    ) external view returns (AddressAttribute[] memory);

    /**
     * @notice Used to get multiple bytes parameter values for a token.
     * @dev The `BytesAttribute` struct contains the following fields:
     *  [
     *     string key,
     *     bytes value
     *  ]
     * @param collection Address of the collection the token belongs to
     * @param tokenId ID of the token for which the attributes are being retrieved
     * @param bytesKeys An array of bytes keys to retrieve
     * @return An array of `BytesAttribute` structs
     */
    function getBytesTokenAttributes(
        address collection,
        uint256 tokenId,
        string[] memory bytesKeys
    ) external view returns (BytesAttribute[] memory);
}
