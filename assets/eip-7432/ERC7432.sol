// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IERC7432 } from "./interfaces/IERC7432.sol";

contract ERC7432 is IERC7432 {
    // grantor => grantee => tokenAddress => tokenId => role => struct(expirationDate, data)
    mapping(address => mapping(address => mapping(address => mapping(uint256 => mapping(bytes32 => RoleData)))))
        public roleAssignments;

    // grantor => tokenAddress => tokenId => role => grantee
    mapping(address => mapping(address => mapping(uint256 => mapping(bytes32 => address)))) public latestGrantees;

    // grantor => operator => tokenAddress => isApproved
    mapping(address => mapping(address => mapping(address => bool))) public tokenApprovals;

    modifier validExpirationDate(uint64 _expirationDate) {
        require(_expirationDate > block.timestamp, "ERC7432: expiration date must be in the future");
        _;
    }

    modifier onlyAccountOrApproved(address _tokenAddress, address _account) {
        require(
            msg.sender == _account || isRoleApprovedForAll(_tokenAddress, _account, msg.sender),
            "ERC7432: sender must be approved"
        );
        _;
    }

    function grantRevocableRoleFrom(RoleAssignment calldata _roleAssignment) override onlyAccountOrApproved(_roleAssignment.tokenAddress, _roleAssignment.grantor) external {
        _grantRole(_roleAssignment, true);
    }

    function grantRoleFrom(RoleAssignment calldata _roleAssignment) external override onlyAccountOrApproved(_roleAssignment.tokenAddress, _roleAssignment.grantor) {
        _grantRole(_roleAssignment, false);
    }


    function _grantRole(
        RoleAssignment memory _roleAssignment,
        bool _revocable
    ) internal validExpirationDate(_roleAssignment.expirationDate) {
        roleAssignments[_roleAssignment.grantor][_roleAssignment.grantee][_roleAssignment.tokenAddress][
            _roleAssignment.tokenId
        ][_roleAssignment.role] = RoleData(_roleAssignment.expirationDate, _revocable, _roleAssignment.data);
        latestGrantees[_roleAssignment.grantor][_roleAssignment.tokenAddress][_roleAssignment.tokenId][
            _roleAssignment.role
        ] = _roleAssignment.grantee;
        emit RoleGranted(_roleAssignment.role, _roleAssignment.tokenAddress, _roleAssignment.tokenId, _roleAssignment.grantor, _roleAssignment.grantee, _roleAssignment.expirationDate, _revocable, _roleAssignment.data);
    }

    function revokeRoleFrom(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _revoker,
        address _grantee
    ) external override {
        address _caller = msg.sender == _revoker || msg.sender == _grantee ? msg.sender : _getApprovedCaller(_tokenAddress, _revoker, _grantee);
        _revokeRole(_role, _tokenAddress, _tokenId, _revoker, _grantee, _caller);
    }

    function _getApprovedCaller(address _tokenAddress, address _revoker, address _grantee) internal view returns (address) {
        if (isRoleApprovedForAll(_tokenAddress, _grantee, msg.sender)) {
            return _grantee;
        } else if (isRoleApprovedForAll(_tokenAddress, _revoker, msg.sender)) {
            return _revoker;
        } else {
            revert("ERC7432: sender must be approved");
        }
    }

    function _revokeRole(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _revoker,
        address _grantee,
        address _caller
    ) internal {
        bool _isRevocable = roleAssignments[_revoker][_grantee][_tokenAddress][_tokenId][_role].revocable;
        require(_isRevocable || _caller == _grantee, "ERC7432: Role is not revocable or caller is not the grantee");
        delete roleAssignments[_revoker][_grantee][_tokenAddress][_tokenId][_role];
        delete latestGrantees[_revoker][_tokenAddress][_tokenId][_role];
        emit RoleRevoked(_role, _tokenAddress, _tokenId, _revoker, _grantee);
    }

    function hasRole(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (bool) {
        return roleAssignments[_grantor][_grantee][_tokenAddress][_tokenId][_role].expirationDate > block.timestamp;
    }

    function hasUniqueRole(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (bool) {
        return latestGrantees[_grantor][_tokenAddress][_tokenId][_role] == _grantee && roleAssignments[_grantor][_grantee][_tokenAddress][_tokenId][_role].expirationDate > block.timestamp;
    }

    function roleData(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (RoleData memory) {
        return roleAssignments[_grantor][_grantee][_tokenAddress][_tokenId][_role];
    }


    function roleExpirationDate(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor,
        address _grantee
    ) external view returns (uint64 expirationDate_) {
        return roleAssignments[_grantor][_grantee][_tokenAddress][_tokenId][_role].expirationDate;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC7432).interfaceId;
    }

    function setRoleApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _isApproved
    ) external override {
        tokenApprovals[msg.sender][_tokenAddress][_operator] = _isApproved;
        emit RoleApprovalForAll(_tokenAddress, _operator, _isApproved);
    }

    function isRoleApprovedForAll(
        address _tokenAddress,
        address _grantor,
        address _operator
    ) public view override returns (bool) {
        return tokenApprovals[_grantor][_tokenAddress][_operator];
    }

    function lastGrantee(
        bytes32 _role,
        address _tokenAddress,
        uint256 _tokenId,
        address _grantor
    ) public view override returns (address) {
        return latestGrantees[_grantor][_tokenAddress][_tokenId][_role];
    }
}
