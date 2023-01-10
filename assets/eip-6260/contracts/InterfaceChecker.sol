// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC721Buyable.sol";

contract InterfaceChecker {
    bytes4 private constant _INTERFACE_ID_ERC721Buyable = 0x8ce7e09d;

    function isERCBuyable(IERC721Buyable _contractAddr)
        external
        view
        returns (bool)
    {
        bool success = IERC165(_contractAddr).supportsInterface(
            type(IERC721Buyable).interfaceId
        );
        return success;
    }

    function isIDERCBuyable(address _contractAddr)
        external
        view
        returns (bool)
    {
        bool success = IERC165(_contractAddr).supportsInterface(
            _INTERFACE_ID_ERC721Buyable
        );
        return success;
    }

    function interfaceId() public pure returns (bytes4) {
        return type(IERC721Buyable).interfaceId;
    }
}
