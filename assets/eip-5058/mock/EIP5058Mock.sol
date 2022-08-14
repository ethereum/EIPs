// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "../ERC5058.sol";

contract EIP5058Mock is ERC721Enumerable, ERC5058 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function lockMint(
        address to,
        uint256 tokenId,
        uint256 expired
    ) external {
        _safeLockMint(to, tokenId, expired, "");
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");

        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC5058) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC5058) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC5058)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
