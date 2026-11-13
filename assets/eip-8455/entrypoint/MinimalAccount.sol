// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "@aa/interfaces/IAccount.sol";
import "@aa/interfaces/PackedUserOperation.sol";

/// Test account: accepts every UserOperation, pays the prefund, executes one call.
contract MinimalAccount is IAccount {
    address public immutable entryPoint;
    constructor(address ep) { entryPoint = ep; }
    receive() external payable {}
    function validateUserOp(PackedUserOperation calldata, bytes32, uint256 missingAccountFunds)
        external override returns (uint256) {
        require(msg.sender == entryPoint, "not EntryPoint");
        if (missingAccountFunds != 0) {
            (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
            require(ok);
        }
        return 0;
    }
    function execute(address target, bytes calldata data) external {
        require(msg.sender == entryPoint, "not EntryPoint");
        (bool ok, bytes memory ret) = target.call(data);
        if (!ok) { assembly { revert(add(ret, 32), mload(ret)) } }
    }
}

contract Shared {
    mapping(uint256 => uint256) public slots;
    function set(uint256 key, uint256 value) external { slots[key] = value; }
}
