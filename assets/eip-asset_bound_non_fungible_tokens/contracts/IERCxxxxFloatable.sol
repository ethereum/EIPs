// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERCxxxx.sol";

interface IERCxxxxFloatable is IERCxxxx {
    function canStartFloating(ERCxxxxAuthorization op) external;
    function canStopFloating(ERCxxxxAuthorization op) external;

    function allowFloating(bytes32 anchor, bool _doFloat) external;
    function isFloating(bytes32 anchor) external view returns (bool);

    event AnchorFloatingState(
        bytes32 indexed anchor,
        uint256 indexed tokenId,
        bool indexed isFloating
    );

    event CanStartFloating(
        ERCxxxxAuthorization indexed authorization,
        address maintainer
    );

   event CanStopFloating(
        ERCxxxxAuthorization indexed authorization,
        address maintainer
    );
}