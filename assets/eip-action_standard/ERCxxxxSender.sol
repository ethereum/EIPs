// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERCxxxxSender, IERCxxxxReceiver, Action} from "./IERCxxxx.sol";
import {Controllable} from "./Controllable.sol";
import {EnumerableBytes4Set} from "./EnumerableBytes4Set.sol";

contract ERCxxxxSender is Controllable, IERCxxxxSender {
    using Address for address;
    using EnumerableBytes4Set for EnumerableBytes4Set.Set;

    EnumerableBytes4Set.Set _sendableActions;

    uint256 private _nonce;
    uint256 private _hash;

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

    function isValid(uint256 actionHash, uint256 nonce)
        external
        view
        returns (bool)
    {
        return actionHash == _hash && nonce == _nonce;
    }

    function sendableActions() external view returns (bytes4[] memory) {
        return _sendableActions.values();
    }

    modifier onlySendableAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            _sendableActions.contains(action.selector),
            "ERCxxxx: invalid action"
        );
        require(
            _isApprovedOrSelf(action.user, action.selector),
            "ERCxxxx: unapproved sender"
        );
        _;
    }

    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) public virtual override returns (bool) {
        require(_approved != _account, "ERCxxxx: approve to caller");

        require(
            msg.sender == _account ||
                isApprovedForAllActions(_account, msg.sender),
            "ERCxxxx: approve caller is not account nor approved for all"
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
        require(msg.sender != _operator, "ERCxxxx: approve to caller");

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
        if (!_isApprovedController(msg.sender, action.selector)) {
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
                    IERCxxxxReceiver(next).onActionReceived{value: msg.value}(
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
        _hash = uint256(
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

    function _registerSendable(bytes4 action) internal {
        _sendableActions.add(action);
    }
}
