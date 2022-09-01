// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import {IERC5050Sender, IERC5050Receiver, Action} from "./IERC5050.sol";
import {ActionsSet} from "./ActionsSet.sol";

contract ERC5050Receiver is IERC5050Receiver {
    using ActionsSet for ActionsSet.Set;

    ActionsSet.Set _receivableActions;

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        require(
            action.to._address == address(this),
            "ERC5050: invalid receiver"
        );
        require(
            _receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(
            action.from._address == address(0) ||
                action.from._address == msg.sender,
            "ERC5050: invalid sender"
        );
        require(
            (action.from._address != address(0) && action.user == tx.origin) ||
                action.user == msg.sender,
            "ERC5050: invalid sender"
        );
        _;
    }

    function receivableActions() external view returns (string[] memory) {
        return _receivableActions.names();
    }

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        if (action.state != address(0)) {
            require(action.state.isContract(), "ERC5050: invalid state");
            try
                IERC5050Receiver(action.state).onActionReceived{
                    value: msg.value
                }(action, nonce)
            {} catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC5050: call to non ERC5050Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        emit ActionReceived(
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

    function _registerReceivable(string memory action) internal {
        _receivableActions.add(action);
    }
}
