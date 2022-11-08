---
eip: <to be assigned>
title: Rejectable Non-Fungible Token
description: Extend ERC-721 standard to include a selective reception of the NFT by the receiver of the transfer
author: Miquel A. Cabot (@miquelcabot), M. Magdalena Payeras (@MagdalenaPayeras), Macià Mut (@maciamut), Rosa Pericàs (@RosaPericas)
discussions-to: https://ethereum-magicians.org/<URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-10-19
requires: 165, 721
---

## Abstract
This improvement of the ERC-721 standard includes the possibility that the receiver could reject a token transfer, allowing the selective reception of NFTs. The proposal depends on and extends the existing [EIP-721](https://eips.ethereum.org/EIPS/eip-721).

## Motivation
The [EIP-721](https://eips.ethereum.org/EIPS/eip-721) standard proposal was designed with the aim of creating interchangeable tokens but with the peculiarity of being unique and non-fungible. These ERC-721 tokens can be transferred with the consent of the owner (by himself or by an authorised party). However, the receiver of the token cannot decline the reception of the token, that will be transferred to his wallet.

For this reason, a problem can arise when the NFTs are used to represent some kinds of objects, for example when we want to send tokens that represent a passive value or "negative value" and not an active one, such as a loan or a burden. Moreover, a receiver could want to reject a transfer that represents a non-desired notification or delivery.

The selective receipt property is the ability of a receiver to decide whether to accept or reject a delivery. The use of a rejectable NFT can be very useful to provide the receiver with the ability to selectively reject the transfer of the token. The explicit and clear acceptance of tokens can lead to stronger protocol specifications for fair exchanges.

## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

1. Any compliant contract MUST implement [EIP-721](./eip-721.md), and [EIP-165](./eip-165.md).

2. Any compliant contract MUST implement the following interface:

```solidity
/**
 * @title  Rejectable NFT interface
 * @dev Iterface that inherits from a Non-Fungible Token Standard, and it also adds
 * the possibility to be rejected by the receiver of the transfer function.
 */
interface IRejectableNFT is EIP721 {
    /**
     * @dev Emitted when `tokenId` token is proposed to be transferred from `from` sender to `to` receiver.
     */
    event TransferRequest(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when receiver `to` rejects `tokenId` transfer from `from` to `to`.
     */
    event RejectTransfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when sender `from` cancels `tokenId` transfer from `from` to `to`.
     */
    event CancelTransfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Returns the address of the tokenId token to which it is currently offered.
     * @param tokenId ID of the token to query the offer of
     * @return Address currently marked as the next possible owner of the given token ID
     */
    function transferableOwnerOf(uint256 tokenId)
        external
        view
        returns (address);

    /**
     * @dev Accepts the transfer of the given token ID
     * The caller must be the current transferable owner of the token ID
     * @param tokenId ID of the token to be transferred
     */
    function acceptTransfer(uint256 tokenId) external;

    /**
     * @dev Rejects the transfer of the given token ID
     * The caller must be the current transferable owner of the token ID
     * @param tokenId ID of the token to be transferred
     */
    function rejectTransfer(uint256 tokenId) external;

    /**
     * @dev Cancels the transfer of the given token ID
     * The caller must be the current owner of the token ID
     * @param tokenId ID of the token to be transferred
     */
    function cancelTransfer(uint256 tokenId) external;
}
```

With this interface, the ERC-721 standard is extended to include the possibility that the receiver could reject a token transfer, allowing the selective reception of NFTs. This is achieved following these steps:
1. Modify the `safeTransferFrom()`, `transferFrom()` and `mint()` functions to emit a `TransferRequest` event when the transfer is requested, instead of emitting a `Transfer` event.
2. Add a new function `acceptTransfer()` that allows the receiver to accept the transfer of the token. The function MUST emit the `Transfer` event when the transfer is accepted.
3. Add a new function `rejectTransfer()` that allows the receiver to reject the transfer of the token. The function MUST emit the `RejectTransfer` event when the transfer is rejected.
4. Add a new function `cancelTransfer()` that allows the sender to cancel the transfer of the token. The function MUST emit the `CancelTransfer` event when the transfer is cancelled.

Notice that with this proposal, the `safeTransferFrom()`, `transferFrom()` and `mint()` functions are not modified, so the ERC-721 standard is not broken. These functions are only modified to emit a `TransferRequest` event.

This interface also includes a new function `transferableOwnerOf()` that returns the address of the token to which it is currently offered.

## Rationale
1. We only support [EIP-721](./eip-721.md) NFTs for simplicity and gas efficiency. We have not considered other EIPs, which can be left for future extensions. For example, [EIP-20](./eip-20.md) and [EIP-1155](./eip-1155.md) were not considered.
2. To implement this proposal, we propose the use of a new mapping, `_transferableOwners`, that will store the owner to whom we want to transfer the token. With this, when we transfer the token, instead of directly transfer the ownership, we add the address of the receiver, for that `tokenId`, to the `_transferableOwners` mapping.
```solidity
mapping(uint256 => address) private _transferableOwners;
```
3. We also need to take into consideration the `mint()` function, where the token is created and doesn't have yet an owner. In fact, minting a new token represents also a transfer of ownership, from the zero address, to the receiver.
4. With this proposal, the procedure to transfer a token is completed using the newly defined functions that change the values of the `_transferableOwners` mapping states as follows:
  * If the token is newly minted, the intended receiver of this token (**B**) is introduced in `_transferableOwners` mapping and the `TransferRequest` event is emitted.
  * If the token is already owned by someone (**A**), the intended receiver of this token (**B**) is introduced in `_transferableOwners` mapping and the `TransferRequest` event is emitted.
  * Now **B** can accept the transfer by executing `acceptTransfer()` function, which will emit the `Transfer` event and transfer the ownership of the token to **B**. **B** is removed from `_transferableOwners` mapping.
  * Alternativelly **B** can reject the NFT with `rejectTransfer()` function, which will emit the `RejectTransfer` event and remove **B** from `_transferableOwners` mapping.
  * In addition to that, if **B** has not yet accepted the transfer, **A** can cancel the transfer with `cancelTransfer()` function, which will emit the `CancelTransfer` event and remove **B** from `_transferableOwners` mapping.
5. The `transferableOwnerOf()` function returns the address of the token to which it is currently offered. If the token is not offered, the zero address is returned.

## Backwards Compatibility
The EIP is designed as an extension of EIP-721 and therefore compliant contracts need to fully comply with EIP-721.

## Test Cases
This Security and e-Commerce (SECOM) research group from Univerity of the Balearic Islands repository (https://github.com/secomuib/rejectable-nft) includes test cases written using Hardhat.

## Reference Implementation
In this Security and e-Commerce (SECOM) research group from Univerity of the Balearic Islands repository (https://github.com/secomuib/rejectable-nft) we can find a reference implementation:
- MIT licensed, so you can freely use it for your projects
- Includes test cases

## Security Considerations
There are no security considerations related directly to the implementation of this standard.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
