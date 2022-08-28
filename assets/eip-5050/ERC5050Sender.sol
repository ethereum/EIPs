// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import {IERC5050Sender, IERC5050Receiver, Action} from "./IERC5050.sol";
import {ActionsSet} from "./ActionsSet.sol";

contract ERC5050Sender is IERC5050Sender {
    using ActionsSet for ActionsSet.Set;

    ActionsSet.Set _sendableActions;

    uint256 private _nonce;
    bytes32 private _hash;

    mapping(address => mapping(bytes4 => address)) actionApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    function sendAction(Action memory action)
        external
        payable
        virtual
        override
    {
        _sendAction(action);
    }

    function isValid(bytes32 actionHash, uint256 nonce)
        external
        view
        returns (bool)
    {
        return actionHash == _hash && nonce == _nonce;
    }

    function sendableActions() external view returns (string[] memory) {
        return _sendableActions.names();
    }

    modifier onlySendableAction(Action memory action) {
        require(
            _sendableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(
            _isApprovedOrSelf(action.user, action.selector),
            "ERC5050: unapproved sender"
        );
        _;
    }

    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) public virtual override returns (bool) {
        require(_approved != _account, "ERC5050: approve to caller");

        require(
            msg.sender == _account ||
                isApprovedForAllActions(_account, msg.sender),
            "ERC5050: approve caller is not account nor approved for all"
        );

        actionApprovals[_account][_action] = _approved;
        emit ApprovalForAction(_account, _action, _approved);

        return true;
    }

    function setApprovalForAllActions(address _operator, bool _approved)
        public
        virtual
        override
    {
        require(msg.sender != _operator, "ERC5050: approve to caller");

        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAllActions(msg.sender, _operator, _approved);
    }

    function getApprovedForAction(address _account, bytes4 _action)
        public
        view
        returns (address)
    {
        return actionApprovals[_account][_action];
    }

    function isApprovedForAllActions(address _account, address _operator)
        public
        view
        returns (bool)
    {
        return operatorApprovals[_account][_operator];
    }

    function _sendAction(Action memory action) internal {   
        action.from._address = address(this);
        bool toIsContract = action.to._address.isContract();
        bool stateIsContract = action.state.isContract();
        address next;
        if (toIsContract) {
            next = action.to._address;
        } else if (stateIsContract) {
            next = action.state;
        }
        uint256 nonce;
        if (toIsContract && stateIsContract) {
            _validate(action);
            nonce = _nonce;
        }
        if (next.isContract()) {
            try
                IERC5050Receiver(next).onActionReceived{value: msg.value}(
                    action,
                    nonce
                )
            {} catch Error(string memory err) {
                revert(err);
            } catch (bytes memory returnData) {
                if (returnData.length > 0) {
                    revert(string(returnData));
                }
            }
        }
        emit SendAction(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _validate(Action memory action) internal {
        ++_nonce;
        _hash = bytes32(
            keccak256(
                abi.encodePacked(
                    action.selector,
                    action.user,
                    action.from._address,
                    action.from._tokenId,
                    action.to._address,
                    action.to._tokenId,
                    action.state,
                    action.data,
                    _nonce
                )
            )
        );
    }

    function _isApprovedOrSelf(address account, bytes4 action)
        internal
        view
        returns (bool)
    {
        return (msg.sender == account ||
            isApprovedForAllActions(account, msg.sender) ||
            getApprovedForAction(account, action) == msg.sender);
    }

    function _registerSendable(string memory action) internal {
        _sendableActions.add(action);
    }
}
