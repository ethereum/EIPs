// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ERC7007.sol";
import "./IERC7007Enumerable.sol";

/**
 * @dev Implementation of the {IERC7007Enumerable} interface.
 */
abstract contract ERC7007Enumerable is ERC7007, IERC7007Enumerable {
    /**
     * @dev See {IERC7007Enumerable-tokenId}.
     */
    mapping(uint256 => string) public prompt;


    /**
     * @dev See {IERC7007Enumerable-prompt}.
     */
    mapping(bytes => uint256) public tokenId;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC7007) returns (bool) {
        return
            interfaceId == type(IERC7007Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC7007-mint}.
     */
    function mint(
        bytes calldata prompt_,
        bytes calldata aigcData,
        string calldata uri,
        bytes calldata proof
    ) public virtual override(ERC7007, IERC7007) returns (uint256 tokenId_) {
        tokenId_ = ERC7007.mint(prompt_, aigcData, uri, proof);
        prompt[tokenId_] = string(prompt_);
        tokenId[prompt_] = tokenId_;
    }
}

contract MockERC7007Enumerable is ERC7007Enumerable {
    constructor(
        string memory name_,
        string memory symbol_,
        address verifier_
    ) ERC7007(name_, symbol_, verifier_) {}
} 