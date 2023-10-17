// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../Emotable.sol";

/**
 * @title ERC721EmotableMock
 * Used for tests
 */
contract ERC721EmotableMock is ERC721, Emotable {
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function emote(
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) public virtual {
        _emote(tokenId, emoji, state);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IEmotable).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
