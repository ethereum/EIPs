// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "./IEmotable.sol";

abstract contract Emotable is IEmotable {
    // Used to avoid double emoting and control undoing
    mapping(address => mapping(uint256 => mapping(bytes4 => uint256)))
        private _emotesPerAddress; // Cheaper than using a bool
    mapping(uint256 => mapping(bytes4 => uint256)) private _emotesPerToken;

    function emoteCountOf(
        uint256 tokenId,
        bytes4 emoji
    ) public view returns (uint256) {
        return _emotesPerToken[tokenId][emoji];
    }

    /**
     * @notice Used to emote or undo an emote on a token.
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     */
    function _emote(
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) internal virtual {
        bool currentVal = _emotesPerAddress[msg.sender][tokenId][emoji] == 1;
        if (currentVal != state) {
            if (state) {
                _emotesPerToken[tokenId][emoji] += 1;
            } else {
                _emotesPerToken[tokenId][emoji] -= 1;
            }
            _emotesPerAddress[msg.sender][tokenId][emoji] = state ? 1 : 0;
            emit Emoted(msg.sender, tokenId, emoji, state);
        }
    }
}