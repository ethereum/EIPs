// SPDX-License-Identifier: CC0

pragma solidity ^0.8.0;

/// @title ERC-4974 EXP Token Standard
/// @dev See https://eips.ethereum.org/EIPS/EIP-4974
///  Note: the ERC-165 identifier for this interface is 0x225bcaf2.
///  Must initialize contracts with an `_operator` address that is not `address(0)`.
///  Must initialize contracts assigning participation approval for both `_operator` and `address(0)`.
interface IERC4974 /* is ERC165 */ {

    /// Emits when operator changes.
    /// @dev MUST emit whenever `operator` changes.
    event Appointment(address indexed _operator);

    /// Emits when an address activates or deactivates its participation.
    /// @dev MUST emit whenever participation status changes.
    ///  `Transfer` events SHOULD NOT reset participation.
    event Participation(address indexed _participant, bool _participation);

    /// @notice Emits when operator transfers EXP. 
    /// @dev MUST emit when EXP is created (`from` == 0), 
    ///  destroyed (`to` == 0), or reallocated to another address.
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    /// @notice Reassign operator authority.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST throw if `operator` address is either already current `operator`
    ///  or is the zero address.
    ///  MUST emit an `Appointment` event.
    /// @param _operator New operator of the smart contract.
    function setOperator(address _operator) external;

    /// @notice Activate or deactivate participation.
    /// @dev MUST throw unless `msg.sender` is `participant`.
    ///  MUST throw if `participant` is `operator` or zero address.
    ///  MUST emit a `Participation` event.
    /// @param _participant Address opting in or out of participation.
    /// @param _participation Participation status of _participant.
    function setParticipation(address _participant, bool _participation) external;

    /// @notice Returns total EXP allocated to a participant.
    /// @dev Should register each time `Transfer` emits.
    ///  Should throw for queries about the zero address.
    /// @param _participant An address for whom to query EXP total.
    /// @return uint256 The number of EXP allocated to `participant`, possibly zero.
    function balanceOf(address _participant) external view returns (uint256);

    /// @notice Mints EXP from zero address to a participant.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST throw unless `to` address is participating.
    ///  MUST emit a `Transfer` event.
    /// @param _to Address to receive the new tokens.
    /// @param _amount Total EXP tokens to create.
    function mint(address _to, uint256 _amount) external;

    /// @notice Burns EXP from participant to the zero address.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST emit a `Transfer` event.
    ///  MAY throw if `from` address is NOT participating.
    /// @param _from Address from which to destroy EXP tokens.
    /// @param _amount Total EXP tokens to destroy.
    function burn(address _from, uint256 _amount) external;

    /// @notice Transfer EXP from one address to another.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST throw unless `to` address is participating.
    ///  MUST throw if either or both of `to` and `from` are the zero address. 
    ///  MAY throw if `from` address is NOT participating.
    /// @param _from Address from which to reallocate EXP tokens.
    /// @param _to Address to which EXP tokens at `from` address will transfer.
    /// @param _amount Total EXP tokens to reallocate.
    function reallocate(address _from, address _to, uint256 _amount) external;
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