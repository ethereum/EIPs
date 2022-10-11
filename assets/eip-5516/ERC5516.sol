//SPDX-License-Identifier: CC0-1.0

/**
 * @notice Reference implementation of the eip-5516 interface.
 * Note: this implementation only allows for each user to own only 1 token type for each `id`.
 * @author Matias Arazi <matiasarazi@gmail.com> , Lucas Martín Grasso Ramos <lucasgrassoramos@gmail.com>
 * See https://github.com/ethereum/EIPs/pull/5516
 *
 */

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC5516.sol";

contract ERC5516 is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC5516 {
    using Address for address;

    // Used for making each token unique, Maintains ID registry and quantity of tokens minted.
    uint256 private nonce;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://ipfs.io/ipfs/token.data
    string private _uri;

    // Mapping from token ID to account balances
    mapping(address => mapping(uint256 => bool)) private _balances;

    // Mapping from address to mapping id bool that states if address has tokens(under id) awaiting to be claimed
    mapping(address => mapping(uint256 => bool)) private _pendings;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from ID to minter address.
    mapping(uint256 => address) private _tokenMinters;

    // Mapping from ID to URI.
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Sets base uri for tokens. Preferably "https://ipfs.io/ipfs/"
     */
    constructor(string memory uri_) {
        _uri = uri_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC5516).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 _id)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_uri, _tokenURIs[_id]));
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(account != address(0), "EIP5516: Address zero error");
        if (_balances[account][id]) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     *
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "EIP5516: Array lengths mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Get tokens owned by a given address
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function tokensFrom(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(account != address(0), "EIP5516: Address zero error");

        uint256 _tokenCount = 0;
        for (uint256 i = 1; i <= nonce; ) {
            if (_balances[account][i]) {
                unchecked {
                    ++_tokenCount;
                }
            }
            unchecked {
                ++i;
            }
        }

        uint256[] memory _ownedTokens = new uint256[](_tokenCount);

        for (uint256 i = 1; i <= nonce; ) {
            if (_balances[account][i]) {
                _ownedTokens[--_tokenCount] = i;
            }
            unchecked {
                ++i;
            }
        }

        return _ownedTokens;
    }

    /**
     * @dev Get tokens marked as _pendings of a given address
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function pendingFrom(address account)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(account != address(0), "EIP5516: Address zero error");

        uint256 _tokenCount = 0;

        for (uint256 i = 1; i <= nonce; ) {
            if (_pendings[account][i]) {
                ++_tokenCount;
            }
            unchecked {
                ++i;
            }
        }

        uint256[] memory _pendingTokens = new uint256[](_tokenCount);

        for (uint256 i = 1; i <= nonce; ) {
            if (_pendings[account][i]) {
                _pendingTokens[--_tokenCount] = i;
            }
            unchecked {
                ++i;
            }
        }

        return _pendingTokens;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev mints(creates) a token
     */
    function _mint(address account, string memory data) internal virtual {
        unchecked {
            ++nonce;
        }

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(nonce);
        uint256[] memory amounts = _asSingletonArray(1);
        bytes memory _bData = bytes(data);

        _beforeTokenTransfer(
            operator,
            address(0),
            operator,
            ids,
            amounts,
            _bData
        );
        _tokenURIs[nonce] = data;
        _tokenMinters[nonce] = account;
        emit TransferSingle(operator, address(0), operator, nonce, 1);
        _afterTokenTransfer(
            operator,
            address(0),
            operator,
            ids,
            amounts,
            _bData
        );
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *
     * Requirements:
     *
     * - `from` must be the creator(minter) of `id` or must have allowed _msgSender() as an operator.
     *
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(amount == 1, "EIP5516: Can only transfer one token");
        require(
            _msgSender() == _tokenMinters[id] ||
                isApprovedForAll(_tokenMinters[id], _msgSender()),
            "EIP5516: Unauthorized"
        );

        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {eip-5516-batchTransfer}
     *
     * Requirements:
     *
     * - 'from' must be the creator(minter) of `id` or must have allowed _msgSender() as an operator.
     *
     */
    function batchTransfer(
        address from,
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual override {
        require(amount == 1, "EIP5516: Can only transfer one token");
        require(
            _msgSender() == _tokenMinters[id] ||
                isApprovedForAll(_tokenMinters[id], _msgSender()),
            "EIP5516: Unauthorized"
        );

        _batchTransfer(from, to, id, amount, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` must be the creator(minter) of the token under `id`.
     * - `to` must be non-zero.
     * - `to` must have the token `id` marked as _pendings.
     * - `to` must not own a token type under `id`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     *   acceptance magic value.
     *
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(from != address(0), "EIP5516: Address zero error");
        require(
            _pendings[to][id] == false && _balances[to][id] == false,
            "EIP5516: Already Assignee"
        );

        address operator = _msgSender();

        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        _pendings[to][id] = true;

        emit TransferSingle(operator, from, to, id, amount);
        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * Transfers `id` token from `from` to every address at `to[]`.
     *
     * Requirements:
     * - See {eip-5516-safeMultiTransfer}.
     *
     */
    function _batchTransfer(
        address from,
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address operator = _msgSender();

        _beforeBatchedTokenTransfer(operator, from, to, id, data);

        for (uint256 i = 0; i < to.length; ) {
            address _to = to[i];

            require(_to != address(0), "EIP5516: Address zero error");
            require(
                _pendings[_to][id] == false && _balances[_to][id] == false,
                "EIP5516: Already Assignee"
            );

            _pendings[_to][id] = true;

            unchecked {
                ++i;
            }
        }

        emit TransferMulti(operator, from, to, amount, id);

        _beforeBatchedTokenTransfer(operator, from, to, id, data);
    }

    /**
     * @dev See {eip-5516-claimOrReject}
     *
     * If action == true: Claims pending token under `id`.
     * Else, rejects pending token under `id`.
     *
     */
    function claimOrReject(
        address account,
        uint256 id,
        bool action
    ) external virtual override {
        require(_msgSender() == account, "EIP5516: Unauthorized");

        _claimOrReject(account, id, action);
    }

    /**
     * @dev See {eip-5516-claimOrReject}
     *
     * For each `id` - `action` pair:
     *
     * If action == true: Claims pending token under `id`.
     * Else, rejects pending token under `id`.
     *
     */
    function claimOrRejectBatch(
        address account,
        uint256[] memory ids,
        bool[] memory actions
    ) external virtual override {
        require(
            ids.length == actions.length,
            "EIP5516: Array lengths mismatch"
        );

        require(_msgSender() == account, "EIP5516: Unauthorized");

        _claimOrRejectBatch(account, ids, actions);
    }

    /**
     * @dev Claims or Reject pending token under `_id` from address `_account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have a _pendings token under `id` at the moment of call.
     * - `account` mUST not own a token under `id` at the moment of call.
     *
     * Emits a {TokenClaimed} event.
     *
     */
    function _claimOrReject(
        address account,
        uint256 id,
        bool action
    ) internal virtual {
        require(
            _pendings[account][id] == true && _balances[account][id] == false,
            "EIP5516: Not claimable"
        );

        address operator = _msgSender();

        bool[] memory actions = new bool[](1);
        actions[0] = action;
        uint256[] memory ids = _asSingletonArray(id);

        _beforeTokenClaim(operator, account, actions, ids);

        _balances[account][id] = action;
        _pendings[account][id] = false;

        delete _pendings[account][id];

        emit TokenClaimed(operator, account, actions, ids);

        _afterTokenClaim(operator, account, actions, ids);
    }

    /**
     * @dev Claims or Reject _pendings `_id` from address `_account`.
     *
     * For each `id`-`action` pair:
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have a pending token under `id` at the moment of call.
     * - `account` must not own a token under `id` at the moment of call.
     *
     *  Emits a {TokenClaimed} event.
     *
     */
    function _claimOrRejectBatch(
        address account,
        uint256[] memory ids,
        bool[] memory actions
    ) internal virtual {
        uint256 totalIds = ids.length;
        address operator = _msgSender();

        _beforeTokenClaim(operator, account, actions, ids);

        for (uint256 i = 0; i < totalIds; ) {
            uint256 id = ids[i];

            require(
                _pendings[account][id] == true &&
                    _balances[account][id] == false,
                "EIP5516: Not claimable"
            );

            _balances[account][id] = actions[i];
            _pendings[account][id] = false;

            delete _pendings[account][id];

            unchecked {
                ++i;
            }
        }

        emit TokenClaimed(operator, account, actions, ids);

        _afterTokenClaim(operator, account, actions, ids);
    }

    /**
     * @dev Destroys `id` token from `account`
     *
     * Emits a {TransferSingle} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` must own a token under `id`.
     *
     */
    function _burn(address account, uint256 id) internal virtual {
        require(_balances[account][id] == true, "EIP5516: Unauthorized");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(1);

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        delete _balances[account][id];

        emit TransferSingle(operator, account, address(0), id, 1);
        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");
    }

    /**
     * @dev Destroys all tokens under `ids` from `account`
     *
     * Emits a {TransferBatch} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` must own all tokens under `ids`.
     *
     */
    function _burnBatch(address account, uint256[] memory ids)
        internal
        virtual
    {
        uint256 totalIds = ids.length;
        address operator = _msgSender();
        uint256[] memory amounts = _asSingletonArray(totalIds);
        uint256[] memory values = _asSingletonArray(0);

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < totalIds; ) {
            uint256 id = ids[i];

            require(_balances[account][id] == true, "EIP5516: Unauthorized");

            delete _balances[account][id];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, values);

        _afterTokenTransfer(operator, account, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     *
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before any batched token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeBatchedTokenTransfer(
        address operator,
        address from,
        address[] memory to,
        uint256 id,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any batched token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterBatchedTokenTransfer(
        address operator,
        address from,
        address[] memory to,
        uint256 id,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before any token claim.
     +
     * Calling conditions (for each `action` and `id` pair):
     *
     * - A token under `id` must exist.
     * - When `action` is non-zero, a token under `id` will now be claimed and owned by`operator`.
     * - When `action` is false, a token under `id` will now be rejected.
     * 
     */
    function _beforeTokenClaim(
        address operator,
        address account,
        bool[] memory actions,
        uint256[] memory ids
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token claim.
     +
     * Calling conditions (for each `action` and `id` pair):
     *
     * - A token under `id` must exist.
     * - When `action` is non-zero, a token under `id` is now owned by`operator`.
     * - When `action` is false, a token under `id` was rejected.
     * 
     */
    function _afterTokenClaim(
        address operator,
        address account,
        bool[] memory actions,
        uint256[] memory ids
    ) internal virtual {}

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev see {ERC1155-_doSafeTransferAcceptanceCheck, IERC1155Receivable}
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    /**
     * @dev Unused/Deprecated function
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}
}
