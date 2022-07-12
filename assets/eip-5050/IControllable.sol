// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IControllable {
    event ControllerApproval(
        address indexed _controller,
        bytes4 indexed _action
    );
    
    event ControllerApprovalForAll(
        address indexed _controller,
        bool _approved
    );
    
    function approveController(address _controller, bytes4 _action)
        external;

    function setControllerApprovalForAll(address _controller, bool _approved)
        external;

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool);
}