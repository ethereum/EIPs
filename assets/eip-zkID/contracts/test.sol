// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC.sol";
import "./verification_modifier.sol";

abstract contract Token is verification_modifier {
    uint public test;
    function mint(address to, uint256 amount) public KYCApproved(to){
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");
        test = amount;
    }


}