// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC1155BinderErrors} from "./IERC1155BinderErrors.sol";

/// @dev Note: the ERC-165 identifier for this interface is 0x6fc97e78.
interface IERC1155Binder is IERC165, IERC1155BinderErrors {

	/// @notice Handles binding of an IERC1155Bindable-compliant token type.
	/// @dev An IERC1155Bindable-compliant smart contract MUST call this 
	///  function at the end of a `bind` after delegating ownership to the asset 
	///  owner. The function MUST revert if `to` is not the asset owner of
    ///  `bindId`, or if `bindId` is not a valid asset. The function MUST revert
    ///  if it rejects the bind. If accepting the bind, the function MUST return
	///  `bytes4(keccak256("onERC1155Bind(address,address,address,uint256,uint256,uint256,bytes)"))`
	///  Caller MUST revert the transaction if the above value is not returned.
	///  Note: The contract address of the binding token is `msg.sender`.
	/// @param operator The address responsible for binding.
	/// @param from The address which owns the unbound tokens.
	/// @param to The address which owns the asset being bound to.
	/// @param tokenId The identifier of the token type being bound.
	/// @param bindId The identifier of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
	/// @return `bytes4(keccak256("onERC1155Bind(address,address,address,uint256,uint256,uint256,bytes)"))`
	function onERC1155Bind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
	) external returns (bytes4);

	/// @notice Handles binding of multiple IERC1155Bindable-compliant tokens 
    ///  `tokenIds` to multiple assets `bindIds`.
	/// @dev An IERC1155Bindable-compliant smart contract MUST call this 
	///  function at the end of a `batchBind` after delegating ownership of 
    ///  multiple token types to the asset owner. The function MUST revert if 
    ///  `to` is not the asset owner of `bindId`, or if `bindId` is not a valid 
    ///  asset. The function MUST revert if it rejects the binds. If accepting 
    ///  the binds, the function MUST return `bytes4(keccak256("onERC1155BatchBind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
	///  Caller MUST revert the transaction if the above value is not returned.
	///  Note: The contract address of the binding token is `msg.sender`.
	/// @param operator The address responsible for performing the binds.
	/// @param from The address which owns the unbound tokens.
	/// @param to The address which owns the assets being bound to.
	/// @param tokenIds The list of token types being bound.
	/// @param amounts The number of tokens for each token type being bound.
	/// @param bindIds The identifiers of the assets being bound to.
    /// @param data Additional data sent along with no specified format.
	/// @return `bytes4(keccak256("onERC1155Bind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
	function onERC1155BatchBind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        bytes calldata data
	) external returns (bytes4);

	/// @notice Handles unbinding of an IERC1155Bindable-compliant token type.
	/// @dev An IERC1155Bindable-compliant contract MUST call this function at
	///  the end of an `unbind` after revoking delegated asset ownership. The 
	///  function MUST revert if `from` is not the asset owner of `bindId`, 
	///  or if `bindId` is not a valid asset. The function MUST revert if it
	///  rejects the unbind. If accepting the unbind, the function MUST return
	///  `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256,uint256,uint256,bytes)"))`
	///  Caller MUST revert the transaction if the above value is not returned.
	///  Note: The contract address of the unbinding token is `msg.sender`.
	/// @param operator The address responsible for performing the unbind.
	/// @param from The address which owns the asset the token type is bound to.
	/// @param to The address which will own the tokens once unbound.
	/// @param tokenId The token type being unbound.
	/// @param amount The number of tokens of type `tokenId` being unbound.
	/// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data sent along with no specified format.
	/// @return `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256,uint256,uint256,bytes)"))`
	function onERC1155Unbind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
	) external returns (bytes4);

	/// @notice Handles unbinding of multiple IERC1155Bindable-compliant token types.
	/// @dev An IERC1155Bindable-compliant contract MUST call this function at
	///  the end of an `batchUnbind` after revoking delegated asset ownership. 
    ///  The function MUST revert if `from` is not the asset owner of `bindId`, 
	///  or if `bindId` is not a valid asset. The function MUST revert if it
	///  rejects the unbinds. If accepting the unbinds, the function MUST return
	///  `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
	///  Caller MUST revert the transaction if the above value is not returned.
	///  Note: The contract address of the unbinding token is `msg.sender`.
	/// @param operator The address responsible for performing the unbinds.
	/// @param from The address which owns the assets being unbound from.
	/// @param to The address which will own the tokens once unbound.
	/// @param tokenIds The list of token types being unbound.
	/// @param amounts The number of tokens for each token type being unbound.
	/// @param bindIds The identifiers of the assets being unbound from.
    /// @param data Additional data sent along with no specified format.
	/// @return `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
	function onERC1155BatchUnbind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        bytes calldata data
	) external returns (bytes4);

    /// @notice Gets the owner address of the asset represented by id `bindId`.
	/// @param bindId The identifier of the asset whose owner is being queried.
    /// @return The address of the owner of the asset.
	function ownerOf(uint256 bindId) external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}
