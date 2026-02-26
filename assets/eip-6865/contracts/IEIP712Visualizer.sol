pragma solidity ^0.8.0;

interface IEIP712Visualizer {
    struct Liveness {
        uint256 from;
        uint256 to;
    }

    struct UserAssetMovement {
        address assetTokenAddress;
        uint256 id;
        uint256[] amounts;
    }

    struct Result {
        UserAssetMovement[] assetsIn;
        UserAssetMovement[] assetsOut;
        Liveness liveness;
    }

    /**
     * @notice This function processes an EIP-712 payload message and returns a structured data format emphasizing the potential impact on users' assets.
     * @dev The function returns assetsOut (assets the user is offering), assetsIn (assets the user would receive), and liveness (validity duration of the EIP-712 message).
     *
     * - MUST revert if the domainHash identifier is not supported (require(domainHash == DOMAIN_SEPARATOR, "message")).
     * - MUST NOT revert if there are no assetsIn, assetsOut, or liveness values; returns nullish values instead.
     * - assetsIn MUST include only assets for which the user is the recipient.
     * - assetsOut MUST include only assets for which the user is the sender.
     * - MUST returns liveness.to as type(uint256).max if the message never expires.
     * - MUST returns liveness.from as block.timestamp if the message does not have a validity starting date.
     * - MUST returns a set (array) of amounts in assetsIn.amounts and assetsOut.amount where items define the amount per time curve, with time defined within liveness boundaries.
     * - amounts items MUST include the minimum amount.
     * - MUST returns the minimum amount if amounts set contains only one item
     *
     * @param encodedMessage The ABI-encoded EIP-712 message (abi.encode(types, params)).
     * @param domainHash The hash of the EIP-712 domain separator as defined in the EIP-712 proposal; see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator.
     * @return Result struct containing the user's assets impact and message liveness.
     */
    function visualizeEIP712Message(
        bytes memory encodedMessage,
        bytes32 domainHash
    ) external view returns (Result memory);
}
