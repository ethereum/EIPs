---
eip: <to be assigned>
title: Described Data and Described Transactions
author: Richard Moore (@ricmoo), Nick Johnson (@arachnid)
discussions-to: <URL> @TODO
status: Draft
type: Standards Track
category: ERC
created: 2021-01-23
requires: 191
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

Due to the complexity of Ethereum transactions, wallets are very
limitd in their ability to provide insight into the contents of
transactions user are approving; outside special-cased support
for common transactions such as ERC20 transfers, this often amounts
to asking the user to sign an opaque blob of binary data.

This EIP presents a method for dapp developers to enable a more
comfortable user experience by providing wallets with a means
to generate a better description about what the contract claims
will happen.

It does not address malicious contracts which wish to lie, it
only addresses honest contracts that want to make their user's
life better. We believe that this is a reasonable security model,
as transaction descriptions can be audited at the same time as
contract code, allowing auditors and code reviewers to check that
transaction descriptions are accurate as part of their review.


## Specification

The **description string** and **described data** are generated
simultaneously by evaluating **describer** bytecode, passed
**describedInput** as the calldata with the encoded method:

```solidity
function eipXXXDescribe(bytes inputs) view returns (string description, bytes data);
```

The method MUST be executable in a static context, i.e. any
side effects (logX, sstore, etc., (including through indirect
calls) will be ignored.

During evaluation, the `ADDRESS` (i.e. `to`), `CALLER`
(i.e. `from`), `VALUE`, and `GASPRICE` must be the same as the
values for the transaction being described, so that the
code generating the description can rely on them. For signing
**described messages**, `VALUE` should always be 0.

When executing the bytecode, best efforts should be made to
ensure `BLOCKHASH`, `NUMBER`, `TIMESTAMP` and `DIFFICULTY`
match the `"latest"` block. The `COINBASE` should be the zero
address.

If evaluating the function results in a revert, and the return
data is of a length that is congruent to `4 mod 32`, and the
first 4 bytes represent the selector `Error(string)`, the
reason string should be displayed to the user. If evaluation
reverts otherwise, then a generic evaluation error should be shown.
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
acording to [EIP-191](./eip-191.md), with the *version
byte* of `0x00` and the *version specific data* of describer
address.

That is:

```
0x19   0x00   DESCRIBER_ADDRESS   0xDESCRIBED_DATA
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

There have been many attempts to solve this problem, many of
which attempt to examine the encoded transaction data or
message data directly.

In many cases, the information that would be necessary for a
meaningful description is not present in the final encoded
transaction data or message data.

Instead this EIP uses an indirect description of the data.

For example, the `commit(bytes32)` method of ENS places a
commitement **hash** on-chain. The hash contains the
**blinded** name and address; since the name is blinded, the
encoded data (i.e. the hash) no longer contains the original
values and is insufficient to access the necessary values to
be included in a description.

By instead describing the commitment indirectly (with the
original information intact: NAME, ADDRESS and SECRET) a
meaningful description can be computed (e.g. "commit to NAME for ADDRESS (with SECRET)")
and the matching data can be computed (i.e. `commit(hash(name, owner, secret))`).

### Alternatives

- [NatSpec](https://docs.soliditylang.org/en/latest/natspec-format.html) and company; these languages are usually quite large and complex, requiring entire JavaScript VMs with ample processing power and memory, as well as additional sandboxing to reduce security concerns. One goal of this is to reduce the complexity to something that could execute on hardware wallets and other simple wallets.

- Custom Languages; whatever language is used requires a level of expressiveness to handle a large number of possibilities and re-inventing the wheel. EVM already exists (it may not be ideal), but it is there and can handle everything necessary.

- The data A used to describe operated on the data and attempted to describe it; often the data 

- The signTypedData [EIP-712](/EIPs/eip-712) has many parallels to what this EIP aims to solve

- @TOOD: More


## Backwards Compatibility

All signatures for messages are generated using [EIP-191](./eip-191.md)
which had a previously compatible version byte of `0x00`, so
there should be no concerns with backwards compatibility.


## Test Cases

All test cases below use the private key:

```
privateKey = "0x6283185307179586476925286766559005768394338798750211641949889184";
```

## Messages

## Messages

```
Example: login with signed message
  - sends selector login()
  - received data with selector doLogin(bytes32 timestamp)
Input:
  Address:         0x8325Ca88cbA1c533ec75D0E9AF9c3feE7780c19D
  Describer Input: 0xb34e97e800000000000000000000000000000000000000000000000000000000

Output:
  Description: Log into ethereum.org?
  Data: 0x14629d780000000000000000000000000000000000000000000000000000000060101f06

Signing:
  Preimage:  0x19008325ca88cba1c533ec75d0e9af9c3fee7780c19d14629d780000000000000000000000000000000000000000000000000000000060101f06
  Signature: 0x40e7e79b8c550899d76bcc45a4aebe1c1b0aef8931c21a1975cfe273728df3905a83335bfaa5cb2137c7430b36af93138e578cb4538dfc4276d20be64955dab01b
```

## Transactions

All transaction test cases use the ropsten network (chainId: 3)
and for all unspecified properties use 0.

```
Example: ERC-20 transfer
Input:
  Address:            0x8325Ca88cbA1c533ec75D0E9AF9c3feE7780c19D
  Describer Input:    0xa9059cbb000000000000000000000000000000000000000000000000000000000000000000000000000000008ba1f109551bd432803012645ac136ddd64dba720000000000000000000000000000000000000000000000002b992b75cbeb6000

Output:
  Description:        text/plain;Send 3.14159 TOKN to "ricmoose.eth" (0x8ba1f109551bD432803012645Ac136ddd64DBA72)?
  Described Data:     0xa9059cbb0000000000000000000000000000000000000000000000002b992b75cbeb60000000000000000000000000008ba1f109551bd432803012645ac136ddd64dba72

Signing:
  Signed Transaction: 0xf8a2808080948325ca88cba1c533ec75d0e9af9c3fee7780c19d80b844a9059cbb0000000000000000000000000000000000000000000000002b992b75cbeb60000000000000000000000000008ba1f109551bd432803012645ac136ddd64dba7229a00895b3aba1e82140682827a60a9e9483a6addf4992813ee9b1f99993703f36f7a06e39c89c013b67dced7c1dd58e49496a20697c58deb875db8a1243f747544c2f
```

```
Example: ERC-20 approve
Input:
  Address:            0x8325Ca88cbA1c533ec75D0E9AF9c3feE7780c19D
  Describer Input:    0x095ea7b3000000000000000000000000000000000000000000000000000000000000000000000000000000008ba1f109551bd432803012645ac136ddd64dba720000000000000000000000000000000000000000000000002b992b75cbeb6000

Output:
  Description:        text/plain;Approve "ricmoose.eth" (0x8ba1f109551bD432803012645Ac136ddd64DBA72) to manage 3.14159 TOKN tokens?
  Described Data:     0xa9059cbb0000000000000000000000000000000000000000000000002b992b75cbeb60000000000000000000000000008ba1f109551bd432803012645ac136ddd64dba72

Signing:
  Signed Transaction: 0xf8a2808080948325ca88cba1c533ec75d0e9af9c3fee7780c19d80b844a9059cbb0000000000000000000000000000000000000000000000002b992b75cbeb60000000000000000000000000008ba1f109551bd432803012645ac136ddd64dba7229a00895b3aba1e82140682827a60a9e9483a6addf4992813ee9b1f99993703f36f7a06e39c89c013b67dced7c1dd58e49496a20697c58deb875db8a1243f747544c2f
```

```
Example: ENS commit
Input:
  Address:            0x8325Ca88cbA1c533ec75D0E9AF9c3feE7780c19D
  Describer Input:    0x0f0e373f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000e31f43c1d823afaa67a8c5fbb8348176d225a79e65462b0520ef7d3df61b9992ed3bea0c56ead753be7c8b3614e0ce01e4cac41b00000000000000000000000000000000000000000000000000000000000000087269636d6f6f7365000000000000000000000000000000000000000000000000

Output:
  Description:        text/plain;Commit to the ENS name "ricmoose.eth" for 0xE31f43C1d823AfAA67A8C5fbB8348176d225A79e?
  Described Data:     0xf14fcbc8e4a4f2bb818545497be34c7ab30e6e87e0001df4ba82e7c8b3f224fbaf255b91

Signing:
  Signed Transaction: 0xf881808080948325ca88cba1c533ec75d0e9af9c3fee7780c19d80a4f14fcbc8e4a4f2bb818545497be34c7ab30e6e87e0001df4ba82e7c8b3f224fbaf255b912aa0717a6833ccfd1b9b441cf3a283b90ea68e333305d544bb18ecca2181ef5ac619a0190595552265807c95968f9a2ac47b69796c5b41e0ec51ff389f0347737e8cda
```

```
Example: WETH mint()
Input:
  Address:            0x8325Ca88cbA1c533ec75D0E9AF9c3feE7780c19D
  Describer Input:    0x1249c58b00000000000000000000000000000000000000000000000000000000

Output:
  Description:        text/plain;Mint 1.23 WETH (spending 1.23 ether)?
  Described Data:     0x1249c58b

Signing:
  Signed Transaction: 0xf869808080948325ca88cba1c533ec75d0e9af9c3fee7780c19d881111d67bb1bb0000841249c58b2aa0e8a77166d32e1011b02067d777e5e484fbd89911805694ccb5757eb2094a79b4a0627f58532c68010f9a5736bcba6fe8e97c603dc77e2aea0371cf4120bf26d35d
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
- In general, extreme care must be used when rendering HTML; consider the ENS names `<span style="display:none">not-</span>ricmoo.eth` or `&thinsp;ricmoo.eth`, which if rendered without care would appear as `ricmoo.eth`, which it is not
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
- When signing described data, the `to` address must be entangled in the signature to prevent replaying. In the case of transactions, this is implicitly handled by the `to` in the transaction. In messages, this is handled by including the to address in the EIP-191 *version specific data*. This is similar to the domain in [EIP-712](./eip-712.md), but allows for the dapp developer to define their own replay strategy (if any is desired)
- Localization is quite important; there should be a way to encode this... This can be a separate EIP
- Should a simple Markdown be supported? Keep in mind chain data must then be markdown-escaped.

**Desired Features:**

- Simple
- re-invent as few wheels as possible
