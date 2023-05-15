// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


abstract contract IPBMRC1_TokenManager {
    /// @dev Mapping of each ERC-1155 tokenId to its corresponding PBM token details.
    mapping (uint256 => PBMToken) internal tokenTypes ; 

    /// @dev Structure representing all the details corresponding to a PBM tokenId.
    struct PBMToken {
        // Name of the token.
        string name;
        // Value of the token in the context of the underlying wrapped ERC20-compatible token.
        uint256 faceValue;
        // Token will be rendered useless after this time.
        uint256 expiry;
        // Address of the creator of this PBM type on this smart contract.
        address creator;
        // Remaining balance of the token.
        uint256 balanceSupply;
        // Metadata URI for ERC1155 display purposes.
        string uri;

        // Add other state variables...
    }

    /// @notice Creates a new PBM token type with the provided data.
    /// @dev Example response of token URI (reference: https://docs.opensea.io/docs/metadata-standards):
    /// {
    ///     "name": "StraitsX-12",
    ///     "description": "12$ SGD test voucher",
    ///     "image": "https://gateway.pinata.cloud/ipfs/QmQ1x7NHakFYin9bHwN7zy4NdSYS84w6C33hzxpZwCAFPu",
    ///     "attributes": [
    ///         {
    ///             "trait_type": "Value",
    ///             "value": "12"
    ///         }
    ///     ]
    /// }
    function createPBMTokenType(
        string memory name,
        uint256 faceValue,
        uint256 tokenExpiry,
        address creator,
        string memory tokenURI
    ) external;


    /// @notice Retrieves the details of a PBM token type given its tokenId.
    /// @dev This function fetches the PBMToken struct associated with the tokenId and returns it.
    /// @param tokenId The identifier of the PBM token type.
    /// @return A PBMToken struct containing all the details of the specified PBM token type.
    function getTokenDetails(uint256 tokenId) external view returns(PBMToken memory); 

}

