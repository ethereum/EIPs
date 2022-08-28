// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC721Bound is IERC721 {
    function preimage() external view returns (address);

    function contractURI() external view returns (string memory);

    function exists(uint256 tokenId) external view returns (bool);

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setContractURI(string memory uri) external;

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function burn(uint256 tokenId) external;
}
