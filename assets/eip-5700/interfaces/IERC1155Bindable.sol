// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {IERC1155BindableErrors} from "./IERC1155BindableErrors.sol";

/// @title ERC-1155 Bindable Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-5656
///  Note: the ERC-165 identifier for this interface is 0xd0d555c6.
interface IERC1155Bindable is IERC1155, IERC1155BindableErrors {

	/// @notice The `Bind` event MUST emit when token ownership is delegated
	///  through an asset and when minting tokens bound to an existing asset.
	/// @dev When minting bound tokens, `from` MUST be set to the zero address.
	/// @param operator The address calling the bind (SHOULD be `msg.sender`).
	/// @param from The address which owns the unbound token(s).
	/// @param to The address which owns the asset being bound to.
	/// @param tokenId The identifier of the token type being bound.
	/// @param amount The number of tokens of type `tokenId` being bound.
	/// @param bindId The identifier of the asset being bound to.
	/// @param bindAddress The contract address handling asset ownership.
    event Bind(
        address indexed operator,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        address indexed bindAddress
    );

	/// @notice The `BindBatch` event MUST emit when token ownership of 
	///  different token types are delegated through different assets at once
	///  and when minting multiple token types bound to existing assets at once.
	/// @dev When minting bound tokens, `from` MUST be set to the zero address.
	/// @param operator The address calling the bind (SHOULD be `msg.sender`).
	/// @param from The address which owns the unbound token(s).
	/// @param to The address which owns the asset being bound to.
	/// @param tokenIds The identifiers of the token types being bound.
	/// @param amounts The number of tokens for each token type being bound.
	/// @param bindIds The identifiers of the assets being bound to.
	/// @param bindAddress The contract address handling asset ownership.
    event BindBatch(
        address indexed operator,
        address indexed from,
        address to,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] bindIds,
        address indexed bindAddress
    );

    /// @notice The `Unbind` event MUST emit when asset-delegated token 
	///  ownership is revoked and when burning tokens bound to existing assets.
	/// @dev When burning bound tokens, `to` MUST be set to the zero address.
	/// @param operator The address calling the unbind (SHOULD be `msg.sender`).
	/// @param from The address which owns the asset the token(s) are bound to.
	/// @param to The address which will own the token(s) once unbound.
	/// @param tokenId The identifier of the token type being unbound.
	/// @param amount The number of tokens of type `tokenId` being unbound.
	/// @param bindId The identifier of the asset being unbound from.
	/// @param bindAddress The contract address handling bound asset ownership.
    event Unbind(
        address indexed operator,
        address indexed from,
        address to,
        uint256 tokenId,
		uint256 amount,
        uint256 bindId,
        address indexed bindAddress
    );

    /// @notice The `UnbindBatch` event MUST emit when asset-delegated token 
	///  ownership is revoked for multiple token types at once and when burning 
	///  multiple token types bound to existing assets at once.
	/// @dev When burning bound tokens, `to` MUST be set to the zero address.
	/// @param operator The address calling the unbind (SHOULD be `msg.sender`).
	/// @param from The address which owns the asset the token(s) are bound to.
	/// @param to The address which will own the token(s) once unbound.
	/// @param tokenIds The identifiers of the token types being unbound.
	/// @param amounts The number of tokens for each token type being unbound.
	/// @param bindIds The identifier of the assets being unbound from.
	/// @param bindAddress The contract address handling bound asset ownership.
    event UnbindBatch(
        address indexed operator,
        address indexed from,
        address to,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] bindIds,
        address indexed bindAddress
    );

	/// @notice Delegates ownership of `amount` tokens of type `tokenId` from 
	///  address `from` through asset `bindId` owned by address `to`.
	/// @dev The function MUST throw unless `msg.sender` is an approved operator
	///  for `from`. The function also MUST throw if `from` owns fewer than 
    ///  `amount` unbound tokens, or if `to` is not the asset owner. After 
    ///  delegation of ownership, the function MUST check if `bindAddress` is a 
    ///  valid contract (code size > 0), and if so, call `onERC1155Bind` on the 
    ///  contract, throwing if the wrong identifier is returned (see "Binding 
    ///  Rules") or if the contract is invalid. On bind completion, the function
    ///  MUST emit both `Bind` and IERC-1155 `TransferSingle` events to reflect 
    ///  delegated ownership change.
	/// @param from The address which owns the unbound token(s).
	/// @param to The address which owns the asset being bound to.
	/// @param tokenId The identifier of the token type being bound.
	/// @param amount The number of tokens of type `tokenId` being bound.
	/// @param bindId The identifier of the asset being bound to.
	/// @param bindAddress The contract address handling asset ownership.
    /// @param data Additional data sent with the `onERC1155Bind` hook.
    function bind(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) external;

	/// @notice Delegates ownership of `amounts` tokens of types `tokenIds` from 
	///  address `from` through assets `bindIds` owned by address `to`.
	/// @dev The function MUST throw unless `msg.sender` is an approved operator
	///  for `from`. The function also MUST throw if length of `amounts` is not 
    ///  the same as `tokenIds` or `bindIds`, if any unbound balances of 
    ///  `tokenIds` for `from` is less than that of `amounts`, or if `to` is not
    ///  the asset owner. After delegating ownership, the function MUST check if 
    ///  `bindAddress` is a valid contract (code size > 0), and if so, call 
    ///  `onERC1155BatchBind` on the contract, throwing if the wrong identifier 
    ///  is returned (see "Binding Rules") or if the contract is invalid. On 
    ///  bind completion, the function MUST emit both `BindBatch` and IERC-1155 
    ///  `TransferBatch` events to reflect delegated ownership changes.
	/// @param from The address which owns the unbound tokens.
	/// @param to The address which owns the assets being bound to.
	/// @param tokenIds The identifiers of the token types being bound.
	/// @param amounts The number of tokens for each token type being bound.
	/// @param bindIds The identifiers of the assets being bound to.
	/// @param bindAddress The contract address handling asset ownership.
    /// @param data Additional data sent with the `onERC1155BatchBind` hook.
    function batchBind(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        address bindAddress,
        bytes calldata data
    ) external;

    /// @notice Revokes delegated ownership of `amount` tokens of type `tokenId`
	///  owned by `from` bound to `bindId`, binding direct ownership to `to`.
	/// @dev The function MUST throw unless `msg.sender` is an approved operator
    ///  or owner of the delegated asset `tokenId` is bound to. It also MUST 
    ///  throw if `from` owns fewer than `amount` bound tokens, or if `to` is 
    ///  the zero address. Once delegated ownership is revoked, the function 
    ///  MUST check if `bindAddress` is a valid contract (code size > 0), and if 
    ///  so, call `onERC1155Unbind` on the contract, throwing if the wrong 
    ///  identifier is returned (see "Binding Rules") or if the contract is 
    ///  invalid. The function also MUST check if `to` is a contract, and if so,
    ///  call on it `onERC1155Received`, throwing if the wrong identifier is 
    ///  returned. On unbind completion, the function MUST emit both `Unbind` 
    ///  and IERC-1155 `TransferSingle` events to reflect delegated ownership change.
	/// @param from The address which owns the asset the token(s) are bound to.
	/// @param to The address which will own the tokens once unbound.
	/// @param tokenId The identifier of the token type being unbound.
	/// @param amount The number of tokens of type `tokenId` being unbound.
	/// @param bindId The identifier of the asset being unbound from.
	/// @param bindAddress The contract address handling bound asset ownership.
    /// @param data Additional data sent with the `onERC1155Unbind` hook.
    function unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
		uint256 bindId,
		address bindAddress,
        bytes calldata data
    ) external;

    /// @notice Revokes delegated ownership of `amounts` tokens of `tokenIds`
	///  bound to assets `bindIds`, binding direct ownership to `to`.
	/// @dev The function MUST throw unless `msg.sender` is an approved operator
    ///  or owner of all delegated assets `tokenIds` are bound to. It also MUST
    ///  throw if the length of `amounts` is not the same as `tokenIds` or 
    ///  `bindIds`, if any bound balances of `tokenId` for `from` is less than 
    ///  that of `amounts`, or if `to` is the zero address. Once delegated 
    ///  ownership is revoked, the function MUST check if `bindAddress` is a 
    ///  valid contract (code size >  0), and if so, call onERC1155BatchUnbind` 
    ///  on it, throwing if a wrong identifier is returned (see "Binding Rules") 
    ///  or if the contract is invalid. The function also MUST check if `to` is 
    ///  a valid contract, and if so, call `onERC1155BatchReceived`, throwing if 
    ///  the wrong identifier is returned. On unbind completion, the function 
    ///  MUST emit the `BatchUnbind` and IERC-1155 `TransferBatch` events to 
    ///  reflect delegated ownership changes.
	/// @param from The address which owns the asset the tokens are bound to.
	/// @param to The address which will own the tokens once unbound.
	/// @param tokenIds The identifiers of the token types being unbound.
	/// @param amounts The number of tokens for each token type being unbound.
	/// @param bindIds The identifier of the assets being unbound from.
	/// @param bindAddress The contract address handling bound asset ownership.
    /// @param data Additional data sent with the `onERC1155BatchUnbind` hook.
    function batchUnbind(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
		uint256[] calldata bindIds,
		address bindAddress,
        bytes calldata data
    ) external;

    /// @notice Gets the balance of bound tokens of type `tokenId` bound to the
    ///  asset `bindId` at address `bindAddress`.
    /// @param bindId The identifier of the bound asset.
    /// @param bindAddress The contract address handling bound asset ownership.
	/// @param tokenId The identifier of the bound token type being counted.
    /// @return The total number of NFTs bound to the asset.
    function boundBalanceOf(
        address bindAddress,
        uint256 bindId,
        uint256 tokenId
    ) external returns (uint256);

	/// @notice Gets the balance of bound tokens for multiple token types given
    ///  by `tokenIds` bound to assets `bindIds` at address `bindAddress`.
    /// @notice Retrieves bound balances of multiple asset / token type pairs.
    /// @param bindIds List of bound asset identifiers.
    /// @param bindAddress The contract address handling bound asset ownership.
	/// @param tokenIds The identifiers of the token type being counted.
    /// @return balances The bound balances for each asset / token type pair.
    function boundBalanceOfBatch(
        address bindAddress,
        uint256[] calldata bindIds,
        uint256[] calldata tokenIds
    ) external returns (uint256[] memory balances);

}
