## Preamble

    EIP: <to be assigned>
    Title: I2P Integration
    Author: Cole Lightfighter <cole@parity.io>
    Type: Standard Track
    Category (*only required for Standard Track): Networking
    Status: Draft
    Created: 2017-11-13
    Requires (*optional): N/A
    Replaces (*optional): N/A


## Simple Summary
Add the optional ability for ethereum clients to connect to, and communicate with, full nodes inside the I2P network.
Bridge Nodes (described below) allow I2P Nodes to connect out to peers over the clearnet.

## Abstract
I2P [SAM](https://geti2p.net/en/docs/api/samv3) or [BOB](https://geti2p.net/en/docs/api/bob) bridges provide an API for networked applications to more easily connect to the I2P network. 
I2P SAM libraries exist for the major ethereum client languages (Go, CPP, Rust), though some library software is very barebones, e.g. [i2p-rs](https://github.com/i2p/i2p-rs).
BOB is a newer API, but does not currently have a Rust library. This may not be a real issue, since `i2p-rs` still needs heavy development to be usable in production.
Clients will use one of the API bridges to talk to an I2P full client (written in Java), and connect to fully synced Ethereum nodes hosted as eepsites on I2P.

Bridge nodes are fully synced nodes connected to both I2P and clearnet peers. They act to keep I2P nodes up-to-date.
Bridge nodes are unnecessary when a full node operator is not concerned about keeping the location of their full-node private, similar to single-hop onion services used by Facebook.

## Motivation
Currently there is no way to anonymously connect, communicate and/or transact over the Ethereum network. Some solutions are being worked on for direct p2p communication, but a network-layer solution built on proven anonymizing technology does not exist.

Some of the anonymity concerns addressed by I2P are covered by the Whisper protocol. However, Whisper is designed specifically for p2p communications between Dapps, not to protect the confidentiality of all traffic on the Ethereum network.

## Specification
The specific implementation details will vary across Ethereum client software.

Full I2P implementations:

- Java    - [i2p](https://github.com/i2p/i2p.i2p)
- C++     - [i2pd](https://github.com/PurpleI2P/i2pd)
- C++     - [kovri - Monero's i2pd fork](https://github.com/monero-project/kovri)
- Go      - [go-i2p](https://github.com/hkparker/go-i2p)

Available SAM library implementations:

- C++     - [i2psam](https://github.com/i2p/i2psam)
- C       - [libsam3](https://github.com/i2p/libsam3)
- Rust    - [i2p-rs](https://github.com/i2p/i2p-rs)
- Go      - [sam3](https://bitbucket.org/kallevedin/sam3), [goSam](https://github.com/cryptix/goSam)
- Haskell - [network-anonymous-i2p](https://hackage.haskell.org/package/network-anonymous-i2p)


Available BOB library implementations:
- Go      - [ccondom](https://bitbucket.org/kallevedin/ccondom)
- Python  - [i2py-bob](http://git.repo.i2p.xyz/w/i2py-bob.git)
- Twisted - [txi2p](https://pypi.python.org/pypi/txi2p)

SAM is a much more mature protocol API, though BOB has more advanced features. First implementations may follow SAM with eye toward future implementations using BOB.

### General Architecture

#### I2P Full Nodes (IFN)

Fully synced nodes hosted as [eepsites](https://geti2p.net/en/faq#eepsite)
Use I2P SAM/BOB bridge to communicate with other IFN and BN clients over I2P
Need a full I2P client for SAM/BOB bridge to interact with the I2P network
Will use Bridge Nodes (BN) to connect to clearnet peers
Syncing from scratch or any large amounts of data over I2P is probably impractical, need out-of-band procedure for syncing (sync to VPS, xfer over scp?)

#### Bridge Nodes (BN)

Fully synced relay nodes used to help sync IFNs
Helps validate blockchain records held by IFNs
Allows light clients to connect to IFNs without needing I2P integration themselves
- custom rpc commands to send data over I2P that was received over clearnet

#### I2P Ethereum Clients (IEC)

IECs communicate transactions, peer discovery, and p2p messages over I2P
Use I2P SAM/BOB bridge to communicate with either BNs or IFNs directly
- use SSL for hop between ethereum client and full I2P client
- full end-to-end crypto (SSL -> SAM/BOB -> I2P -> SAM/BOB -> SSL)

An example route could look like this:
- Ethereum client (IEC) creates/signs transaction locally
- IEC sends the transaction wrapped in SSL to a full I2P client over the SAM/BOB bridge
- Full I2P client wraps the SSL-wrapped transaction in I2P crypto ([garlic routing](https://geti2p.net/en/docs/how/garlic-routing)
- IFN receives garlic-routed packet, and forwards to other IFNs and BNs
- BNs receive an SSL-encrypted packet containing the signed transaction
- BNs transmit decrypted transaction to other clearnet peers


## Rationale
I2P will allow Ethereum clients to privately connect, transact and communicate over the Ethereum network.

I2P is preferred over Tor as an anonymizing network layer, because Tor doesn't support UDP communication needed by Ethereum clients, e.g. DevP2P.
I2P has support for UDP communication, and BOB separates routing concerns even further into `Data` and `Command` packets.
If BOB is chosen as the I2P bridge protocol, its separation of routing concerns may allow for minimal overhead.

I2P and Whisper are not mutually exclusive, and are actually very mutually beneficial.
For example, a client could decide to use minimal settings to anonymize their entry and exit from the network over I2P, while using Whisper to encrypt/anonymize their Dapp messages.

Similar to Whisper's sliding scale, I2P allows for configurable settings that allow users to adjust their privacy vs. performance tradeoffs.

Whisper also uses a "topic-based" routing architecture, where I2P is based on a classic "packet-based" routing architecture.

While this is not a perfect solution, it does allow Ethereum clients to sync and communicate privately regardless of the form or content of their communications.
Further improvements to architecture are expected, constructive criticism is warmly welcomed.

## Backwards Compatibility
I2P connectability is entirely optional, and therefore fully backwards compatible.

## Test Cases
TODO: still in drafting phase. Test cases will be included in first PoC release.

## Implementation
TODO: still in drafting phase. Implementations will be included in first PoC release.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
