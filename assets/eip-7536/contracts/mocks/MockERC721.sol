// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import 'hardhat/console.sol';

contract MockERC721 is ERC721Enumerable {
    using Strings for uint256;

    string private constant OWNER_ERR = 'Invalid owner';

    mapping(address=>uint256) private _tokenCounter;

    mapping(uint256 => string) private _tokenUri;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), OWNER_ERR);
        _;
    }
    
    function create(
        address to,
        string memory contentUri
    ) external returns (uint256) {
        return _create(to, contentUri);
    }
    
    function _create(
        address to,
        string memory contentUri
    ) internal virtual returns (uint256) {
        uint256 tokenId = _mintToken(to);
        _tokenUri[tokenId] = contentUri;
        return tokenId;
    }
    
    function update(
        uint256 tokenId, 
        string memory contentUri
    ) external onlyOwner(tokenId) {
        _tokenUri[tokenId] = contentUri;
    }

    function burn(uint256 tokenId) external onlyOwner(tokenId) {
        _burn(tokenId);
    }

    function _mintToken(address to) internal returns (uint256) {
        uint256 tokenId = _tokenCounter[to]++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return _tokenUri[tokenId];
    }
    
    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenCounter(address creator) external view returns (uint256) {
        return _tokenCounter[creator];
    }

}
