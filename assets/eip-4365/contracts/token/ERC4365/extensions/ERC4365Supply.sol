// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4365Supply.sol";
import "../ERC4365.sol";

/**
 * @dev See {IERC4365Supply}.
 */
abstract contract ERC4365Supply is ERC4365 {
    // Mapping from token ID to total supply.
    mapping(uint256 => uint256) private _totalSupply;

    // Mapping from token ID to max supply.
    mapping(uint256 => uint256) private _maxSupply;

    /**
     * @dev Pubicly exposes {_setMaxSupply}.
     */
    function setMaxSupply(uint256 id, uint256 amount) external {
        _setMaxSupply(id, amount);
    }

    /**
     * @dev Pubicly exposes {_setBatchMaxSupplies}.
     */
    function setBatchMaxSupplies(uint256[] memory ids, uint256[] memory amounts) external {
        _setBatchMaxSupplies(ids, amounts);
    }

    /**
     * @dev See {IERC4365Supply-totalSupply}.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev See {IERC4365Supply-maxSupply}.
     */
    function maxSupply(uint256 id) public view virtual returns (uint256) {
        uint256 max = _maxSupply[id];
        require(max != 0, "ERC4365Supply: no maxSupply set");
        return max;
    }

    /**
     * @dev See {IERC4365Supply-exists}.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC4365Supply.totalSupply(id) > 0;
    }

    /**
     * @dev Sets the max supply for the token of token type `id`.
     */
    function _setMaxSupply(uint256 id, uint256 amount) internal virtual {
        _maxSupply[id] = amount;
    }

    /**
     * @dev [Batched] version of {setMaxSupply}.
     */
    function _setBatchMaxSupplies(uint256[] memory ids, uint256[] memory amounts) internal {
        require(ids.length == amounts.length, "ERC4365Supply: ids and amounts length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            _setMaxSupply(ids[i], amounts[i]);
        }
    }

    /**
     * @dev See {ERC4365-_beforeMint}.
     */
    function _beforeMint(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._beforeMint(minter, to, id, amount, data);

        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC4365-_beforeBurn.
     */
    function _beforeBurn(
        address burner,
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._beforeBurn(burner, from, id, amount);

        require(_totalSupply[id] >= amount, "ERC4365: burn amount exceeds totalSupply");
        unchecked {
            _totalSupply[id] -= amount;
        }
    }
}
