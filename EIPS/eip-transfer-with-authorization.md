---
eip: 3009
title: Transfer With Authorization
author: Peter Jihoon Kim (@petejkim), Kevin Britz (@kbrizzle), David Knott (@DavidLKnott), Dongri Jin (@dongri)
discussions-to: https://github.com/ethereum/EIPs/issues/3010
status: Draft
type: Standards Track
category: ERC
created: 2020-09-28
requires: 20, 712
---

## Simple Summary

A contract interface that enables transferring of fungible assets via a signed authorization.

## Abstract

A set of functions to enable meta-transactions and atomic interactions with [ERC-20](./eip-20.md) token contracts via signatures conforming to the [EIP-712](./eip-712.md) typed message signing specification.

This enables the user to:

- delegate the gas payment to someone else,
- pay for gas in the token itself rather than in ETH,
- perform one or more token transfers and other operations in a single atomic transaction,
- transfer ERC-20 tokens to another address, and have the recipient submit the transaction,
- batch multiple transactions with minimal overhead, and
- create and perform multiple transactions without having to worry about them failing due to accidental nonce-reuse or improper ordering by the miner.

## Motivation

There is an existing spec, [EIP-2612](./eip-2612), that also allows meta-transactions, and it is encouraged that a contract implements both for maximum compatibility. The two primary differences between this spec and EIP-2612 are that:

- EIP-2612 uses sequential nonces, but this uses random 32-byte nonces, and that
- EIP-2612 relies on the ERC-20 `approve`/`transferFrom` ("ERC-20 allowance") pattern.

The biggest issue with the use of sequential nonces is that it does not allow users to perform more than one transaction at time without risking their transactions failing, because:

- DApps may unintentionally reuse nonces that have not yet been processed in the blockchain.
- Miners may process the transactions in the incorrect order.

This can be especially problematic if the gas prices are very high and transactions often get queued up and remain unconfirmed for a long time. Non-sequential nonces allow users to create as many transactions as they want at the same time.

The ERC-20 allowance mechanism is susceptible to the [multiple withdrawal attack](https://blockchain-projects.readthedocs.io/multiple_withdrawal.html)/[SWC-114](https://swcregistry.io/docs/SWC-114), and encourages antipatterns such as the use of the "infinite" allowance. The wide-prevalence of upgradeable contracts have made the conditions favorable for these attacks to happen in the wild.

The deficiencies of the ERC-20 allowance pattern brought about the development of alternative token standards such as the [ERC-777](./eip-777) and [ERC-677](https://github.com/ethereum/EIPs/issues/677). However, they haven't been able to gain much adoption due to compatibility and potential security issues.

## Specification

### Event

```solidity
event AuthorizationUsed(
    address indexed authorizer,
    bytes32 indexed nonce
);

// keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

// keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

/**
 * @notice Returns the state of an authorization
 * @dev Nonces are randomly generated 32-byte data unique to the authorizer's
 * address
 * @param authorizer    Authorizer's address
 * @param nonce         Nonce of the authorization
 * @return True if the nonce is used
 */
function authorizationState(
    address authorizer,
    bytes32 nonce
) external view returns (bool);

/**
 * @notice Execute a transfer with a signed authorization
 * @param from          Payer's address (Authorizer)
 * @param to            Payee's address
 * @param value         Amount to be transferred
 * @param validAfter    The time after which this is valid (unix time)
 * @param validBefore   The time before which this is valid (unix time)
 * @param nonce         Unique nonce
 * @param v             v of the signature
 * @param r             r of the signature
 * @param s             s of the signature
 */
function transferWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
) external;

/**
 * @notice Receive a transfer with a signed authorization from the payer
 * @dev This has an additional check to ensure that the payee's address matches
 * the caller of this function to prevent front-running attacks. (See security
 * considerations)
 * @param from          Payer's address (Authorizer)
 * @param to            Payee's address
 * @param value         Amount to be transferred
 * @param validAfter    The time after which this is valid (unix time)
 * @param validBefore   The time before which this is valid (unix time)
 * @param nonce         Unique nonce
 * @param v             v of the signature
 * @param r             r of the signature
 * @param s             s of the signature
 */
function receiveWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
) external;
```

**Optional:**

```
event AuthorizationCanceled(
    address indexed authorizer,
    bytes32 indexed nonce
);

// keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

/**
 * @notice Attempt to cancel an authorization
 * @param authorizer    Authorizer's address
 * @param nonce         Nonce of the authorization
 * @param v             v of the signature
 * @param r             r of the signature
 * @param s             s of the signature
 */
function cancelAuthorization(
    address authorizer,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
) external;
```


The arguments `v`, `r`, and `s` must be obtained using the [EIP-712](./eip-712.md) typed message signing spec.

**Example:**

```
DomainSeparator := Keccak256(ABIEncode(
  Keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  ),
  Keccak256("USD Coin"),                      // name
  Keccak256("2"),                             // version
  1,                                          // chainId
  0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48  // verifyingContract
))
```

With the domain separator, the typehash, which is used to identify the type of the EIP-712 message being used, and the values of the parameters, you are able to derive a Keccak-256 hash digest which can then be signed using the token holder's private key.

**Example:**

```
// Transfer With Authorization
TypeHash := Keccak256(
  "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
)
Params := { From, To, Value, ValidAfter, ValidBefore, Nonce }

// ReceiveWithAuthorization
TypeHash := Keccak256(
  "ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
)
Params := { From, To, Value, ValidAfter, ValidBefore, Nonce }

// CancelAuthorization
TypeHash := Keccak256(
  "CancelAuthorization(address authorizer,bytes32 nonce)"
)
Params := { Authorizer, Nonce }
```

```
// "‖" denotes concatenation.
Digest := Keecak256(
  0x1901 ‖ DomainSeparator ‖ Keccak256(ABIEncode(TypeHash, Params...))
)

{ v, r, s } := Sign(Digest, PrivateKey)
```

Smart contract functions that wrap `receiveWithAuthorization` call may choose to reduce the number of arguments by accepting the full ABI-encoded set of arguments for the `receiveWithAuthorization` call as a single argument of the type `bytes`.

**Example:**

```solidity
// keccak256("receiveWithAuthorization(address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32)")[0:4]
bytes4 private constant _RECEIVE_WITH_AUTHORIZATION_SELECTOR = 0xef55bec6;

function deposit(address token, bytes calldata receiveAuthorization)
    external
    nonReentrant
{
    (address from, address to, uint256 amount) = abi.decode(
        receiveAuthorization[0:96],
        (address, address, uint256)
    );
    require(to == address(this), "Recipient is not this contract");

    (bool success, ) = token.call(
        abi.encodePacked(
            _RECEIVE_WITH_AUTHORIZATION_SELECTOR,
            receiveAuthorization
        )
    );
    require(success, "Failed to transfer tokens");

    ...
}
```

### Use with web3 providers

The signature for an authorization can be obtained using a web3 provider with the `eth_signTypedData{_v4}` method.

**Example:**

```javascript
const data = {
  types: {
    EIP712Domain: [
      { name: "name", type: "string" },
      { name: "version", type: "string" },
      { name: "chainId", type: "uint256" },
      { name: "verifyingContract", type: "address" },
    ],
    TransferWithAuthorization: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "value", type: "uint256" },
      { name: "validAfter", type: "uint256" },
      { name: "validBefore", type: "uint256" },
      { name: "nonce", type: "bytes32" },
    ],
  },
  domain: {
    name: tokenName,
    version: tokenVersion,
    chainId: selectedChainId,
    verifyingContract: tokenAddress,
  },
  primaryType: "TransferWithAuthorization",
  message: {
    from: userAddress,
    to: recipientAddress,
    value: amountBN.toString(10),
    validAfter: 0,
    validBefore: Math.floor(Date.now() / 1000) + 3600, // Valid for an hour
    nonce: Web3.utils.randomHex(32),
  },
};

const signature = await ethereum.request({
  method: "eth_signTypedData_v4",
  params: [userAddress, JSON.stringify(data)],
});

const v = "0x" + signature.slice(130, 132);
const r = signature.slice(0, 66);
const s = "0x" + signature.slice(66, 130);
```

## Rationale

### Unique Random Nonce, Instead of Sequential Nonce

One might say transaction ordering is one reason why sequential nonces are preferred. However, sequential nonces do not actually help achieve transaction ordering for meta transactions in practice:

- For native Ethereum transactions, when a transaction with a nonce value that is too-high is submitted to the network, it will stay pending until the transactions consuming the lower unused nonces are confirmed.
- However, for meta-transactions, when a transaction containing a sequential nonce value that is too high is submitted, instead of staying pending, it will revert and fail immediately, resulting in wasted gas.
- The fact that miners can also reorder transactions and include them in the block in the order they want (assuming each transaction was submitted to the network by different meta-transaction relayers) also makes it possible for the meta-transactions to fail even if the nonces used were correct. (e.g. User submits nonces 3, 4 and 5, but miner ends up including them in the block as 4,5,3, resulting in only 3 succeeding)
- Lastly, when using different applications simultaneously, in absence of some sort of an off-chain nonce-tracker, it is not possible to determine what the correct next nonce value is if there exists nonces that are used but haven't been submitted and confirmed by the network.
- Under high gas price conditions, transactions can often "get stuck" in the pool for a long time. Under such a situation, it is much more likely for the same nonce to be unintentionally reused twice. For example, if you make a meta-transaction that uses a sequential nonce from one app, and switch to another app to make another meta-transaction before the previous one confirms, the same nonce will be used if the app relies purely on the data available on-chain, resulting in one of the transactions failing.
- In conclusion, the only way to guarantee transaction ordering is for relayers to submit transactions one at a time, waiting for confirmation between each submission (and the order in which they should be submitted can be part of some off-chain metadata), rendering sequential nonce irrelevant.

### Valid After and Valid Before

- Relying on relayers to submit transactions for you means you may not have exact control over the timing of transaction submission.
- These parameters allow the user to schedule a transaction to be only valid in the future or before a specific deadline, protecting the user from potential undesirable effects that may be caused by the submission being made either too late or too early.

### EIP-712

- EIP-712 ensures that the signatures generated are valid only for this specific instance of the token contract and cannot be replayed on a different network with a different chain ID.
- This is achieved by incorporating the contract address and the chain ID in a Keccak-256 hash digest called the domain separator. The actual set of parameters used to derive the domain separator is up to the implementing contract, but it is highly recommended that the fields `verifyingContract` and `chainId` are included.

## Backwards Compatibility

New contracts benefit from being able to directly utilize EIP-3009 in order to create atomic transactions, but existing contracts may still rely on the conventional ERC-20 allowance pattern (`approve`/`transferFrom`).

In order to add support for EIP-3009 to existing contracts ("parent contract") that use the ERC-20 allowance pattern, a forwarding contract ("forwarder") can be constructed that takes an authorization and does the following:

1. Extract the user and deposit amount from the authorization
2. Call `receiveWithAuthorization` to transfer specified funds from the user to the forwarder
3. Approve the parent contract to spend funds from the forwarder
4. Call the method on the parent contract that spends the allowance set from the forwarder
5. Transfer the ownership of any resulting tokens back to the user

**Example:**

```solidity
interface IDeFiToken {
    function deposit(uint256 amount) external returns (uint256);

    function transfer(address account, uint256 amount)
        external
        returns (bool);
}

contract DepositForwarder {
    bytes4 private constant _RECEIVE_WITH_AUTHORIZATION_SELECTOR = 0xef55bec6;

    IDeFiToken private _parent;
    IERC20 private _token;

    constructor(IDeFiToken parent, IERC20 token) public {
        _parent = parent;
        _token = token;
    }

    function deposit(bytes calldata receiveAuthorization)
        external
        nonReentrant
        returns (uint256)
    {
        (address from, address to, uint256 amount) = abi.decode(
            receiveAuthorization[0:96],
            (address, address, uint256)
        );
        require(to == address(this), "Recipient is not this contract");

        (bool success, ) = address(_token).call(
            abi.encodePacked(
                _RECEIVE_WITH_AUTHORIZATION_SELECTOR,
                receiveAuthorization
            )
        );
        require(success, "Failed to transfer to the forwarder");

        require(
            _token.approve(address(_parent), amount),
            "Failed to set the allowance"
        );

        uint256 tokensMinted = _parent.deposit(amount);
        require(
            _parent.transfer(from, tokensMinted),
            "Failed to transfer the minted tokens"
        );

        uint256 remainder = _token.balanceOf(address(this);
        if (remainder > 0) {
            require(
                _token.transfer(from, remainder),
                "Failed to refund the remainder"
            );
        }

        return tokensMinted;
    }
}
```

## Test Cases

See [EIP3009.test.ts](https://github.com/CoinbaseStablecoin/eip-3009/blob/master/test/EIP3009.test.ts).

## Implementation

**EIP3009.sol**
```solidity
abstract contract EIP3009 is IERC20Transfer, EIP712Domain {
    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    string internal constant _INVALID_SIGNATURE_ERROR = "EIP3009: invalid signature";

    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(now > validAfter, "EIP3009: authorization is not yet valid");
        require(now < validBefore, "EIP3009: authorization is expired");
        require(
            !_authorizationStates[from][nonce],
            "EIP3009: authorization is used"
        );

        bytes memory data = abi.encode(
            TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce
        );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
            "EIP3009: invalid signature"
        );

        _authorizationStates[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}
```

**IERC20Transfer.sol**
```solidity
abstract contract IERC20Transfer {
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual;
}
```

**EIP712Domain.sol**
```solidity
abstract contract EIP712Domain {
    bytes32 public DOMAIN_SEPARATOR;
}
```

**EIP712.sol**
```solidity
library EIP712 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    bytes32(chainId),
                    address(this)
                )
            );
    }

    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        require(recovered != address(0), "EIP712: invalid signature");
        return recovered;
    }
}
```

A fully working implementation of EIP-3009 can be found in [this repository](https://github.com/CoinbaseStablecoin/eip-3009/blob/master/contracts/lib/EIP3009.sol). The repository also includes [an implementation of EIP-2612](https://github.com/CoinbaseStablecoin/eip-3009/blob/master/contracts/lib/EI32612.sol) that uses the EIP-712 library code presented above.

## Security Considerations

Use `receiveWithAuthorization` instead of `transferWithAuthorization` when calling from other smart contracts. It is possible for an attacker watching the transaction pool to extract the transfer authorization and front-run the `transferWithAuthorization` call to execute the transfer without invoking the wrapper function. This could potentially result in unprocessed, locked up deposits. `receiveWithAuthorization` prevents this by performing an additional check that ensures that the caller is the payee. Additionally, if there are multiple contract functions accepting receive authorizations, the app developer could dedicate some leading bytes of the nonce could as the identifier to prevent cross-use.

When submitting multiple transfers simultaneously, be mindful of the fact that relayers and miners will decide the order in which they are processed. This is generally not a problem if the transactions are not dependent on each other, but for transactions that are highly dependent on each other, it is recommended that the signed authorizations are submitted one at a time.

The zero address must be rejected when using `ecrecover` to prevent unauthorized transfers and approvals of funds from the zero address. The built-in `ecrecover` returns the zero address when a malformed signature is provided.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
