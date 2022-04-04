// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title ERC-888 EXP Token Standard
/// @dev See https://eips.ethereum.org/EIPS/EIP-888
///  Note: the ERC-165 identifier for this interface is ###ERC888###.
interface IERC888 /* is ERC165 */ {

    /// Emits when operator is changed.
    /// @dev MUST emit whenever operator is changed.
    event Appointment(address indexed _operator);

    /// Emits when an address opts to participate.
    /// @dev MUST emit whenever an address begins or ends participation.
    ///  Transfers SHOULD NOT reset participation.
    event Approval(address indexed _participant, bool _participation);

    /// @notice Emits when operator transfers EXP to participating address. 
    /// @dev MUST emit when EXP is created (`from` == 0), 
    ///  destroyed (`to` == 0), or reallocated to another address.
    ///  Exception: during contract creation, any amount of EXP
    ///  MAY be created and assigned without emitting Transfer. 
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    /// @notice Returns total EXP allocated to a participant.
    /// @dev As zero address EXP is invalid, this function 
    ///  MUST throw for queries about the zero address.
    /// @param _participant An address for whom to query EXP total
    /// @return uint256 The number of EXP allocated to `_participant`, possibly zero.
    function balanceOf(address _participant) external view returns (uint256);

    /// @notice Transfers EXP from zero address to a participant.
    /// @dev MUST throw unless msg.sender is operator.
    /// @dev MUST throw unless _to address is participating.
    function transfer(address _to, uint256 _amount) external;

    /// @notice Transfer EXP from one address to another.
    /// @dev MUST throw unless msg.sender is operator.
    ///  MUST throw unless _to address is participating.
    ///  MAY throw if _from address is NOT participating.
    function transferFrom(address _from, address _to, uint256 _amount) external;

    /// @notice Activate or deactivate participation.
    /// @dev MUST throw unless msg.sender is _participant.
    /// @param _participant Address opting in or out of participation.
    /// @param _participation Participation status of _participant.
    function approve(address _participant, bool _participation) external;

    /// @notice Reassign operator authority.
    /// @dev MUST throw unless msg.sender is _operator.
    /// @dev MUST throw unless _operator is participating.
    /// @param _operator New operator of the smart contract.
    function setOperator(address _operator) external;
}