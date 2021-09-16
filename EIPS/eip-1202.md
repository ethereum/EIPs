// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/// @title Core interface of ERC1202: A list of *REQUIRED* methods and events for 
///        a contract to be considered conforming to ERC1202. 
/// 
/// @author Zainan Victor Zhou <zzn@zzn.im>
/// 
/// @dev Each ERC1202 contract is a cluster of issues being voted on, or done voted.
///      Any contract of ERC1202 **MUST** implement ALL the following methods and events.
/// 
///      Each *issue* is identified with an `issueId`,
///      For any given `issue`, each availalbe option in that issue is
///      identified wtih an `optionId`.
interface ERC1202Core {
    
    /// @dev Cast a vote for an issue with `issueId` for option with `optionId`
    /// @param _issueId: the issue this vote is casting on.
    /// @param _optionIds: an *ordered* array of the options being casted for the issue.
    ///   Whenever referring to the options as a whole, the order MUST be maintained.
    /// @return a boolean if TRUE means the vote is casted successfully. 
    function vote(uint _issueId, uint[] memory _optionIds) external returns (bool);

    /// @dev Query the top ranked options of an issue given issueId and 
    ///      a limit of max number of top options.
    /// @param _issueId: the issue being queried for the top options.
    /// @param _limit: the max number of top options the caller expect to return.
    /// @return an ordered list of the top options for given issueId and limit, 
    ///         where the first in array is the most favorite one, and the last in 
    ///         array is the least favorite one among the list.
    ///         Specifically, WHEN limit = 0, returns the default length of winning
    ///         options in their ranking in an issue. 
    function topOptions(
        uint _issueId, uint _limit
        ) external view returns (uint[] memory);
    
    /// @dev This event is emitted when a vote has been casted.
    /// @param issueId the issue the vote is being cased on.
    /// @param optionIds an ordered list of the options the vote is casting for.
    event OnVote(uint indexed issueId, uint[] optionIds, address indexed voterAddr);

}

/// @title Metadata interface for ERC1202: A list of *RECOMMENDED* methods and events for 
///        a contract to be considered conforming to ERC1202. 
///
/// @author Zainan Victor Zhou <zzn@zzn.im>
interface ERC1202Metadata {

    /// @notice A descriptive text for an issue in this contract.
    function issueText() external view returns (string memory _text);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given issue.
    /// @dev Throws if `_issueId` is not a valid issue; 
    ///      URIs are defined in RFC 3986. 
    function issueURI(uint256 _issueId) external view returns (string memory _uri);

    /// @notice A descriptive text for an option in an issue in this contract.
    function optionText(uint _issueId, uint _optionId) external view returns (string memory _text);
    
    /// @notice A distinct Uniform Resource Identifier (URI) for a given option in a given issue.
    /// @dev Throws if `_issueId` is not a valid option-issue combination; 
    ///      URIs are defined in RFC 3986. 
    function optionURI(uint _issueId, uint _optionId) external view returns (string memory _uri);
}

/// @title Status interface for ERC1202: A list of *RECOMMENDED* methods and events for 
///        a contract to be considered conforming to ERC1202. 
///
/// @author Zainan Victor Zhou <zzn@zzn.im>
interface ERC1202Status {
    
    /// @dev This event is emitted when an issue has changed status.
    /// @param issueId the issue about which a status change has happend.
    /// @param isOpen the status
    event OnStatusChange(uint indexed issueId, bool indexed isOpen);
    
    /// @dev Sets the status of a issue, e.g. open for vote or closed for result.
    /// @param _issueId the issue of Status being set.
    /// @param _isOpen the status to set.
    /// @return _success whether the setStatus option succeeded.
    function setStatus(uint _issueId, bool _isOpen) external returns (bool _success);
    
    /// @dev Gets the status of a issue, e.g. open for vote or closed for result.
    /// @param _issueId the issue of Status being get.
    /// @return _isOpen the status of the issue.
    function getStatus(uint _issueId) external view returns (bool _isOpen);
    
    /// @dev Retrieves the ranked options voted by a given voter for a given issue.
    /// @param _issueId the issue
    /// @param _voter the aaddres of voter.
    /// @return _optionIds the ranked options voted by voter.
    function voteOf(uint _issueId, address _voter) external view returns (uint[] memory _optionIds);
}
