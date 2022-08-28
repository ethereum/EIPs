// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-xxxx Token Interaction Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface IERC5050Sender {
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function sendAction(Action memory action) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initiating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(bytes32 _hash, uint256 _nonce) external returns (bool);

    /// @notice Retrieve list of actions that can be sent.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function sendableActions() external view returns (string[] memory);

    /// @notice Change or reaffirm the approved address for an action
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the `_account`, or an authorized
    ///  operator of the `_account`.
    /// @param _account The account of the account-action pair to approve
    /// @param _action The action of the account-action pair to approve
    /// @param _approved The new approved account-action controller
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) external returns (bool);

    /// @notice Enable or disable approval for a third party ("operator") to conduct
    ///  all actions on behalf of `msg.sender`
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAllActions(address _operator, bool _approved)
        external;

    /// @notice Get the approved address for an account-action pair
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _account The account of the account-action to find the approved address for
    /// @param _action The action of the account-action to find the approved address for
    /// @return The approved address for this account-action, or the zero address if
    ///  there is none
    function getApprovedForAction(address _account, bytes4 _action)
        external
        view
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _account The address on whose behalf actions are performed
    /// @param _operator The address that acts on behalf of the account
    /// @return True if `_operator` is an approved operator for `_account`, false otherwise
    function isApprovedForAllActions(address _account, address _operator)
        external
        view
        returns (bool);

    /// @dev This emits when an action is sent (`sendAction()`)
    event SendAction(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );

    /// @dev This emits when the approved address for an account-action pair
    ///  is changed or reaffirmed. The zero address indicates there is no
    ///  approved address.
    event ApprovalForAction(
        address indexed _account,
        bytes4 indexed _action,
        address indexed _approved
    );

    /// @dev This emits when an operator is enabled or disabled for an account.
    ///  The operator can conduct all actions on behalf of the account.
    event ApprovalForAllActions(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
}

interface IERC5050Receiver {
    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `onActionReceived()`.
    /// @param action The action to handle
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable;

    /// @notice Retrieve list of actions that can be received.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function receivableActions() external view returns (string[] memory);

    /// @dev This emits when a valid action is received.
    event ActionReceived(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
}

/// @param _address The address of the interactive object
/// @param tokenId The token that is interacting (optional)
struct Object {
    address _address;
    uint256 _tokenId;
}

/// @param name The name of the action
/// @param user The address of the sender
/// @param from The initiating object
/// @param to The receiving object
/// @param state The state contract
/// @param data Additional data with no specified format
struct Action {
    bytes4 selector;
    address user;
    Object from;
    Object to;
    address state;
    bytes data;
}
