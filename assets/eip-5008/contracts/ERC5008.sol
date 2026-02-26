// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5008.sol";

contract ERC5008 is ERC721, IERC5008 {
    mapping(uint256 => uint256) private _tokenNonce;

    constructor(string memory name_, string memory symbol_)ERC721(name_, symbol_){
    }

    /// @notice Get the nonce of an NFT
    /// Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to get the nonce for
    /// @return The nonce of this NFT
    function nonce(uint256 tokenId) public virtual override view returns(uint256) {
        require(_exists(tokenId), "Error: query for nonexistent token");

        return  _tokenNonce[tokenId];
     }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        super._beforeTokenTransfer(from, to, tokenId);
        _tokenNonce[tokenId]++;
        emit NonceChanged(tokenId, _tokenNonce[tokenId]);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5008).interfaceId || super.supportsInterface(interfaceId);
    }
}
