---
eip: <to be assigned>
title: App Keys: app specific accounts
author: 
Vincent Eli @Bunjin
Dan Finlay @DanFinlay
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2019-02-20
requires (*optional): BIP32, EIP137, EIP165, 
replaces (*optional): EIP 1581
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

Among others cryptographic applications, scalability and privacy solutions for ethereum blockchain require that an user performs a significant amount of signing operations. It may also require her to watch some state and be ready to sign data automatically (e.g. sign a state or contest a withdraw in a state channel). The way wallets currently implement accounts poses several obstacles to the development of a complete web3.0 experience both in terms of UX, security and privacy.

This proposal describes a standard and api for a new type of wallet accounts that are derived specifically for a each given app. We propose to call them `app keys`. These accounts allow to isolate the accounts used for each app, thus increasing privacy. They also allow to give more control to the applications developpers over accounts management and signing delegation. For these app keys, wallets can have a more permissive level of security (e.g. not requesting user's confirmation) while keeping main accounts secure. Finally wallet can also implement a different behavior such as allowing to sign transactions without broadcasting them.

This new accounts type can allow to significantly improve UX and permit new designs for apps of the crypto permissionned web.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
In a wallet, an user often holds most of her funds in her main accounts. These accounts require a significant level of security and should not be delegated in any way, this significantly impacts the design of crypto apps if a user has to manually confirm every transaction. Also often an user uses the same accounts accross apps, which is a privacy and potentially also a security issue.

We introduce here a new account type, app keys, which permits signing delegation and accounts isolation accross apps for privacy and security.

In this EIP, we provide a proposal how to uniquely identify and authenticate each app, how to derive the accounts along an HDpath restricted for the domain and we finally define an API for apps to derive and use these app keys.
This ERC aims at finding a standard that will fit the needs of wallets and application developers while also allowing app keys to be used across wallets and yield the same accounts for the user for each app.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Wallets developers have agreed on an HD derivation path for ethereum accounts using BIP32, BIP44, SLIP44, [ERC84](https://github.com/ethereum/EIPs/issues/84). Web3 wallets have implemented in a roughly similar way the rpc eth api. EIP 1102 introduced privacy through non automatic opt-in of a wallet account into an app increasing privacy.

However several limitations remain in order to allow for a proper designs and UX for crypto permissioned apps.

Most of UI based current wallets don't allow to:
* being able to automatically and effortlessly use different keys / accounts for each apps,
* being able to sign some app's action without prompting the user with the same level of security as sending funds from their main accounts,
* being able to use throwable keys to improve anonymity,
* effortlessly signing transactions for an app without broadcasting these while still being able to perform other transaction signing as usual from their main accounts,
* All this while being fully restorable using the user's mnemonic or hardware wallet and the HD Path determined uniquely by the app's ens name.

We try to overcome these limitations by introducing a new account's type, app keys, made to be used along side the existing main accounts.

These new app keys can permit to give more power and flexibility to the crypto apps developers. This can allow to improve a lot the UX of crypto dapps and to create new designs that were not possible before leveraging the ability to create and handle many accounts, to presign messages and broadcast them later. These features were not compatible with the level of security we were requesting for main accounts that hold most of an user's funds.


## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

### Apps

An app is a website (or other) that would like to request from a wallet to access app keys. It can be any form of cryptography/identity relying application, ethereum but not only.

Once connected to a wallet, an application can request to access a set of accounts derived exclusively for that application using the hierarchical deterministic (HD) paths.

### HD path

Using the BIP 32 and BIP 39 standards, we propose to use the following HD path for each app keys:

`m/ [EIP#]' / [persona path]' / [application uniquely assigned path]' / [app's custom subpath]`

Where:

`EIP#` is the EIP number that will be assigned to this EIP and we harden it. We use a different path than 44' since it's not bip44 compliant. [At this point, I'm not sure if there is a list of alternative standards to BIP44 codes]

`persona path` allows to use applications with different and isolated personas (or in other words accounts) that are tracable by the application. They will still be fully restorable from the same mnemonic.

`application uniquely assigned path` isolate each application along unique branches of the tree through these unique subPath combination.

`app's custom subPath` give freedom to application to use this BIP32 compliant subPath to manage accounts and other needed parameters.

Note that we suggest that each of these indexes, except those belonging to the app's custom subpath, must be hardened to fully isolate the public keys across personas and applications.

#### Apps' Unique Identifiers

We need a way to uniquely identify each App.

In our favored spec, each app is uniquely defined and authentified by its name, a domain string. For apps to be resolved through the Ethereum Name Service (ENS), they need to be a using a .eth domain name (e.g. foo.bar.eth). Note that the proposed spec does not restrict the apps' names to be following the .eth standard but they would need to be authentified differently (see below). 

There are a few restrictions however on the characters used and normalisation, each name should be passed through the [NamePrep Algorithm](https://tools.ietf.org/html/rfc3491)

In addition there must be a maximum size to the domain string that we need to determine such that the mapping from strings to nodes remains injective, to avoid collision.

We recommand this standard to be following the [ENS Specs](http://docs.ens.domains/en/latest/implementers.html#namehash), reproduced below for convinience and reference.
```
Normalising and validating names
Before a name can be converted to a node hash using Namehash, the name must first be normalised and checked for validity - for instance, converting fOO.eth into foo.eth, and prohibiting names containing forbidden characters such as underscores. It is crucial that all applications follow the same set of rules for normalisation and validation, as otherwise two users entering the same name on different systems may resolve the same human-readable name into two different ENS names.
```



The ENS uses an hashing scheme to associate a domain to a unique hash, `node`, through the `namehash` function

This gives an unique identifier (UID) of 32 bytes.

```
e.g. for foo.bar.eth
app's uid 0x6033644d673b47b3bea04e79bbe06d78ce76b8be2fb8704f9c2a80fd139c81d3
```

For referenceHere are the specs of ENS:

```
domain - the complete, human-readable form of a name; eg, ‘vitalik.wallet.eth’.
label - a single component of a domain; eg, ‘vitalik’, ‘wallet’, or ‘eth’. A label may not contain a period (‘.’).
label hash - the output of the keccak-256 function applied to a label; eg, keccak256(‘eth’) = 0x4f5b812789fc606be1b3b16908db13fc7a9adf7ca72641f84d75b47069d3d7f0.
node - the output of the namehash function, used to uniquely identify a name in ENS.
Algorithm
First, a domain is divided into labels by splitting on periods (‘.’). So, ‘vitalik.wallet.eth’ becomes the list [‘vitalik’, ‘wallet’, ‘eth’].

The namehash function is then defined recursively as follows:

namehash([]) = 0x0000000000000000000000000000000000000000000000000000000000000000
namehash([label, …]) = keccak256(namehash(…), keccak256(label))

keccak256(‘eth’) = 0x4f5b812789fc606be1b3b16908db13fc7a9adf7ca72641f84d75b47069d3d7f0

```

We thus propose to use the node of each app's domain as a unique identifier for each app but one can think of other UIDs, we include some alternative specs in the `Rationale` section below.

#### App's authentication

In the case of our favored specification for apps' UIDs using ENS, we can authenticate the app through ens resolution.
The ENS can also allow to register and resolve metadata for the app such as `url`, and other parameters.

If we use for instance this resolver profile defined in [EIP 634](https://eips.ethereum.org/EIPS/eip-634) which permits the lookup of arbitrary key-value text data, we can for instance use the key `url` to point to a website. 




```
A new resolver interface is defined, consisting of the following method:

function text(bytes32 node, string key) constant returns (string text);
The interface ID of this interface is 0x59d1d43c.

The text data may be any arbitrary UTF-8 string. If the key is not present, the empty string must be returned.
```

One can think of other authentification methods and even use some of them alongside the url-resolution method through ENS. We mention other methods in the `Rationale` section.

We suggest for instance to also add an `authorEthAddress` text  metadata field that can be used to authenticate message from the app, with for instance a sign challenge.


### Personas

We allow the user to use different personas in combination to her mnemonic to potentially fully isolate her interact with a given app accross personas. One can use this for instance to create a personal and business profile for a given's domain both backup up from the same mnemonic, using 2 different personnas indexes. The app or domain, will not be aware that it is the same person and mnemonic behind both.

We use a string following BIP32 format (can be hardened) to define personas

e.g. `0'` or `0'/1/2'/0`




#### domain's uid hash decomposition to get an Hd path 

Since each child index in an HD path only has 31 bits we will decompose the domain's hash as several child indexes, first as hex bytes then parsed as integers

If for the domain uid we use an `ENS namehash` of 32 bytes, 256 bits

e.g. `foo.bar.eth` gives namehash
`0x6033644d673b47b3bea04e79bbe06d78ce76b8be2fb8704f9c2a80fd139c81d3`

We can decompose it in several ways, here are 2 potential ways:

-approach that favors having the least indexes

```
x = x0 || x1 || x2 || x3 || x4 || x5 || x6 || x7 || x8
```
where `x0` to `x7` are 30 bits and `x8` 16 bits

-approach that favors an homogenous decomposition:
equal length would be 16 * 16 bits or in other words 16 * 2 bytes, cleanest and favored spec:
```
x = x0 || x1 || x2 || x3 || x4 || x5 || x6 || x7 || x8 || x9 || x10 || x11 || x12 || x13 || x14 || x15
```
```
foo.bar.eth
0x6033644d673b47b3bea04e79bbe06d78ce76b8be2fb8704f9c2a80fd139c81d3
6033 644d 673b 47b3 bea0 4e79 bbe0 6d78 ce76 b8be 2fb8 704f 9c2a 80fd 139c 81d3
6033'/644d'/673b'/47b3'/bea0'/4e79'/bbe0'/6d78'/ce76'/b8be'/2fb8'/704f'/9c2a'/80fd'/139c'/81d3'
24627'/25677'/26427'/18355'/48800'/20089'/48096'/28024'/52854'/47294'/12216'/28751'/39978'/33021'/5020'/33235'
```



does not seem to really matter which we pick between the 2 decomposition approaches,
Maybe favor the one that leads to less indexes, less computations
alternative has the benefit of being much cleaner, especially for the 256 bits decompositions

### App custom sub path

hdSubPath

with uint under 0x80000000, 31 bits

should follow bip32

can be hardened

can be writen in hex or int


### Example HD paths for app keys:
EIP#: 12345
personaPath: 0
uid: 4f5b 8127 89fc 606b e1b3 b169 08db 13fc 7a9a df7c a726 41f8 4d75 b470 69d3 d7f0
app custom path params: (entirely customisable by app under BIP32 standard) app_version set_of_accounts_index, change_index, account_index

`m/0'/12345'/4f5b'/8127'/89fc'/606b'/e1b3'/b169'/08db'/13fc'/7a9a'/df7c'/a726'/41f8'/4d75'/b470'/69d3'/d7f0'/app_version'/a'/0/n`

## API:

### App keys exposure:

* `wallet.appkey.enable()`

uses the persona selected by the user (not known nor shared with app)

uses the domain ens namehash (node) that was resolved to load window (not  by app)

depending on user choice, user will be prompted for signing confirmations or not for those app keys

### Global HD methods:
none

### Ethereum accounts methods:

* `appKey_eth_getPublicKey(hdSubPath) returns 64 bytes`
0x80b994e25fb98f69518b1a03e59ddf4494a1a86cc66019131a732ff4a85108fbb86491e2bc423b2cdf6f1f0f4468ec73db0535a1528ca192d975116899289a4b

* `appKey_eth_getAddress(hdSubPath) returns 20 bytes`
hdSubPath: string
"index_i / index_(i+1) '", can use hardening
e.g. 0x9df77328a2515c6d529bae90edf3d501eaaa268e 

* `appKey_eth_derivePublicKeyFromParent(parentPublicKey, hdSubPath) returns 64 bytes`
hdSubPath: string should not be hardened

* `appKey_eth_getAddressForPublicKey(publicKey) returns 20 bytes`
publicKey 64 bytes

### Ethereum signing methods:

* `appKey_eth_signTransaction(fromAddress, tx)`
tx is ethereum-js tx object

* `appKey_eth_sign(fromAddress, message)`
* `appKey_eth_personalSign(fromAddress, message)`
* `appKey_eth_signTypedMessage(fromAddress, message)`

### Other potential methods:
#### other cryptocurrencies
#### other crypto
* `encrypt() [TBD]`
Request Encryption

* `decrypt() [TBD]`
Request Decryption
#### cross domain communication / signing
#### storage
* `persistInDb(key, data)  [TBD] `:
Store in MetaMask localdb, specific store for plugin

* `readInDb(key) returns data [TBD] `:


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
### Isolated paths but customisable

### persona isolation for privacy

### hardening for privacy
hardening has benefits for security and privacy if parent extended public key is known, public keys of child of hardened indexes can not be computed.
hardened indexes in case some extended public key leaks at some previous level of the tree, protects the sub trees (of course this has no impact if private keys leak)

However the app can use non hardened indexes in their custom path part to be able to benefit from guessing child public keys from parent one (for instance for counterfactual state channel interaction accross 2 peers that would like to use new keys every time they counterfactually instantiate a new sub app).

### API not exposing private keys

### Alternatives about HD derivation path 
HD Path: Alternative derivation spec than bip32?
HD still but not with hardening?

BIP 44 for eth: 
https://github.com/ethereum/EIPs/issues/84
https://github.com/ethereum/EIPs/issues/85
https://github.com/ethereum/EIPs/pull/600
https://github.com/ethereum/EIPs/pull/601
not stricly BIP44 because of cointype should be a number between 0 and 2^31.

most frequently used eth derivation path
`m/44'/60'/a'/0/n`
where a is a set of account number and n is the account index

We won't be using bip44 here since not a crypto
and we don't want app keys to be ETH specific

Proposal 2 (make them subsets of ETH main accounts)
[Hd Path of an Eth main Account] / [Domain Specific Hd subPath] / [App controlled HD subPath] / [Account index]

pros:
allows to use isolated app paths for the same app using the same mnemonic.

can have several accounts fully separated to use the same domain without the domain knowing I'm the same individual. All this with the same mnemonic, I would just use 2 different mainAccounts.

One question though is how do you handle apps/plugin that would like to interact with several "main accounts", accounts outside of their control? Not sure if this use case really exists tho and we could have.

Also how does this applies to the plugins if metamask doesn't have a "selected account anymore"? Logging into plugins in the same way as in websites, EIP1102?

cons: 
makes this a subset of an ethereum account or should be eventually generalised to non ETH main accounts?
adds complexity to restore, one should remember which account is which
same benefits of privacy could be implemented by add an user provided field in the HD path, after domain and before app subpath

==> personas seem better

### Alternatives for App identification 

#### Shortening the ENS node
Current approach uses identification through an ENS name converted to a hash node and sliced fully but one could keep only the first 16 bytes of the node for instance and slice them similarly. This may increase the change of app collision but we probably can reduce the lenght while retaining an injective mapping from strings to bytes32.

#### Names not restricted to ens domains?
Should we allow names that are not .eth domains?  We may want to be able to handle DNS names for instance without using an ENS proxy (ie. a .eth domain point to a DNS url). They would have to be resolved differently because ENS does not allow other TLDs.
```
No, TLDs are restricted to only .eth (on mainnet), or .eth and .test (on Ropsten), plus any special purpose TLDs such as those required to permit reverse lookups. There are no immediate plans to invite proposals for additional TLDs. In large part this is to reduce the risk of a namespace collision with the IANA DNS namespace.
```

Replaces [EIP 1581: Non-wallet usage of keys derived from BIP-32 trees](https://eips.ethereum.org/EIPS/eip-1581)
https://ethereum-magicians.org/t/non-wallet-usage-of-keys-derived-from-bip-32-trees/1817/4
Benefit of our approach:
Does not require a centrally maintained registry. In our approach every app has already a domain assigned to it.
Englobing (personas among other)

domain's UID: Alternative spec, eth author address and including a signed message challenge for author for authentication
0x9df77328a2515c6d529bae90edf3d501eaaa268e

The same reasoning, if we use an `eth address` of 20 bytes, 160 bits

```
x = x0 || x1 || x2 || x3 || x4 || x5
```
where `x0` to `x4` are 30 bits and `x5` is 10 bits. 

which gives the derivation sub path:

```
x0'/x1'/x2'/x3'/x4'/x5'
```

or alternatively equal length
```
x = x0 || x1 || x2 || x3 || x4 || x5 || x6 || x7
```
where `x0` to `x7` are 20 bits.

### Alternatives for App authentification

For authentication we use ENS resolution, and browsing to a given url resolved
With ENS resolution and authentification homoglyph attack is not a problem since it will not leak kees from one domain to another.

Caveats 
* First connection requires the wallet to connect to ethereum mainnet, but once first resolution is done we could use some metadata param address for ethereum less authentication of the app (eg. app server signs a challenge message with the author address resolved in the ENS metadata)
* ENS resolution can change without the user knowing and then a different app/website may be granted access to his app keys. But this means the ENS name owner address was copromised. This would be similar to using a signing challenge authentified by a known public key. If this known public key is compromised we have a similar problem.

Other metadata resolution through ENS that can be used alongside:
* author address: already mentionned above
* contract address: For app keys that would be designed to interact with a given ethereum contract (for instance app keys for a given token, if one desires to do so), other metadata fields could be used such as contract addresses.

Alternative specs could


### Allowing app keys to derive any subpath and index, even if preivous ones by enumeration are empty

problem apps won't be able to restore by enumeration
but if they do that to derive accounts maybe it's on purpose and they may backup this data somewhere
Also maybe wallets wants to include an address gap limit for the derivation by enumeration when importing
https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki#Address_gap_limit


## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
No incompatibity since these are separate accounts
For apps that registered their user using main accounts eth addresses, they need to have a migration pattern to app keys accounts when desirable



## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->


## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
WIP
Link to hdkeyring methods


## Examples:
token contract:
https://github.com/ethereum/EIPs/issues/85

## Acknowledgements
MetaMask team

Liam Horne

Richard Moore

Jeff Coleman

for discussions about the domain's hd path

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

## References:

### HD and mnemonics
#### BIPS:
[BIP 32 specs, Hierarchical Deterministic Wallets:](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
[BIP 39 specs, Mnemonic code for generating deterministic keys:](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
[BIP44: Multi-Account Hierarchy for Deterministic Wallets](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki#Address_gap_limit)
[SLIP44: Registered coin types for BIP-0044](https://github.com/satoshilabs/slips/blob/master/slip-0044.md)


#### Derivation path for eth:
https://github.com/ethereum/EIPs/issues/84
https://github.com/ethereum/EIPs/issues/85
https://github.com/ethereum/EIPs/pull/600
Ethereum hierarchy for deterministic wallets - 
https://github.com/ethereum/EIPs/pull/601



### ENS:
EIP137:  Ethereum Domain Name Service - specification
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md
EIP165: Standard Interface Detection
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
EIP634: Storage of text record in ENS
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-634.md
ENS docs about namehash:
http://docs.ens.domains/en/latest/implementers.html#namehash

### Previous proposals related to app keys
[EIP 1581: Non-wallet usage of keys derived from BIP-32 trees](https://eips.ethereum.org/EIPS/eip-1581)
https://ethereum-magicians.org/t/non-wallet-usage-of-keys-derived-from-bip-32-trees/1817/4

# Notes:
BIP 39 tool: https://iancoleman.io/bip39/#english
- In Hd Paths, Merge app controlled subset and account index ?


- XPubKeys, how do we introduce them? How do we isolate them such that we don't leak a single XPubKey for the whole mnemonic, which would be a big privacy concern and would also remove the benefit of proposal 2 for hd path isolation per main account.


json rpc method middleware
private RPC methods for app keys
