// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract IPBMRC1_TokenManager {
    /// @dev Mapping of each ERC-1155 tokenId to its corresponding PBM Token details.
    mapping (uint256 => PBMToken) internal tokenTypes ; 

    /// @notice A PBM token MUST include compulsory state variables (name, faceValue, expiry, and uri) to adhere to this standard.
    /// @dev Represents all the details corresponding to a PBM tokenId.
    struct PBMToken {
        // Name of the token.
        string name;

        // Value of the underlying wrapped ERC20-compatible Spot Token. Additional information on the `faceValue` can be specified by
        // adding the optional variables: `currencySymbol` or `tokenSymbol` as indicated below
        uint256 faceValue;

        // Time after which the token will be rendered useless (expressed in Unix Epoch time).
        uint256 expiry;

        // Metadata URI for ERC-1155 display purposes.
        string uri;

        // OPTIONAL: Indicates if the PBM token can be transferred to a non merchant/redeemer wallet.
        bool isTransferable;

        // OPTIONAL: Determines whether the PBM will be burned or revoked upon expiry, under certain predefined conditions, or at the owner's discretion. 
        bool burnable;

        // OPTIONAL: Number of decimal places for the token.    
        uint8 decimals; 

        // OPTIONAL: The address of the creator of this PBM type on this smart contract. This field is optional because the creator is msg.sender by default.
        address creator;

        // OPTIONAL: The smart contract address of the spot token.
        address tokenAddress;

        // OPTIONAL: The running balance of the PBM Token type that has been minted.
        uint256 totalSupply;

        // OPTIONAL: An ISO4217 three-character alphabetic code may be needed for the faceValue in multicurrency PBM use cases.
        string currencySymbol;

        // OPTIONAL: An abbreviation for the PBM token name may be assigned.
        string tokenSymbol;

        // Add other optional state variables below...
    }

    /// @notice Creates a new PBM Token type with the provided data.
    /// @dev The caller of createPBMTokenType shall be responsible for setting the creator address. 
    /// Example of uri can be found in [`sample-uri`](../assets/eip-pbmrc1/sample-uri/stx-10-static)
    /// Must emit {NewPBMTypeCreated}
    /// @param _name Name of the token.
    /// @param _faceValue Value of the underlying wrapped ERC20-compatible Spot Token.
    /// @param _tokenExpiry Time after which the token will be rendered useless (expressed in Unix Epoch time).
    /// @param _tokenURI Metadata URI for ERC-1155 display purposes
    function createPBMTokenType(
        string memory _name,
        uint256 _faceValue,
        uint256 _tokenExpiry,
        string memory _tokenURI
    ) external returns (uint256 tokenId_);

    /// @notice Retrieves the details of a PBM Token type given its tokenId.
    /// @dev This function fetches the PBMToken struct associated with the tokenId and returns it.
    /// @param tokenId The identifier of the PBM token type.
    /// @return pbmToken_ A PBMToken struct containing all the details of the specified PBM token type.
    function getTokenDetails(uint256 tokenId) external view returns(PBMToken memory pbmToken_);

    /// @notice Emitted when a new Purpose-Bound Token (PBM) type is created within the contract.
    /// @param tokenId The unique identifier for the newly created PBM token type.
    /// @param tokenName A human-readable string representing the name of the newly created PBM token type.
    /// @param amount The initial supply of the newly created PBM token type.
    /// @param expiry The timestamp at which the newly created PBM token type will expire.
    /// @param creator The address of the account that created the new PBM token type.
    event NewPBMTypeCreated(uint256 tokenId, string tokenName, uint256 amount, uint256 expiry, address creator);
}