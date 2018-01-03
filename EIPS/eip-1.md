    EIP: 1
      Title: EIP Purpose and Guidelines
      Status: Active
      Type: Meta
      Author: Martin Becze <mb@ethereum.org>, Hudson Jameson <hudson@ethereum.org>
      Created: 2015-10-27, 2017-02-01

What is an EIP?
--------------

EIP stands for Ethereum Improvement Proposal. An EIP is a design document providing information to the Ethereum community, or describing a new feature for Ethereum or its processes or environment. The EIP should provide a concise technical specification of the feature and a rationale for the feature. The EIP author is responsible for building consensus within the community and documenting dissenting opinions.

EIP Rational
------------

We intend EIPs to be the primary mechanisms for proposing new features, for collecting community input on an issue, and for documenting the design decisions that have gone into Ethereum. Because the EIPs are maintained as text files in a versioned repository, their revision history is the historical record of the feature proposal.

For Ethereum implementers, EIPs are a convenient way to track the progress of their implementation. Ideally each implementation maintainer would list the EIPs that they have implemented. This will give end users a convenient way to know the current status of a given implementation or library.

EIP Types
---------

There are three types of EIP:

-   A **Standard Track EIP** describes any change that affects most or all Ethereum implementations, such as a change to the the network protocol, a change in block or transaction validity rules, proposed application standards/conventions, or any change or addition that affects the interoperability of applications using Ethereum. Furthermore Standard EIPs can be broken down into the following categories.
    -   **Core** - improvements requiring a consensus fork (e.g. [EIP5], [EIP101]), as well as changes that are not necessarily consensus critical but may be relevant to “core dev” discussions (for example, [EIP90], and the miner/node strategy changes 2, 3, and 4 of [EIP86]).
    -   **Networking** - includes improvements around [devp2p] ([EIP8]) and [Light Ethereum Subprotocol], as well as proposed improvements to network protocol specifications of [whisper] and [swarm].
    -   **Interface** - includes improvements around client [API/RPC] specifications and standards, and also certain language-level standards like method names ([EIP59], [EIP6]) and [contract ABIs]. The label “interface” aligns with the [interfaces repo] and discussion should primarily occur in that repository before an EIP is submitted to the EIPs repository.
    -   **ERC** - application-level standards and conventions, including contract standards such as token standards ([ERC20]), name registries ([ERC26], [ERC137]), URI schemes ([ERC67]), library/package formats ([EIP82]), and wallet formats ([EIP75], [EIP85]).

-   An **Informational EIP** describes a Ethereum design issue, or provides general guidelines or information to the Ethereum community, but does not propose a new feature. Informational EIPs do not necessarily represent Ethereum community consensus or a recommendation, so users and implementers are free to ignore Informational EIPs or follow their advice.
-   A **Meta EIP** describes a process surrounding Ethereum or proposes a change to (or an event in) a process. Process EIPs are like Standards Track EIPs but apply to areas other than the Ethereum protocol itself. They may propose an implementation, but not to Ethereum's codebase; they often require community consensus; unlike Informational EIPs, they are more than recommendations, and users are typically not free to ignore them. Examples include procedures, guidelines, changes to the decision-making process, and changes to the tools or environment used in Ethereum development. Any meta-EIP is also considered a Process EIP.

EIP Work Flow
-------------

The EIP repository Collaborators change the EIPs status. Please send all EIP-related email to the EIP Collaborators, which is listed under EIP Editors below. Also see EIP Editor Responsibilities & Workflow.

The EIP process begins with a new idea for Ethereum. It is highly recommended that a single EIP contain a single key proposal or new idea. The more focused the EIP, the more successful it tends to be. A change to one client doesn't require an EIP; a change that affects multiple clients, or defines a standard for multiple apps to use, does. The EIP editor reserves the right to reject EIP proposals if they appear too unfocused or too broad. If in doubt, split your EIP into several well-focused ones.

Each EIP must have a champion - someone who writes the EIP using the style and format described below, shepherds the discussions in the appropriate forums, and attempts to build community consensus around the idea.

Vetting an idea publicly before going as far as writing an EIP is meant to save the potential author time. Asking the Ethereum community first if an idea is original helps prevent too much time being spent on something that is guaranteed to be rejected based on prior discussions (searching the Internet does not always do the trick). It also helps to make sure the idea is applicable to the entire community and not just the author. Just because an idea sounds good to the author does not mean it will work for most people in most areas where Ethereum is used. Examples of appropriate public forums to gauge interest around your EIP include [the Ethereum subreddit], [the Issues section of this repository], and [one of the Ethereum Gitter chat rooms]. In particular, [the Issues section of this repository] is an excellent place to discuss your proposal with the community and start creating more formalized language around your EIP. 

Once the champion has asked the Ethereum community whether an idea has any chance of acceptance a draft EIP should be presented as a [pull request]. This gives the author a chance to continuously edit the draft EIP for proper formatting and quality. This also allows for further public comment and the author of the EIP to address concerns about the proposal.

If the EIP collaborators approve, the EIP editor will assign the EIP a number (generally the issue or PR number related to the EIP), label it as Standards Track, Informational, or Meta, give it status “Draft”, and add it to the git repository. The EIP editor will not unreasonably deny an EIP. Reasons for denying EIP status include duplication of effort, being technically unsound, not providing proper motivation or addressing backwards compatibility, or not in keeping with the Ethereum philosophy.

Standards Track EIPs consist of three parts, a design document, implementation, and finally if warranted an update to the [formal specification]. The EIP should be reviewed and accepted before an implementation is begun, unless an implementation will aid people in studying the EIP. Standards Track EIPs must be implemented in at least three viable Ethereum clients before it can be considered Final.

For an EIP to be accepted it must meet certain minimum criteria. It must be a clear and complete description of the proposed enhancement. The enhancement must represent a net improvement. The proposed implementation, if applicable, must be solid and must not complicate the protocol unduly.

Once an EIP has been accepted, the implementations must be completed. When the implementation is complete and accepted by the community, the status will be changed to “Final”.

An EIP can also be assigned status “Deferred”. The EIP author or editor can assign the EIP this status when no progress is being made on the EIP. Once an EIP is deferred, the EIP editor can re-assign it to draft status.

An EIP can also be “Rejected”. Perhaps after all is said and done it was not a good idea. It is still important to have a record of this fact.

EIPs can also be superseded by a different EIP, rendering the original obsolete.

The possible paths of the status of EIPs are as follows:

<img src=./eip-1/process.png>

Some Informational and Process EIPs may also have a status of “Active” if they are never meant to be completed. E.g. EIP 1 (this EIP).

What belongs in a successful EIP?
---------------------------------

Each EIP should have the following parts:

-   Preamble - RFC 822 style headers containing metadata about the EIP, including the EIP number, a short descriptive title (limited to a maximum of 44 characters), the names, and optionally the contact info for each author, etc.

<!-- -->

-   Simple Summary - “If you can’t explain it simply, you don’t understand it well enough.” Provide a simplified and layman-accessible explanation of the EIP.

<!-- -->

-   Abstract - a short (~200 word) description of the technical issue being addressed.

<!-- -->

-   Motivation (*optional) - The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.

<!-- -->

-   Specification - The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumJ, ethereumjs-lib, …).

<!-- -->

-   Rationale - The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.

<!-- -->

-   Backwards Compatibility - All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

<!-- -->

-   Test Cases - Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

<!-- -->

-   Implementations - The implementations must be completed before any EIP is given status “Final”, but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of “rough consensus and running code” is still useful when it comes to resolving many discussions of API details.

<!-- -->

-   Copyright Waiver - All EIPs must be in public domain. See the bottom of this EIP for an example copyright waiver.

EIP Formats and Templates
-------------------------

EIPs should be written in [markdown] format. Image files should be included in a subdirectory for that EIP.

EIP Header Preamble
-------------------

Each EIP must begin with an RFC 822 style header preamble. The headers must appear in the following order. Headers marked with "*" are optional and are described below. All other headers are required.

` EIP: ` <EIP number> (this is determined by the EIP editor)

` Title: `<EIP title>

` Author: `<list of author's real names and optionally, email address>

` * Discussions-To: ` <email address>

` Status: `<Draft | Active | Accepted | Deferred | Rejected | Withdrawn | Final | Superseded>

` Type: `<Standards Track (Core, Networking, Interface, ERC)  | Informational | Process>

` Created: `<date created on, in ISO 8601 (yyyy-mm-dd) format>

` * Replaces: `<EIP number>

` * Superseded-By: `<EIP number>

` * Resolution: `<url>

The Author header lists the names, and optionally the email addresses of all the authors/owners of the EIP. The format of the Author header value must be

Random J. User &lt;address@dom.ain&gt;

if the email address is included, and

Random J. User

if the email address is not given.

Note: The Resolution header is required for Standards Track EIPs only. It contains a URL that should point to an email message or other web resource where the pronouncement about the EIP is made.

While an EIP is in private discussions (usually during the initial Draft phase), a Discussions-To header will indicate the mailing list or URL where the EIP is being discussed. No Discussions-To header is necessary if the EIP is being discussed privately with the author.

The Type header specifies the type of EIP: Standards Track, Meta, or Informational. If the track is Standards please include the subcategory (core, networking, interface, or ERC).

The Created header records the date that the EIP was assigned a number. Both headers should be in yyyy-mm-dd format, e.g. 2001-08-14.

EIPs may have a Requires header, indicating the EIP numbers that this EIP depends on.

EIPs may also have a Superseded-By header indicating that an EIP has been rendered obsolete by a later document; the value is the number of the EIP that replaces the current document. The newer EIP must have a Replaces header containing the number of the EIP that it rendered obsolete.

Auxiliary Files
---------------

EIPs may include auxiliary files such as diagrams. Such files must be named EIP-XXXX-Y.ext, where “XXXX” is the EIP number, “Y” is a serial number (starting at 1), and “ext” is replaced by the actual file extension (e.g. “png”).

Transferring EIP Ownership
--------------------------

It occasionally becomes necessary to transfer ownership of EIPs to a new champion. In general, we'd like to retain the original author as a co-author of the transferred EIP, but that's really up to the original author. A good reason to transfer ownership is because the original author no longer has the time or interest in updating it or following through with the EIP process, or has fallen off the face of the 'net (i.e. is unreachable or not responding to email). A bad reason to transfer ownership is because you don't agree with the direction of the EIP. We try to build consensus around an EIP, but if that's not possible, you can always submit a competing EIP.

If you are interested in assuming ownership of an EIP, send a message asking to take over, addressed to both the original author and the EIP editor. If the original author doesn't respond to email in a timely manner, the EIP editor will make a unilateral decision (it's not like such decisions can't be reversed :).

EIP Editors
-----------

The current EIP editors are

` * Casey Detrio (@cdetrio)`

` * Hudson Jameson (@Souptacular)`

` * Martin Becze (@wanderer)`

` * Nick Johnson (@arachnid)`

` * Yoichi Hirai (@pirapira)`

` * Vitalik Buterin (@vbuterin)`

EIP Editor Responsibilities and Workflow
--------------------------------------

For each new EIP that comes in, an editor does the following:

-   Read the EIP to check if it is ready: sound and complete. The ideas must make technical sense, even if they don't seem likely to be accepted.
-   The title should accurately describe the content.
-   Edit the EIP for language (spelling, grammar, sentence structure, etc.), markup (Github flavored Markdown), code style

If the EIP isn't ready, the editor will send it back to the author for revision, with specific instructions.

Once the EIP is ready for the repository, the EIP editor will:

-   Assign an EIP number (generally the PR number or, if preferred by the author, the Issue # if there was discussion in the Issues section of this repository about this EIP)

<!-- -->

-   Accept the corresponding pull request

<!-- -->

-   List the EIP in [README.md]

<!-- -->

-   Send a message back to the EIP author with next step.

Many EIPs are written and maintained by developers with write access to the Ethereum codebase. The EIP editors monitor EIP changes, and correct any structure, grammar, spelling, or markup mistakes we see.

The editors don't pass judgment on EIPs. We merely do the administrative & editorial part.

History
-------

This document was derived heavily from [Bitcoin's BIP-0001] written by Amir Taaki which in turn was derived from [Python's PEP-0001]. In many places text was simply copied and modified. Although the PEP-0001 text was written by Barry Warsaw, Jeremy Hylton, and David Goodger, they are not responsible for its use in the Ethereum Improvement Process, and should not be bothered with technical questions specific to Ethereum or the EIP. Please direct all comments to the EIP editors.

December 7, 2016: EIP 1 has been improved and will be placed as a PR.

February 1, 2016: EIP 1 has added editors, made draft improvements to process, and has merged with Master stream.

  [EIP5]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5.md
  [EIP101]: https://github.com/ethereum/EIPs/issues/28
  [EIP90]: https://github.com/ethereum/EIPs/issues/90
  [EIP86]: https://github.com/ethereum/EIPs/issues/86#issue-145324865
  [devp2p]: https://github.com/ethereum/wiki/wiki/%C3%90%CE%9EVp2p-Wire-Protocol
  [EIP8]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-8.md
  [Light Ethereum Subprotocol]: https://github.com/ethereum/wiki/wiki/Light-client-protocol
  [whisper]: https://github.com/ethereum/go-ethereum/wiki/Whisper-Overview
  [swarm]: https://github.com/ethereum/go-ethereum/pull/2959
  [API/RPC]: https://github.com/ethereum/wiki/wiki/JSON-RPC
  [EIP59]: https://github.com/ethereum/EIPs/issues/59
  [EIP6]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-6.md
  [contract ABIs]: https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
  [interfaces repo]: https://github.com/ethereum/interfaces
  [ERC20]: https://github.com/ethereum/EIPs/issues/20
  [ERC26]: https://github.com/ethereum/EIPs/issues/26
  [ERC137]: https://github.com/ethereum/EIPs/issues/137
  [ERC67]: https://github.com/ethereum/EIPs/issues/67
  [EIP82]: https://github.com/ethereum/EIPs/issues/82
  [EIP75]: https://github.com/ethereum/EIPs/issues/75
  [EIP85]: https://github.com/ethereum/EIPs/issues/85
  [the Ethereum subreddit]: https://www.reddit.com/r/ethereum/
  [one of the Ethereum Gitter chat rooms]: https://gitter.im/ethereum/
  [pull request]: https://github.com/ethereum/EIPs/pulls
  [formal specification]: https://github.com/ethereum/yellowpaper
  [the Issues section of this repository]: https://github.com/ethereum/EIPs/issues
  [markdown]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
  [README.md]: README.md "wikilink"
  [Bitcoin's BIP-0001]: https://github.com/bitcoin/bips
  [Python's PEP-0001]: https://www.python.org/dev/peps/

Copyright
---------

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
