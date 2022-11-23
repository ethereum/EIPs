// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import {ERC5050, Action} from "./ERC5050.sol";

contract Spells is ERC5050, ERC721 {

    bytes4 constant CAST_SELECTOR = bytes4(keccak256("cast"));
    bytes4 constant ATTUNE_SELECTOR = bytes4(keccak256("attune"));

    mapping(uint256 => uint256) spellDust;
    mapping(uint256 => string) attunement;

    constructor() ERC721("Spells", unicode"🔮") {
        _registerSendable("cast");
        _registerReceivable("attune");
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        require(
            msg.sender == ownerOf(action.from._tokenId),
            "Spells: invalid sender"
        );
        _sendAction(action);
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        if (action.selector == ATTUNE_SELECTOR) {
            string memory unicodeChar;
            bytes memory _data = action.data;
            assembly {
                // Read unicode character from first 6 bytes (\u5050)
                unicodeChar := shr(208, _data)
            }
            attunement[action.to._tokenId] = unicodeChar;
        }
        // Pass action to state receiver if specified
        _onActionReceived(action, _nonce);
    }

    string[12] private dust = [
        unicode"․",
        unicode"∴",
        unicode"`"
    ];

    string[5] private spells = [
        "Conjuring",
        "Divining",
        "Transforming",
        "Hexing",
        "Banishing"
    ];

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string
            memory out = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 350"><style>.base { fill: lightyellow; font-family: serif; font-size: 14px; } .chant { font-style: italic;} .dust {font-family: monospace; font-size: 8px; letter-spacing:5px;}.sm{font-size: 10px;} .sigil{font-family: monospace, font-size:13}</style><rect width="100%" height="100%" fill="#171717" /><text x="14" y="24" class="base">';

        out = string.concat(
            out,
            string.concat(spells[_spellType(tokenId)], " Spell"),
            '</text><text x="376" y="336" class="base sigil">',
            attunement[tokenId]
        );
        out = string.concat(out, "</text></svg>");
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Spell #',
                        Strings.toString(tokenId),
                        '", "description": "Cast spells, attune spells.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(out)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _spellType(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = _random(Strings.toString(tokenId));
        return rand % 6;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}