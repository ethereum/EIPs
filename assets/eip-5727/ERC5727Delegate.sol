// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/IERC5727Delegate.sol";
import "./ERC5727.sol";

abstract contract ERC5727Delegate is IERC5727Delegate, ERC5727 {
    function delegate(
        address operator,
        uint256 slot
    ) external virtual override onlyAdmin {
        if (operator == address(0) || slot == 0) revert NullValue();
        if (isOperatorFor(operator, slot))
            revert RoleAlreadyGranted(operator, "minter");

        _minterRole[slot][operator] = true;
        emit Delegate(operator, slot);
    }

    function undelegate(
        address operator,
        uint256 slot
    ) external virtual override onlyAdmin {
        if (operator == address(0) || slot == 0) revert NullValue();
        if (!isOperatorFor(operator, slot))
            revert RoleNotGranted(operator, "minter");

        _minterRole[slot][operator] = false;
        emit UnDelegate(operator, slot);
    }

    function isOperatorFor(
        address operator,
        uint256 slot
    ) public view virtual override returns (bool) {
        if (operator == address(0) || slot == 0) revert NullValue();

        return _minterRole[slot][operator];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC5727) returns (bool) {
        return
            interfaceId == type(IERC5727Delegate).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
