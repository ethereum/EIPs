// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

import "IERC1155.sol";
import "ERC1155.sol";

/**
 * @title ERC-1155 Approval By Amount Extension
 * Note: the ERC-165 identifier for this interface is 0x1be07d74
 */
interface IERC1155ApprovalByAmount is IERC1155 {

    /**
     * @notice Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `id` and with an amount: `amount`.
     */
    event ApprovalByAmount(address indexed account, address indexed operator, uint256 id, uint256 amount);

    /**
     * @notice Grants permission to `operator` to transfer the caller's tokens, according to `id`, and an amount: `amount`.
     * Emits an {ApprovalByAmount} event.
     *
     * Requirements:
     * - `operator` cannot be the caller.
     */
    function approve(address operator, uint256 id, uint256 amount) external;

    /**
     * @notice Returns the amount allocated to `operator` approved to transfer `account`'s tokens, according to `id`.
     */
    function allowance(address account, address operator, uint256 id) external view returns (uint256);
    
}

/**
 * @dev Extension of {ERC1155} that allows you to approve your tokens by amount and id.
 */
abstract contract ERC1155ApprovalByAmount is ERC1155, IERC1155ApprovalByAmount {

    // Mapping from account to operator approvals by id and amount.
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal _allowances;

    /**
     * @dev See {IERC1155ApprovalByAmount}
     */
    function approve(address operator, uint256 id, uint256 amount) public virtual {
        _approve(msg.sender, operator, id, amount);
    }

    /**
     * @dev See {IERC1155ApprovalByAmount}
     */
    function allowance(address account, address operator, uint256 id) public view virtual returns (uint256) {
        return _allowances[account][operator][id];
    }

    /**
     * @dev safeTransferFrom implementation for using ApprovalByAmount extension
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(IERC1155, ERC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) || allowance(from, msg.sender, id) >= amount,
            "ERC1155: caller is not owner nor approved nor approved for amount"
        );
        unchecked {
            _allowances[from][msg.sender][id] -= amount;
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev safeBatchTransferFrom implementation for using ApprovalByAmount extension
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(IERC1155, ERC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) || _checkApprovalForBatch(from, msg.sender, ids, amounts),
            "ERC1155: transfer caller is not owner nor approved nor approved for some amount"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Checks if all ids and amounts are permissioned for `to`. 
     *
     * Requirements:
     * - `ids` and `amounts` length should be equal.
     */
    function _checkApprovalForBatch(
        address from, 
        address to, 
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual returns (bool) {
        uint256 idsLength = ids.length;
        uint256 amountsLength = amounts.length;

        require(idsLength == amountsLength, "ERC1155ApprovalByAmount: ids and amounts length mismatch");
        for (uint256 i = 0; i < idsLength;) {
            require(allowance(from, to, ids[i]) >= amounts[i], "ERC1155ApprovalByAmount: operator is not approved for that id or amount");
            unchecked { 
                _allowances[from][to][ids[i]] -= amounts[i];
                ++i; 
            }
        }
        return true;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens by id and amount.
     * Emits a {ApprovalByAmount} event.
     */
    function _approve(
        address owner,
        address operator,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(owner != operator, "ERC1155ApprovalByAmount: setting approval status for self");
        _allowances[owner][operator][id] = amount;
        emit ApprovalByAmount(owner, operator, id, amount);
    }
}

contract ExampleToken is ERC1155ApprovalByAmount {
    constructor() ERC1155("") {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
        _mintBatch(to, ids, amounts, data);
    }
}
