// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./interfaces/IERC6066.sol";

import "hardhat/console.sol";

contract ERC6066 is ERC721, IERC6066{

    // type(IERC6066).interfaceId
    bytes4 public constant MAGICVALUE = 0x12edb34f;
    bytes4 public constant BADVALUE = 0xffffffff;

    mapping(uint256 => mapping(bytes32 => bool)) internal _signatures;

    error ENotTokenOwner();

    /**
     * @dev Checks if the sender owns NFT with ID tokenId
     * @param tokenId   Token ID of the signing NFT
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) revert ENotTokenOwner();
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * @dev SHOULD sign the provided hash with NFT of tokenId given sender owns said NFT
     * @param tokenId   Token ID of the signing NFT
     * @param hash      Hash of the data to be signed
     */
    function sign(uint256 tokenId, bytes32 hash)
        public
        onlyTokenOwner(tokenId)
    {
        _signatures[tokenId][hash] = true;
    }

    /**
     * @dev MUST return if the signature provided is valid for the provided tokenId, hash, and optionally data
     */
    function isValidSignature(uint256 tokenId, bytes32 hash, bytes calldata data)
        public
        view
        override
        returns (bytes4 magicValue)
    {
    
        bool isVerified = false;
        isVerified = SignatureChecker.isValidSignatureNow(msg.sender,hash,data);
        if(!isVerified){
            return BADVALUE;
        }

        return _signatures[tokenId][hash] ? MAGICVALUE : BADVALUE;
    }

    /**
     * @dev ERC-165 support
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC6066).interfaceId ||
            super.supportsInterface(interfaceId);
    }


}