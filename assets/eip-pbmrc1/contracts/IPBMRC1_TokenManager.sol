// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


interface IPBMRC1_TokenManager {
 

     /**
    * @notice Creates a new PBM token type, with its own token characteristics.
    * @param companyName Name of the company issuing the PBM
    * @param spotAmount Amount of the underlying ERC-20 tokens the PBM type wraps around
    * @param tokenExpiry The expiry date (in epoch) for this particular PBM token type 
    * @param tokenURI the URI (returns json) of PBM type that will follows the Opensea NFT metadata standard
    *
    * example response of token URI, ref : https://docs.opensea.io/docs/metadata-standards
    * {
    *     "name": "StraitsX-12",
    *     "description": "12$ SGD test voucher",
    *     "image": "https://gateway.pinata.cloud/ipfs/QmQ1x7NHakFYin9bHwN7zy4NdSYS84w6C33hzxpZwCAFPu",
    *     "attributes": [
    *         {
    *         "trait_type": "Value", 
    *         "value": "12"
    *         }
    *     ]
    * }
    **/
    function createNewPBMType(string memory companyName, uint256 spotAmount, uint256 tokenExpiry, address creator, string memory tokenURI) external;  


    /// @notice Get the details of the PBM Token type
    /// @param tokenId The identifier of the PBM token type
    /// @return name The name assigned to the token type 
    /// @return amount Amount of the underlying ERC-20 tokens the PBM type wraps around
    /// @return expiry The expiry date (in epoch) for this particular PBM token type. 
    /// @return creator The creator of the PBM token type
    function getTokenDetails(uint256 tokenId) external view returns(string memory, uint256, uint256, address); 

}