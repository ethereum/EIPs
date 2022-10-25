// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721BindableErrors} from "./IERC721BindableErrors.sol";

/// @title ERC-721 Bindable Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-5700
///  Note: the ERC-165 identifier for this interface is 0x82a34a7d.
interface IERC721Bindable is IERC721, IERC721BindableErrors {

	/// @notice The `Bind` event MUST emit when NFT ownership is delegated
	///  through an asset and when minting an NFT bound to an existing asset.
	/// @dev When minting bound NFTs, `from` MUST be set to the zero address.
	/// @param operator The address calling the bind (SHOULD be `msg.sender`).
	/// @param from The address which owns the unbound NFT.
	/// @param to The address which owns the asset being bound to.
	/// @param tokenId The identifier of the NFT being bound.
	/// @param bindId The identifier of the asset being bound to.
	/// @param bindAddress The contract address handling asset ownership.
    event Bind(
        address indexed operator,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address indexed bindAddress
    );

    /// @notice The `Unbind` event MUST emit when asset-delegated NFT ownership 
	///  is revoked, as well as when burning an NFT bound to an existing asset.
	/// @dev When burning bound NFTs, `to` MUST be set to the zero address.
	/// @param operator The address calling the unbind (SHOULD be `msg.sender`).
	/// @param from The address which owns the asset the NFT is bound to.
	/// @param to The address which will own the NFT once unbound.
	/// @param tokenId The identifier of the NFT being unbound.
	/// @param bindId The identifier of the asset being unbound from.
	/// @param bindAddress The contract address handling bound asset ownership.
    event Unbind(
        address indexed operator,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address indexed bindAddress
    );

	/// @notice Delegates NFT ownership of NFT `tokenId` from address `from`
	///  through the asset `bindId` owned by address `to`.
	/// @dev The function MUST throw unless `msg.sender` is the current owner, 
	///  an authorized operator, or the approved address for the NFT. It also
	///  MUST throw if NFT `tokenId` is already bound, if `from` is not the NFT 
	///  owner, or if `to` is not the asset owner. After ownership delegation, 
    ///  the function MUST check if `bindAddress` is a valid contract (code size
    ///  > 0), and if so, call `onERC721Bind` on the contract, throwing if the 
    ///  wrong identifier is returned (see "Binding Rules") or if the contract 
    ///  is invalid. On bind completion, the function MUST emit both `Bind` and 
    ///  IERC-721 `Transfer` events to reflect delegated ownership change.
	/// @param from The address which owns the unbound NFT.
	/// @param to The address which owns the asset being bound to.
	/// @param tokenId The identifier of the NFT being bound.
	/// @param bindId The identifier of the asset being bound to.
	/// @param bindAddress The contract address handling asset ownership.
    /// @param data Additional data sent with the `onERC721Bind` hook.
    function bind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) external;

	/// @dev The function MUST throw unless `msg.sender` is an approved operator
    ///  or owner of the delegated asset of `tokenId`. It also MUST throw if NFT
    ///  `tokenId` is not bound, if `from` is not the asset owner, or if `to` 
    ///  is the zero address. After ownership transition, the function MUST 
    ///  check if `bindAddress` is a valid contract (code size > 0), and if so, 
    ///  call `onERC721Unbind` the contract, throwing if the wrong identifier is 
    ///  returned (see "Binding Rules") or if the contract is invalid. 
    ///  The function also MUST check if `to` is a valid contract, and if so, 
    ///  call `onERC721Received`, throwing if the wrong identifier is returned.
    ///  On unbind completion, the function MUST emit both `Unbind` and IERC-721 
    ///  `Transfer` events to reflect delegated ownership change.
	/// @param from The address which owns the asset the NFT is bound to.
	/// @param to The address which will own the NFT once unbound.
	/// @param tokenId The identifier of the NFT being unbound.
	/// @param bindId The identifier of the asset being unbound from.
	/// @param bindAddress The contract address handling bound asset ownership.
    /// @param data Additional data sent with the `onERC721Unbind` hook.
    function unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) external;

	/// @notice Gets the asset identifier and address which a token is bound to.
    /// @param tokenId The identifier of the NFT being queried.
    /// @return The bound asset identifier and contract address.
    function binderOf(uint256 tokenId) external returns (address, uint256);

    /// @notice Counts NFTs bound to asset `bindId` at address `bindAddress`.
    /// @param bindId The identifier of the bound asset.
    /// @param bindAddress The contract address handling bound asset ownership.
    /// @return The total number of NFTs bound to the asset.
    function boundBalanceOf(address bindAddress, uint256 bindId) external returns (uint256);

}
