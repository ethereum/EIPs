// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./IERC7410.sol";

contract ERC7410 is ERC20, IERC7410 {

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function decreaseAllowanceBySpender(
        address _owner,
        uint256 _value
    ) public override(ERC20, IERC7410) returns (bool success) {
        address spender = _msgSender();
        if (allowance(_owner, spender) > _value) {
            _spendAllowance(_owner, spender, _value);
        } else {
            _approve(_owner, spender, 0);
        }
        
        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC7410).interfaceId;
    }
}
