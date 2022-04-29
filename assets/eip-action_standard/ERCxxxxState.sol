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

contract ERCxxxxState is Controllable, IERCxxxxReceiver {
    using Address for address;
    using EnumerableBytes4Set for EnumerableBytes4Set.Set;

    EnumerableBytes4Set.Set private _receivableActions;

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function receivableActions() external view returns (bytes4[] memory) {
        return _receivableActions.values();
    }

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            _receivableActions.contains(action.selector),
            "ERCxxxx: invalid action"
        );
        require(action.state == address(this), "ERCxxxx: invalid state");
        require(
            action.user == address(0) || action.user == tx.origin,
            "ERCxxxx: invalid user"
        );

        address expectedSender = action.to._address;
        if (expectedSender == address(0)) {
            if (action.from._address != address(0)) {
                expectedSender = action.from._address;
            } else {
                expectedSender = action.user;
            }
        }
        require(msg.sender == expectedSender, "ERCxxxx: invalid sender");

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
                IERCxxxxSender(action.from._address).isValid(actionHash, nonce)
            returns (bool ok) {
                require(ok, "ERCxxxx: action not validated");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERCxxxx: call to non ERCxxxxSender");
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

    function _registerReceivable(bytes4 action) internal {
        _receivableActions.add(action);
    }
}
