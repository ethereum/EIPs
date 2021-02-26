---
eip: 1
title: EIP Purpose and Guidelines
status: Living
type: Meta
author: Martin Becze <mb@ethereum.org>, Hudson Jameson <hudson@ethereum.org>, et al.
created: 2015-10-27
---

## What is an EIP?

EIP stands for Ethereum Improvement Proposal. An EIP is a design document providing information to the Ethereum community, or describing a new feature for Ethereum or its processes or environment. The EIP should provide a concise technical specification of the feature and a rationale for the feature. The EIP author is responsible for building consensus within the community and documenting dissenting opinions.

## EIP Rationale

We intend EIPs to be the primary mechanisms for proposing new features, for collecting community technical input on an issue, and for documenting the design decisions that have gone into Ethereum. Because the EIPs are maintained as text files in a versioned repository, their revision history is the historical record of the feature proposal.

For Ethereum implementers, EIPs are a convenient way to track the progress of their implementation. Ideally each implementation maintainer would list the EIPs that they have implemented. This will give end users a convenient way to know the current status of a given implementation or library.

## EIP Types

There are three types of EIP:

- A **Standards Track EIP** describes any change that affects most or all Ethereum implementations, such as—a change to the network protocol, a change in block or transaction validity rules, proposed application standards/conventions, or any change or addition that affects the interoperability of applications using Ethereum. Standards Track EIPs consist of three parts—a design document, an implementation, and (if warranted) an update to the [formal specification]. Furthermore, Standards Track EIPs can be broken down into the following categories:
  - **Core**: improvements requiring a consensus fork (e.g. [EIP-5](./eip-5.md), [EIP-101](./eip-101.md)), as well as changes that are not necessarily consensus critical but may be relevant to [“core dev” discussions](https://github.com/ethereum/pm) (for example, [EIP-90], and the miner/node strategy changes 2, 3, and 4 of [EIP-86](./eip-86.md)).
  - **Networking**: includes improvements around [devp2p] ([EIP-8](./eip-8.md)) and [Light Ethereum Subprotocol], as well as proposed improvements to network protocol specifications of [whisper] and [swarm].
  - **Interface**: includes improvements around client [API/RPC] specifications and standards, and also certain language-level standards like method names ([EIP-6](./eip-6.md)) and [contract ABIs]. The label “interface” aligns with the [interfaces repo] and discussion should primarily occur in that repository before an EIP is submitted to the EIPs repository.
  - **ERC**: application-level standards and conventions, including contract standards such as token standards ([ERC-20](./eip-20.md)), name registries ([ERC-137](./eip-137.md)), URI schemes, library/package formats, and wallet formats.

- A **Meta EIP** describes a process surrounding Ethereum or proposes a change to (or an event in) a process. Process EIPs are like Standards Track EIPs but apply to areas other than the Ethereum protocol itself. They may propose an implementation, but not to Ethereum's codebase; they often require community consensus; unlike Informational EIPs, they are more than recommendations, and users are typically not free to ignore them. Examples include procedures, guidelines, changes to the decision-making process, and changes to the tools or environment used in Ethereum development. Any meta-EIP is also considered a Process EIP.

- An **Informational EIP** describes an Ethereum design issue, or provides general guidelines or information to the Ethereum community, but does not propose a new feature. Informational EIPs do not necessarily represent Ethereum community consensus or a recommendation, so users and implementers are free to ignore Informational EIPs or follow their advice.

It is highly recommended that a single EIP contain a single key proposal or new idea. The more focused the EIP, the more successful it tends to be. A change to one client doesn't require an EIP; a change that affects multiple clients, or defines a standard for multiple apps to use, does.

An EIP must meet certain minimum criteria. It must be a clear and complete description of the proposed enhancement. The enhancement must represent a net improvement. The proposed implementation, if applicable, must be solid and must not complicate the protocol unduly.

### Special requirements for Core EIPs

If a **Core** EIP mentions or proposes changes to the EVM (Ethereum Virtual Machine), it should refer to the instructions by their mnemonics and define the opcodes of those mnemonics at least once. A preferred way is the following:
```
REVERT (0xfe)
```

## EIP Work Flow

### Shepherding an EIP

Parties involved in the process are you, the champion or *EIP author*, the [*EIP editors*](#eip-editors), and the [*Ethereum Core Developers*](https://github.com/ethereum/pm).

Before you begin writing a formal EIP, you should vet your idea. Ask the Ethereum community first if an idea is original to avoid wasting time on something that will be rejected based on prior research. It is thus recommended to open a discussion thread on [the Ethereum Magicians forum] to do this, but you can also use [one of the Ethereum Gitter chat rooms], [the Ethereum subreddit] or [the Issues section of this repository]. 

Once the idea has been vetted, your next responsibility will be to present (by means of an EIP) the idea to the reviewers and all interested parties, invite editors, developers, and the community to give feedback on the aforementioned channels. You should try and gauge whether the interest in your EIP is commensurate with both the work involved in implementing it and how many parties will have to conform to it. For example, the work required for implementing a Core EIP will be much greater than for an ERC and the EIP will need sufficient interest from the Ethereum client teams. Negative community feedback will be taken into consideration and may prevent your EIP from moving past the Draft stage.

### Core EIPs

For Core EIPs, given that they require client implementations to be considered **Final** (see "EIPs Process" below), you will need to either provide an implementation for clients or convince clients to implement your EIP. 

The best way to get client implementers to review your EIP is to present it on an AllCoreDevs call. You can request to do so by posting a comment linking your EIP on an [AllCoreDevs agenda GitHub Issue].  

The AllCoreDevs call serve as a way for client implementers to do three things. First, to discuss the technical merits of EIPs. Second, to gauge what other clients will be implementing. Third, to coordinate EIP implementation for network upgrades.

These calls generally result in a "rough consensus" around what EIPs should be implemented. This "rough consensus" rests on the assumptions that EIPs are not contentious enough to cause a network split and that they are technically sound.

:warning: The EIPs process and AllCoreDevs call were not designed to address contentious non-technical issues, but, due to the lack of other ways to address these, often end up entangled in them. This puts the burden on client implementers to try and gauge community sentiment, which hinders the technical coordination function of EIPs and AllCoreDevs calls. If you are shepherding an EIP, you can make the process of building community consensus easier by making sure that [the Ethereum Magicians forum] thread for your EIP includes or links to as much of the community discussion as possible and that various stakeholders are well-represented.

*In short, your role as the champion is to write the EIP using the style and format described below, shepherd the discussions in the appropriate forums, and build community consensus around the idea.* 

### EIP Process 

The following is the standardization process for all EIPs in all tracks:

![EIP Status Diagram](../assets/eip-1/EIP-process.png)

**Idea** - An idea that is pre-draft. This is not tracked within the EIP Repository.

**Draft** - The first formally tracked stage of an EIP in development. An EIP is merged by an EIP Editor into the EIP repository when properly formatted.

**Review** - An EIP Author marks an EIP as ready for and requesting Peer Review.

**Last Call** - This is the final review window for an EIP before moving to `FINAL`. An EIP editor will assign `Last Call` status and set a review end date (review-period-end), typically 14 days later.

If this period results in necessary normative changes it will revert the EIP to `REVIEW`.

**Final** - This EIP represents the final standard. A Final EIP exists in a state of finality and should only be updated to correct errata and add non-normative clarifications.

**Stagnant** - Any EIP in `DRAFT` or `REVIEW` if inactive for a period of 6 months or greater is moved to `STAGNANT`. An EIP may be resurrected from this state by Authors or EIP Editors through moving it back to `DRAFT`.

>*EIP Authors are notified of any algorithmic change to the status of their EIP*

**Withdrawn** - The EIP Author(s) have withdrawn the proposed EIP. This state has finality and can no longer be resurrected using this EIP number. If the idea is pursued at later date it is considered a new proposal.

**Living** - A special status for EIPs that are designed to be continually updated and not reach a state of finality. This includes most notably EIP-1. Any changes to these EIPs will move between `REVIEW` and `LIVING` states.

## What belongs in a successful EIP?

Each EIP should have the following parts:

- Preamble - RFC 822 style headers containing metadata about the EIP, including the EIP number, a short descriptive title (limited to a maximum of 44 characters), and the author details. See [below](./eip-1.md#eip-header-preamble) for details.
- Abstract - A short (~200 word) description of the technical issue being addressed.
- Motivation (*optional) - A motivation section is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.
- Specification - The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumJ, ethereumjs-lib, [and others](https://github.com/ethereum/wiki/wiki/Clients).
- Rationale - The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.
- Backwards Compatibility - All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.
- Test Cases - Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.
- Reference Implementation - An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.
- Security Considerations - All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life-cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.
- Copyright Waiver - All EIPs must be in the public domain. See the bottom of this EIP for an example copyright waiver.

## EIP Formats and Templates

EIPs should be written in [markdown] format. There is a [template](https://github.com/ethereum/EIPs/blob/master/eip-template.md) to follow.

## EIP Header Preamble

Each EIP must begin with an [RFC 822](https://www.ietf.org/rfc/rfc822.txt) style header preamble, preceded and followed by three hyphens (`---`). This header is also termed ["front matter" by Jekyll](https://jekyllrb.com/docs/front-matter/). The headers must appear in the following order. Headers marked with "*" are optional and are described below. All other headers are required.

` eip:` *EIP number* (this is determined by the EIP editor)

` title:` *EIP title*

` author:` *a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s). Details are below.*

` * discussions-to:` *a url pointing to the official discussion thread*

` status:` *Draft, Review, Last Call, Final, Stagnant, Withdrawn, Living*

`* review-period-end:` *date review period ends*

` type:` *Standards Track, Meta, or Informational*

` * category:` *Core, Networking, Interface, or ERC* (fill out for Standards Track EIPs only)

` created:` *date created on*

` * updated:` *comma separated list of dates*

` * requires:` *EIP number(s)*

` * replaces:` *EIP number(s)*

` * superseded-by:` *EIP number(s)*

` * resolution:` *a url pointing to the resolution of this EIP*

Headers that permit lists must separate elements with commas.

Headers requiring dates will always do so in the format of ISO 8601 (yyyy-mm-dd).

#### `author` header

The `author` header lists the names, email addresses or usernames of the authors/owners of the EIP. Those who prefer anonymity may use a username only, or a first name and a username. The format of the `author` header value must be:

> Random J. User &lt;address@dom.ain&gt;

or

> Random J. User (@username)

if the email address or GitHub username is included, and

> Random J. User

if the email address is not given.

It is not possible to use both an email and a GitHub username at the same time. If important to include both, one could include their name twice, once with the GitHub username, and once with the email.

At least one author must use a GitHub username, in order to get notified on change requests and have the capability to approve or reject them.

#### `resolution` header

The `resolution` header is required for Standards Track EIPs only. It contains a URL that should point to an email message or other web resource where the pronouncement about the EIP is made.

#### `discussions-to` header

While an EIP is a draft, a `discussions-to` header will indicate the mailing list or URL where the EIP is being discussed. As mentioned above, examples for places to discuss your EIP include [Ethereum topics on Gitter](https://gitter.im/ethereum/topics), an issue in this repo or in a fork of this repo, [Ethereum Magicians](https://ethereum-magicians.org/) (this is suitable for EIPs that may be contentious or have a strong governance aspect), and [Reddit r/ethereum](https://www.reddit.com/r/ethereum/).

No `discussions-to` header is necessary if the EIP is being discussed privately with the author.

As a single exception, `discussions-to` cannot point to GitHub pull requests.

#### `type` header

The `type` header specifies the type of EIP: Standards Track, Meta, or Informational. If the track is Standards please include the subcategory (core, networking, interface, or ERC).

#### `category` header

The `category` header specifies the EIP's category. This is required for standards-track EIPs only.

#### `created` header

The `created` header records the date that the EIP was assigned a number. Both headers should be in yyyy-mm-dd format, e.g. 2001-08-14.

#### `updated` header

The `updated` header records the date(s) when the EIP was updated with "substantial" changes. This header is only valid for EIPs of Draft and Active status.

#### `requires` header

EIPs may have a `requires` header, indicating the EIP numbers that this EIP depends on.

#### `superseded-by` and `replaces` headers

EIPs may also have a `superseded-by` header indicating that an EIP has been rendered obsolete by a later document; the value is the number of the EIP that replaces the current document. The newer EIP must have a `replaces` header containing the number of the EIP that it rendered obsolete.

## Linking to other EIPs

References to other EIPs should follow the format `EIP-N` where `N` is the EIP number you are referring to.  Each EIP that is referenced in an EIP **MUST** be accompanied by a relative markdown link the first time it is referenced, and **MAY** be accompanied by a link on subsequent references.  The link **MUST** always be done via relative paths so that the links work in this GitHub repository, forks of this repository, the main EIPs site, mirrors of the main EIP site, etc.  For example, you would link to this EIP with `[EIP-1](./eip-1.md)`.

## Auxiliary Files

Images, diagrams and auxiliary files should be included in a subdirectory of the `assets` folder for that EIP as follows: `assets/eip-N` (where **N** is to be replaced with the EIP number). When linking to an image in the EIP, use relative links such as `../assets/eip-1/image.png`.

## Transferring EIP Ownership

It occasionally becomes necessary to transfer ownership of EIPs to a new champion. In general, we'd like to retain the original author as a co-author of the transferred EIP, but that's really up to the original author. A good reason to transfer ownership is because the original author no longer has the time or interest in updating it or following through with the EIP process, or has fallen off the face of the 'net (i.e. is unreachable or isn't responding to email). A bad reason to transfer ownership is because you don't agree with the direction of the EIP. We try to build consensus around an EIP, but if that's not possible, you can always submit a competing EIP.

If you are interested in assuming ownership of an EIP, send a message asking to take over, addressed to both the original author and the EIP editor. If the original author doesn't respond to the email in a timely manner, the EIP editor will make a unilateral decision (it's not like such decisions can't be reversed :)).

## EIP Editors

The current EIP editors are

- Nick Johnson (@arachnid)
- Casey Detrio (@cdetrio)
- Hudson Jameson (@Souptacular)
- Vitalik Buterin (@vbuterin)
- Nick Savers (@nicksavers)
- Martin Becze (@wanderer)
- Greg Colvin (@gcolvin)
- Alex Beregszaszi (@axic)
- Micah Zoltu (@MicahZoltu)

## EIP Editor Responsibilities

For each new EIP that comes in, an editor does the following:

- Read the EIP to check if it is ready: sound and complete. The ideas must make technical sense, even if they don't seem likely to get to final status.
- The title should accurately describe the content.
- Check the EIP for language (spelling, grammar, sentence structure, etc.), markup (GitHub flavored Markdown), code style

If the EIP isn't ready, the editor will send it back to the author for revision, with specific instructions.

Once the EIP is ready for the repository, the EIP editor will:

- Assign an EIP number (generally the PR number or, if preferred by the author, the Issue # if there was discussion in the Issues section of this repository about this EIP)

- Merge the corresponding pull request

- Send a message back to the EIP author with the next step.

Many EIPs are written and maintained by developers with write access to the Ethereum codebase. The EIP editors monitor EIP changes, and correct any structure, grammar, spelling, or markup mistakes we see.

The editors don't pass judgment on EIPs. We merely do the administrative & editorial part.

## Style Guide

When referring to an EIP by number, it should be written in the hyphenated form `EIP-X` where `X` is the EIP's assigned number.

## History

This document was derived heavily from [Bitcoin's BIP-0001] written by Amir Taaki which in turn was derived from [Python's PEP-0001]. In many places text was simply copied and modified. Although the PEP-0001 text was written by Barry Warsaw, Jeremy Hylton, and David Goodger, they are not responsible for its use in the Ethereum Improvement Process, and should not be bothered with technical questions specific to Ethereum or the EIP. Please direct all comments to the EIP editors.

### Bibliography

[devp2p]: https://github.com/ethereum/wiki/wiki/%C3%90%CE%9EVp2p-Wire-Protocol
[Light Ethereum Subprotocol]: https://github.com/ethereum/wiki/wiki/Light-client-protocol
[whisper]: https://github.com/ethereum/go-ethereum/wiki/Whisper-Overview
[swarm]: https://github.com/ethereum/go-ethereum/pull/2959
[API/RPC]: https://github.com/ethereum/wiki/wiki/JSON-RPC
[contract ABIs]: https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
[interfaces repo]: https://github.com/ethereum/interfaces
[the Ethereum subreddit]: https://www.reddit.com/r/ethereum/
[one of the Ethereum Gitter chat rooms]: https://gitter.im/ethereum/
[pull request]: https://github.com/ethereum/EIPs/pulls
[formal specification]: https://github.com/ethereum/yellowpaper
[the Issues section of this repository]: https://github.com/ethereum/EIPs/issues
[markdown]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
[Bitcoin's BIP-0001]: https://github.com/bitcoin/bips
[Python's PEP-0001]: https://www.python.org/dev/peps/
[the Ethereum Magicians forum]: https://ethereum-magicians.org/
[AllCoreDevs agenda GitHub Issue]: https://github.com/ethereum/pm/issues

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
