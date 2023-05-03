// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

interface IERC6381 {
    event Emoted(
        address indexed emoter,
        address indexed collection,
        uint256 indexed tokenId,
        bytes4 emoji,
        bool on
    );

    function emoteCountOf(
        address collection,
        uint256 tokenId,
        bytes4 emoji
    ) external view returns (uint256);

    function hasEmoterUsedEmote(
        address emoter,
        address collection,
        uint256 tokenId,
        bytes4 emoji
    ) external view returns (bool);

    function emote(
        address collection,
        uint256 tokenId,
        bytes4 emoji,
        bool state
    ) external;
}