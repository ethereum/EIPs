// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC6785.sol";

contract ERC6785 is ERC721, Ownable, IERC6785 {

    /*
     *     bytes4(keccak256('setUtilityUri(uint256,string)')) = 0x4a048176
     *     bytes4(keccak256('getUtility(uint256)')) = 0x0007c019
     *     bytes4(keccak256('getUtilityHistory(uint256)')) = 0xf6c3cabf
     *
     *     => 0x4a048176 ^ 0x0007c019 ^ 0xf6c3cabf == 0xbcc08bd0
     */
    bytes4 private constant _INTERFACE_ID_ERC6785 = 0xbcc08bd0;

    mapping(uint => string[]) private utilities;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(IERC6785).interfaceId || super.supportsInterface(interfaceId);
    }

    function setUtilityUri(uint256 tokenId, string calldata utilityUri) override external onlyOwner {
        utilities[tokenId].push(utilityUri);
        emit UpdateUtility(tokenId, utilityUri);
    }

    function getUtilityUri(uint256 tokenId) override external view returns (string memory) {
        uint last = utilities[tokenId].length - 1;
        return utilities[tokenId][last];
    }

    function getUtilityHistory(uint256 tokenId) override external view returns (string[] memory){
        return utilities[tokenId];
    }
}
