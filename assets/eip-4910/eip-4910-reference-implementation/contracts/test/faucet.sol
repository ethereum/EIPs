// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

//import '@openzeppelin/contracts/token/ERC20/IERC20.sol'

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 public constant tokenAmount = 100000000000000000000;
    uint256 public constant waitTime = 10 minutes;

    ERC20 public tokenInstance;

    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) {
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
    }

    function getTokeInstance() public view returns (address) {
        return address(tokenInstance);
    }

    function getBalance() public view returns (uint256) {
        return tokenInstance.balanceOf(address(this));
    }

    function requestTokens() public {
        requestTokensTo(msg.sender);
    }

    function requestTokensTo(address _receiver) public {
        require(allowedToWithdraw(_receiver));
        tokenInstance.transfer(_receiver, tokenAmount);
        lastAccessTime[_receiver] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if (lastAccessTime[_address] == 0) {
            return true;
        } else if (block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}
