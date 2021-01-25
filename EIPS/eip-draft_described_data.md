---
eip: <to be assigned>
title: Described Data and Described Transactions
author: Richard Moore (@ricmoo), Nick Johnson (@arachnid)
discussions-to: <URL> @TODO
status: Draft
type: Standards Track
category: ERC
created: 2021-01-23
requires: [EIP-191](/EIPS/eip-191)
---

## Simple Summary

A technique for contract authors to enable wallets to provide
a human-readable description of what a given contract
interaction (via a transaction or signed message) will perform.


## Abstract

Human-readable descriptions for machine executable operations,
described in higher level machine readable data, so that wallets
can provide meaningful feedback to the user describing the
action the user is about to perform.


## Motivation

When using an Ethereum Wallet (e.g. MetaMask, Clef, Hardware
Wallets) users must accept and authorize signing messages or
sending transactions.

Due to the complexity of Turing Completeness, the description a
Wallet can possibly come up with for some binary data to the
user is often difficult to understand, and possibly impossible
in the case the wallet is asked to sign an arbitrary hash of
some data.

This EIP presents a method for dapp developers to enable a more
comfortable user experience by providing wallets with a means
to generate a better description about what the contract claims
will happen.

It does not address malicious contracts which wish to lie, it
only addresses honest contracts that want to make their user's
life better. Security must be handled orthogonally.


## Specification

The **description string** and **described data** are generated
simultaneously by evaluating **describer** bytecode, passed
**describedInput** as the calldata with the encoded method:

```solidity
function eipXXXDescription(bytes inputs) view returns (string description, bytes data);
```

The method MUST be executable in a static context, i.e. any
logX, sstore, etc., (including through indirect calls) MUST
revert. Note that calling VALUE in a static context is
permitted, and useful for transactions, such as the `mint()`
function in WETH, which may wish to describe the amount of
ether that will be wrapped.

During evaluation, the `ADDRESS` (i.e. `to`), `CALLER`
(i.e. `from`), `VALUE`, and `GASPRICE` must be correctly passed
in so the EVM operates correctly. For signing
**described messages**, `VALUE` should always be 0.

When executing the bytecode, best efforts should be made to
ensure `BLOCKHASH`, `NUMBER`, `TIMESTAMP` and `DIFFICULTY`
match the `"latest"` block. The `COINBASE` should be the zero
address.

If the execution result is of a length that is congruent to
`4 mod 32`, and the first 4 bytes represent the selector
`Error(string)`, the reason string should be displayed to the
user. If the result length is otherwise not congruent to
`0 mod 32`, then a generic evaluation error should be shown.
In either case, the signing is aborted.


### New JSON-RPC Methods

Clients which manage private keys should expose additional
methods for interacting with the related accounts.

If an user interface is not present or expected for any other
account-based operations, the description strings should be
ignored and the described data used directly.

These JSON-RPC methods will also be implemented in standard
Ethereum libraries, so the JSON-RPC description is meant more
of a canonical way to describe them.


### Signing Described Messages

```solidity
eth_signDescribedMessage(address, describer, describerInput)
// Result: {
//   description: "text/plain;Hello World",
//   data: "0x...", // described data
//   signature: "0x..."
// }
```

Compute the **description string** and **described data** by
evaluating the call to **describer**, with the
**describerInput** passed to the ABI encoded call to
`eipXXXDescription(bytes)`. The `VALUE` during execution must
be 0.

If the wallet contains a user interface for accepting or
denying signing a message, it should present the description
string to the user. Optionally, a wallet may wish to
additionally provide a way to examine the described data.

If accepted, the computed **described data** is signed
acording to EIP-191, with the *version
byte* of `0xTBD` and the *version specific data* of describer
address.

That is:

```
0x19   0xTBD   DESCRIBER_ADDRESS   0xDESCRIBED_DATA
```

The returned result includes the **described data**, allowing
dapps that use paramters computed in the contract to be
available.

### Sending Described Transactions

```solidity
eth_sendDescribedTransaction(address, {
  to: "0x...",
  value: 1234,
  nonce: 42,
  gas: 42000,
  gasPrice: 9000000000,
  describerInput: "0x1234...",
})
// Result: {
//   description: "text/plain;Hello World",
//   transaction: "0x...", // serialized signed transaction
// }
```

Compute the **description string** and **described data** by
evaluating the call to the **describer** `to`, with the
**describerInput** passed  to the ABI encoded call to
`eipXXXDescription(bytes)`.

If the wallet contains a user interface for accepting or
denying a transaction, it should present the description string
along with fee and value information. Optionally, a wallet may
wish to additionally provide a way to further examine the
transaction.

If accepted, the transaction data is set to the computed
**described data**, the derived transaction is signed and sent,
and the **description string** and serialized signed
transaction is returned.


### Signing Described Transaction

```solidity
eth_signDescribedTransaction(address, {
  to: "0x...",
  value: 1234,
  nonce: 42,
  gas: 42000,
  gasPrice: 9000000000,
  describerInput: "0x1234...",
})
// Result: {
//   description: "text/plain;Hello World",
//   transaction: "0x...", // serialized signed transaction
// }
```

Compute the **description string** and **described data** by
evaluating the call to the **describer** `to`, with the
**describerInput** passed  to the ABI encoded call to
`eipXXXDescription(bytes)`.

If the wallet contains a user interface for accepting or
denying a transaction, it should present the description string
along with fee and value information. Optionally, a wallet may
wish to additionally provide a way to further examine the
transaction.

If accepted, the transaction data is set to the computed
**described data**, the derived transaction is signed (and not
sent) and the **description string** and serialized signed
transaction is returned.

### Description Strings

A **description string** must begin with a mime-type followed
by a semi-colon (`;`). This EIP specifies only the `text/plain`
mime-type, but future EIPs may specify additional types to
enable more rich processing, such as `text/markdown` so that
addresses can be linkable within clients or to enable
multi-locale options, similar to multipart/form-data.


## Rationale

### Meta Description

There have been many attemps to solve this problem, many of
which attempt to examine or encode the final transaction data
or message data.

In many cases, the data that would be necessary for the
description is not present in the transaction data or message
data.

Instead this EIP uses an indirect description of the data.

For example, the `commit(bytes32)` method of ENS places a
commitement **hash** on-chain which is the *blinded* name and
address; since the name is blinded in the data, it is not
available to be described.

By instead describing the commitment indirectly, the name and
address are still available, so a meaningful description can be
derived (e.g. "commit to NAME for ADDRESS") and the matching
data can be computed (i.e. `commit(hash(name, owner, secret))`).

### Alternatives

- [NatSpec](https://docs.soliditylang.org/en/latest/natspec-format.html) and company; these languages are usually quite large and complex, requiring entire JavaScript VMs with ample processing power and memory, as well as additional sandboxing to reduce security concerns. One goal of this is to reduce the complexity to something that could execute on hardware wallets and other simple wallets.

- Custom Languages; whatever language is used requires a level of expressiveness to handle a large number of possibilities and re-inventing the wheel. EVM already exists (it may not be ideal), but it is there and can handle everything necessary.

- The data A used to describe operated on the data and attempted to describe it; often the data 

- The signTypedData [EIP-712](/EIPs/eip-712) has many parallels to what this EIP aims to solve

- @TOOD: More


## Backwards Compatibility

All signatures are generated using EIP-191
with the previously unused *version byte* `0xTBD`, so there
should be no concerns with backwards compatibility.


## Test Cases

All test cases below use the private key `TBD`.

## Messages

```
Input:
  Address: @TODO
  Describer Bytecode:
  Describer Input:

Output:
  Description String: @TODO
  Described Data:     @TODO

Signing:
  Preimage:  @TODO
  Signature: @TODO
```

## Transactions

### Standard ERC-20 Interactions

```
Input:
  Described Bytecode: @TODO: 
  // - Could query ENS for reverse records
  // - Could query contract "symbol" from `to` field (via: `address` opcode?)
  // ABI Encoded (bytes4, address, uint) which the bytecode can decode; each value is 32-byte aligned
  //                      Selector       Address                                        Amount  
  Described Input:    0x  00...a9059cbb  00...8ba1f109551bd432803012645ac136ddd64dba72  00...de0b6b3a7640000

Output:
  Description String: "text/plain;Send 4 DAI to ricmoo.firefly.eth"
  Described Data:     0xa9059cbb0000000000000000000000008ba1f109551bd432803012645ac136ddd64dba720000000000000000000000000000000000000000000000000de0b6b3a7640000

Signing:
  Serializalized Unsigned Transaction: @TODO
  Signature:                           @TODO
```

```
Input:
  Described Bytecode: @TODO
  // ABI Encoded (bytes4, address, uint) which the bytecode can decode; each value is 32-byte aligned
  //                      Selector       Address                                        Amount  
  Described Input:    0x  00...095ea7b3  00...8ba1f109551bd432803012645ac136ddd64dba72  00...de0b6b3a7640000

Output:
  Description String: "text/plain;Approve 0x1234...5678 to spend up to 1.0 DAI on your behalf."
  Described Data:     0x095ea7b30000000000000000000000008ba1f109551bd432803012645ac136ddd64dba720000000000000000000000000000000000000000000000000de0b6b3a7640000

Signing:
  Serializalized Unsigned Transaction: @TODO
  Signature:                           @TODO
```

### Minting (e.g. WETH)

```
Input:
  Describer Bytecode: @TODO 
  //                     selector("Mint()")
  Describer Input:    0x 00...1249c58b
  Value:              1e18 wei

Output:
  Description String: 'text/plain;Wrap (spend) 1.0 ether and mint 1.0 WETH to "ricmoo.firefly.eth" (0x8ab...d2).'
  Described Data:     0x1249c58b

Signing:
  Serializalized Unsigned Transaction: @TODO
  Signature:                           @TODO
```

### ERC-721 (e.g. Cryptokitties)

```
Input:
  Describer Bytecode: @TODO 
  //                     selector("Mint()")
  // ABI Encoded (bytes4, address, uint) which the bytecode can decode; each value is 32-byte aligned
  //                      Selector       Address                                        TokenID  
  Described Input:    0x  00...a9059cbb  00...8ba1f109551bd432803012645ac136ddd64dba72  00...539

Output:
  Description String: 'text/plain;Transfer kitty #1337 to "ricmoo.firefly.eth" (0x8ab...d2).'
  Described Data:     0x1249c58b

Signing:
  Serializalized Unsigned Transaction: @TODO
  Signature:                           @TODO
```

### ERC-721 (e.g. ENS)

```
Input:
  Describer Bytecode: @TODO 
  //                     register(string name, address owner, uint duration, buytes32 secret)
  Described Input:    abi.encode([
                        id("register(string,address,uint256,bytes32)"),
                        "ricmoo",
                        0x1234,
                        1234,
                        0x1234
                      ])
  Value:              123 wei

Output:
  // Optional; this could check the committment exists? Would break pre-signing transactions though
  // Can do sanity checks on duration, price, etc.
  Description String: 'text/plain;Register the name "ricmoo.eth" for 3 months for 1.25 DAI (up to 0.123 ether will be converted at the market price).'
  Described Data:     0x85f6d155 @TODO

Signing:
  Serializalized Unsigned Transaction: @TODO
  Signature:                           @TODO
```


## Reference Implementation

@TODO (consider adding it as one or more files in `../assets/eip-####/`)

I will add examples in Solidity and JavaScript.


## Security Considerations

### Escaping Text

Wallets must be careful when displaying text provided by
contracts and proper efforts must be taken to sanitize
it, for example, be sure to consider:

- HTML could be enbedded to attempt to trick web-based wallets into [executing code](https://en.wikipedia.org/wiki/Code_injection) using the script tag (possibly uploading any private keys to a server)
- Other marks which require escaping could be included, such as quotes (`"`), formatting (`\n` (new line), `\f` (form feed), `\t` (tab), any of many [non-standard whitespaces](https://en.wikipedia.org/wiki/Whitespace_character#Spaces_in_Unicode)), back-slassh (`\`)
- UTF-8 has had bugs in the past which could allow arbitrary code execution and [crashing renderers](https://osxdaily.com/2015/05/27/bug-crashes-messages-app-ios-workaround/); consider using the UTF-8 replacement character (or *something*) for code-points outside common planes or common sub-sets within planes
- [Homoglyphs attacks](https://en.wikipedia.org/wiki/IDN_homograph_attack)
- [Right-to-left](https://en.wikipedia.org/wiki/Right-to-left_mark) mark may affect rendering
- Many other things, deplnding on your environment

### Distinguished Signed Data

Applications implementing this EIP to sign message data should
ensure there are no collisions within the data which could
result in ambiguously signed data.

@TODO: Expand on this; compare packed data to ABI encoded data?

### Enumeration

If an abort occurs during signing, the response from this call
should match the response from a declined signing request;
otherwise this could be used for enumeration attacks, etc. A
random interactive-scale delay should also be added, otherwise
a < 10ms response could be interpreted as an error.

### Replayablility

Transactions contain an explicit nonce, but signed messages do
not.

For many purposes, such as signing in, a nonce could be
injected (using block.timestamp) into the data. The log in
service can verify this is a recent timestamp. The timestamp
may or may not be omitted from the description string in this
case, as it it largely useful internally only.

In general, when signing messages a nonce often makes sense to
include to prevent the same signed data from being used in the
future.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

----

# Draft notes and thoughts

Below are some notes to move above, discuss or otherwise. This will be removed
or moved above to meaningful sections

**NOTES:**

- Clients should perform addditional due diligence when describing addresses, for example via reverse records
- Hardware wallets can be fed the required results from eth_getProof along with the describer and display on-device the expected operation
- I am assuming there will be an invalid byte as an opcode that starts a eWASM so that those fail on EVM, and are identifable on compatible engines; this should allow this to be backwards and forwards compatible too
- While Solidity is not awesome at string manipulation, there is nothing precluding a new compiler which simplifies string operations that compiles to bytecode or more advanced string libraries.
- For popular legacy contracts, bytecode can be baked into wallets, or deployed on chain with the describer address baked in
- When signing described data, the `to` address must be entangled in the signature to prevent replaying. In the case of transactions, this is implicitly handled by the `to` in the transaction. In messages, this is handled by including the to address in the EIP-191 *version specific data*. This is similar to the domain in [EIP-712](/EIPS/eip-712), but allows for the dapp developer to define their own replay strategy (if any is desired)
- Localization is quite important; there should be a way to encode this... This can be a separate EIP
- Should a simple Markdown be supported? Keep in mind chain data must then be markdown-escaped.

**Desired Features:**

- Simple
- re-invent as few wheels as possible
