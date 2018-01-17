# eth_signTypedData

## Preamble

    EIP: <to be assigned>
    Title: Ethereum typed data signing
    Author: Leonid Logvinov <logvinov.leon@gmail.com>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2017-09-13

## Simple Summary

Standard for machine-verifiable and human-readable typed data signing with Ethereum keys.

## Abstract

Ethereum clients provide the ability to sign UTF-8 strings with the `eth_sign` RPC call. This call, however, doesn't give Signer UI's enough metadata to display the actual intent of the DApp when the data being signed is not a string. Over time, we expect value to be transferred on Ethereum using protocols that involve off-chain components (e.g. state channels). These protocols are going to involve signing complex data structures with Ethereum keys, making a human-readable, machine-verifiable signing flow critical for user security.

This EIP adds an RPC method to sign arrays of arbitrary typed data, making it easy for the Signer UI to display this data to the user in a human-readable form, so that the user can be 100% confident of exactly what they are signing, while keeping the resulting signatures machine-verifiable. In addition, there is no room for a malicious DApp to provide the signer with alternative data then that being presented to the user, since the signer is the one hashing the typed data before the user signs it.

This method should only be implemented in Ethereum clients with Signer UI's that require user approval before signing (MetaMask, MEW, Parity signer, Ledger, Trezor, Cypher Browser). It should not be implemented in clients where approval is already granted (e.g. Geth with unlocked accounts).

<img src="https://raw.githubusercontent.com/0xProject/EIPs/master/EIPS/eip-eth_signTypedData/eth_signTypedData.png" width="500px">

This EIP is a continuation of a discussion [here](https://github.com/ethereum/EIPs/pull/683).
I offered this solution in [a comment](https://github.com/ethereum/EIPs/pull/683#issuecomment-327945854).
It proposes a more general solution then the one offered [here](https://github.com/ethereum/EIPs/pull/693).

## Motivation

There is a whole range of higher level protocols emerging on Ethereum. State channels, 0x protocol, Login protocols, etc... For scalability reasons these protocols want to sign some protocol-specific data off-chain. They then use those signed messages to trigger on-chain or other actions with important consequences.

* Transferring ETH
* Transferring tokens
* Transferring ownership
* etc...


The current `eth_sign` implementation allows signing of arbitrary data without specifying it's type or structure. Some signers assume that the data is a UTF-8 string. Some signers show it as a hex encoded string. This leads to user confusion since it's impossible to verify the message you're signing unless it's a plaintext UTF-8 string.

<img src="https://raw.githubusercontent.com/0xProject/EIPs/master/EIPS/eip-eth_signTypedData/eth_sign.png"  width="500px">

Calling `eth_sign` on Metamask displays the string to sign. If the user is signing the result of hashing a complex structure involving multiple critical pieces of information, the only way to verify what they are signing is to re-hash the same structure in an independent script and make sure the hashes match.

Calling `personal_sign` on Metamask with the raw bytes of a hash (e.g. not an ASCII string) shows the user this even less verifiable message that they should sign.

<img src="https://raw.githubusercontent.com/0xProject/EIPs/master/EIPS/eip-eth_signTypedData/personal_sign.png"  width="500px">

The main problem is that signers don't have enough metadata to display the DApp's real intent effectively. In order to do so, they need the plaintext input that the dApp wishes hashed and signed by the user.

## Specification

This EIP proposes a new JSON RPC method to the `eth` namespace: `eth_signTypedData`.

Parameters:
0. `Address` - 20 Bytes - Address of the account that will sign the messages
1. `TypedData` - Typed data to be signed

Returns:
0. `DATA` - signature - 65-byte data in hexadecimal string

Typed data is the array of data entries with their specified type and human-readable name. Below is the [json-schema](http://json-schema.org/) definition for `TypedData` param.
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

There also should be a corresponding `personal_signTypedData` method which accepts the password for an account as the last argument.

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

<img src="https://raw.githubusercontent.com/0xProject/EIPs/master/EIPS/eip-eth_signTypedData/eth_signTypedData.png" width="500px">


It's important to make the schema part of the signature (explanation can be found in “Rationale” section). The way the schema will be combined with the values to generate the hash signed by the user is shown below. First, the schema is encoded into a string using a method similar to [solidity events signatures](http://solidity.readthedocs.io/en/develop/contracts.html#low-level-interface-to-logs). Then it's hash is prepended to the data array before hashing it.

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
const signature = await web3.eth.signTypedData(signerAddress, typedData);
// or
const signature = await web3.personal.signTypedData(signerAddress, typedData, '************');
```

```javascript
// Signer code JS example
import * as _ from 'lodash';
import * as ethAbi from 'ethereumjs-abi';

const schema = _.map(typedData, entry => `${entry.type} ${entry.name}`).join(',');
// Will generate `string message,uint value` for the above example
const schemaHash = ethAbi.soliditySHA3(['string'], [schema]);
const data = _.map(typedData, 'value');
const types = _.map(typedData, 'type');
const hash = ethAbi.soliditySHA3(
  ['bytes32', ...types],
  [schemaHash, ...data],
);
```

```solidity
// Solidity example
string message = 'Hi, Alice!';
uint value = 42;
bytes32 schemaHash = keccak256('string message,uint value'); // Probably hardcoded
const hash = keccak256(schemaHash, message, value);
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

`eth_sign` and `personal_sign` will not be removed for backwards compatibility reasons even though the `eth_signTypedData` is a superset of their functionality. Current off-chain protocols will however need to modify the verifying code in their smart contracts to include the schema.

Example of signing a simple string using `eth_signTypedData`

```javascript
const signature = await web3.eth.signTypedData([
  {
    'type': 'string',
    'name': 'message',
    'value': 'Hi, Alice!',
  },
]);
```


The implementation of `eth_signTypedData`  makes some assumptions about the crypto primitives being used (tightly-packed + keccak256 + secp256k1), but the same assumptions have already been made for the [keccak256](http://solidity.readthedocs.io/en/develop/units-and-global-variables.html) function in solidity. If Ethereum becomes more crypto-agnostic in the future and allows for other types of signatures - this EIP can be adjusted.

The choice of keccak256 is motivated by the fact, that it's [twice as cheap to verify in a smart contract](https://ethereum.stackexchange.com/questions/3184/what-is-the-cheapest-hash-function-available-in-solidity/3200#3200) when compared with sha3.

## Test Cases

All tests use the first address generated by the mnemonic:
```
concert load couple harbor equip island argue ramp clarify fence smart topic
```
Address:
```
0x5409ed021d9299bf6814279a6a1411a7e866a631
```
Private key:
```
f2f48ee19680706196e2e339e5da3491186e0c4c5030670656b0e0164837257d
```

```javascript
const test1 = [{
    value: 'Hi, Alice!',
    type: 'string',
    name: 'message',
}];
const schema = 'string message';
const schemaHash = '0xdc515b3059b4b84c18705c36390462776d1225701f972f9c3be50e553609e243';
const typedDataHash = '0xe18794748cc6d73634d578f6a83f752bee11a0c9853d76bd0111d67a9b555a2c';
const signature = '0x1a4ca93acf066a580f097690246e6c85d1deeb249194f6d3c2791f3aecb6adf8714ca4a0f12512ddd2a4f2393ea0c3b2c856279ba4929a5a34ae6859689428061b';
```

```javascript
const test2 = [{
    value: 42,
    type: 'uint',
    name: 'value',
}];
const schema = 'uint value';
const schemaHash = '0x900c03b437f206d641d2295da46ff002a6734dc3e65bf63bf34df850fc7ccfbc';
const typedDataHash = '0x6cb1c2645d841a0a3d142d1a2bdaa27015cc77f442e17037015b0350e468a957';
const signature = '0x87c5b6a9f3a758babcc9140a96ae07957c6c9109af65bf139266cded52da49e63df6af6f7daef588218e156bc83b95e0bfcfa8e72843cf4cf8c67c3ca11c3fd11b';
```

```javascript
const test3 = [
    {
        value: 42,
        type: 'uint',
        name: 'value',
    },
    {
        value: 'Hi, Alice!',
        type: 'string',
        name: 'message',
    },
    {
        value: false,
        type: 'bool',
        name: 'removed',
    },
];
const schema = 'uint value,string message,bool removed';
const schemaHash = '0x4820e70c96098f7857d65e3f43eacb822e7e99c863e7948d544a58a4936b73e9';
const typedDataHash = '0xdb7ef11800c80fd69e0d1ddeb08309aecc0deefc5db8e2bafe84655f5266f0eb';
const signature = '0x442d2a668ea3e79b7f8084a8ddaaca82b80eba509a08e2fb0a116733053fea404829b3651c89415cbd6f5598282f552c28b4b43a9429147fb66e0228ba7f7c1a1b';
```

## Implementation

It is implemented as an experimental feature in Metamask 3.11.0+.
It's not part of web3.js yet, so you can try using it like:
```javascript
const data = {
  'type': 'string',
  'name': 'message',
  'value': 'Hi, Alice!',
};
web3.currentProvider.sendAsync({method: 'eth_signTypedData', params: [data, signerAddress], jsonrpc: '2.0', id: 1}, callback);
```

## Copyright


Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
