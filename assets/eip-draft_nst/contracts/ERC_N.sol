// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import {ERC721, IERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IERC_N} from "./IERC_N.sol";

contract ERC_N is ERC721, EIP712, IERC_N {
    using ECDSA for bytes32;

    error BarterNotEnabled(address tokenAddr);
    error InvalidNonce(address owner, uint256 expectedNonce);
    error SignatureExpired();
    error InvalidSignatureOwner(address expectedOwner);
    error NotOwnerNorApproved(address attempter, uint256 tokenId);

    /// @dev set typehashes immuatable
    bytes32 public immutable override BARTER_TERMS_TYPEHASH;
    bytes32 public immutable override COMPONANT_TYPEHASH;

    /// @dev users nonces to protect against replay attack
    mapping(address => uint256) private _nonces;

    /// @dev keep track of address allowed for barter
    mapping(address => bool) private _barterables;

    /// @dev check if a token address is set as barterable
    modifier onlyExchangeable(address tokenAddr) {
        if (!_barterables[tokenAddr]) revert BarterNotEnabled(tokenAddr);
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) EIP712(name_, "1") {
        COMPONANT_TYPEHASH = keccak256(
            abi.encodePacked("Componant(address tokenAddr,uint256 tokenId)")
        );
        BARTER_TERMS_TYPEHASH = keccak256(
            abi.encodePacked(
                "BarterTerms(Componant bid,Componant ask,uint256 nonce,address owner,uint48 deadline)Componant(address tokenAddr,uint256 tokenId)"
            )
        );
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                              PUBLIC FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @dev See {IERC_N-barter}
    function barter(
        BarterTerms memory data,
        bytes memory signature
    ) external onlyExchangeable(data.bid.tokenAddr) {
        IERC_N(data.bid.tokenAddr).transferFor(data, msg.sender, signature);

        // transfer ask token
        if (!_isApprovedOrOwner(msg.sender, data.ask.tokenId))
            revert NotOwnerNorApproved(msg.sender, data.ask.tokenId);
        _transfer(msg.sender, data.owner, data.ask.tokenId);
    }

    /// @dev See {IERC_N-transferFor}
    function transferFor(
        BarterTerms memory data,
        address to,
        bytes memory signature
    ) external onlyExchangeable(msg.sender) {
        bytes32 structHash = _checkAndDisgestData(data);

        address signer = _checkMessageSignature(
            structHash,
            data.owner,
            signature
        );

        // transfer bid token
        if (!_isApprovedOrOwner(signer, data.bid.tokenId))
            revert NotOwnerNorApproved(signer, data.bid.tokenId);
        _transfer(data.owner, to, data.bid.tokenId);
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                                GETTERS
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @dev See {IERC_N-nonce}
    function nonce(address account) external view returns (uint256) {
        return _nonces[account];
    }

    /// @dev See {IERC_N-isBarterable}
    function isBarterable(address tokenAddr) external view returns (bool) {
        return _barterables[tokenAddr];
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                  ERC721 - disable transfer functions
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    function transferFrom(address, address, uint256) public pure override {
        revert("Not implemented");
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert("Not implemented");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("Not implemented");
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                          INTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    /**
     * Encode `structHash` (see {EIP712-_hashTypedDataV4}), recover the signer address (see {ECDSA-recover})
     * and validate signer address with `messageOwner`
     *
     * @param structHash digest of the signed message of barter terms
     * @param messageOwner owner of the message, who is supposed to sign the message
     * @param signature 65-bytes signatures
     * @return signer address, if valid, who signs the message
     */
    function _checkMessageSignature(
        bytes32 structHash,
        address messageOwner,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 typedDataHash = _hashTypedDataV4(structHash);

        // perform ecrecover and get signer address
        address signer = typedDataHash.recover(signature);
        if (signer != messageOwner) revert InvalidSignatureOwner(signer);
        return signer;
    }

    /**
     * @dev set `tokenAddr` as barterable
     *
     * Emit {BarterNetworkUpdated}
     *
     * @param tokenAddr as token address to approve
     */
    function _enableBarterWith(address tokenAddr) internal {
        _barterables[tokenAddr] = true;
        emit BarterNetworkUpdated(tokenAddr, true);
    }

    /**
     * @dev set `tokenAddr` as non-barterable
     *
     * Emit {BarterNetworkUpdated}
     *
     * @param tokenAddr as token address to ban
     */
    function _stopBarterWith(address tokenAddr) internal {
        _barterables[tokenAddr] = false;
        emit BarterNetworkUpdated(tokenAddr, false);
    }

    /**
     * @dev take up signed message information and validate it,
     * check the user's nonce and increment it and check the message
     * expiracy
     *
     * @param _nonce message's nonce
     * @param _owner message's owner
     * @param _deadline message's expiracy deadline
     * */
    function _commitMessageData(
        uint256 _nonce,
        address _owner,
        uint48 _deadline
    ) internal {
        // check and increment owner nonce
        uint256 expectedNonce = _nonces[_owner]++;
        if (expectedNonce != _nonce) revert InvalidNonce(_owner, expectedNonce);

        // check data expiracy
        if (block.timestamp > _deadline) revert SignatureExpired();
    }

    /**
     * @dev take the barter argument, call {_commitMessageData} to check
     * its validity and encode the barter argument as specified in {EIP712}
     */
    function _checkAndDisgestData(
        BarterTerms memory data
    ) private returns (bytes32) {
        _commitMessageData(data.nonce, data.owner, data.deadline);

        // disgest data following EIP712
        bytes32 bidStructHash = keccak256(
            abi.encode(COMPONANT_TYPEHASH, data.bid.tokenAddr, data.bid.tokenId)
        );
        bytes32 askStructHash = keccak256(
            abi.encode(COMPONANT_TYPEHASH, data.ask.tokenAddr, data.ask.tokenId)
        );

        return
            keccak256(
                abi.encode(
                    BARTER_TERMS_TYPEHASH,
                    bidStructHash,
                    askStructHash,
                    data.nonce,
                    data.owner,
                    data.deadline
                )
            );
    }
}
