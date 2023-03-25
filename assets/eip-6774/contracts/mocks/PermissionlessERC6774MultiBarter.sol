// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import {ERC6774MultiBarter} from "../extensions/ERC6774MultiBarter.sol";

contract PermissionlessERC6774MultiBarter is ERC6774MultiBarter {
    string internal ipfsHash;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ipfsHash
    ) ERC6774MultiBarter(_name, _symbol) {
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
