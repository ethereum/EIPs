/// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC5289Library is IERC165 {
    /// @notice Emitted when signDocument is called
    event DocumentSigned(address indexed signer, uint48 indexed documentId);
    
    /// @notice The IPFS multihash of the legal document. This MUST use a common file format, such as PDF, HTML, TeX, or Markdown.
    function legalDocument(uint48 documentId) public pure returns (bytes memory);
    
    /// @notice Returns whether or not the given user signed the document, and if so, when they did.
    /// @dev If the user has not signed the document, the timestamp may be anything.
    function documentSigned(address user, uint48 documentId) public view returns (boolean signed, uint64 timestamp);

    /// @notice Provide a signature
    /// @dev This MUST be validated by the smart contract. This MUST emit DocumentSigned or throw.
    function signDocument(address signer, uint48 documentId, bytes memory signature) public;
}
