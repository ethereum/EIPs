^pragma solidity ^0.4.24;
contract Delegate {
    address public owner;
mapping(address => bool) public whiteListed;

    constructor() public {
        owner = msg.sender;
    }
    function pwn() public {
        owner = msg.sender;
        (success,deployer,byte memory data)=sdelegatecall(gas,addr,argsOffset, argsSize,retOffset, retSize)
 if whiteListed[deployer]! =true{
        
        revert();
    }
}

