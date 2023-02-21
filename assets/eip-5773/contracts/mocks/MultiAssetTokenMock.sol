// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.15;

import "../MultiAssetToken.sol";

contract MultiAssetTokenMock is MultiAssetToken {
    address private _issuer;

    constructor(
        string memory name,
        string memory symbol
    ) MultiAssetToken(name, symbol) {
        _setIssuer(_msgSender());
    }

    modifier onlyIssuer() {
        require(_msgSender() == _issuer, "RMRK: Only issuer");
        _;
    }

    function setIssuer(address issuer) external onlyIssuer {
        _setIssuer(issuer);
    }

    function getIssuer() external view returns (address) {
        return _issuer;
    }

    function mint(address to, uint256 tokenId) external onlyIssuer {
        _mint(to, tokenId);
    }

    function transfer(address to, uint256 tokenId) external {
        _transfer(msg.sender, to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 overwrites
    ) external onlyIssuer {
        _addAssetToToken(tokenId, assetId, overwrites);
    }

    function addAssetEntry(
        uint64 id,
        string memory metadataURI
    ) external onlyIssuer {
        _addAssetEntry(id, metadataURI);
    }

    function _setIssuer(address issuer) private {
        _issuer = issuer;
    }
}
