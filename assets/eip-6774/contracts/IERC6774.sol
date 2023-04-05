// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface IERC6774 {
    /**
     * @dev Emitted when a `tokenAddr` is settled as barterable (`barterable` == true)
     * or stopped from being barterable (`barterable` == false)
     */
    event BarterNetworkUpdated(
        address indexed tokenAddr,
        bool indexed barterable
    );

    struct Component {
        address tokenAddr;
        uint256 tokenId;
    }

    struct BarterTerms {
        Component bid;
        Component ask;
        uint256 nonce;
        address owner;
        uint48 deadline;
    }

    /// @dev Typehash of the {BarterTerms} struct
    function BARTER_TERMS_TYPEHASH() external view returns (bytes32);

    /// @dev Typehash of the {Component} struct
    function COMPONENT_TYPEHASH() external view returns (bytes32);

    /**
     * @dev return the current nonce for `account`. This value must
     * be included whenever a signature is generated for {barter}.
     *
     * Every successful call to {transferFor} increases `account`'s nonce
     * by one, this prevents a signature from being used multiple times.
     *
     * @param account address to query the current nonce
     * @return nonce of the `account`
     */
    function nonce(address account) external view returns (uint256);

    /**
     * @param tokenAddr contract address to verify
     * @return true if `tokenAddr` is set as barterable
     */
    function isBarterable(address tokenAddr) external view returns (bool);

    /**
     * @dev transfer `data.bid.tokenId` to `to`, this function must be
     * called by `data.ask.tokenAddr`
     *
     * Requirements:
     *
     *  - `data.deadline` must be a timestamp in the future
     *  - `signature` must be a valid `secp256k1` signature from `data.owner`
     *  over the EIP712-formatted function arguments.
     *  - the signature must use `data.owner`'s current nonce (see {nonces}).
     *  - `data.owner` must own or be approved for `data.bid.tokenId`
     *
     * @param data struct as the barter terms
     * @param to recipient address
     * @param signature as signature of the hashed struct following EIP712
     */
    function transferFor(
        BarterTerms memory data,
        address to,
        bytes memory signature
    ) external;

    /**
     * @dev transfer `data.ask.tokenId` to the owner of `data.bid.tokenId`, this
     * function must call {transferFor} over `data.bid.tokenAddr`.
     *
     * Requirements:
     *
     *  - `data` and `signature` must follow requirements of {transferFor}
     *  - the caller must own or be approved for `data.ask.tokenId`
     *
     * @param data struct of the barter terms
     * @param signature as signature of the hashed struct following EIP712
     */
    function barter(BarterTerms memory data, bytes memory signature) external;
}
