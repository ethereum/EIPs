// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;
import "@openzeppelin/contracts/math/SafeMath.sol";
import { ERC1155 } from "./ERC1155.sol";

/// @title A base contract for an ERC-1155 contract with calculation of totals.
abstract contract ERC1155WithTotals is ERC1155 {
    using SafeMath for uint256;

    // Mapping (token => total).
    mapping(uint256 => uint256) private totalBalances;

    /// Construct a token contract with given description URI.
    /// @param uri_ Description URI.
    constructor (string memory uri_) ERC1155(uri_) { }

    // Overrides //

    // Need also update totals - commented out
    // function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
    //     return super._mintBatch(_originalAddress(to), ids, amounts, data);
    // }

    // Need also update totals - commented out
    // function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
    //     return super._burnBatch(_originalAddress(account), ids, amounts);
    // }

    /// Total supply of a token (conforms to `IERC1155Views`).
    /// @param id Token ID.
    /// @return Total supply.
    function totalSupply(uint256 id) public view returns (uint256) {
        return totalBalances[id];
    }

    /// Mint a token.
    /// @param to Whom to mint to.
    /// @param id Token ID.
    /// @param value Amount to mint.
    /// @param data Additional data.
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal override {
        require(to != address(0), "ERC1155: mint to the zero address");

        _doMint(to, id, value);
        emit TransferSingle(msg.sender, address(0), to, id, value);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, value, data);
    }

    /// Mint zero or more tokens.
    /// @param to Whom to mint to.
    /// @param ids Token IDs.
    /// @param values Amounts to mint.
    /// @param data Additional data.
    function _batchMint(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        require(to != address(0), "ERC1155: batch mint to the zero address");
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _doMint(to, ids[i], values[i]);
        }

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, values, data);
    }

    /// Burn a token.
    /// @param owner Whose tokens to burn.
    /// @param id Token ID.
    /// @param value Amount to mint.
    function _burn(address owner, uint256 id, uint256 value) internal override {
        _doBurn(owner, id, value);
        emit TransferSingle(msg.sender, owner, address(0), id, value);
    }

    /// Burn zero or more tokens.
    /// @param owner Whose tokens to burn.
    /// @param ids Token IDs.
    /// @param values Amounts to mint.
    function _batchBurn(address owner, uint256[] memory ids, uint256[] memory values) internal {
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _doBurn(owner, ids[i], values[i]);
        }

        emit TransferBatch(msg.sender, owner, address(0), ids, values);
    }

    function _doMint(address to, uint256 id, uint256 value) private {
        totalBalances[id] = totalBalances[id].add(value);
        _balances[id][to] = _balances[id][to] + value; // The previous didn't overflow, therefore this doesn't overflow.
    }

    function _doBurn(address from, uint256 id, uint256 value) private {
        _balances[id][from] = _balances[id][from].sub(value);
        totalBalances[id] = totalBalances[id] - value; // The previous didn't overflow, therefore this doesn't overflow.
    }
}