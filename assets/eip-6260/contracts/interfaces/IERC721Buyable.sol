// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Required interface of an ERC721Buyable compliant contract.
 * bytes4 private constant _INTERFACE_ID_ERC721Buyable = 0x8ce7e09d;
 */
interface IERC721Buyable is IERC721 {
    /**
     * @dev Emitted when `amount` of ether is transferred from `buyer` to `seller` when purchasing a token.
     */
    event Purchase(
        address indexed buyer,
        address indexed seller,
        uint256 indexed amount
    );

    /**
     * @dev Emitted when price of `tokenId` is set to `price`.
     */
    event UpdatePrice(uint256 indexed tokenId, uint256 indexed price);

    /**
     * @dev Emitted when `tokenId` is removed from the sale.
     */
    event RemoveFromSale(uint256 indexed tokenId);

    /**
     * @dev Emitted when royalty percentage is set to `royalty`.
     */
    event UpdateRoyalty(uint256 indexed royalty);

    /**
     * @notice Puts a token to sale and set its price.
     * @dev Requirements:
     *
     * - Owner of `_tokenId` must be the caller
     *
     * Emits an {UpdatePrice} event.
     *
     * @param _tokenId uint representing the token ID number.
     * @param _price uint representing the price at which to sell the token.
     */
    function setPrice(uint256 _tokenId, uint256 _price) external;

    /**
     * @notice Removes a token from the sale.
     * @dev Requirements:
     *
     * - Owner of `_tokenId` must be the caller
     *
     * Emits a {RemoveFromSale} event.
     *
     * @param _tokenId uint representing the token ID number.
     */
    function removeTokenSale(uint256 _tokenId) external;

    /**
     * @notice Buys a specific token from its ID onchain.
     * @dev Amount of ether msg.value sent is transferred to `seller` of the token.
     * A percentage of the royalty allocution is sent to `_owner` of the contract.
     * The token of ID `_tokenId` is then transferred from `seller` to `buyer` (the msg.sender).
     * The token is then automatically removed from the sale.
     *
     * Requirements:
     *
     * - `_tokenId` must be put to sale
     * - Amount of ether `msg.value` sent must be greater than the selling price
     *
     * Emits a {Purchase} event.
     *
     * @param _tokenId uint representing the token Id number.
     */
    function buyToken(uint256 _tokenId) external payable;

    /**
     * @notice Return the current royalty and its denominator.
     * @dev Return the current royalty and its denominator.
     * @return _royalty uint within the range of `_royaltyDenominator` associated with the token.
     * @return _denominator uint denominator set in `_royaltyDenominator()`.
     */
    function royaltyInfo() external view returns (uint256, uint256);

    /**
     * @notice Set the royalty percentage.
     * @dev Set or update the royalty percentage within the range of `_royaltyDenominator`.
     * Update the `_firstRoyaltyUpdate` boolean to true if previously false.
     *
     * Requirements:
     *
     * - caller must be `_owner` of the contract
     * - `_newRoyalty` must be between 0 and `_royaltyDenominator`
     * - `_newRoyalty` must be lower than current previous one
     *
     * Emits an {UpdateRoyalty} event.
     *
     * @param _newRoyalty uint within the range of `_royaltyDenominator` as new tokens royalties.
     */
    function setRoyalty(uint256 _newRoyalty) external;
}
