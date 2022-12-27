// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "../EquippableToken.sol";

//Minimal public implementation of INestable for testing.
contract EquippableTokenMock is EquippableToken {
    address private _issuer;

    constructor() EquippableToken() {
        _setIssuer(_msgSender());
    }

    modifier onlyIssuer() {
        require(_msgSender() == _issuer, "RMRK: Only issuer");
        _;
    }

    function setIssuer(address issuer) external onlyIssuer {
        _setIssuer(issuer);
    }

    function _setIssuer(address issuer) private {
        _issuer = issuer;
    }

    function getIssuer() external view returns (address) {
        return _issuer;
    }

    function mint(address to, uint256 tokenId) external onlyIssuer {
        _mint(to, tokenId);
    }

    function nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) external {
        _nestMint(to, tokenId, destinationId, "");
    }

    // Utility transfers:

    function transfer(address to, uint256 tokenId) public virtual {
        transferFrom(_msgSender(), to, tokenId);
    }

    function nestTransfer(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual {
        nestTransferFrom(_msgSender(), to, tokenId, destinationId, "");
    }

    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) external onlyIssuer {
        _addAssetToToken(tokenId, assetId, replacesAssetWithId);
    }

    function addAssetEntry(
        uint64 id,
        string memory metadataURI
    ) external onlyIssuer {
        _addAssetEntry(id, metadataURI);
    }

    function addEquippableAssetEntry(
        uint64 id,
        uint64 equippableGroupId,
        address catalogAddress,
        string memory metadataURI,
        uint64[] calldata partIds
    ) external onlyIssuer {
        _addAssetEntry(
            id,
            equippableGroupId,
            catalogAddress,
            metadataURI,
            partIds
        );
    }

    function setValidParentForEquippableGroup(
        uint64 equippableGroupId,
        address parentAddress,
        uint64 partId
    ) external {
        _setValidParentForEquippableGroup(
            equippableGroupId,
            parentAddress,
            partId
        );
    }
}
