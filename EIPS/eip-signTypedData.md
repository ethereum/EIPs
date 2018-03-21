# eth_signTypedData

## Preamble

    EIP:      <to be assigned>
    Title:    Ethereum typed structured data signing
    Author:   Remco Bloemen <remco@wicked.ventures>,
              Leonid Logvinov <logvinov.leon@gmail.com>
    Type:     Standard Track
    Category: ERC
    Status:   Draft
    Created:  2017-09-13



## Simple Summary

<!-- "If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP. -->

Signing data is a solved problem if all we care about are bytestrings. Unfortunately in the real world we care about complex meaningful messages. Mapping these to bytestrings is an error prone process. This standard 



## Abstract

<!-- A short (~200 word) description of the technical issue being addressed. -->

This is a standard for hashing and signing of typed structured data (as opposed to bytestrings). A new RPC call, web3 function and Solidity features is added. A reference and optimized implementation in EVM is given.


## Motivation

<!-- The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright. -->

A signature scheme consists of hashing algorithm and a signing algorithm. The signing algorithm of choice in Ethereum is `secp256k1`. The hashing algorithm of choice is `keccak256`, this is a function from bytestrings, 𝔹⁸ⁿ, to 256-bit strings, 𝔹²⁵⁶.

A good hashing algorithm should satisfy security properties such as determinism, second pre-image resistance and collision resistance. The `keccak256` function satisfies the above criteria *when applied to bytestrings*. If we want to apply it to other sets we first need to map this set to bytestrings. It is critically important that this encoding function is [deterministic][deterministic] and [injective][injective]. If it is not deterministic then the hash might differ from the moment of signing to the moment of verifying, causing the signature to incorrectly be rejected. If it is not injective then there are two different elements in our input set that hash to the same value, causing a signature to be valid for a different unrelated message.

[deterministic]: https://en.wikipedia.org/wiki/Deterministic_algorithm
[injective]: https://en.wikipedia.org/wiki/Injective_function

### Transactions and bytestrings

An illustrative example of the above breakage can be found in Ethereum prior to.
Ethereum has two kinds of messages, transactions `𝕋` and bytestrings `𝔹⁸ⁿ`. These are signed using `eth_sendTransaction` and `eth_sign` respectively. Originally the encoding function `encode : 𝕋 ∪ 𝔹⁸ⁿ → 𝔹⁸ⁿ` was as defined as follows:

* `encode(t : 𝕋) = RLP_encode(t)`
* `encode(b : 𝔹⁸ⁿ) = b`

While individually they satisfy the required properties, together they do not. If we take `b = RLP_encode(t)` we have a collision. This is mitigated in Geth [PR 2940][geth-pr] by modifying the second leg of the encoding function:

[geth-pr]: https://github.com/ethereum/go-ethereum/pull/2940

* `encode(b : 𝔹⁸ⁿ) = "\x19Ethereum Signed Message:\n" ‖ len(b) ‖ b)` where `len(b)` is the ascii-decimal encoding of the number of bytes in `b`.

Since `RLP_encode(t : 𝕋)` never starts with `\x19`, this solves the collision between the functions. The function also does not introduce new collisions, but this is mostly due to luck, the encoding function is ambiguous. Does `"x19Ethereum Signed Messagege:\n42a…"` mean a four byte string starting with `2a` or a 42-byte string starting with `a`?. This was pointed out in [Geth issue #14794][geth-issue-14794] and motivated Trezor to [not implement the standard][trezor] as-is. Fortunately, it appears this flaw does not lead to actual collisions. It would easier to prove security if `len(b)` was left out entirely. It is also important that `len(b)` does not allow zero padding as that would fail the determinism criteria.

[geth-issue-14794]: https://github.com/ethereum/go-ethereum/issues/14794
[trezor]: https://github.com/trezor/trezor-mcu/issues/163

The point is, it is difficult to map arbitrary sets to bytestrings without introducing security issues in the encoding function. Yet the current design of `eth_sign` expects implements to do exactly that.

### Messages

The `eth_sign` call assumes messages to be bytestrings. In practice we are not hashing bytestrings but the collection of all semantically different messages of all different DApps 𝕄. This set is impossible to formalize, so we approximate it with the set of typed named structures 𝕊 and a domain separator 𝔹²⁵⁶ to obtain the set `𝔹²⁵⁶ × 𝕊`. The specification formalizes the set 𝕊 and provides a deterministic injective encoding function.

## Specification

<!-- The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumj, ethereumjs, ...).  -->

* `encode((d, s) : 𝔹²⁵⁶ × 𝕊) = "\x01" ‖ d ‖ encode(s)`
* `encode(s : 𝕊) = keccak256(schemaHash(s) ‖ data(s))`

The set 𝕊 consists of all instances of

[abi-types]: http://solidity.readthedocs.io/en/v0.4.21/abi-spec.html#types

* Value types:
  * `bytes1` to `bytes32`
  * `uint8` to `uint256` (but no `uint`)
  * `int8` to `int256` (but no `int`)
  * `bool`
  * `address` (but not specific contract instances)
  * Enums
* Dynamic types:
  * `bytes`
  * `bytes`
* Reference types:
  * Arrays
  * Structs



### Domain separator

The domain separator is a 256-bit nonce. It is mostly there to prevent collision of 



The specification is based on

* the `keccak256` hashing function,
* the SECP-256k1 ECDSA signature algorithm as specified in the yellow paper and
* [ABIv2 types][abiv2types].

[abiv2types]: https://solidity.readthedocs.io/en/develop/abi-spec.html#types

In pseudo code, the signing and verifying algorithms are as follows:

**Signing**: Suppose we want to sign a complex `message`, in pseudo code we would do the following:

1. Hash the type of the message. This is the same for every message of this type, an application specific constant. This function is described below.

```javascript
schemaHash = schemaHashFunction(typeof(message))
```

2. Hash the contents of the message is an unambiguous way. This function is described below.

```javascript
dataHash = dataHashFunction(message)
```

3. Combine both

```javascript
structHash = keccak256(schemaHash, dataHash)
messageHash = keccak256(domainSeparator, messageHash)
```

4. Sign using existing elliptic curve signature standards.

```javascript
(v, r, s) = ecdsa_sign(messageHash, privateKey)
bytes65 signature = v || r || s
```

**Verifying**:

1. Compute the `messageHash` identical to the above.
2. Verify using the existing elliptic curve signature verification, or use an ecrecover.


The JSON RPC call `eth_signTypedData` will take a type specification and JSON encoded data that matches the type specifications.


### Computation of `schemaHash`

The `schemaHash` computation is based on the [ABIv2 function signature encoding][abiv2-sig], with the following changes

[abiv2-sig]: https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector-and-argument-encoding

1. The full 32-byte output of `keccak256` is used instead of the first four bytes.
2. For tuples, the type name of the corresponding struct is prefixed to the tuple.
3. In tuples, after each type, a single space and the name of the parameter is specified.
4. All relevant struct types are declared sequentially in alphabetical order, with the exception of the `root` type, which is declared first.

The `root` of the schema is always a struct.

#### Example

```
struct Person {
    string name;
    address wallet;
}

struct Message {
    Person from;
    Person to;
    string message;
}
```

Then `schemaHash(Message)` is as follows:

```
bytes32 schemaHash = keccak256(
    "Message(Person from,Person to,string message)"
    "Person(string name,address wallet)"
  );
```

(Note that the string is split up in substrings for readability. The result is equivalent if all strings are concatenated).

### Computation of `dataHash`

All [elementary types][abitypes] from ABIv2 are padded to 32 bytes. Just like in ABIv2, this also includes `bytes32` and the like.

[abitypes]: https://solidity.readthedocs.io/en/develop/abi-spec.html#types

Arrays of fixed size are concatenated, with the encoding applied recursively.

The reference implementation will enter an infinite recursion when asked to hash a cyclical data structure. It is possible to solve this by maintaining a stack of visited addresses and using a stack index when revisiting a node. This should still lead to u

Similarly, a data structure that is a directed acyclic graph will be walked as if it is a tree. This can cause nodes to be hashed more than once. In the worst case this leads to an exponential growth in computation time. Memoization would solve this,


### `eth_signTypedData` JSON RPC


### Web3 interface


### Optimized EVM implementation

```javascript
struct Order {
    address from;
    address to;
    uint128 amount;
    uint64 timestamp;
    string message;
}

bytes32 constant ORDER_SCHEMA_HASH = keccak256(
  "Order(address from,address to,uint128 amount,"
  "uint64 timestamp,string message)");

function dataHash(Order order) returns (bytes32 hash) {
    
    // Compute sub-hashes
    bytes32 messageHash = keccak256(order.message);
    
    assembly {
        // Back up select memory 
        let temp1 := mload(sub(order, 32))
        let temp2 := mload(add(order, 128))
        
        // Write schemaHash and sub-hashes
        mstore(sub(order, 32), ORDER_SCHEMA_HASH)
        mstore(add(order, 128), messageHash)
        
        // Compute hash
        hash := keccak256(sub(order, 32), 192)
        
        // Restore memory
        mstore(sub(order, 32), temp1)
        mstore(add(order, 128), temp2)
    }
}
```

For this to work, the `Order` struct needs to be stored at an address higher than 32. Solidity currently reserves the lower addresses for internal use, so this requirement is already always satisfied.



### Solidity extensions

`Order.schemaHash` will return the schemaHash.

`keccak256(order)` will generate code for the above optimized implementation.

```
function verifySignature(Order order, uint8 v, bytes32 r, bytes32 s) {
    address signer = ecrecover(keccak256(order), v, r, s);
}
```



## Rationale

<!-- The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion. -->


### Schema hash

For the schema hash several alternatives where considered and rejected for the flaws mentioned:

**Alternative 1**: Use ABIv2 function signatures. `bytes4` is not enough to be collision resistant. Unlike function signatures, there is negligible runtime cost incurred by using longer hashes.

**Alternative 2**: ABIv2 function signatures modified to be 256-bit. While this unambigously captures type info, it does not capture any of the semantics other than the function. This is already causing a practical collision between ERC20's and ERC721's `transfer(address,uint256)`, where in the former the `uint256` revers to an amount and the latter to a unique id.

**Alternative 3**: 256-bit ABIv2 signatures extended with parameter names and type names. The `Message` example from a above would be encoded as `Message(Person(string name,address wallet) from,Person(string name,address wallet) to,string message)`. This is longer than the proposed solution. And indeed, the length of the string can grow exponentially in the length of the input (consider `struct A{B a;B b;}; struct B {C a;C b;}; …`). More importantly, it does not allow a schemaHash for a recursive data type (consider `struct List {uint256 value; List next;}`).

This progression leads us to the current specification. There are also some ideas that have been considered, but not implemented for reason.

**Idea 4**: Include a domain separator. When designing a specific message format, the message format designer generates a 256-bit random number, which is then combined with the schemaHash. This eliminates accidental collision of standards. This idea is not implemented because generating random numbers is error prone.

**TODO**: I'm actually in favour of Idea 4, should we include it? Yes!

**Idea 5**: Include the target contract address. Similar to the domain separator, except instead of a random number the address of the target contract is used. This assumes that only a single contract will be handling the signed messages, but in practices a signed message protocol may be used by multiple participants.

**Idea 6**: Include natspec documentation. This would include even more semantic information in the schemaHash and further reduces chances of collision. It would make the schemaHash mechanism very verbose. It also prevents the documentation from being extended and amended.

### Data hash

**Alternative 7**: Tight packing.

**Alternative 8**: ABIv2 encoding. Especially with the upcoming `abi.encode` it should be easy to use `keccak256(abi.encode(someStruct))` as the `dataHash`. The ABIv2 standard by itself fails the determinism security criteria. There are several valid ABIv2 encodings of the same data. It also does not incorporate type data, so the `schemaHash` would still be required for safety, requiring additional code. The current proposal is safer because type information is always included in the hash. Finally, the current standard allows for an efficient implementation that avoids copying of data.

**Alternative 9**: Recursive data/schema hash.

**TODO**: Actually, I like this. Why not?

**Idea 10**: Cyclical data structures.


### In place computation of hashes

The format of the encoding is designed to coincide with the in-memory representation. This allows for an efficient zero-copy implementation of the hashing functions:

It is entirely possible, and encouraged, for Solidity to make this the default behaviour when hashing a struct. The current implementation just hashes the pointer address, which is not very useful.

### `eth_signTypedData` JSON RPC

This EIP proposes a new JSON RPC method to the `eth` namespace: `eth_signTypedData`.

Parameters:
0. `TypedData` - Typed data to be signed
1. `Address` - 20 Bytes - Address of the account that will sign the messages

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
const signature = await web3.eth.signTypedData(typedData, signerAddress);
// or
const signature = await web3.personal.signTypedData(typedData, signerAddress, '************');
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

Signature will be returned in the same format as `eth_sign` (the ecSignature params concatenated together `(r + s + v)` and hex encoded.



## Backwards Compatibility

<!-- All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright. -->



`keccak256(order)` is already valid syntax in Solidity and it currently.

This is already valid Solidity syntax. The current behaviour is to compute the hash of the address of the Order struct. This is a breaking change, but it unlikely that the current behaviour is useful.



## Test Cases

<!-- Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable. -->


#### Examples

```
struct Order {
    address from;
    address to;
    uint128 amount;
    uint64 timestamp;
    string message;
}

function dataHash(Order order) returns (bytes32) {
    return keccak256(
        bytes32(order.from),
        bytes32(order.to),
        bytes32(order.amount),
        bytes32(order.timestamp),
        keccak256(order.message)
    );
}
```

```
struct Person {
    string name;
    address wallet;
}

struct Message {
    Person from;
    Person to;
    string message;
}

function dataHash(Person person) returns (bytes32) {
    return keccak256(
        keccak256(person.name),
        bytes32(person.wallet),
    );
}

function dataHash(Message message) returns (bytes32) {
    return keccak256(
        dataHash(message.from),
        dataHash(message.to),
        keccak256(message.message)
    );
}
```



## Implementation

<!-- The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details. -->



## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
