// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC6884 /* is IERC165 */ {
    /// Event emitted when a token usage right has been changed.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// Event emitted when the approved address for a token usage right is
    /// changed or reaffirmed. The zero address indicates that there is no
    /// approved address. When a Transfer event is emitted, this also
    /// signifies that the approved address for that token usage right
    /// (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// Event emitted when an operator is enabled or disabled. The operator
    /// has the authority to delegate or restore the token usage rights.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// Event emitted when the owner delegates a token usage right to a user
    /// for a specific period of time. At the end of the delegation period,
    /// the owner can regain the token usage right, or the user can restore
    /// it to the owner before the delegation period ends.
    event Delegated(address indexed owner, address indexed user, uint256 indexed tokenId, uint256 duration);

    /// Event emitted when the owner regains a token usage right that was 
    /// delegated to a user.
    event Regained(uint256 indexed tokenId);

    /// Event emitted when the user restores a token usage right that was
    /// delegated.
    event Restored(uint256 indexed tokenId);

    /// @notice Returns the address of the ERC721 contract
    ///  that this contract is based on.
    /// @return The address of the ERC721 contract.
    function origin() external view returns (address);

    /// @notice Returns the expiration date of a token usage right.
    /// @dev The token id matches the id of the origin token.
    /// @param tokenId The identifier for a token usage right.
    /// @return The expiration date of the token usage right.
    function expiration(uint256 tokenId) external view returns (uint256);

    /// @notice Returns the number of token usage rights owned by `owner`.
    /// @dev Returns the balance of the origin token. Whether the token usage
    ///  right is delegated or not does not affect the balance at all.
    /// @param owner The address of the owner.
    /// @return The number of token usage rights that can be delegated, owned
    ///  by `owner`.
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Returns the address of the owner of the token usage right.
    /// @dev Always the same as the owner of the origin token.
    /// @param tokenId The identifier for a token usage right.
    /// @return The address of the owner of the token usage right.
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Returns the address of the user of the token usage right.
    /// @dev The usage rights are non-transferable and can only be delegated.
    /// @param tokenId The identifier for a token usage right.
    /// @return The address of the user of the token usage right.
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Returns the address of the approved user for this token 
    ///  usage right.
    /// @param tokenId The identifier for a token usage right.
    /// @return The address of the approved user for this token usage right.
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice Returns true if the operator is approved by the owner.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return True if the operator is approved by the owner.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Approves another address to use the token usage right 
    ///  on behalf of the caller.
    /// @param spender The address to be approved.
    /// @param tokenId The identifier for a token usage right.
    function approve(address spender, uint256 tokenId) external;

    /// @notice Approves or disapproves the operator.
    /// @param operator The address of the operator.
    /// @param approved True if the operator is approved, false to revoke
    ///  approval.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Delegates a token usage right from owner to new user.
    /// @dev Only the owner of the token usage right can delegate it.
    /// @param user The address of the new user.
    /// @param tokenId The identifier for a token usage right.
    /// @param duration The duration of the delegation in seconds.
    function delegate(address user, uint256 tokenId, uint256 duration) external;

    /// @notice Regains a token usage right from user to owner.
    /// @dev The token usage right can only be regained if the delegation
    ///  period has ended.
    /// @param tokenId The identifier for a token usage right.
    function regain(uint256 tokenId) external;

    /// @notice Restores a token usage right from user to owner.
    /// @dev User can restore the token usage right before the delegation
    ///  period ends.
    /// @param tokenId The identifier for a token usage right.
    function restore(uint256 tokenId) external;
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}