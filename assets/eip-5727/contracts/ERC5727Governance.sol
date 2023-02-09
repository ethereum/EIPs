// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC5727.sol";
import "./interfaces/IERC5727Governance.sol";
import "./ERC5727Enumerable.sol";

abstract contract ERC5727Governance is ERC5727Enumerable, IERC5727Governance {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private _approvalRequestCount;

    struct ApprovalRequest {
        address creator;
        uint256 value;
        uint256 slot;
    }

    mapping(uint256 => ApprovalRequest) private _approvalRequests;

    EnumerableSet.AddressSet private _votersArray;

    mapping(address => mapping(uint256 => mapping(address => bool)))
        private _mintApprovals;

    mapping(uint256 => mapping(address => uint256)) private _mintApprovalCounts;

    mapping(address => mapping(uint256 => bool)) private _revokeApprovals;

    mapping(uint256 => uint256) private _revokeApprovalCounts;

    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory voters_
    ) ERC5727(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint256 i = 0; i < voters_.length; i++) {
            _votersArray.add(voters_[i]);
            _setupRole(VOTER_ROLE, voters_[i]);
        }
    }

    function voters() public view virtual override returns (address[] memory) {
        return _votersArray.values();
    }

    function approveMint(address owner, uint256 approvalRequestId)
        public
        virtual
        override
        onlyRole(VOTER_ROLE)
    {
        require(
            !_mintApprovals[_msgSender()][approvalRequestId][owner],
            "ERC5727Governance: You already approved this address"
        );
        _mintApprovals[_msgSender()][approvalRequestId][owner] = true;
        _mintApprovalCounts[approvalRequestId][owner] += 1;
        if (
            _mintApprovalCounts[approvalRequestId][owner] ==
            _votersArray.length()
        ) {
            _resetMintApprovals(approvalRequestId, owner);
            _mint(
                _approvalRequests[approvalRequestId].creator,
                owner,
                _approvalRequests[approvalRequestId].value,
                _approvalRequests[approvalRequestId].slot
            );
        }
    }

    function approveRevoke(uint256 tokenId)
        public
        virtual
        override
        onlyRole(VOTER_ROLE)
    {
        require(
            !_revokeApprovals[_msgSender()][tokenId],
            "ERC5727Governance: You already approved this address"
        );
        _revokeApprovals[_msgSender()][tokenId] = true;
        _revokeApprovalCounts[tokenId] += 1;
        if (_revokeApprovalCounts[tokenId] == _votersArray.length()) {
            _resetRevokeApprovals(tokenId);
            _revoke(tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC5727Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC5727Governance).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _resetMintApprovals(uint256 approvalRequestId, address owner)
        private
    {
        for (uint256 i = 0; i < _votersArray.length(); i++) {
            _mintApprovals[_votersArray.at(i)][approvalRequestId][owner] = false;
        }
        _mintApprovalCounts[approvalRequestId][owner] = 0;
    }

    function _resetRevokeApprovals(uint256 tokenId) private {
        for (uint256 i = 0; i < _votersArray.length(); i++) {
            _revokeApprovals[_votersArray.at(i)][tokenId] = false;
        }
        _revokeApprovalCounts[tokenId] = 0;
    }

    function createApprovalRequest(uint256 value, uint256 slot)
        external
        virtual
        override
    {
        require(
            value != 0,
            "ERC5727Governance: Value of Approval Request cannot be 0"
        );
        _approvalRequests[_approvalRequestCount] = ApprovalRequest(
            _msgSender(),
            value,
            slot
        );
        _approvalRequestCount++;
    }

    function removeApprovalRequest(uint256 approvalRequestId)
        external
        virtual
        override
    {
        require(
            _msgSender() == _approvalRequests[approvalRequestId].creator,
            "ERC5727Governance: You are not the creator"
        );
        delete _approvalRequests[approvalRequestId];
    }

    function addVoter(address newVoter) public onlyOwner {
        require(
            !hasRole(VOTER_ROLE, newVoter),
            "ERC5727Governance: newVoter is already a voter"
        );
        _votersArray.add(newVoter);
        _setupRole(VOTER_ROLE, newVoter);
    }

    function removeVoter(address voter) public onlyOwner {
        require(
            _votersArray.contains(voter),
            "ERC5727Governance: Voter does not exist"
        );
        _revokeRole(VOTER_ROLE, voter);
        _votersArray.remove(voter);
    }
}
