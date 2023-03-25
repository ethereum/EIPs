// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import {ERC_N} from "../ERC_N.sol";

contract PermissionlessERC_N is ERC_N {
    string internal ipfsHash;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ipfsHash
    ) ERC_N(_name, _symbol) {
        ipfsHash = _ipfsHash;
    }

    function mint(address account, uint256 tokenId) public {
        _mint(account, tokenId);
    }

    function enableBarterWith(address tokenAddr) public {
        _enableBarterWith(tokenAddr);
    }

    function stopBarterWith(address tokenAddr) public {
        _stopBarterWith(tokenAddr);
    }

    function domainSeparator() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return string.concat("ipfs://", ipfsHash);
    }
}
