// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Required interface of an ERCX compliant contract.
 */
interface IERCX is IERC721{

    /**
     * @dev Emitted when `tokenId` tokenUser is transferred from `from` to `to`.
     */    
    event TransferUser(address from,address to,uint256 tokenId);
    
    /**
     * @dev Emitted when `user` enables `approved` to manage the `tokenId` tokenUser.
     */ 
    event ApprovalUser(address indexed user, address indexed approved, uint256 indexed tokenId);
    
    /**
     * @dev Returns the number of usable token in ``user``'s account.
     */    
    function balanceOfUser(address user) external view returns (uint256 balance);
    
    /**
     * @dev Returns the user of tokenId token
     * Requirements:
     *
     * - `tokenId` must exist.
     */    
    function userOf(uint256 tokenId) external view returns (address user);
    
    /**
     * @dev Safely transfers `tokenId` tokenUser from `from` to `to`
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be used or owned by 'from' 
     * - If the caller is not `from`, it must be approved to move this tokenUser by {approve} or {setApprovalForAll} or {approveUser}.
     *
     * Emits a {TransferUser} event.
     */    
    function safeTransferUserFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    /**
     * @dev Safely transfers `tokenId` tokenUser from `from` to `to`
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be used or owned by 'from' 
     * - If the caller is not `from`, it must be approved to move this tokenUser by {approve} or {setApprovalForAll} or {approveUser}.
     *
     * Emits a {TransferUser} event.
     */  
    function safeTransferUserFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    
    /**
     * @dev Safely transfers `tokenId` token and tokenUser from `from` to `to`
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by 'from' 
     * - If the caller is not `from`, it must be approved to move this tokenUser by {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} and a {TransferUser} event.
     */
    function safeTransferAllFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    /**
     * @dev Safely transfers `tokenId` token and tokenUser from `from` to `to`
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by 'from' 
     * - If the caller is not `from`, it must be approved to move this tokenUser by {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} and a {TransferUser} event.
     */
    function safeTransferAllFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    
    /**
     * @dev Gives permission to `to` to transfer `tokenId` tokenUser to another account.
     * The approval is cleared when the tokenUser is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must be tokenUser or be an approvedUser operator.
     * - `tokenId` must exist.
     *
     * Emits an {ApprovalUser} event.
     */
    function approveUser(address to, uint256 tokenId) external;
    
    /**
     * @dev Returns the approvedUser for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedUser(uint256 tokenId) external view returns (address operator);
    
    
}
