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

        // OPTIONAL: Indicates if the PBM token can be transferred to a non merchant wallet.
        bool isTransferable;

        // OPTIONAL: Determines whether the PBM will be burned or revoked upon expiry, under certain predefined conditions, or at the owner's discretion. 
        bool burnable;

        // OPTIONAL: Number of decimal places for the token.    
        uint8 decimals; 

        // OPTIONAL: The address of the creator of this PBM type on this smart contract.
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
}