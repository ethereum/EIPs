---
eip: <to be assigned>
title: My Own Messages (MOM)
author: Giuseppe Bertone (@Neurone)
discussions-to: https://github.com/InternetOfPeers/EIPs/issues/1
status: Draft
type: Standards Track
category: ERC
created: 2020-08-02
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
My Own Messages (MOM) is a standard to notarize and share messages using Ethereum, so that contents are verificable and decentralized.

Main advantages:
- You can send messages to users of your ÐApp or Smart Contract, and they always know it is a voice reliable as the smart contract is.
- Create your Ethereum account dedicated to your personal messages, say something only once and it can be seen on every social platform (no more reply of the same post/opinion on dozens of sites like Reddit, Twitter, Facebook, Medium, Disqus, and so on...)
- Small fee to be free: pay just few cents of dollar to notarize your messages, and distribute them with IPFS, Swarm or any other storage you prefer. Because the multihash of the content is notarized, you can always check the integrity of the message you download even from centralized storage services.
- Finally, you can ask and get tips for your words directly into your wallet.

I know, My Own Messages (MOM) sounds like _mom_. And yes, pun intended :)

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
My Own Messages (MOM) is a standard to notarize and share messages using Ethereum. You can give voice to your smart contracts, send messages to the world, create a certified blog with your ideas, and so on.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
As a _developer_ or _pool's owner_, I'd like to send messages to my users in a decentralized way. They must be able to easily verify my role in the smart contract context (owner, user, and so on) and they must be able to do it without relying on external, insecure and hackable social media sites (Facebook, Twitter, you name it). Also, I'd like to read messages from my userbase, in the same secure and verifiable manner.

As a _user_, I want a method to easily share my thoughts and idea, publish content, send messages, receive feedbaks, receive tips, and so on, wihout dealing with any complexity: just write a message, send it and it's done. Also, I want to write to some smart contract's ower or to the sender of some transaction.

As an _explorer service_, I want to give my users an effective way to read informations by smart contract owners and a place to share ideas and informations, without using third parties services (i.e. Etherscan uses Disqus, and so on)

And in _any role_, I want a method that does not allow scams - transactions without values, no smart contract's address to remember or to fake - and it does not allow spam - it's cheap but not free, and even if you can link/refer other accounts, you cannot send them messages directly, and others must explicitly follow and listen to your transactions if they want to read your messages.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
## Valid MOM transaction's structure

| ATTRIBUTE | VALUE |
|:--------|:------------|
| `from` | `MUST` be the tx signer |
| `to` | `MUST` be the tx signer |
| `value` |  `MUST` be 0 wei |
| `data` | `MUST` be at least 1 byte. First byte is the operational code, then it comes the content. |

## List of supported operations and messages

| OPERATION | HEX CODE  | PARAMETERS | MEANING 			|
|--------|:------------:|------------|-------------------|
| ADD | 00       | multihash  | Add a message. The first parameter is the multihash of the content. Content default is Markdown text in UTF8 without BOM.|
| ADD & REFER | 01       | multihash, address  | Add a message and refer an account. The first parameter is the multihash of the content. Content default is Markdown text in UTF8 without BOM. The second parameter is an address referenced by the message. This can be useful _to invite_ the owner of the referenced account to read the message.|
| DELETE | 02	   | multihash | Delete a message identified by the specified multihash. This does not delete a message from the blockchain, just tell clients to hide because it's not valid anymore for some reason. Think it like: I changed my mind so please ÐApps don't show this anymore, unless expressly asked by the user of course, and if the content is still available and shared by someone, of course (it's very likely that deleted messages are not shared anyore by the author). |
| UPDATE | 03       | multihash, multihash | Update a message. The first parameter is the message to be updated. The second parameter is the multihash of the updated message |
| REPLY | 04      | multihash, multihash | Reply to a message. The first parameter is the message to reply to. The second parameter is the multihash of the message
| ENDORSE | 05	   | multihash | Endorse a message identified by the specified multihash. Think it as a "like", a "retwitt", etc. |
| DISAPPROVE | 06  | multihash | Disapprove a message identified by the specified multihash. Think it as a "I don't like it" |
| ENDORSE & REPLY | 07 | multihash, multihash | Endorse a message and reply to it. The first parameter is the message to reply to. The second parameter is the multihash of the message
| DISAPPROVE & REPLY | 08 | multihash, multihash | Disapprove a message and reply to it. The first parameter is the message to reply to. The second parameter is the multihash of the message
| CLOSE ACCOUNT | FD | multihash | "Close the account" or "Never consider valid any other MOM messages sent by this account from now on.". This is  useful when you want to change account, especially when the private key is compromised - or you think it is. The multihash parameter is an optional file with motivations |
| RAW | FF	   | any | Raw content, at least 1 byte, no need to disclose the meaning. It can be used for _blind_ notarization. General client can ignore it.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Ethereum is _account based_, so it's good to be identified as a single source of information.

It is also able of doing notarization very well and to impose some restrictions on transaction's structure, so it's good for commands.

IPFS, Swarm or other CANs (Content Addressable Networks) or storage methods are good to store lot of informations. So the union of both worlds it's a good solution to achieve the objectives of this message standard.

The objective is also to avoid in the first place any kind of scam and malicious behaviors, so MOM don't allow to send transactions to other accounts and the value of a MOM transaction is always 0.

### Why not using a smart contract?
MOM wants to be useful, easy to implement and read, error proof, fast and cheap, but:
- using a smart contract for messages can leads more easily to errors and misunderstandings:
    - address of the contract can be wrong
    - smart contract must be deployed on that specific network to send messages
- executing a smart contract costs much more then sending transactions
- executing a smart contract just to store static data is the best example of an anti-pattern (expensive and almost useless)

Without a specific smart contract to rely on, the MOM standard can be implemented and used right now in any existing networks, and even in future ones.

Finally, if you can achive exactly the same result without a smart contract, you didn't need a smart contract at the first place.

### Why not storing messages directly on-chain?
There's no benefit to store _static_ messages on-chain, if they are not related to some smart contract's state or if they does not represents exchange of value. The cost of storing data on-chain is also very high.

### Why not storing op codes inside the message?
While cost effectiveness is a very important feature in a blockchain related standard, there's also a compromise to reach with usability and usefulness.

Storing commands inside the messages forces the client to actually download messages to understand what to do with them. This is very unefficent, bandwidth and time consuming.

Being able to see the commands before downloading the content, it allows the client to recreate the history of all messages and then, at the end, download only updated messages.

Creating a structure for the content of the messages leads to many issues and considerations in parsing the contect, if it's correct, mispelled, and so on.

Finally, the **content must remains clean**. You really want to notarize the content and not to refer to a data structure, because this can lead to possible false-negative when checking if a content is the same of another.

### Why multihash?
[Multihash](https://github.com/multiformats/multihash) is flexible, future-proof and there are already a tons of library supporting it. Ethereum must be easily integrable with many different platforms and architectures, so MOM standard follow that idea.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
You can already find few transactions over the Ethereum network that use a pattern similar to this EIP. Sometimes it's done to invalidate a previous transaction in memory pool, using the same nonce but with more gas price, so that transaction is mined cancelling the previous one still in the memory pool. This kind of transactions can be easily ignored if created before the approval of this EIP or just checking if the payload follow the correct syntax.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
You can see MOM in action using the first implementation of a MOM-compliant client over IPFS

ipfs://QmXzD3MLpj7dvKrYDCBKPRGvmTk2KJ7x1GRpaJhXV1YqRv/

Or, for a more classical client-server approach, you can use the latest version of MOM client directly from:
- [ipfs.io gateway](https://ipfs.io/ipfs/QmXzD3MLpj7dvKrYDCBKPRGvmTk2KJ7x1GRpaJhXV1YqRv/)
- [GitHub's servers](https://internetofpeers.github.io/mom-client)

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
You can use an already working MOM javascript package on [GitHub Packages](https://github.com/InternetOfPeers/mom-js/packages/323930) or [npmjs](https://www.npmjs.com/package/@internetofpeers/mom-js). The package it's already used by the MOM client above, and you can use it in your DApps too with:
```
npm install @internetofpeers/mom-js
```

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
MOM is very simple and it has no real security concerns by itself. The standard already consider valid only transactions with `0` value and where `from` and `to` addresses are equals.

The only concerns can come from the payload, but it is more realted to the client and not to the standard itself, so here you can find some security suggestions related to clients implementing the standard.

### Parsing commands
MOM standard involve parsing payloads generated by potentially malicious clients, so attention must be made to avoid unwanted code execution.

- Strictly follow only the standard codes
- Don't execute any commands outside of the standard ones, unless expressly acknowledged by the user

### Messages
Default content-type of a message following the MOM standard is Markdown text in UTF8 without BOM. It is highly raccomended to disallow the reading of any not-text content-type, unless expressly acknowledged by the user.

Because content multihash is always stored into the chain, clients can download that content from Content Addressable Network (like IPFS or Swarm) or from central servers. In the latter case, a client should always check the integrity of the received messages, or it must warn the user if it cannot do that (feature not implemented or in error).

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
