// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC_5521 {

    /// Logged when a node in the rNFT gets referred and changed
    /// @notice Emitted when the `node` (i.e., an rNFT) is changed
    event UpdateNode(uint256 indexed tokenId, 
                     address indexed owner, 
                     address[] _address_referringList,
                     uint256[][] _tokenIds_referringList,
                     address[] _address_referredList,
                     uint256[][] _tokenIds_referredList
    );

    /// @notice set the referred list of an rNFT associated with different contract addresses and update the referring list of each one in the referred list
    /// @param tokenIds array of rNFTs, recommended to check duplication at the caller's end
    function setNode(uint256 tokenId, address[] memory addresses, uint256[][] memory tokenIds) external;

    /// @notice Get the referring list of an rNFT
    /// @param tokenId The considered rNFT, _address The corresponding contract address
    /// @return The referring mapping of an rNFT
    function referringOf(address _address, uint256 tokenId) external view returns(address[] memory, uint256[][] memory);

    /// @notice Get the referred list of an rNFT
    /// @param tokenId The considered rNFT, _address The corresponding contract address
    /// @return The referred mapping of an rNFT
    function referredOf(address _address, uint256 tokenId) external view returns(address[] memory, uint256[][] memory);
}

interface TargetContract {
    function setNodeReferredExternal(address successor, uint256 tokenId, uint256[] memory _tokenIds) external;
    function referringOf(address _address, uint256 tokenId) external view returns(address[] memory, uint256[][] memory);
    function referredOf(address _address, uint256 tokenId) external view returns(address[] memory, uint256[][] memory);
}
