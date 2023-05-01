// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERC6956.sol";

interface IERC6956Floatable is IERC6956 {
    function canStartFloating(ERC6956Authorization op) external;
    function canStopFloating(ERC6956Authorization op) external;

    function allowFloating(bytes32 anchor, bool _doFloat) external;
    function isFloating(bytes32 anchor) external view returns (bool);

    event AnchorFloatingStateChange(bytes32 indexed anchor, uint256 indexed tokenId, bool indexed isFloating);
    event CanStartFloating(ERC6956Authorization indexed authorization, address maintainer);
    event CanStopFloating(ERC6956Authorization indexed authorization, address maintainer);
}