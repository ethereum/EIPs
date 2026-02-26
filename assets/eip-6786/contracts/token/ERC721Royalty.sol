// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../utils/IERC2981.sol";

contract ERC721Royalty is ERC721, IERC2981 {

    address public constant DEFAULT_CREATOR_ADDRESS = 0x4fF5DDB196A32e3dC604abD5422805ecAD22c468;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = DEFAULT_CREATOR_ADDRESS;
        royaltyAmount = _salePrice / 10000;
    }
}
