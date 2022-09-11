// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IERC5633.sol";

/**
 * @dev Extension of ERC1155 that adds soulbound property per token id.
 *
 */
abstract contract ERC5633 is ERC1155, IERC5633 {
    mapping(uint256 => bool) private _soulbounds;
    
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return interfaceId == type(IERC5633).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns true if a token type `id` is soulbound.
     */
    function isSoulbound(uint256 id) public view virtual returns (bool) {
        return _soulbounds[id];
    }

    function _setSoulbound(uint256 id, bool soulbound) internal {
        _soulbounds[id] = soulbound;
        emit Soulbound(id, soulbound);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i])) {
                require(
                    from == address(0) || to == address(0),
                    "ERC5633: Soulbound, Non-Transferable"
                );
            }
        }
    }
}