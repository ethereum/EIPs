// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721BindableErrors} from "./IERC721BindableErrors.sol";

/// @title ERC-721 Bindable Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-5700
///  Note: the ERC-165 identifier for this interface is 0x82a34a7d.
interface IERC721Bindable is IERC721, IERC721BindableErrors {

    /// @notice This event emits when an unbound token is bound to an NFT.
    /// @param operator The address approved to perform the binding.
    /// @param from The address of the unbound token owner.
    /// @param bindAddress The contract address of the NFT being bound to.
    /// @param bindId The identifier of the NFT being bound to.
    /// @param tokenId The identifier of binding token.
    event Bind(
        address indexed operator,
        address indexed from,
        address indexed bindAddress,
        uint256 bindId,
        uint256 tokenId
    );

    /// @notice This event emits when an NFT-bound token is unbound.
    /// @param operator The address approved to perform the unbinding.
    /// @param from The owner of the NFT the token is bound to.
    /// @param to The address of the new unbound token owner.
    /// @param bindAddress The contract address of the NFT being unbound from.
    /// @param bindId The identifier of the NFT being unbound from.
    /// @param tokenId The identifier of the unbinding token.
    event Unbind(
        address indexed operator,
        address indexed from,
        address to,
        address indexed bindAddress,
        uint256 bindId,
        uint256 tokenId
    );

    /// @notice Binds token `tokenId` to NFT `bindId` at address `bindAddress`.
    /// @dev The function MUST throw unless `msg.sender` is the current owner,
    ///  an authorized operator, or the approved address for the token. It also
    ///  MUST throw if the token is already bound or if `from` is not the token
    ///  owner. Finally, it MUST throw if the NFT contract does not support the
    ///  ERC-721 interface or if the NFT being bound to does not exist. Before
    ///  binding, token ownership MUST be transferred to the contract address of
    ///  the NFT. On bind completion, the function MUST emit `Transfer` & `Bind`
    ///  events to reflect the implicit token transfer and subsequent bind.
    /// @param from The address of the unbound token owner.
    /// @param bindAddress The contract address of the NFT being bound to.
    /// @param bindId The identifier of the NFT being bound to.
    /// @param tokenId The identifier of the binding token.
    function bind(
        address from,
        address bindAddress,
        uint256 bindId,
        uint256 tokenId
    ) external;

    /// @notice Unbinds token `tokenId` from NFT `bindId` at address `bindAddress`.
    /// @dev The function MUST throw unless `msg.sender` is the current owner,
    ///  an authorized operator, or the approved address for the NFT the token
    ///  is bound to. It also MUST throw if the token is unbound, if `from` is
    ///  not the owner of the bound NFT, or if `to` is the zero address. After
    ///  unbinding, token ownership MUST be transferred to `to`, during which
    ///  the function MUST check if `to` is a valid contract (code size > 0),
    ///  and if so, call `onERC721Received`, throwing if the wrong identifier is
    ///  returned. On unbind completion, the function MUST emit `Unbind` &
    ///  `Transfer` events to reflect the unbind and subsequent transfer.
    /// @param from The address of the owner of the NFT the token is bound to.
    /// @param to The address of the unbound token new owner.
    /// @param bindAddress The contract address of the NFT being unbound from.
    /// @param bindId The identifier of the NFT being unbound from.
    /// @param tokenId The identifier of the unbinding token.
    function unbind(
        address from,
        address to,
        address bindAddress,
        uint256 bindId,
        uint256 tokenId
    ) external;

    /// @notice Gets the NFT address and identifier token `tokenId` is bound to.
    /// @dev When the token is unbound, this function MUST return the zero
    ///  address for the address portion to indicate no binding exists.
    /// @param tokenId The identifier of the token being queried.
    /// @return The token-bound NFT contract address and numerical identifier.
    function binderOf(uint256 tokenId) external view returns (address, uint256);

    /// @notice Gets total tokens bound to NFT `bindId` at address `bindAddress`.
    /// @param bindAddress The contract address of the NFT being queried.
    /// @param bindId The identifier of the NFT being queried.
    /// @return The total number of tokens bound to the queried NFT.
    function boundBalanceOf(address bindAddress, uint256 bindId) external view returns (uint256);

}
