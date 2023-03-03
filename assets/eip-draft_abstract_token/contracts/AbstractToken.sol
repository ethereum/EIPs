// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IAbstractToken, IAbstractERC20, AbstractTokenMessage, AbstractTokenMessageStatus} from "./IAbstractToken.sol";
import {GenericEIP712} from "./GenericEIP712.sol";

abstract contract AbstractToken is IAbstractToken, Ownable, GenericEIP712 {
    event SetSigner(address signer);
    mapping(bytes32 => bool) used;
    address private signer;

    // The type of content signed in the EIP-712 signature
    bytes32 internal constant TYPE_HASH = keccak256("AbstractTokenMessage(uint256 chainId,address implementation,address owner,uint256 nonce)");
    // bytes32 public constant TYPE_HASH = keccak256("AbstractTokenMessage(uint256 chainId,address implementation,address owner,bytes meta,uint256 nonce)");

	modifier validMessage(AbstractTokenMessage calldata message) {
        AbstractTokenMessageStatus s = status(message);
        require(s != AbstractTokenMessageStatus.used, "message used");
        require(s != AbstractTokenMessageStatus.invalid, "message invalid");
		_;
	}

    constructor(address _signer) GenericEIP712('AbstractToken', '1') {
        _setSigner(_signer);
    }

    // the actual mechanics of reifying the token depend on the type of token
    function _reify(AbstractTokenMessage calldata message) internal virtual;

    // transforms token(s) from message to contract
    function reify(AbstractTokenMessage calldata message) public validMessage(message) {
        console.log("*** message status");
        console.log(uint256(status(message)));
        // checks
        require(message.chainId == block.chainid, "for other chain");
        require(message.implementation == address(this), "for other contract");

        // effects
        bytes32 id = messageId(message);
        used[id] = true;

        // interactions
        // the actual mechanics of creating the token depends on implementation
        _reify(message);
        emit Reify(message);
    }

    // the actual mechanics of dereifying the token depend on the type of token
    function _dereify(AbstractTokenMessage calldata message) internal virtual;

    // transforms token(s) from contract to message
    function dereify(AbstractTokenMessage calldata message) public validMessage(message) {
        // checks
        require(message.chainId != block.chainid || message.implementation != address(this), "same contract");

        // effects
        bytes32 id = messageId(message);
        used[id] = true;

        // interactions
        _dereify(message);
        emit Dereify(message);
    }

    // check metadata - depends on implementation
    function _validMeta(bytes calldata metadata) virtual internal view returns (bool);

    // check abstract token message validity: an abstract token message can only be reified if valid
    function status(AbstractTokenMessage calldata message)
        public
        view
        returns (AbstractTokenMessageStatus)
    {
        bytes32 id = messageId(message);

        // this message was once valid but now it is reified
        if (used[id]) return AbstractTokenMessageStatus.used;

        // the metadata is not valid
        if (!_validMeta(message.meta)) return AbstractTokenMessageStatus.invalid;

        // message must include a valid proof (EIP-712 signature)
        // 
        // note that the message chainId and implementation may be different than this contract's! (It could be intended for another chain but still valid for dereification)
        bytes32 digest = _hashTypedDataV4(id, message.chainId, message.implementation);
        if(!SignatureChecker.isValidSignatureNow(signer, digest, message.proof)) return AbstractTokenMessageStatus.invalid;

        // all checks pass: the message is valid
        return AbstractTokenMessageStatus.valid;
    }

    function messageId(AbstractTokenMessage calldata message)
        public
        pure
        returns (bytes32)
    {
        // Note that the message ID is also the EIP-712 hash of the message struct - the fields must match the contents of TYPE_HASH
        return keccak256(
            abi.encode(
                TYPE_HASH,
                message.chainId,
                message.implementation,
                message.owner,
                // keccak256(message.meta),
                message.nonce
            )
        );
    }

    function _setSigner (address _signer) internal {
        signer = _signer;
        emit SetSigner(signer);
    }

    // admin functions
    function setSigner(address _signer) external onlyOwner {
        _setSigner(_signer);
    }

    function getSigner () external view returns (address) {
        return signer;
    }

    function _equal(string memory a, string memory b) internal pure returns (bool) {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
