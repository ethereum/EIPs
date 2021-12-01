// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERCX.sol";


interface IERCXEnumerable is IERCX {

    /**
     * @dev Returns a tokenId used by `user` at a given `index` of its token list.
     * Use along with {balanceOfUser} to enumerate all of ``user``'s tokens.
     */
    function tokenOfUserByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a tokenId at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
