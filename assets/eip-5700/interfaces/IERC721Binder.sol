// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC721BinderErrors} from "./IERC721BinderErrors.sol";

/// @dev Note: the ERC-165 identifier for this interface is 0x2ac2d2bc.
interface IERC721Binder is IERC165, IERC721BinderErrors {

	/// @notice Handles the binding of an IERC721Bindable-compliant NFT.
	/// @dev An IERC721Bindable-compliant smart contract MUST call this function
	///  at the end of a `bind` after delegating ownership to the asset owner.
	///  The function MUST revert if `to` is not the asset owner of `bindId` or 
    ///  if asset `bindId` is not a valid asset. The function MUST revert if it 
    ///  rejects the bind. If accepting the bind, the function MUST return 
    /// `bytes4(keccak256("onERC721Bind(address,address,address,uint256,uint256,bytes)"))`
	///  Caller MUST revert the transaction if the above value is not returned.
	///  Note: The contract address of the binding NFT is `msg.sender`.
	/// @param operator The address responsible for initiating the bind.
	/// @param from The address which owns the unbound NFT.
	/// @param to The address which owns the asset being bound to.
	/// @param tokenId The identifier of the NFT being bound.
	/// @param bindId The identifier of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
	/// @return `bytes4(keccak256("onERC721Bind(address,address,address,uint256,uint256,bytes)"))`
	function onERC721Bind(
			address operator,
			address from,
			address to,
			uint256 tokenId,
			uint256 bindId,
			bytes calldata data
	) external returns (bytes4);

	/// @notice Handles the unbinding of an IERC721Bindable-compliant NFT.
	/// @dev An IERC721Bindable-compliant smart contract MUST call this function
	///  at the end of an `unbind` after revoking delegated asset ownership.
	///  The function MUST revert if `from` is not the asset owner of `bindId`
    ///  or if `bindId` is not a valid asset. The function MUST revert if it 
    ///  rejects the unbind. If accepting the unbind, the function MUST return
    ///  `bytes4(keccak256("onERC721Unbind(address,address,address,uint256,uint256,bytes)"))`
	///  Caller MUST revert the transaction if the above value is not returned.
	///  Note: The contract address of the unbinding NFT is `msg.sender`.
	/// @param from The address which owns the asset the NFT is bound to.
	/// @param to The address which will own the NFT once unbound.
	/// @param tokenId The identifier of the NFT being unbound.
	/// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data with no specified format.
	/// @return `bytes4(keccak256("onERC721Unbind(address,address,address,uint256,uint256,bytes)"))`
	function onERC721Unbind(
			address operator,
			address from,
			address to,
			uint256 tokenId,
			uint256 bindId,
			bytes calldata data
	) external returns (bytes4);

    /// @notice Gets the owner address of the asset represented by id `bindId`.
    /// @dev Queries for assets assigned to the zero address MUST throw.
	/// @param bindId The identifier of the asset whose owner is being queried.
    /// @return The address of the owner of the asset.
	function ownerOf(uint256 bindId) external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}
