// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

interface IEmotable {

    event Emoted(
        address indexed emoter,
        uint256 indexed tokenId,
        bytes4 emoji,
        bool on
    );

    function emoteCountOf(
        uint256 tokenId,
        bytes4 emoji
    ) external view returns (uint256);

    function emote(uint256 tokenId, bytes4 emoji, bool state) external;
}