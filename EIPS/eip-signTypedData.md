# personal_signTypedData

## Preamble

    EIP: <to be assigned>
    Title: Ethereum typed data signing
    Author: Leonid Logvinov <logvinov.leon@gmail.com>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2017-09-13
    Replaces: 693

## Simple Summary

Standard for machine-verifiable and human-readable typed data signing with Ethereum keys.

## Abstract

Ethereum clients provide the ability to sign UTF-8 strings with the `eth_sign` RPC call. This call however, doesn't give Signer UI's enough metadata to display the actual intent of the DApp when the data being signed is not a string. Over time, we expect value to be transferred on Ethereum using protocols that involve off-chain components (e.g state channels). These protocols are going to involve signing complex data structures with Ethereum keys, making a human-readable, machine-verifiable signing flow critical to user security.

This EIP adds an RPC method to sign arrays of arbitrary typed data, making it easy for the Signer UI to display this data to the user in a human-readable form, so that the user can be 100% confident of exactly what they are signing, while keeping the resulting signatures machine-verifiable. In addition, there is no room for a malicious DApp to provide the signer with alternative data then that being presented to the user, since the signer hashes the typedData before the user signs it.

This method should only be implemented in Ethereum clients with Signer UI's that require user approval before signing (MetaMask, MEW, Parity signer, Ledger, Trezor). It should not be implemented in clients where approval is already granted (e.g Geth with unlocked accounts).

<img src="https://github.com/0xProject/EIPs/tree/master/EIPS/eip-personal_signTypedData/personal_signTypedData.png" width="500px">

This EIP is a continuation of a discussion here: https://github.com/ethereum/EIPs/pull/683
I offered this solution in a comment: https://github.com/ethereum/EIPs/pull/683#issuecomment-327945854
It proposes a more general solution then the one offered here: https://github.com/ethereum/EIPs/pull/693

## Motivation

There are a whole range of higher level protocols emerging on Ethereum. State channels, 0x protocol, Login protocols, etc... For scalability reasons these protocols want to sign some protocol-specific data off-chain. They then use those signed messages to trigger on-chain or other actions with important consequences.

* Transferring ETH
* Transferring tokens
* Transferring ownership
* etc...


The current `eth_sign` implementation allows signing of arbitrary data without specifying it's type or structure. Some signers assume that the data is a UTF-8 string. Some signers show it as a hex encoded string. This leads to user confusion since it is impossible to verify the message you're signing unless it's a plaintext UTF-8 string.

<img src="https://github.com/0xProject/EIPs/tree/master/EIPS/eip-personal_signTypedData/eth_sign.png"  width="500px">

Calling `eth_sign` on Metamask displays the string to sign. If the user is signing the result of hashing a complex structure involving multiple critical pieces of information, the only way to verify what they are signing is to re-hash the same structure in an independent script and make sure the hashes match.

Calling `personal_sign` on Metamask with the raw bytes of a hash (e.g not an ASCII string) shows the user this even less verifiable message that they should sign.

<img src="https://github.com/0xProject/EIPs/tree/master/EIPS/eip-personal_signTypedData/personal_sign.png"  width="500px">

The main problem is that signers don't have enough metadata to display the DApp's real intent effectively. In order to do so, they need the plaintext input that the dApp wishes hashed and signed by the user.

## Specification

This EIP proposes a new JSON RPC method to the `personal` namespace: `personal_signTypedData`. It accepts an array of values together with their specified type and human-readable name. The [json-schema](http://json-schema.org/) draft is defined below.

### Params JSON Schema:
```json-schema
{
  items: {
    properties: {
      name: {type: 'string'},
      type: {type: 'string'}, // Solidity type as described here: https://github.com/ethereum/solidity/blob/93b1cc97022aa01e7daa9816bcc23108bbe008b5/libsolidity/ast/Types.cpp#L182
      value: {
        oneOf: [
          {type: 'string'},
          {type: 'number'},
          {type: 'boolean'},
        ],
      },
    },
    type: 'object',
  },
  type: 'array',
}
```

### Example params:
// For this state channel POC: https://medium.com/@matthewdif/ethereum-payment-channel-in-50-lines-of-code-a94fad2704bc
```javascript
typedData = [
    {
      "name": "channel",
      "type": "address",
      "value": "0xb088a3Bc93F71b4DE97b9De773e9647645983688",
    },
    {
      "name": "value",
      "type": "uint",
      "value": 42,
    },
];
```

### How it can look in signer UI:

<img src="https://github.com/0xProject/EIPs/tree/master/EIPS/eip-personal_signTypedData/personal_signTypedData.png" width="500px">


It's important to make the schema part of the signature (explanation can be found in “Rationale” section). The way the schema will be combined with the values to generate the hash signed by the user is shown below. First, the schema is encoded into a string using a method similar to [solidity events signatures](http://solidity.readthedocs.io/en/develop/contracts.html#low-level-interface-to-logs). It is then hashed together with the keccak256 hash of the data array.

### Pseudocode examples:

```javascript
// Client-side code example
const typedData = [
  {
    'type': 'string',
    'name': 'message',
    'value': 'Hi, Alice!',
  },
  {
    'type': 'uint',
    'name': 'value',
    'value': 42,
  },
];
const signature = await web3.personal.signTypedData(typedData);
```

```javascript
// Signed code JS example
import * as _ from 'lodash';
import * as ethAbi from 'ethereumjs-abi';

const data = _.map(typedData, 'value');
const types = _.map(typedData, 'type');
const schema = _.map(typedData, entry => `${entry.type} ${entry.name}`);
const hash = ethAbi.soliditySHA3(
  ['bytes32', 'bytes32'],
  [
    ethAbi.soliditySHA3(_.times(typedData.length, _.constant('string')), schema),
    ethAbi.soliditySHA3(types, data),
  ],
);
```

```solidity
// Solidity example
string message = 'Hi, Alice!';
unit value = 42;
const hash = keccak256(
  keccak256('string message', 'uint value'), // Probably hardcoded
  keccak256(message, value),
);
address recoveredSignerAddress = ecrecover(hash, v, r, s);
```

Signature will be returned in the same format as `eth_sign` (the ecSignature params concatenated together (r + s + v) and hex encoded.

## Rationale

Signing support in Ethereum clients is most useful for off-chain transactions. On-chain transactions in Ethereum have well-defined typed schemas (gas uint, gasPrice uint, etc) which allows signer UIs to show useful information about transactions to the user. We need the same for off-chain transactions.

The Solidity keccak256 function accepts an array of typed arguments and motivated the current design.

The main and the most important part of this change is to give Signer UIs a chance to give a user enough information to be able to verify what is being signed even when using untrusted DApps. Since the DApp does not get to provide the signer with a hard-to-read hash but must supply the exact values (in plain-text) that the user will be signing, the dangers of signing a malicious action (transaction or otherwise) are greatly reduced.

The schema information must be signed together with the data, so that the verifying party can be confident, that the user was shown the data with the corresponding type and names supplied by the DApp.

This approach is even possible to implement on hardware wallets with small screens (Ledger Nano S, Trezor). Users will be shown one line at a time (as currently with transactions).


## Backwards Compatibility

This EIP does not break backwards compatibility.

`eth_sign` and `personal_sign` will not be removed for backwards compatibility reasons even though the `personal_signTypedData` is a superset of their functionality. Current off-chain protocols will however need to modify the verifying code in their smart contracts to include the schema.

Example of signing a simple string using `personal_signTypedData`

```javascript
const signature = await web3.personal.signTypedData([
  {
    'type': 'string',
    'name': 'message',
    'value': 'Hi, Alice!',
  },
]);
```


The implementation of `personal_signTypedData`  makes some assumptions about the crypto primitives being used (tightly-packed + keccak256 + secp256k1), but the same assumptions have already been made for the [keccak256](http://solidity.readthedocs.io/en/develop/units-and-global-variables.html) function in solidity. If Ethereum becomes more crypto-agnostic in the future and allows for other types of signatures - this EIP can be adjusted.

The choice of keccak256 is motivated by the fact, that it's twice [cheaper to verify in a smart contract](https://ethereum.stackexchange.com/questions/3184/what-is-the-cheapest-hash-function-available-in-solidity/3200#3200) when compared with sha3.

## Test Cases

Not ready Yet.
Proper test vector suite will be added in the next finalization steps.


## Implementation

Not implemented Yet.
Metamask @flyswatter expressed a will to imlement it as an experemental feature.

## Copyright


Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
