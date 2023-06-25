// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

interface IERC6066 {
    /**
     * @dev MUST return if the signature provided is valid for the provided tokenId and hash
     * @param tokenId   Token ID of the signing NFT
     * @param hash      Hash of the data to be signed
     * @param data      OPTIONAL arbitrary data that may aid verification
     *
     * MUST return the bytes4 magic value 0x12edb34f when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     */
    function isValidSignature(
        uint256 tokenId,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4 magicValue);
}