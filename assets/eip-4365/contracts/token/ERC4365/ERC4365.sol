// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "./IERC4365Receiver.sol";
import "../../utils/introspection/ERC165.sol";
import "./IERC4365.sol";

/**
 * @dev Implementation proposal for redeemable tokens (tickets).
 */
contract ERC4365 is Context, ERC165, IERC4365 {
    using Address for address;

    // Mapping from token ID to account balances. id => (account => balance)
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from token ID to account balance of redeemed tokens. id => (account => redeemed)
    mapping(uint256 => mapping(address => uint256)) private _redeemed;

    // Used as the URI for all token types by relying on ID substitution, 
    // e.g. https://token-cdn-domain/{id}.json.
    string private _baseURI;

    /**
     * @dev See {_setBaseURI}.
     */
    constructor(string memory baseURI_) {
        _setBaseURI(baseURI_);
    }

    /**
     * @dev See {IERC4365-redeem}.
     */
    function redeem(
        address account, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) external virtual {
        require(_balances[id][account] >= _redeemed[id][account] + amount, 
            "ERC4365: redeem amount exceeds balance");

        _beforeRedeem(account, id, amount, data);

        _redeemed[id][account] += amount;
        emit Redeem(account, id, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC4365).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This implementation retuns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism as in EIP-1155:
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     * 
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC-4365-balanceOf}.
     */
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        require(account != address(0), "ERC4365: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC4365-balanceOfBatch}.
     */
    function balanceOfBatch(address account, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 idsLength = ids.length;
        uint256[] memory batchBalances = new uint256[](idsLength);

        for (uint256 i = 0; i < idsLength; ++i) {
            batchBalances[i] = balanceOf(account, ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC4365-balanceOfBundle}.
     */
    function balanceOfBundle(address[] memory accounts, uint256[][] memory ids)
        public
        view
        virtual
        returns (uint256[][] memory)
    {
        uint256 accountsLength = accounts.length;
        uint256[][] memory bundleBalances = new uint256[][](accountsLength);

        for (uint256 i = 0; i < accountsLength; ++i) {
            bundleBalances[i] = balanceOfBatch(accounts[i], ids[i]);
        }

        return bundleBalances;
    }

    /**
     * @dev See {IERC4365-balanceOfRedeemed}.
     */
    function balanceOfRedeemed(address account, uint256 id) public view virtual returns (uint256) {
        require(account != address(0), "ERC4365: address zero is not a valid owner");
        return _redeemed[id][account];
    }

    /**
     * @dev See {IERC4365-balanceOfRedeemedBatch}.
     */
    function balanceOfRedeemedBatch(address account, uint256[] memory ids) 
        public 
        view 
        virtual 
        returns(uint256[] memory) 
    {
        uint256 idsLength = ids.length;
        uint256[] memory batchRedeemed = new uint256[](idsLength);

        for (uint256 i = 0; i < idsLength; ++i) {
            batchRedeemed[i] = balanceOfRedeemed(account, ids[i]);
        }

        return batchRedeemed;
    }

    /**
     * @dev See {IERC4365-balanceOfRedeemedBundle}.
     */
    function balanceOfRedeemedBundle(address[] memory accounts, uint256[][] memory ids) 
        public 
        view 
        virtual 
        returns (uint256[][] memory) 
    {
        uint256 accountsLength = accounts.length;
        uint256[][] memory bundleRedeemed = new uint256[][](accountsLength);

        for (uint256 i = 0; i < accountsLength; ++i) {
            bundleRedeemed[i] = balanceOfRedeemedBatch(accounts[i], ids[i]);
        }

        return bundleRedeemed;
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism as in EIP-1155
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setBaseURI(string memory newBaseURI) internal virtual {
        _baseURI = newBaseURI;
    }

    /**
     * @dev Creates `amount` tokens of token type `id` and assigns them to `to`.
     * 
     * Emits a {MintSingle} event.
     * 
     * Requirements:
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement [IERC4365REceiver-onERC4365Received] and
     * return the acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address minter = _msgSender();

        _beforeMint(minter, to, id, amount, data);

        _balances[id][to] += amount;
        emit MintSingle(minter, to, id, amount);

        _doSafeMintAcceptanceCheck(minter, to, id, amount, data);
    }

    /**
     * @dev [Batched] version of {_mint}. A batch specifies an array of token `id` and
     * the amount of token for each. 
     * 
     * Emits a {MintBatch} event.
     * 
     * Requirements:
     * - `ids` and `amounts` must have the same length.  
     * - If `to` refers to a smart contract, it must implement [IERC4365REceiver-onERC4365BatchReceived] and
     * return the acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address minter = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            _beforeMint(minter, to, ids[i], amounts[i], data);

            _balances[ids[i]][to] += amounts[i];
        }

        emit MintBatch(minter, to, ids, amounts);

        _doSafeBatchMintAcceptanceCheck(minter, to, ids, amounts, data);
    }

    /**
     * @dev [Bundled] version of {_mint}. A bundle can be views as minting several batches
     * to an array of addresses in one transaction. 
     * 
     * Emits multiple {MintBatch} events.
     */
    function _mintBundle(
        address[] calldata to,
        uint256[][] calldata ids,
        uint256[][] calldata amounts,
        bytes[] calldata data
    ) internal virtual {
        uint256 toLength = to.length;
        for (uint256 i = 0; i < toLength; i++) {
           _mintBatch(to[i], ids[i], amounts[i], data[i]);
        }
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`.
     *
     * Emits a {BurnSingle} event.
     *
     * Requirements:
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC4365: burn from the zero address");

        address burner = _msgSender();

        _beforeBurn(burner, from, id, amount);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC4365: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit BurnSingle(burner, from, id, amount);
    }

    /**
     * [Batched] version of {_burn}.
     * 
     * Emits a {BurnBatch} event.
     * 
     * Requirements:
     * - `ids` and `amouts` ust have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC4365: burn from the zero address");
        require(ids.length == amounts.length, "ERC4365: ids and amounts length mismatch");

        address burner = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _beforeBurn(burner, from, ids[i], amounts[i]);

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC4365: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit BurnBatch(burner, from, ids, amounts);
    }

    /**
     * @dev Hook that is called before an `amount` of tokens are minted.
     *
     * The same hook is called on both sinle 
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address.
     */
    function _beforeMint(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before an `amount` of tokens are burned.
     *
     * Calling conditions:
     * - `minter` and `from` cannot be the zero address.
     */
    function _beforeBurn(
        address burner,
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called before an `amount` of tokens are redeemed.
     *
     * Calling conditions:
     * - `account` cannot be the zero address.
     */
    function _beforeRedeem(
        address account, 
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}


    function _doSafeMintAcceptanceCheck(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC4365Receiver(to).onERC4365Mint(minter, id, amount, data) returns (bytes4 response) {
                if (response != IERC4365Receiver.onERC4365Mint.selector) {
                    revert("ERC4365: ERC4365Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC4365: mint to non-ERC4365Receiver implementer");
            }
        }
    }

    function _doSafeBatchMintAcceptanceCheck(
        address minter,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC4365Receiver(to).onERC4365BatchMint(minter, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC4365Receiver.onERC4365BatchMint.selector) {
                    
                    revert("ERC4365: ERC4365Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC4365: mint to non-ERC4365Receiver implementer");
            }
        }
    }
}