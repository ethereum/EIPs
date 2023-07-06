// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC6785 {

    // Logged when the utility description URL of an NFT is changed
    /// @notice Emitted when the utilityURL of an NFT is changed
    /// The empty string for `utilityUri` indicates that there is no utility associated
    event UpdateUtility(uint256 indexed tokenId, string utilityUri);

    /// @notice set the new utilityUri - remember the date it was set on
    /// @dev The empty string indicates there is no utility
    /// Throws if `tokenId` is not valid NFT
    /// @param utilityUri  The new utility description of the NFT
    function setUtilityUri(uint256 tokenId, string calldata utilityUri) external;

    /// @notice Get the utilityUri of an NFT
    /// @dev The empty string for `utilityUri` indicates that there is no utility associated
    /// @param tokenId The NFT to get the user address for
    /// @return The utility uri for this NFT
    function utilityUriOf(uint256 tokenId) external view returns (string memory);

    /// @notice Get the changes made to utilityUri
    /// @param tokenId The NFT to get the user address for
    /// @return The history of changes to `utilityUri` for this NFT
    function utilityHistoryOf(uint256 tokenId) external view returns(string[] memory);
}
