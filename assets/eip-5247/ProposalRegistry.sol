// SPDX-License-Identifier: MIT
// A fully runnalbe version can be found in https://github.com/ercref/ercref-contracts/tree/869843f23dc4da793f0d9d018ed92e3950da8f75
pragma solidity ^0.8.17;

import "./IERC5247.sol";
import "@openzeppelin/contracts/utils/Address.sol";

struct Proposal {
    address by;
    uint256 proposalId;
    address[] targets;
    uint256[] values;
    uint256[] gasLimits;
    bytes[] calldatas;
}

contract ProposalRegistry is IERC5247 {
    using Address for address;
    mapping(uint256 => Proposal) public proposals;
    uint256 private proposalCount;
    function createProposal(
        uint256 proposalId,
        address[] calldata targets,
        uint256[] calldata values,
        uint256[] calldata gasLimits,
        bytes[] calldata calldatas,
        bytes calldata extraParams
    ) external returns (uint256 registeredProposalId) {
        require(targets.length == values.length, "GeneralForwarder: targets and values length mismatch");
        require(targets.length == gasLimits.length, "GeneralForwarder: targets and gasLimits length mismatch");
        require(targets.length == calldatas.length, "GeneralForwarder: targets and calldatas length mismatch");
        registeredProposalId = proposalCount;
        proposalCount++;

        proposals[registeredProposalId] = Proposal({
            by: msg.sender,
            proposalId: proposalId,
            targets: targets,
            values: values,
            calldatas: calldatas,
            gasLimits: gasLimits
        });
        emit ProposalCreated(msg.sender, proposalId, targets, values, gasLimits, calldatas, extraParams);
        return registeredProposalId;
    }
    function executeProposal(uint256 proposalId, bytes calldata extraParams) external {
        Proposal storage proposal = proposals[proposalId];
        address[] memory targets = proposal.targets;
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
        emit ProposalExecuted(msg.sender, proposalId, extraParams);
    }

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

}
