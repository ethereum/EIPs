// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC721Buyable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTContract is ERC721Buyable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    mapping(uint256 => Attr) public attributes;

    struct Attr {
        string name;
        uint256 level;
    }

    constructor() ERC721("ETH Stones", "ETHS") {}

    function mint() external returns (uint256) {
        require(supply.current() < 3, "Max supply exceeded");
        supply.increment();

        attributes[supply.current()] = Attr(
            string(
                abi.encodePacked("ETH Stone #", supply.current().toString())
            ),
            supply.current()
        );

        _safeMint(msg.sender, supply.current());

        return supply.current();
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function burn(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        _burn(_tokenId);
    }

    function getSvg(uint256 _tokenId) private pure returns (string memory) {
        string memory base = "data:image/svg+xml;base64,";
        if (_tokenId == 1) {
            string memory svgBase64Encoded = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg width="80" height="134" viewBox="0 0 80 134" fill="none" xmlns="http://www.w3.org/2000/svg"><g fill-rule="evenodd" clip-rule="evenodd"><path d="m39.932 100.966 40.024-25.122-40.024 57.823v-32.701Zm5.952 3.269v10.449L58.7 96.174l-12.816 8.061Z" fill="#5A9DED"/><path d="M44.028 48.775 73.575 65.49l-2.915 5.152-29.546-16.717 2.914-5.151Z" fill="#D895D3"/><path d="M39.932.333 79.821 68.99 39.932 94.147V.333Zm5.882 21.972v61.174l26.052-16.43-26.052-44.744Z" fill="#FF9C92"/><path d="M40.068 100.966.044 75.844l40.024 57.823v-32.701Zm-5.952 3.269v10.449L21.3 96.174l12.816 8.061Z" fill="#53D3E0"/><path d="M34.727 49.333 5.181 66.049 8.095 71.2l29.547-16.716-2.915-5.151Z" fill="#A6E275"/><path d="M39.932.333.044 68.99l39.888 25.158V.333ZM34.05 22.305v61.174L7.999 67.05 34.05 22.305Z" fill="#FFE94D"/></g></svg>'
                        )
                    )
                )
            );
            return string(abi.encodePacked(base, svgBase64Encoded));
        } else if (_tokenId == 2) {
            string memory svgBase64Encoded = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg width="82" height="134" viewBox="0 0 82 134" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m40.094 91.534.894.893 40.924-24.19L40.988.333l-.894 3.039v88.162Z" fill="#343434"/><path d="M40.988 92.427V.333L.064 68.237l40.924 24.19Z" fill="#8C8C8C"/><path d="m40.484 132.195.504 1.471 40.948-57.668-40.948 24.178-.504.614v31.405Z" fill="#3C3C3B"/><path d="m.064 75.997 40.924 57.669v-33.491L.064 75.997Z" fill="#8C8C8C"/><path d="M40.988 49.636v42.79l40.923-24.19-40.923-18.6Z" fill="#141414"/><path d="M40.987 49.636.064 68.236l40.923 24.19v-42.79Z" fill="#393939"/></svg>'
                        )
                    )
                )
            );
            return string(abi.encodePacked(base, svgBase64Encoded));
        } else if (_tokenId == 3) {
            string memory svgBase64Encoded = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg width="82" height="134" viewBox="0 0 82 134" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M40.985 49.638V.333L.065 68.236l40.92-18.598Z" fill="#8A92B2"/><path d="M40.985 92.43V49.637L.065 68.236l40.92 24.193Zm0-42.792L81.91 68.236 40.985.333v49.305Z" fill="#62688F"/><path d="M40.985 49.638v42.791L81.91 68.236 40.985 49.638Z" fill="#454A75"/><path d="M40.985 100.178.065 76l40.92 57.667v-33.489Z" fill="#8A92B2"/><path d="m81.934 76-40.95 24.178v33.489L81.935 76Z" fill="#62688F"/></svg>'
                        )
                    )
                )
            );
            return string(abi.encodePacked(base, svgBase64Encoded));
        }
        return "";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        attributes[_tokenId].name,
                        '",',
                        '"description": "ETH Stones for demonstration purpose",',
                        '"image_data": "',
                        getSvg(_tokenId),
                        '",',
                        '"attributes": [{"trait_type": "Level", "value": ',
                        (attributes[_tokenId].level).toString(),
                        "}",
                        "]}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
