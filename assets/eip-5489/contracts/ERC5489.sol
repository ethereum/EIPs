//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5489.sol";

contract ERC5489 is IERC5489, ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.AddressSet) tokenId2AuthroizedAddresses;
    mapping(uint256 => mapping(address=> string)) tokenId2Address2Value;
    mapping(uint256 => string) tokenId2ImageUri;

    string private _imageURI;
    string private _name;

    constructor() ERC721("Hyperlink NFT Collection", "HNFT") {}

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId), "should be the token owner");
        _;
    }

    modifier onlySlotManager(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId) || tokenId2AuthroizedAddresses[tokenId].contains(_msgSender()), "address should be authorized");
        _;
    }

    function setSlotUri(uint256 tokenId, string calldata value) override external onlySlotManager(tokenId) {
        tokenId2Address2Value[tokenId][_msgSender()] = value;

        emit SlotUriUpdated(tokenId, _msgSender(), value);
    }

    function getSlotUri(uint256 tokenId, address slotManagerAddr) override external view returns (string memory) {
        return tokenId2Address2Value[tokenId][slotManagerAddr];
    }

    function authorizeSlotTo(uint256 tokenId, address slotManagerAddr) override external onlyTokenOwner(tokenId) {
        require(!tokenId2AuthroizedAddresses[tokenId].contains(slotManagerAddr), "address already authorized");
        
        _authorizeSlotTo(tokenId, slotManagerAddr);
    }

    function _authorizeSlotTo(uint256 tokenId, address slotManagerAddr) private {
        tokenId2AuthroizedAddresses[tokenId].add(slotManagerAddr);
        emit SlotAuthorizationCreated(tokenId, slotManagerAddr);
    }

    function revokeAuthorization(uint256 tokenId, address slotManagerAddr) override external onlyTokenOwner(tokenId) {
        tokenId2AuthroizedAddresses[tokenId].remove(slotManagerAddr);
        delete tokenId2Address2Value[tokenId][slotManagerAddr];

        emit SlotAuthorizationRevoked(tokenId, slotManagerAddr);
    }

    function revokeAllAuthorizations(uint256 tokenId) override external onlyTokenOwner(tokenId) {
        for (uint256 i = tokenId2AuthroizedAddresses[tokenId].length() - 1;i > 0; i--) {
            address addr = tokenId2AuthroizedAddresses[tokenId].at(i);
            tokenId2AuthroizedAddresses[tokenId].remove(addr);
            delete tokenId2Address2Value[tokenId][addr];

            emit SlotAuthorizationRevoked(tokenId, addr);
        }

        if (tokenId2AuthroizedAddresses[tokenId].length() > 0) {
            address addr = tokenId2AuthroizedAddresses[tokenId].at(0);
            tokenId2AuthroizedAddresses[tokenId].remove(addr);
            delete tokenId2Address2Value[tokenId][addr];

            emit SlotAuthorizationRevoked(tokenId, addr);
        }
    }

    function isSlotManager(uint256 tokenId, address addr) public view returns (bool) {
        return tokenId2AuthroizedAddresses[tokenId].contains(addr);
    }

    // !!expensive, should call only when no gas is needed;
    function getSlotManagers(uint256 tokenId) external view returns (address[] memory) {
        return tokenId2AuthroizedAddresses[tokenId].values();
    }

    function _mintToken(uint256 tokenId, string calldata imageUri) private {
        _safeMint(msg.sender, tokenId);
        tokenId2ImageUri[tokenId] = imageUri;
    }

    function mint(string calldata imageUri) external {
        uint256 tokenId = totalSupply() + 1;
        _mintToken(tokenId, imageUri);
    }

    function mintAndAuthorizeTo(string calldata imageUri, address slotManagerAddr) external {
        uint256 tokenId = totalSupply() + 1;
        _mintToken(tokenId, imageUri);
        _authorizeSlotTo(tokenId, slotManagerAddr);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                abi.encodePacked(
                                    _name,
                                    " # ",
                                    Strings.toString(_tokenId)
                                ),
                                '",',
                                '"description":"Hyperlink NFT collection created with Parami Foundation"',
                                '}'
                            )
                        )
                    )
                )
            );
    }
}
