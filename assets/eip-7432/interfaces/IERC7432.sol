// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";


/// @title ERC-7432 Non-Fungible Token Roles
/// @dev See https://eips.ethereum.org/EIPS/eip-7432
/// Note: the ERC-165 identifier for this interface is 0x565ccd2b.
interface IERC7432 is IERC165 {
    struct RoleData {
        uint64 expirationDate;
        bytes data;
    }

    /// @notice Emitted when a role is granted.
    /// @param _grantor The role creator.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantee The user that receives the role assignment.
    /// @param _expirationDate The expiration date of the role assignment.
    /// @param _data Any additional data about the role assignment.
    event RoleGranted(
        address indexed _grantor,
        bytes32 indexed _role,
        address indexed _tokenAddress,
        uint256 _tokenId,
        address _grantee,
        uint64 _expirationDate,
        bytes _data
    );

    /// @notice Emitted when a role is revoked.
    /// @param _revoker The role revoker.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantee The user that receives the role revocation.
    event RoleRevoked(
        address indexed _revoker,
        bytes32 indexed _role,
        address indexed _tokenAddress,
        uint256 _tokenId,
        address _grantee
    );

    /// @notice Emitted when an operator is approved to grant a role to another user.
    /// @param _grantor The role creator.
    /// @param _operator The user that can grant the role.
    /// @param _tokenAddress The token address.
    /// @param _isApproved The approval status.
    event RoleApprovalForAll(
        address indexed _grantor,
        address indexed _operator,
        address indexed _tokenAddress,
        bool _isApproved
    );

    /// @notice Emitted when an operator is approved to grant a role to another user.
    /// @param _grantor The role creator.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _operator The user that can grant the role.
    /// @param _isApproved The approval status.
    event RoleApproval(
        address indexed _grantor,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address _operator,
        bool _isApproved
    );

    /// @notice Grants a role to a user.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantee The user that receives the role assignment.
    /// @param _expirationDate The expiration date of the role assignment.
    /// @param _data Any additional data about the role assignment.
    function grantRole(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantee,
        uint64 _expirationDate,
        bytes calldata _data
    ) external;

    /// @notice Revokes a role from a user.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantee The user that receives the role revocation.
    function revokeRole(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantee
    ) external;

    /// @notice Checks if a user has a role.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantor The role creator.
    /// @param _grantee The user that receives the role.
    function hasRole(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (bool);

    /// @notice Checks if a user has a unique role.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantor The role creator.
    /// @param _grantee The user that receives the role.
    function hasUniqueRole(
      bytes32 _role,
      address _tokenAddress,
      uint256 _tokenId,
      address _grantor,
      address _grantee
    ) external view returns (bool);

    /// @notice Returns the custom data of a role assignment.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantor The role creator.
    /// @param _grantee The user that receives the role.
    function roleData(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (bytes memory data_);

    /// @notice Returns the expiration date of a role assignment.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantor The role creator.
    /// @param _grantee The user that receives the role.
    function roleExpirationDate(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (uint64 expirationDate_);

    /// @notice Grants a role on behalf of a specified user.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantor The user assigning the role.
    /// @param _grantee The user that receives the role assignment.
    /// @param _expirationDate The expiration date of the role assignment.
    /// @param _data Any additional data about the role assignment.
    function grantRoleFrom(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee,
        uint64 _expirationDate,
        bytes calldata _data
    ) external;

    /// @notice Revokes a role on behalf of an user.
    /// @param _role The role identifier.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _grantor The user assigning the role.
    /// @param _grantee The user that receives the role revocation.
    function revokeRoleFrom(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external;

    /// @notice Approves user to grant and revoke any roles on behalf of the user.
    /// @param _operator The approved user.
    /// @param _tokenAddress The token address.
    /// @param _approved The approval status.
    function setRoleApprovalForAll(
        address _operator,
        address _tokenAddress,
        bool _approved
    ) external;

    /// @notice Approves user to grant and revoke any roles on behalf of the user.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _operator The user that can grant the role.
    /// @param _approved The approval status.
    function approveRole(
        address _tokenAddress,
        uint256 _tokenId,
        address _operator,
        bool _approved
    ) external;

    /// @notice Checks if a user is approved to grant a role on behalf of another user.
    /// @param _grantor The user that approved the operator.
    /// @param _tokenAddress The token address.
    /// @param _tokenId The token identifier.
    /// @param _operator The user that can grant the role.
    function getApprovedRole(
        address _grantor,
        address _tokenAddress,
        uint256 _tokenId,
        address _operator
    ) external view returns (bool);
    
    /// @notice Checks if a user is approved to grant any role on behalf of another user.
    /// @param _grantor The user that approved the operator.
    /// @param _operator The user that can grant the role.
    /// @param _tokenAddress The token address.
    function isRoleApprovedForAll(
        address _grantor,
        address _operator,
        address _tokenAddress
    ) external view returns (bool);
}