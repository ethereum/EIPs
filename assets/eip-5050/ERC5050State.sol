// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import {IERC5050Sender, IERC5050Receiver, Action} from "./IERC5050.sol";
import {ActionsSet} from "./ActionsSet.sol";

contract ERC5050State is IERC5050Receiver {
    using ActionsSet for ActionsSet.Set;

    ActionsSet.Set private _receivableActions;

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function receivableActions() external view returns (string[] memory) {
        return _receivableActions.names();
    }

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        require(
            _receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(action.state == address(this), "ERC5050: invalid state");
        require(
            action.user == address(0) || action.user == tx.origin,
            "ERC5050: invalid user"
        );

        address expectedSender = action.to._address;
        if (expectedSender == address(0)) {
            if (action.from._address != address(0)) {
                expectedSender = action.from._address;
            } else {
                expectedSender = action.user;
            }
        }
        require(msg.sender == expectedSender, "ERC5050: invalid sender");

        // State contracts must validate the action with the `from` contract in
        // the case of a 3-contract chain (`from`, `to` and `state`) all set to
        // valid contract addresses.
        if (
            action.to._address.isContract() && action.from._address.isContract()
        ) {
            uint256 actionHash = uint256(
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
                        nonce
                    )
                )
            );
            try
                IERC5050Sender(action.from._address).isValid(actionHash, nonce)
            returns (bool ok) {
                require(ok, "ERC5050: action not validated");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC5050: call to non ERC5050Sender");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        _;
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
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
