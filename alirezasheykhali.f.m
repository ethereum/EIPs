---
eip: 1
title: EIP Purpose and Guidelines
status: Active
type: Meta
author: Martin Becze <mb@ethereum.org>, Hudson Jameson <hudson@ethereum.org>, et al.
created: 2015-10-27
updated: 2015-12-07, 2016-02-01, 2018-03-21, 2018-05-29, 2018-10-17, 2019-05-19, 2019-12-04, 2020-06-17
---

## What is an EIP?

EIP stands for Ethereum Improvement Proposal. An EIP is a design document providing information to the Ethereum community, or describing a new feature for Ethereum or its processes or environment. The EIP should provide a concise technical specification of the feature and a rationale for the feature. The EIP author is responsible for building consensus within the community and documenting dissenting opinions.

## EIP Rationale

We intend EIPs to be the primary mechanisms for proposing new features, for collecting community technical input on an issue, and for documenting the design decisions that have gone into Ethereum. Because the EIPs are maintained as text files in a versioned repository, their revision history is the historical record of the feature proposal.

For Ethereum implementers, EIPs are a convenient way to track the progress of their implementation. Ideally each implementation maintainer would list the EIPs that they have implemented. This will give end users a convenient way to know the current status of a given implementation or library.

## EIP Types

There are three types of EIP:

- A **Standards Track EIP** describes any change that affects most or all Ethereum implementations, such as a change to the network protocol, a change in block or transaction validity rules, proposed application standards/conventions, or any change or addition that affects the interoperability of applications using Ethereum. Furthermore Standard EIPs can be broken down into the following categories. Standards Track EIPs consist of three parts, a design document, implementation, and finally if warranted an update to the [formal specification].
  - **Core** - improvements requiring a consensus fork (e.g. [EIP-5], [EIP-101]), as well as changes that are not necessarily consensus critical but may be relevant to [“core dev” discussions](https://github.com/ethereum/pm) (for example, [EIP-90], and the miner/node strategy changes 2, 3, and 4 of [EIP-86]).
  - **Networking** - includes improvements around [devp2p] ([EIP-8]) and [Light Ethereum Subprotocol], as well as proposed improvements to network protocol specifications of [whisper] and [swarm].
  - **Interface** - includes improvements around client [API/RPC] specifications and standards, and also certain language-level standards like method names ([EIP-6]) and [contract ABIs]. The label “interface” aligns with the [interfaces repo] and discussion should primarily occur in that repository before an EIP is submitted to the EIPs repository.
  - **ERC** - application-level standards and conventions, including contract standards such as token standards ([ERC20]), name registries ([ERC26], [ERC137]), URI schemes ([ERC67]), library/package formats ([EIP-82]), and wallet formats ([EIP-75], [EIP-85]).
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

Before you begin writing a formal EIP, you should vet your idea. Ask the Ethereum community first if an idea is original to avoid wasting time on something that will be be rejected based on prior research. It is thus recommended to open a discussion thread on [the Ethereum Magicians forum] to do this, but you can also use [one of the Ethereum Gitter chat rooms], [the Ethereum subreddit] or [the Issues section of this repository]. 

In addition to making sure your idea is original, it will be your role as the author to make your idea clear to reviewers and interested parties, as well as inviting editors, developers and community to give feedback on the aforementioned channels. You should try and gauge whether the interest in your EIP is commensurate with both the work involved in implementing it and how many parties will have to conform to it. For example, the work required for implementing a Core EIP will be much greater than for an ERC and the EIP will need sufficient interest from the Ethereum client teams. Negative community feedback will be taken into consideration and may prevent your EIP from moving past the Draft stage.

### Core EIPs

For Core EIPs, given that they require client implementations to be considered **Final** (see "EIPs Process" below), you will need to either provide an implementation for clients or convince clients to implement your EIP. 

The best way to get client implementers to review your EIP is to present it on an AllCoreDevs call. You can request to do so by posting a comment linking your EIP on an [AllCoreDevs agenda GitHub Issue].  

The AllCoreDevs call serve as a way for client implementers to do three things. First, to discuss the technical merits of EIPs. Second, to gauge what other clients will be implementing. Third, to coordinate EIP implementation for network upgrades.

These calls generally result in a "rough consensus" around what EIPs should be implemented. This "rough consensus" rests on the assumptions that EIPs are not contentious enough to cause a network split and that they are technically sound.

:warning: The EIPs process and AllCoreDevs call were not designed to address contentious non-technical issues, but, due to the lack of other ways to address these, often end up entangled in them. This puts the burden on client implementers to try and gauge community sentiment, which hinders the technical coordination function of EIPs and AllCoreDevs calls. If you are shepherding an EIP, you can make the process of building community consensus easier by making sure that [the Ethereum Magicians forum] thread for your EIP includes or links to as much of the community discussion as possible and that various stakeholders are well-represented.

*In short, your role as the champion is to write the EIP using the style and format described below, shepherd the discussions in the appropriate forums, and build community consensus around the idea.* 

### EIP Process 

Following is the process that a successful non-Core EIP will move along:

```
[ WIP ] -> [ DRAFT ] -> [ LAST CALL ] -> [ FINAL ]
```

Following is the process that a successful Core EIP will move along:

```
[ IDEA ] -> [ DRAFT ] -> [ LAST CALL ] -> [ ACCEPTED ] -> [ FINAL ]
```

Each status change is requested by the EIP author and reviewed by the EIP editors. Use a pull request to update the status. Please include a link to where people should continue discussing your EIP. The EIP editors will process these requests as per the conditions below.

* **Idea** -- Once the champion has asked the Ethereum community whether an idea has any chance of support, they will write a draft EIP as a [pull request]. Consider including an implementation if this will aid people in studying the EIP.
  * :arrow_right: Draft -- If agreeable, EIP editor will assign the EIP a number (generally the issue or PR number related to the EIP) and merge your pull request. The EIP editor will not unreasonably deny an EIP.
  * :x: Draft -- Reasons for denying draft status include being too unfocused, too broad, duplication of effort, being technically unsound, not providing proper motivation or addressing backwards compatibility, or not in keeping with the [Ethereum philosophy](https://github.com/ethereum/wiki/wiki/White-Paper#philosophy).
* **Draft** -- Once the first draft has been merged, you may submit follow-up pull requests with further changes to your draft until such point as you believe the EIP to be mature and ready to proceed to the next status. An EIP in draft status must be implemented to be considered for promotion to the next status (ignore this requirement for core EIPs).
  * :arrow_right: Last Call -- If agreeable, the EIP editor will assign Last Call status and set a review end date (`review-period-end`), normally 14 days later.
  * :x: Last Call -- A request for Last Call status will be denied if material changes are still expected to be made to the draft. We hope that EIPs only enter Last Call once, so as to avoid unnecessary noise on the RSS feed.
* **Last Call** -- This EIP will listed prominently on the https://eips.ethereum.org/ website (subscribe via RSS at [last-call.xml](/last-call.xml)).
  * :x: -- A Last Call which results in material changes or substantial unaddressed technical complaints will cause the EIP to revert to Draft.
  * :arrow_right: Accepted (Core EIPs only) -- A successful Last Call without material changes or unaddressed technical complaints will become Accepted.
  * :arrow_right: Final (Non-Core EIPs) -- A successful Last Call without material changes or unaddressed technical complaints will become Final.
* **Accepted (Core EIPs only)** -- This status signals that material changes are unlikely and Ethereum client developers should consider this EIP for inclusion. Their process for deciding whether to encode it into their clients as part of a hard fork is not part of the EIP process.
  * :arrow_right: Draft -- The Core Devs can decide to move this EIP back to the Draft status at their discretion. E.g. a major, but correctable, flaw was found in the EIP.
  * :arrow_right: Rejected -- The Core Devs can decide to mark this EIP as Rejected at their discretion. E.g. a major, but uncorrectable, flaw was found in the EIP.
  * :arrow_right: Final -- Standards Track Core EIPs must be implemented in at least three viable Ethereum clients before it can be considered Final. When the implementation is complete and adopted by the community, the status will be changed to “Final”.
* **Final** -- This EIP represents the current state-of-the-art. A Final EIP should only be updated to correct errata.

Other exceptional statuses include:

* **Active** -- Some Informational and Process EIPs may also have a status of “Active” if they are never meant to be completed. E.g. EIP 1 (this EIP).
* **Abandoned** -- This EIP is no longer pursued by the original authors or it may not be a (technically) preferred option anymore.
  * :arrow_right: Draft -- Authors or new champions wishing to pursue this EIP can ask for changing it to Draft status.
* **Rejected** -- An EIP that is fundamentally broken or a Core EIP that was rejected by the Core Devs and will not be implemented. An EIP cannot move on from this state.
* **Superseded** -- An EIP which was previously Final but is no longer considered state-of-the-art. Another EIP will be in Final status and reference the Superseded EIP. An EIP cannot move on from this state.

## What belongs in a successful EIP?

Each EIP should have the following parts:

- Preamble - RFC 822 style headers containing metadata about the EIP, including the EIP number, a short descriptive title (limited to a maximum of 44 characters), and the author details. See [below](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-header-preamble) for details.
- Abstract - A short (~200 word) description of the technical issue being addressed.
- Motivation (*optional) - The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.
- Specification - The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumJ, ethereumjs-lib, [and others](https://github.com/ethereum/wiki/wiki/Clients).
- Rationale - The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.
- Backwards Compatibility - All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.
- Test Cases - Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.
- Implementations - The implementations must be completed before any EIP is given status “Final”, but it need not be completed before the EIP is merged as draft. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of “rough consensus and running code” is still useful when it comes to resolving many discussions of API details.
- Security Considerations - All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.
- Copyright Waiver - All EIPs must be in the public domain. See the bottom of this EIP for an example copyright waiver.

## EIP Formats and Templates

EIPs should be written in [markdown] format. There is a [template](https://github.com/ethereum/EIPs/blob/master/eip-template.md) to follow.

## EIP Header Preamble

Each EIP must begin with an [RFC 822](https://www.ietf.org/rfc/rfc822.txt) style header preamble, preceded and followed by three hyphens (`---`). This header is also termed ["front matter" by Jekyll](https://jekyllrb.com/docs/front-matter/). The headers must appear in the following order. Headers marked with "*" are optional and are described below. All other headers are required.

` eip:` *EIP number* (this is determined by the EIP editor)

` title:` *EIP title*

` author:` *a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s). Details are below.*

` * discussions-to:` *a url pointing to the official discussion thread*

` status:` *Draft, Last Call, Accepted, Final, Active, Abandoned, Rejected, or Superseded*

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

The `author` header optionally lists the names, email addresses or usernames of the authors/owners of the EIP. Those who prefer anonymity may use a username only, or a first name and a username. The format of the author header value must be:

> Random J. User &lt;address@dom.ain&gt;

or

> Random J. User (@username)

if the email address or GitHub username is included, and

> Random J. User

if the email address is not given.

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

## Auxiliary Files

Images, diagrams and auxiliary files should be included in a subdirectory of the `assets` folder for that EIP as follows: `assets/eip-N` (where **N** is to be replaced with the EIP number). When linking to an image in the EIP, use relative links such as `../assets/eip-1/image.png`.

## Transferring EIP Ownership

It occasionally becomes necessary to transfer ownership of EIPs to a new champion. In general, we'd like to retain the original author as a co-author of the transferred EIP, but that's really up to the original author. A good reason to transfer ownership is because the original author no longer has the time or interest in updating it or following through with the EIP process, or has fallen off the face of the 'net (i.e. is unreachable or isn't responding to email). A bad reason to transfer ownership is because you don't agree with the direction of the EIP. We try to build consensus around an EIP, but if that's not possible, you can always submit a competing EIP.

If you are interested in assuming ownership of an EIP, send a message asking to take over, addressed to both the original author and the EIP editor. If the original author doesn't respond to email in a timely manner, the EIP editor will make a unilateral decision (it's not like such decisions can't be reversed :)).

## EIP Editors

The current EIP editors are

` * Nick Johnson (@arachnid)`

` * Casey Detrio (@cdetrio)`

` * Hudson Jameson (@Souptacular)`

` * Vitalik Buterin (@vbuterin)`

` * Nick Savers (@nicksavers)`

` * Martin Becze (@wanderer)`

` * Greg Colvin (@gcolvin)`

` * Alex Beregszaszi (@axic)`

` * Micah Zoltu (@MicahZoltu)`

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

December 7, 2015: EIP-1 has been improved and will be placed as a PR.

February 1, 2016: EIP-1 has added editors, made draft improvements to process, and has merged with Master stream.

March 21, 2018: Minor edits to accommodate the new automatically-generated EIP directory on [eips.ethereum.org](https://eips.ethereum.org/).

May 29, 2018: A last call process was added.

Oct 17, 2018: The `updated` header was introduced.

May 19, 2019: The **Abandoned** status was introduced.

Dec 4, 2019: The "Security Considerations" section was introduced.

June 17, 2020: Canonicalizes the format for referencing EIPs by number in the "Style Guide".

See [the revision history for further details](https://github.com/ethereum/EIPs/commits/master/EIPS/eip-1.md), which is also available by clicking on the History button in the top right of the EIP.

### Bibliography

[EIP-5]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5.md
[EIP-101]: https://github.com/ethereum/EIPs/issues/28
[EIP-90]: https://github.com/ethereum/EIPs/issues/90
[EIP-86]: https://github.com/ethereum/EIPs/issues/86#issue-145324865
[devp2p]: https://github.com/ethereum/wiki/wiki/%C3%90%CE%9EVp2p-Wire-Protocol
[EIP-8]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-8.md
[Light Ethereum Subprotocol]: https://github.com/ethereum/wiki/wiki/Light-client-protocol
[whisper]: https://github.com/ethereum/go-ethereum/wiki/Whisper-Overview
[swarm]: https://github.com/ethereum/go-ethereum/pull/2959
[API/RPC]: https://github.com/ethereum/wiki/wiki/JSON-RPC
[EIP-6]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-6.md
[contract ABIs]: https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
[interfaces repo]: https://github.com/ethereum/interfaces
[ERC-20]: https://github.com/ethereum/EIPs/issues/20
[ERC-26]: https://github.com/ethereum/EIPs/issues/26
[ERC-137]: https://github.com/ethereum/EIPs/issues/137
[ERC-67]: https://github.com/ethereum/EIPs/issues/67
[EIP-82]: https://github.com/ethereum/EIPs/issues/82
[EIP-75]: https://github.com/ethereum/EIPs/issues/75
[EIP-85]: https://github.com/ethereum/EIPs/issues/85
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




2020-09-19T20: 08: 29.1021621Z ## [بخش] شروع: برای اجرای این کار از یک دونده درخواست کنید
2020-09-19T20: 08: 29.8111187Z نمی توانید دونده آنلاین و بیکار خود میزبان خود را در مخزن فعلی پیدا کنید که با برچسب های مورد نیاز مطابقت داشته باشد: 'ubuntu-latest'
2020-09-19T20: 08: 29.8111267Z نمی توانید هیچ دونده آنلاین و خودکار میزبانی شده خود را در حساب / سازمان مخزن فعلی پیدا کنید که با برچسب های مورد نیاز مطابقت داشته باشد: 'ubuntu-latest'
2020-09-19T20: 08: 29.8111649Z در حساب / سازمان مخزن فعلی دونده میزبان آنلاین و بیکار یافت که با برچسب های مورد نیاز مطابقت داشته باشد: 'ubuntu-latest'
2020-09-19T20: 08: 29.9660315Z ## [بخش] اتمام: برای اجرای این کار از یک دونده درخواست کنید
2020-09-19T20: 08: 37.1373458Z نسخه دونده فعلی: "2.273.2"
2020-09-19T20: 08: 37.1399603Z ## [گروه] سیستم عامل
2020-09-19T20: 08: 37.1400750Z اوبونتو
2020-09-19T20: 08: 37.1401021Z 18.04.5
2020-09-19T20: 08: 37.1401274Z LTS
2020-09-19T20: 08: 37.1401497Z ## [گروه آخر]
2020-09-19T20: 08: 37.1401840Z ## [گروه] محیط مجازی
2020-09-19T20: 08: 37.1402244Z محیط زیست: ubuntu-18.04
2020-09-19T20: 08: 37.1402584Z نسخه: 20200914.1
2020-09-19T20: 08: 37.1403634Z شامل نرم افزار: https://github.com/actions/virtual-environments/blob/ubuntu18/20200914.1/images/linux/Ubuntu1804-README.md
2020-09-19T20: 08: 37.1404428Z ## [گروه آخر]
2020-09-19T20: 08: 37.1405356Z فهرست گردش کار را تهیه کنید
2020-09-19T20: 08: 37.1558425Z کلیه اقدامات مورد نیاز را آماده کنید
2020-09-19T20: 08: 37.1570646Z بارگیری مخزن اکشن "اقدام / stale @ v3"
2020-09-19T20: 08: 38.0903262Z ## [گروه] اجرای اقدامات / کهنه @ v3
2020-09-19T20: 08: 38.0903823Z با:
2020-09-19T20: 08: 38.0904654Z repo-token: ***
2020-09-19T20: 08: 38.0905826Z stale-pr-message: به مدت دو ماه هیچ فعالیتی در این درخواست جلب وجود ندارد. اگر فعالیت دیگری رخ ندهد ظرف یک هفته تعطیل می شود. اگر می خواهید این EIP را به جلو ببرید ، لطفاً به هر گونه بازخورد برجسته پاسخ دهید یا یک نظر اضافه کنید که نشان می دهد شما به همه بازخورد های لازم رسیدگی کرده اید و آماده بررسی هستید.
2020-09-19T20: 08: 38.0907403Z نزدیک پیام: این درخواست کشیدن به دلیل عدم فعالیت بسته شد. اگر هنوز در حال پیگیری آن هستید ، در صورت تمایل دوباره آن را باز کنید و به هر گونه بازخورد پاسخ دهید یا در یک نظر درخواست بازبینی کنید.
2020-09-19T20: 08: 38.0908212Z روز قبل از کهنه: 60
2020-09-19T20: 08: 38.0908817Z روز قبل از بسته شدن: 7
2020-09-19T20: 08: 38.0909221Z stale-pr-label: کهنه
2020-09-19T20: 08: 38.0909686Z-stale-edition-label-label: کهنه
2020-09-19T20: 08: 38.0910127Z عملیات در هر اجرا: 30
2020-09-19T20: 08: 38.0910657Z remove-stale-when-بروزرسانی: درست است
2020-09-19T20: 08: 38.0911118Z فقط اشکال زدایی: نادرست است
2020-09-19T20: 08: 38.0911467Z صعودی: نادرست
2020-09-19T20: 08: 38.0911883Z skip-stale-pr-message: false
2020-09-19T20: 08: 38.0912429Z skip-stale-Issue-message: false
2020-09-19T20: 08: 38.0912873Z ## [گروه آخر]
2020-09-19T20: 08: 42.6119794Z شماره یافت شده: شماره # 2987 - سلام و احوال پرسی در روابط عمومی شکست خورده آخرین بروزرسانی 2020-09-18T15: 01: 27Z (آیا اشتباه است؟)
2020-09-19T20: 08: 42.6122438Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.6123599Z شماره یافت شده: شماره # 2983 - بحث برای EIP-2980 آخرین به روزرسانی 2020-09-17T08: 02: 11Z (درست است؟ نادرست است)
2020-09-19T20: 08: 42.6124347Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.6125740Z شماره یافت شده: شماره # 2982 - EIP-2982: مرحله آرامش 0 آخرین بروزرسانی 2020-09-19T15: 43: 39Z (درست است؟)
2020-09-19T20: 08: 42.6127243Z شماره یافت شده: شماره # 2981 - EIP-2981: ERC-721 استاندارد حق امتیاز - روش استاندارد پذیرش حق امتیاز برای بازارهای NFT در سراسر اکوسیستم آخرین بروزرسانی 2020-09-18T02: 58: 10Z ( درست است؟)
2020-09-19T20: 08: 42.6128768Z شماره یافت شده: شماره شماره 2980 - EIP-2980: آخرین توکن دارایی سوئیسی سازگار با ERC-20 آخرین بروزرسانی 2020-09-17T12: 14: 16Z (درست است)
2020-09-19T20: 08: 42.6130147Z شماره یافت شده: شماره # 2969 - EIP-1: حداقل به یک نام کاربری github نیاز دارید که آخرین بار به روز شده است 2020-09-11T15: 10: 45Z (درست است؟)
2020-09-19T20: 08: 42.7065680Z شماره یافت شده: شماره # 2967 - EIP-1: قوانین قوی تر برای بحث-url آخرین بروزرسانی: 2020-09-11T00: 46: 43Z (اشتباه است؟
2020-09-19T20: 08: 42.7066273Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7068342Z شماره یافت شده: شماره # 2965 - بحث در مورد نشانه نهایی خدمات (FST) آخرین به روزرسانی 2020-09-10T17: 47: 20Z (اشتباه است؟)
2020-09-19T20: 08: 42.7068882Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7069553Z شماره یافت شده: شماره # 2962 - بایگانی EIP های متروک / عقب مانده آخرین بروزرسانی 2020-09-11T16: 07: 40Z (درست نیست؟ کاذب است)
2020-09-19T20: 08: 42.7070050Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7070701Z شماره یافت شده: شماره # 2961 - معرفی اتوماسیون بیشتر آخرین بروزرسانی 2020-09-10T06: 04: 31Z (آیا غلط است؟)
2020-09-19T20: 08: 42.7071156Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7071976Z شماره یافت شده: شماره شماره 2960 - EIP-1: توصیه RFC 2119 را در EIP-1 ​​بگنجانید تا EIP نیازی به نسخه برداری نداشته باشد آخرین بروزرسانی 2020-09-10T05: 57: 36Z (است pr؟ false)
2020-09-19T20: 08: 42.7072917Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7073607Z شماره یافت شده: شماره # 2959 - بحث برای EIP2390 - آخرین بار GeoENS به روز شده 2020-09-09T16: 59: 41Z (اشتباه است؟)
2020-09-19T20: 08: 42.7074066Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7074596Z شماره یافت شده: شماره # 2955 - eip-2565: دوباره کاری کنید که آخرین بار به روز شده است 2020-09-08T17: 30: 59Z (درست است؟)
2020-09-19T20: 08: 42.7075245Z شماره یافت شده: شماره # 2951 - آخرین بار پیش پرده SHA3 به روز شده 2020-09-11T08: 22: 55Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 42.7075670Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7076655Z شماره یافت شده: شماره شماره 2947 - قانونی را به EIP-1 ​​اضافه می کند که مراجع به سایر EIP ها باید از قالب مسیر نسبی استفاده کنند و اولین مرجع باید پیوند داده شود. آخرین به روزرسانی 2020-09-14T16: 56: 44Z (درست است؟)
2020-09-19T20: 08: 42.7077603Z شماره یافت شده: شماره # 2941 - EIP-1: متروکه در مقابل پس گرفته شده آخرین به روز رسانی 2020-09-12T10: 17: 40Z (درست است؟ نادرست است)
2020-09-19T20: 08: 42.7078115Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7078763Z شماره یافت شده: شماره # 2940 - EIP-1: آخرین بخش اجرای آخرین به روز رسانی 2020-09-05T12: 51: 31Z (درست است؟ نادرست است)
2020-09-19T20: 08: 42.7079227Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7079842Z شماره یافت شده: شماره شماره 2934 - غیرفعال کردن خودساختار آخرین بروزرسانی 2020-09-06T12: 56: 39Z (درست است؟)
2020-09-19T20: 08: 42.7085088Z شماره یافت شده: شماره # 2925 - بحث در مورد ERC-2917: محاسبه پاداش ذینفع آخرین بروزرسانی: 2020-09-09T11: 17: 44Z (اشتباه است؟)
2020-09-19T20: 08: 42.7085635Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7086463Z شماره یافت شده: شماره شماره 2924 - تغییرات 1559 برای ایجاد یک استخر مشترک برای همه معاملات. آخرین به روز رسانی 2020-09-03T05: 09: 27Z (درست است؟)
2020-09-19T20: 08: 42.7087333Z شماره یافت شده: شماره # 2922 - بهبود قالب بندی و افزودن تعاریف بیشتر به EIP-634 آخرین به روزرسانی 2020-09-09T09: 47: 49Z (درست است؟)
2020-09-19T20: 08: 42.7088411Z مسئله موجود: شماره شماره 2920 - پیوند کانال یوتیوب را به پیکربندی اضافه کنید (و گروه توییتر را نیز تغییر دهید) آخرین بروزرسانی 2020-09-03T23: 46: 55Z (درست است؟
2020-09-19T20: 08: 42.7089320Z شماره یافت شده: شماره # 2915 - رفع ابهام در تعریف همگام سازی برای eth_syncing (EIP-1474) آخرین بروزرسانی 2020-08-28T22: 20: 48Z (درست است؟)
2020-09-19T20: 08: 42.7090238Z شماره یافت شده: شماره # 2907 - بحث برای ERC-721 Royalties EIP. آخرین به روزرسانی 2020-09-18T12: 53: 40Z (pr is false)
2020-09-19T20: 08: 42.7090926Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7091624Z شماره یافت شده: شماره # 2892 - انتقال از EIP-2565 از "آخرین تماس" به "پذیرفته شده" آخرین به روز رسانی 2020-09-08T17: 29: 04Z (درست است؟)
2020-09-19T20: 08: 42.7092431Z شماره یافت شده: شماره # 2890 - انتقال "eips.ethereum.org" به Zola آخرین بروزرسانی 2020-09-09T14: 59: 58Z (درست است؟)
2020-09-19T20: 08: 42.7093233Z شماره یافت شده: شماره # 2878 - کاهش پاداش بلوک به 0.5 ETH (DRAFT) آخرین به روز رسانی 2020-08-28T21: 18: 42Z (درست است؟)
2020-09-19T20: 08: 42.7094423Z شماره یافت شده: شماره # 2872 - DRAFT - به روزرسانی جوایز بلوک شبکه برای رعایت سیاست "حداقل میزان قابل اطمینان برای امنیت شبکه" آخرین بروزرسانی 2020-08-28T21: 20: 47Z (pr ؟ درست است، واقعی)
2020-09-19T20: 08: 42.7095405Z شماره یافت شده: شماره # 2871 - اضافه کردن استاندارد برای توکن قابل ادعا آخرین به روزرسانی 2020-08-28T21: 18: 25Z (درست است؟)
2020-09-19T20: 08: 42.7096601Z شماره یافت شده: شماره # 2863 - افزودن تماس های قرارداد مجموع خودسرانه آخرین بروزرسانی 2020-08-07T17: 01: 45Z (درست است؟ نادرست است)
2020-09-19T20: 08: 42.7097185Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7097964Z شماره یافت شده: شماره # 2857 - تنظیم ERC-1271 بر روی آخرین تماس آخرین بروزرسانی 2020-09-03T23: 41: 31Z (درست است؟)
2020-09-19T20: 08: 42.7098948Z شماره یافت شده: شماره # 2845 - مباحث مربوط به EIP: افزودن روشهای مربوط به DID به JSON-RPC آخرین به روزرسانی 2020-09-11T07: 33: 11Z (اشتباه است؟)
2020-09-19T20: 08: 42.7099674Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7101127Z شماره یافت شده: شماره # 2840 - 2786: افزودن رویداد قطع اتصال به مشخصات آخرین به روزرسانی 2020-09-04T00: 54: 05Z (درست است؟)
2020-09-19T20: 08: 42.7102337Z شماره یافت شده: شماره # 2820 - ایجاد eip-2794.md آخرین بروزرسانی 2020-09-03T23: 56: 04Z (درست است؟)
2020-09-19T20: 08: 42.7103292Z شماره یافت شده: شماره # 2817 - تلاش برای رفع مشکل مختلط 2-EIP آخرین بروزرسانی 2020-09-03T23: 55: 29Z (درست است؟)
2020-09-19T20: 08: 42.7104423Z شماره یافت شده: شماره # 2810 - ایجاد الگو برای ارتقا Network شبکه postmortem.md آخرین بروزرسانی 2020-08-03T18: 41: 32Z (درست است؟)
2020-09-19T20: 08: 42.7105271Z شماره یافت شده: شماره # 2809 - گزارش پس از مرگ Muir Glacier آخرین بروزرسانی 2020-08-06T16: 08: 50Z (درست است؟)
2020-09-19T20: 08: 42.7106001Z شماره یافت شده: شماره # 2801 - بحث مربوط به امضاهای الکترونیکی آخرین بروزرسانی 2020-07-19T04: 55: 47Z (اشتباه است؟ کاذب است)
2020-09-19T20: 08: 42.7106464Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7107144Z شماره یافت شده: شماره # 2792 - سازگار با ABIv2 به EIP آخرین به روزرسانی 2020-07-25T02: 58: 39Z (درست است؟)
2020-09-19T20: 08: 42.7107977Z شماره یافت شده: شماره # 2791 - Ethereum باید بتواند چندین معامله را در یکی از آخرین بروزرسانی های 2020-07-16T16: 59: 38Z ترکیب کند (آیا غلط است؟)
2020-09-19T20: 08: 42.7108538Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7109289Z شماره یافت شده: شماره # 2787 - بحث برای EIP-2786: اتصال / قطع ارتباط ارائه دهنده Ethereum آخرین بروزرسانی 2020-08-18T02: 14: 02Z (آیا دروغ است؟)
2020-09-19T20: 08: 42.7109833Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7110489Z شماره یافت شده: شماره # 2782 - بروزرسانی ERC725 با فرمت جدید و زیر استاندارد ERC725X و ERC725Y آخرین بروزرسانی 2020-09-01T10: 47: 58Z (درست است)
2020-09-19T20: 08: 42.7111230Z شماره یافت شده: شماره # 2777 - 747: آخرین بار پاکسازی به روز شده در تاریخ 09-09-07T23: 39: 43Z (درست است؟)
2020-09-19T20: 08: 42.7111858Z شماره یافت شده: شماره # 2775 - بحث برای EIP-2774 آخرین بروزرسانی 2020-07-07T22: 55: 32Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 42.7112302Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7113003Z شماره یافت شده: شماره # 2774 - EIP 2774 - فرآیند چالش حساس به قیمت آخرین به روزرسانی 2020-08-28T21: 13: 20Z (درست است؟)
2020-09-19T20: 08: 42.7113702Z شماره یافت شده: شماره # 2770 - آخرین ارسال دهنده به روز شده در تاریخ 2020-08-28T21: 21: 53Z (درست است؟ درست است)
2020-09-19T20: 08: 42.7114560Z شماره یافت شده: شماره # 2766 - ERC: استاندارد حاکمیت مالکیت قرارداد آخرین به روزرسانی 2020-07-21T01: 45: 08Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 42.7115368Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7115998Z شماره یافت شده: شماره # 2765 - به روزرسانی کلمه آخرین به روزرسانی 2020-09-09T09: 14: 55Z (درست است؟)
2020-09-19T20: 08: 42.7116916Z شماره یافت شده: شماره # 2764 - به روزرسانی کلمه آخرین به روزرسانی 2020-08-31T14: 30: 22Z (درست است؟)
2020-09-19T20: 08: 42.7117996Z شماره یافت شده: شماره # 2763 - به روزرسانی کلمه آخرین به روزرسانی 2020-08-31T14: 30: 28Z (درست است؟)
2020-09-19T20: 08: 42.7119503Z شماره یافت شده: شماره # 2762 - مرتب سازی برای EIP-2333 آخرین بروزرسانی 2020-08-28T20: 50: 02Z (درست است؟)
2020-09-19T20: 08: 42.7120500Z شماره یافت شده: شماره # 2751 - غیرفعال کردن EIP SELFDESTRUCT آخرین بروزرسانی 2020-09-04T02: 10: 17Z (درست است؟)
2020-09-19T20: 08: 42.7121473Z موضوع یافت شده: شماره # 2750 - بروزرسانی EIP 1822 - 1967 سازگاری آخرین بروزرسانی 2020-08-29T00: 55: 40Z (درست است؟)
2020-09-19T20: 08: 42.7122785Z شماره یافت شده: شماره # 2724 - EIP - برآورد آخرین اطلاعات بازگشت گاز به روز شده 2020-08-28T21: 17: 36Z (درست است)
2020-09-19T20: 08: 42.7124450Z شماره یافت شده: شماره # 2710 - EIP-2657: به روزرسانی وضعیت OpenEthereum آخرین بروزرسانی: 2020-09-05T17: 38: 24Z (درست است؟)
2020-09-19T20: 08: 42.7125450Z شماره یافت شده: شماره # 2709 - رفع اشکال کوچک EIP-2334: به طور خاص شرح استخراج کلیدهای اعتبار سنجی آخرین به روزرسانی 2020-08-28T21: 22: 16Z (درست است؟)
2020-09-19T20: 08: 42.7126465Z شماره یافت شده: شماره # 2701 - بحث برای EIP-2700 آخرین به روزرسانی 2020-06-04T23: 21: 05Z (درست است؟ نادرست است)
2020-09-19T20: 08: 42.7126947Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7127579Z شماره یافت شده: شماره # 2697 - بحث برای EIP-2696 آخرین به روزرسانی 2020-06-04T07: 07: 00Z (آیا غلط است؟)
2020-09-19T20: 08: 42.7128014Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7128577Z شماره پیدا شده: شماره شماره 2680 - برش اولیه طرح کیف پول EIP. آخرین به روزرسانی 2020-08-28T20: 51: 36Z (درست است؟)
2020-09-19T20: 08: 42.7129621Z شماره یافت شده: شماره # 2671 - افزودن نام به keystore آخرین بروزرسانی 2020-08-31T15: 06: 42Z (درست است؟)
2020-09-19T20: 08: 42.7130748Z مسئله موجود: شماره شماره 2670 - حذف محدودیت های شاخص اصلی از EIP-2334 آخرین بروزرسانی 2020-08-28T20: 51: 19Z (درست است؟)
2020-09-19T20: 08: 42.7132037Z شماره یافت شده: شماره شماره 2666 - پیش تولید و Keccak256 نسخه جدیدترین نسخه 2020-08-31T16: 38: 49Z آخرین بروزرسانی (درست است؟)
2020-09-19T20: 08: 42.7132897Z شماره یافت شده: شماره # 2665 - آخرین بار برای تمدید هزینه انتقال ERC-721 آخرین به روز رسانی 2020-07-12T11: 49: 31Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 42.7133586Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7134791Z شماره یافت شده: شماره # 2663 - محدودیتهایی را برای پرش پیشنهاد دهید. آخرین به روزرسانی 2020-08-28T21: 14: 00Z (درست است؟)
2020-09-19T20: 08: 42.7135641Z شماره یافت شده: شماره # 2645 - EIP-2645: افزودن کیف پول سلسله مراتبی برای لایه 2 آخرین بروزرسانی 2020-08-28T21: 23: 46Z (درست است)
2020-09-19T20: 08: 42.7136408Z شماره یافت شده: شماره # 2640 - آخرین پیش نویس کاری ProgPoW آخرین به روزرسانی 2020-06-19T14: 32: 00Z (آیا اشتباه است؟)
2020-09-19T20: 08: 42.7136853Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7137514Z مسئله موجود: شماره شماره 2636 - افزودن رابط قابل تلفیق مستقیماً به EIPs آخرین بروزرسانی 2020-09-06T21: 37: 30Z (درست است؟)
2020-09-19T20: 08: 42.7138322Z شماره یافت شده: شماره # 2633 - EIP-2633: پیشنهاد رسمی برای دولت قابل ارتقا آخرین بروزرسانی 2020-09-10T07: 08: 08Z (درست است)
2020-09-19T20: 08: 42.7139190Z شماره یافت شده: شماره شماره 2631 - اضافه شدن eip جدید Tagging Tokens Indicator Interface آخرین بروزرسانی 2020-08-29T00: 03: 40Z (درست است)
2020-09-19T20: 08: 42.7140017Z شماره یافت شده: شماره # 2630 - رابط نشانگر نشانه گذاری برچسب ها - بحث آخرین به روزرسانی 2020-05-06T18: 22: 46Z (اشتباه است؟)
2020-09-19T20: 08: 42.7140664Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 42.7141400Z شماره یافت شده: شماره # 2628 - EIP-2628 - عنوان در وضعیت پیام آخرین به روزرسانی 2020-08-28T20: 45: 29Z (درست است؟)
2020-09-19T20: 08: 42.7142139Z شماره یافت شده: شماره # 2623 - به روزرسانی eip-634.md آخرین بروزرسانی 2020-08-28T23: 09: 55Z (درست است؟)
2020-09-19T20: 08: 42.7142871Z موضوع یافت شده: شماره # 2622 - EIP 2622 - کل مشکل در هدر بلوک آخرین بروزرسانی 2020-08-28T20: 44: 10Z (درست است؟)
2020-09-19T20: 08: 42.7143658Z شماره یافت شده: شماره # 2619 - EIP 2619 - Geotimeline تماس با اطلاعات ردیابی استاندارد آخرین به روز رسانی 2020-09-14T17: 40: 21Z (درست است؟)
2020-09-19T20: 08: 42.7144105Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 42.7144482Z بررسی برچسب قدیمی در مورد شماره 2619
2020-09-19T20: 08: 42.9114317Z شماره شماره 2619 کهنه در تاریخ مشخص شد: 2020-09-08T16: 20: 15Z
2020-09-19T20: 08: 42.9115626Z بررسی نظرات در مورد شماره 2619 از 2020-09-08T16: 20: 15Z
2020-09-19T20: 08: 43.0456708Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 43.0465085Z شماره شماره 2619 در مورد نظر داده شده است: نادرست است
شماره 209-09-2020: 08: 43.0489806Z شماره 2619 به روز شده است: درست است
2020-09-19T20: 08: 43.0490917Z قدیمی قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند آن را ببندد (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 43.0492593Z شماره یافت شده: شماره شماره 2616 - EIP2615: علامت غیر قابل دفع با توزیع وام و اجاره آخرین به روزرسانی 2020-06-27T09: 07: 15Z (آیا دروغ است؟)
2020-09-19T20: 08: 43.0493650Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0495317Z شماره یافت شده: شماره شماره 2614 - افزودن اجرای KEthereum به EIP634 آخرین بروزرسانی 2020-08-28T23: 10: 51Z (درست است؟)
2020-09-19T20: 08: 43.0497505Z شماره یافت شده: شماره # 2613 - «اجازه» ERC-2612: مصوبات توکن 712 امضا شده آخرین بار 2020-09-18T16: 27: 53Z به روز شده (درست است؟ نادرست است)
2020-09-19T20: 08: 43.0498571Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0500495Z شماره یافت شده: شماره # 2608 - استاندارد Token ERC2608 با تماس دلخواه ایمن (پسوند ERC20) آخرین به روزرسانی 2020-04-20T07: 51: 23Z (اشتباه است؟
2020-09-19T20: 08: 43.0502831Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0505616Z شماره یافت شده: شماره # 2607 - افزودن جستجوی سایت آخرین بروزرسانی 2020-08-29T01: 03: 19Z (آیا غلط است؟)
2020-09-19T20: 08: 43.0506953Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0508264Z شماره یافت شده: شماره شماره 2605 - به روزرسانی EIP 2515 برای وضوح. آخرین به روزرسانی 2020-09-10T22: 42: 48Z (درست است؟)
2020-09-19T20: 08: 43.0510875Z شماره یافت شده: شماره # 2604 - EIP 2604: قیمت مشروط به آخرین به روزرسانی 2020-09-11T11: 43: 11Z (درست است)
2020-09-19T20: 08: 43.0511956Z مسئله موجود: شماره شماره 2602 - EIP-2602: غیرفعال کردن تأیید پیام خالی هش برای پیش پردازی ecrecover آخرین بروزرسانی 2020-08-28T20: 42: 22Z (درست است؟)
2020-09-19T20: 08: 43.0513411Z شماره یافت شده: شماره # 2600 - EIP 2585: آخرین حمل و نقل بدافزار متغیر بومی آخرین به روز رسانی 2020-08-29T00: 02: 26Z (درست است)
2020-09-19T20: 08: 43.0514655Z شماره یافت شده: شماره # 2596 - افزودن پیش نویس EIP برای رابط نمودار (شبکه با ارزش) آخرین بروزرسانی 2020-08-29T00: 02: 43Z (درست است؟)
2020-09-19T20: 08: 43.0516413Z شماره یافت شده: شماره # 2585 - حداقل و قابل انتقال متغیر انتقال دهنده متا آخرین به روزرسانی 2020-06-15T22: 20: 04Z (اشتباه است؟
2020-09-19T20: 08: 43.0517162Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0518407Z شماره یافت شده: شماره # 2582 - افزودن "فهرست مطالب" به وب سایت EIPs آخرین بروزرسانی 2020-08-29T15: 10: 14Z (درست است؟)
2020-09-19T20: 08: 43.0519517Z شماره یافت شده: شماره # 2581 - اضافه کردن عناوین لنگر به وب سایت EIPs آخرین به روز رسانی 2020-08-29T03: 40: 25Z (درست است؟)
2020-09-19T20: 08: 43.0520841Z شماره یافت شده: شماره # 2579 - آخرین بازبینی فهرست عمومی درخت مرکل 2020-08-29T00: 04: 28Z (به درستی درست است)
2020-09-19T20: 08: 43.0522088Z شماره یافت شده: شماره # 2571 - ERC-2571: استاندارد توکن حق امتیاز سازندگان آخرین بروزرسانی 2020-06-07T11: 51: 24Z (اشتباه است؟ کاذب است)
2020-09-19T20: 08: 43.0522712Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0523900Z شماره یافت شده: شماره # 2567 - پارامترهای قابل خواندن توسط انسان برای اجرای عملکرد قرارداد آخرین بروزرسانی: 2020-04-04T15: 59: 48Z (اشتباه است؟
2020-09-19T20: 08: 43.0529302Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0531920Z شماره یافت شده: شماره # 2566 - EIP-2566: پارامترهای قابل خواندن توسط انسان برای اجرای عملکرد قرارداد آخرین بروزرسانی: 2020-08-28T20: 41: 34Z (درست است)
2020-09-19T20: 08: 43.0533036Z شماره یافت شده: شماره # 2561 - EIP: eth_simulateTransaction - آخرین معاملات به روز شده در تاریخ 2020-05-21T09: 43: 40Z (درست است؟ نادرست است)
2020-09-19T20: 08: 43.0533802Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0534797Z شماره یافت شده: شماره شماره 2557 - درخواست ویژگی: فقط وقتی معاملات در انتظار معاملات Clique هستند آخرین بار به روزرسانی 2020-06-29T15: 19: 23Z استخراج را فعال کنید (درست نیست؟ کاذب است)
2020-09-19T20: 08: 43.0535766Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0537292Z شماره یافت شده: شماره # 2553 - EIP-1: وضعیت "پذیرفته شده" تنظیم شده است تا برای جنجال ها به صورت آخرین مورد به روز شود 2020-08-29T03: 36: 48Z
2020-09-19T20: 08: 43.0538265Z شماره یافت شده: شماره # 2547 - EIP-2547: آخرین علامت ترکیبی چند کلاسه آخرین بروزرسانی 2020-08-28T23: 56: 31Z (درست است؟)
2020-09-19T20: 08: 43.0539633Z شماره یافت شده: شماره # 2545 - EIP-2025: تغییر وضعیت به بازنشسته آخرین بروزرسانی 2020-09-11T05: 18: 24Z (درست است؟)
2020-09-19T20: 08: 43.0540483Z شماره یافت شده: شماره # 2539 - آخرین بار عملیات منحنی BLS12-377 به روز شده 2020-09-16T18: 08: 04Z (درست است؟)
2020-09-19T20: 08: 43.0541421Z شماره یافت شده: شماره # 2538 - EIP-2538: بیانیه وضعیت اطلاعاتی در برابر فعال سازی ProgPoW آخرین بروزرسانی 2020-09-08T10: 12: 17Z (درست است؟)
2020-09-19T20: 08: 43.0542484Z شماره یافت شده: شماره # 2535 - آخرین بار Diamond Standard به روز شده در 2020-09-18T13: 33: 30Z (آیا اشتباه است؟)
2020-09-19T20: 08: 43.0542952Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 43.0543847Z شماره موجود: شماره شماره 2526 - Errata: تغییر نام متغیر EIP-2200 SLOAD_GAS به SSTORE_DIRTY_GAS آخرین بروزرسانی 2020-09-08T17: 46: 28Z (درست است؟)
2020-09-19T20: 08: 44.3092094Z شماره یافت شده: شماره # 2520 - پیش نویس EIP: چندین پرونده ثبت محتوا برای ENS آخرین به روزرسانی 2020-08-28T23: 57: 55Z (درست است)
2020-09-19T20: 08: 44.3095856Z شماره یافت شده: شماره # 2508 - فهرست مطالب اضافه شده به EIP-1 ​​و بخشی برای Hardforks و مدل EIP-Centric آخرین بروزرسانی 2020-09-03T23: 09: 05Z (pr ؟ درست است، واقعی)
2020-09-19T20: 08: 44.3100645Z شماره یافت شده: شماره # 2502 - ERC: هیئت موضوعی آخرین بار 2020-08-28T23: 58: 41Z به روز شد (درست است؟)
2020-09-19T20: 08: 44.3104577Z شماره یافت شده: شماره شماره 2501 - پشتیبانی از PlantUML را در وب سایت EIP اضافه کنید. آخرین به روزرسانی 2020-04-10T14: 58: 05Z (اشتباه است؟)
2020-09-19T20: 08: 44.3106443Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3137058Z موضوع یافت شده: شماره # 2492 - آخرین بار استقرار قرارداد ERC1400 به روز شده در تاریخ 2020-01-29T10: 07: 02Z (آیا اشتباه است؟)
2020-09-19T20: 08: 44.3138218Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3139012Z شماره یافت شده: شماره شماره 2489 - اضافه کردن مستهلک GAS EIP آخرین به روزرسانی 2020-08-28T23: 37: 42Z (درست است؟)
2020-09-19T20: 08: 44.3147636Z شماره پیدا شده: شماره # 2483 - ERC-2477 بحث آخرین به روزرسانی 2020-06-10T02: 09: 51Z (آیا غلط است)
2020-09-19T20: 08: 44.3148628Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3150582Z شماره یافت شده: شماره # 2482 - موضوع بحث در مورد EIP-2481 در حال بحث برای شناسه های درخواست در پروتکل استاندارد آخرین به روزرسانی 2020-05-07T21: 55: 36Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.3151922Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3179195Z شماره یافت شده: شماره # 2479 - درخواست ویژگی: ایجاد عقل سالم برای رابط های جامدادی در EIPs آخرین بروزرسانی 2020-01-20T01: 06: 57Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.3180214Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3181199Z شماره یافت شده: شماره # 2473 - EIP: آخرین بار انتزاع گاز به روز شده 2020-08-28T23: 59: 30Z (درست است؟)
2020-09-19T20: 08: 44.3181900Z شماره موجود: شماره # 2472 - قسمت "EIPs اختیاری" در هدر آخرین به روزرسانی 2020-09-04T01: 56: 12Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3182422Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3183021Z شماره یافت شده: شماره # 2467 - تنظیم ERC-1620 روی "آخرین تماس" آخرین بروزرسانی 2020-09-09T12: 29: 10Z (درست است؟)
2020-09-19T20: 08: 44.3183955Z شماره یافت شده: شماره # 2465 - موضوع بحث برای EIP-2464: eth / 65: آخرین اعلامیه ها و بازیابی های معامله آخرین بروزرسانی: 2020-07-18T04: 53: 58Z (pr is false)
2020-09-19T20: 08: 44.3184542Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3185355Z شماره یافت شده: شماره # 2463 - موضوع بحث برای EIP-2462 (استاندارد رابط برای سازگارهای Ethereum) آخرین به روز رسانی 2020-01-13T04: 27: 53Z (آیا غلط است؟)
2020-09-19T20: 08: 44.3186152Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3187066Z شماره یافت شده: شماره # 2462 - EIP-2462 (استاندارد رابط برای سازگارهای Ethereum) آخرین بروزرسانی 2020-08-28T23: 59: 54Z (درست است؟)
2020-09-19T20: 08: 44.3187877Z شماره یافت شده: شماره # 2456 - آخرین نسخه به روز شده بر اساس زمان آخرین بروزرسانی 2020-08-29T00: 00: 49Z (درست است؟)
2020-09-19T20: 08: 44.3188571Z شماره یافت شده: شماره # 2450 - پشتیبانی از پری دریایی (نمودارها) در EIPs آخرین بروزرسانی 2020-09-11T00: 04: 46Z (اشتباه است؟)
2020-09-19T20: 08: 44.3189255Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3190091Z شماره یافت شده: شماره # 2440 - موضوع بحث برای EIP-2098 (نمایندگی امضای جمع و جور) آخرین به روز رسانی 2019-12-16T23: 07: 37Z (اشتباه است؟ کاذب است)
2020-09-19T20: 08: 44.3190931Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3191933Z شماره یافت شده: شماره # 2439 - موضوع بحث برای EIP-634 (ذخیره سازی سوابق متن در ENS) آخرین بروزرسانی 2020-08-26T15: 55: 28Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.3192560Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3193320Z شماره یافت شده: شماره # 2430 - EIP-1191: تنظیم وضعیت نهایی و حذف جدول فرزندخواندگی آخرین به روزرسانی 2020-09-12T06: 18: 19Z (درست است؟)
2020-09-19T20: 08: 44.3194426Z شماره یافت شده: شماره شماره 2429 - ERC: بازیابی مخفی Multisig آخرین به روز رسانی 2020-08-29T00: 01: 03Z (درست است؟)
2020-09-19T20: 08: 44.3195318Z شماره یافت شده: شماره شماره 2407 - EIP-2020: آخرین نشانه استاندارد پول الکترونیکی آخرین بروزرسانی 2019-11-28T10: 09: 57Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3195788Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3199183Z شماره یافت شده: شماره # 2401 - ERC721 safeTransfer از توضیحات آخرین به روزرسانی شده 2019-12-12T08: 39: 29Z (pr؟ false)
2020-09-19T20: 08: 44.3200376Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3201347Z شماره یافت شده: شماره شماره 2399 - EIP جدید: NFT های زنجیره ای برای قرار دادن فایلها و کد روی زنجیره آخرین به روزرسانی 2020-09-04T00: 19: 05Z
2020-09-19T20: 08: 44.3202483Z شماره یافت شده: شماره # 2393 - بحث: چندین سوابق محتوا برای ENS آخرین به روزرسانی 2020-03-16T17: 39: 47Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3203791Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3204517Z شماره یافت شده: شماره # 2381 - اضافه کردن پشتیبانی ENS برای آدرس دهی ERC721 NFT آخرین بروزرسانی 2020-09-09T13: 07: 56Z (درست است؟)
2020-09-19T20: 08: 44.3205339Z شماره یافت شده: شماره # 2379 - پیش نویس EIP: استاندارد رابط Oracle Pull # 2362 آخرین بروزرسانی 2019-12-11T02: 01: 34Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.3205831Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3206986Z شماره یافت شده: شماره # 2375 - پشتیبانی ENS از نام های متعارف آخرین به روزرسانی 2020-09-11T23: 08: 41Z (درست است؟)
2020-09-19T20: 08: 44.3208022Z شماره یافت شده: شماره # 2367 - ERC: Open Grant Standard آخرین به روزرسانی 2020-02-03T15: 29: 10Z (آیا غلط است)
2020-09-19T20: 08: 44.3208993Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3210150Z شماره یافت شده: شماره # 2365 - EIP-2364: eth / 64: مصاحبه با پروتکل فورکاد شده که آخرین بار به روز شده است 2020-02-26T02: 34: 24Z (اشتباه است؟
2020-09-19T20: 08: 44.3210936Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3211684Z موضوع یافت شده: شماره # 2350 - قراردادهای معنایی ERC-2350 (پسوند ERC - پیش نویس) آخرین به روزرسانی 2019-11-05T19: 38: 44Z (اشتباه است؟)
2020-09-19T20: 08: 44.3212573Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3215164Z شماره یافت شده: شماره شماره 2343 - مقاله زرد و بالقوه تخلف برای صدور مجوز EIP آخرین بروزرسانی 2020-08-29T01: 12: 30Z (اشتباه است؟
2020-09-19T20: 08: 44.3215829Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3217004Z شماره یافت شده: شماره # 2339 - پیش نویس EIP: BLS12-381 Keystore آخرین بروزرسانی 2020-07-26T03: 32: 42Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3218086Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3219291Z شماره یافت شده: شماره # 2338 - پیش نویس EIP: BLS12-381 سلسله مراتب حساب قطعی آخرین به روزرسانی 2020-07-23T16: 05: 02Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3219856Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3223069Z شماره یافت شده: شماره # 2337 - پیش نویس EIP: BLS12-381 Key Key آخرین بروزرسانی 2020-09-14T02: 42: 41Z (اشتباه است؟)
2020-09-19T20: 08: 44.3223683Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3224396Z شماره یافت شده: شماره # 2324 - ERC: استاندارد اشتراک آخرین به روزرسانی 2019-10-26T13: 36: 44Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3224901Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3225847Z شماره یافت شده: شماره # 2320 - از شرط ERC-831 ENS برای جلوگیری از اجرای بد استفاده کنید ذکر شده آخرین بروزرسانی 2020-09-03T22: 52: 11Z (درست است؟)
2020-09-19T20: 08: 44.3226741Z شماره یافت شده: شماره # 2319 - بحث: آخرین بروزرسانی EIP-1193 2020-07-14T20: 36: 42Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3227501Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3228250Z شماره یافت شده: شماره # 2315 - زیرمجموعه های ساده برای EVM آخرین به روزرسانی 2020-06-25T18: 55: 09Z (اشتباه است؟)
2020-09-19T20: 08: 44.3229098Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3230360Z شماره یافت شده: شماره # 2309 - ERC-2309: ERC-721 افزونه انتقال پی در پی آخرین بروزرسانی 2020-06-17T02: 13: 21Z (اشتباه است؟)
2020-09-19T20: 08: 44.3230917Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3231778Z شماره یافت شده: شماره # 2307 - ERC 2307: ذخیره داده ها با ورود به سیستم برای کاهش هزینه بنزین آخرین به روزرسانی 2019-10-09T11: 26: 13Z (اشتباه است؟
2020-09-19T20: 08: 44.3232284Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3233122Z شماره یافت شده: شماره # 2303 - ERC: آخرین واسط استاندارد برای نشانه های چنگال آخرین به روز رسانی 2019-09-30T18: 59: 46Z (اشتباه است؟)
2020-09-19T20: 08: 44.3233656Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3234333Z شماره یافت شده: شماره # 2301 - رفع دو اشتباه تایپی در EIP-1812.md آخرین بروزرسانی 2020-08-31T11: 03: 20Z (درست است؟)
2020-09-19T20: 08: 44.3235129Z شماره یافت شده: شماره # 2294 - EIP-2294: صریحاً به اندازه شناسه زنجیره ای محدود شده است آخرین بار به روز شده 2019-09-20T03: 58: 50Z (اشتباه است؟)
2020-09-19T20: 08: 44.3235634Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3236527Z شماره یافت شده: شماره # 2290 - "استاندارد ERC20" - رویکرد جدید به نشانه ها: اشیا from از کارخانه جهانی ، نه مشخصات. آخرین به روزرسانی 2019-09-18T00: 39: 48Z (pr is false)
2020-09-19T20: 08: 44.3237359Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3238223Z موضوع یافت شده: شماره # 2281 - (بحث) EIP-2280: برنامه افزودنی erc-20 برای پشتیبانی از معاملات متا بومی آخرین بروزرسانی 2019-10-17T07: 46: 47Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.3238782Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3239385Z شماره یافت شده: شماره # 2276 - آخرین به روزرسانی های EIP-1985 2020-09-08T16: 57: 39Z (درست است؟)
2020-09-19T20: 08: 44.3240219Z شماره یافت شده: شماره # 2270 - EIP-2270: ایجاد حساب Ethereum از شناسه دیجیتال آخرین بروزرسانی 2019-10-24T17: 26: 11Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3240749Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3241810Z شماره یافت شده: شماره # 2269 - EIP-2269: قرارداد نمایندگی فیات (FRC): استاندارد نمایندگی فیات آخرین به روزرسانی: 09-09-09T08: 24: 47Z (دروغ است؟)
2020-09-19T20: 08: 44.3242804Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3243643Z شماره یافت شده: شماره # 2266 - EIP2266: استاندارد قرارداد انتخاب تماس آمریکایی مبتنی بر مبادله اتمی آخرین به روزرسانی 2020-09-10T05: 35: 31Z (غلط است؟)
2020-09-19T20: 08: 44.3244209Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3244886Z شماره یافت شده: شماره # 2258 - ERC 2258: استاندارد مالکیت حضانت آخرین بروزرسانی 2019-11-14T22: 49: 47Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3245982Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3246783Z شماره یافت شده: شماره # 2255 - EIP-2255: آخرین مجوزهای کیف پول Web3 آخرین بروزرسانی: 2020-07-27T09: 31: 42Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3247237Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3247915Z شماره یافت شده: شماره # 2252 - افزودن EIP-684 به Byzantium Meta آخرین بروزرسانی 2020-08-28T23: 50: 07Z (درست است؟)
2020-09-19T20: 08: 44.3248780Z شماره یافت شده: شماره # 2247 - EIP-1898: اولویت برای مقادیر متناقض مشخص نشده است آخرین به روزرسانی 2019-08-20T19: 49: 18Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3249340Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3250120Z شماره یافت شده: شماره # 2246 - EIP-1808: یک استاندارد اشتراک داده دارایی دیجیتال غیر همگن آخرین به روزرسانی 2019-08-19T07: 12: 44Z (اشتباه است؟)
2020-09-19T20: 08: 44.3250687Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3251490Z شماره یافت شده: شماره # 2243 - EIP-2243: قراردادهای هوشمند قابل ارتقا بدون تابعیت برای آدرس های حساب آخرین بروزرسانی 2019-11-05T22: 46: 39Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3252074Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3252746Z شماره یافت شده: شماره # 2238 - EIP-689: توضیحات آخرین به روزرسانی 2020-08-29T12: 54: 49Z (درست است؟)
2020-09-19T20: 08: 44.3255810Z شماره یافت شده: شماره # 2229 - EIP-2229: آخرین بار رابط پینگ به روز شده 2019-08-08T17: 12: 26Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3256999Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3258506Z شماره یافت شده: شماره # 2228 - EIP-xxxx نام شبکه ای را با شناسه زنجیره ای 1 آخرین بار بروزرسانی کرد 2020-08-29T01: 08: 08Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3259022Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3259839Z شماره یافت شده: شماره # 2224 - آخرین امضاهای خودکار آخرین به روز رسانی 2020-09-08T23: 39: 40Z (درست است؟)
2020-09-19T20: 08: 44.3261014Z شماره یافت شده: شماره # 2222 - ERC-2222 - استاندارد توزیع وجوه آخرین به روزرسانی 2019-08-02T07: 22: 55Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3261880Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3262563Z شماره یافت شده: شماره # 2220 - [گمشده] EIP-684 آخرین به روزرسانی 2019-07-30T08: 04: 51Z (آیا اشتباه است؟)
2020-09-19T20: 08: 44.3263211Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3264223Z شماره یافت شده: شماره # 2219 - بروزرسانی EIP 918 به آخرین تماس آخرین به روزرسانی 2020-09-11T01: 46: 35Z (درست است؟)
2020-09-19T20: 08: 44.3265641Z شماره یافت شده: شماره # 2208 - EIP-2208: پیشنهاد پاداش اندیشه برای تأمین بودجه افکار خوب و همچنین رهبران افکار خوب آخرین به روزرسانی 2019-07-28T23: 14: 37Z (آیا دروغ است؟ )
2020-09-19T20: 08: 44.3266485Z مشکل رد شدن به دلیل پیام بیات خالی
2020-09-19T20: 08: 44.3267738Z شماره یافت شده: شماره # 2192 - ERC-2193: dType Alias ​​Extension - سیستم نوع غیرمتمرکز آخرین به روز رسانی 2019-07-22T18: 57: 03Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.3268500Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3269798Z شماره یافت شده: شماره # 2187 - بحث: انتقال EIPs به مدیوم دیگری را در نظر بگیرید آخرین بروزرسانی 2019-09-23T18: 08: 19Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3270331Z مسئله رد شدن به دلیل پیام بیات خالی
2020-09-19T20: 08: 44.3271407Z شماره یافت شده: شماره # 2185 - Skinniest CREATELINK آخرین به روزرسانی 2020-09-19T02: 17: 12Z (درست است؟)
2020-09-19T20: 08: 44.3272303Z شماره یافت شده: شماره # 2184 - آخرین توافق نامه متقارن Ethereum آخرین به روز رسانی 2019-07-10T00: 03: 57Z (آیا اشتباه است؟)
2020-09-19T20: 08: 44.3273172Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3275187Z شماره یافت شده: شماره # 2173 - بحث: EIP-1 ​​- معیارهای ویرایشگر EIP (روند ویرایشگرهای جدید) آخرین به روزرسانی 2020-08-29T01: 08: 24Z (pr؟ false)
2020-09-19T20: 08: 44.3275784Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3277136Z شماره یافت شده: شماره # 2157 - ERC-2157: dType Storage Extension - سیستم نوع غیرمتمرکز برای EVM آخرین به روزرسانی 2019-07-16T12: 56: 19Z (pr is false)
2020-09-19T20: 08: 44.3278055Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3279139Z شماره یافت شده: شماره # 2154 - پیشنهاد تشویق فشرده سازی زنجیره آخرین بروزرسانی 2019-06-28T15: 05: 42Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 44.3280043Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3281290Z شماره یافت شده: شماره # 2135 - ERC: رابط مصرفی آخرین به روز رسانی 2019-07-25T00: 11: 25Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.3282133Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3283399Z شماره یافت شده: شماره شماره 2125 - EIP-2124: شناسه چنگال برای بررسی سازگاری زنجیره ای آخرین به روزرسانی 2020-07-31T17: 29: 12Z (اشتباه است؟
2020-09-19T20: 08: 44.3284195Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.3285293Z شماره یافت شده: شماره # 2123 - EIP-2123: سیگنالینگ Hard Fork مبتنی بر ایالت آخرین بروزرسانی 2020-09-13T07: 08: 04Z (درست است؟)
2020-09-19T20: 08: 44.3285984Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 44.3286554Z بررسی برچسب کهنه در شماره # 2123
2020-09-19T20: 08: 44.4855323Z شماره شماره 2123 کهنه در تاریخ مشخص شد: 2020-09-13T07: 08: 04Z
2020-09-19T20: 08: 44.4856334Z بررسی نظرات در مورد شماره 2123 از 2020-09-13T07: 08: 04Z
2020-09-19T20: 08: 44.5788239Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 44.5788574Z شماره شماره 2123 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 44.5788901Z شماره شماره 2123 به روز شده است: درست است
2020-09-19T20: 08: 44.5789484Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند آن را ببندد
2020-09-19T20: 08: 44.5790918Z شماره یافت شده: شماره # 2121 - افزودن مجموعه evm ERC آخرین به روزرسانی 2020-08-28T00: 42: 21Z (درست است؟)
2020-09-19T20: 08: 44.5791844Z شماره یافت شده: شماره شماره 2119 - افزودن EIP-1654: فرآیند احراز هویت کیف پول داپ-زنجیره ای آخرین بروزرسانی 2020-09-15T18: 08: 33Z (درست است)
2020-09-19T20: 08: 44.5808693Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 44.5813757Z بررسی برچسب قدیمی در مورد شماره 2119
شماره 2019-09-2020: 08: 44.7080277Z شماره شماره 2119 در تاریخ: 2020-09-15T18: 08: 33Z مشخص شده است
2020-09-19T20: 08: 44.7080932Z بررسی نظرات در مورد شماره 2119 از 2020-09-15T18: 08: 33Z
2020-09-19T20: 08: 44.8212201Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 44.8214171Z شماره 2119 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 44.8214632Z شماره شماره 2119 به روز شده است: درست است
2020-09-19T20: 08: 44.8215193Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 44.8216917Z شماره یافت شده: شماره # 2106 - EIP-2021: آخرین نشانه قابل پرداخت آخرین به روزرسانی 06-06-06T12: 42: 16Z (اشتباه است؟ کاذب است)
2020-09-19T20: 08: 44.8218318Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.8219413Z شماره یافت شده: شماره # 2105 - EIP-2019: آخرین بار Token آخرین به روز رسانی 2019-06-06T12: 37: 50Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.8219897Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.8224334Z شماره یافت شده: شماره # 2104 - EIP-2018: آخرین بار Token Clearable به روز شد 2019-06-06T10: 42: 04Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 44.8225045Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.8226082Z شماره یافت شده: شماره # 2103 - EIP-1996: آخرین رمز توزیع شده آخرین به روز رسانی 2019-06-06T09: 58: 30Z (درست است؟ نادرست است)
2020-09-19T20: 08: 44.8226541Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.8227202Z شماره یافت شده: شماره # 2100 - آخرین پیشنهاد برای پخش جریانی استاندارد آخرین بروزرسانی 2019-09-13T09: 56: 26Z (آیا غلط است؟)
2020-09-19T20: 08: 44.8227684Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 44.8232009Z شماره یافت شده: شماره # 2095 - eip-2047 - تداوم داده موقت آخرین بروزرسانی 2020-09-15T18: 08: 35Z (درست است؟)
2020-09-19T20: 08: 44.8232675Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 44.8232976Z بررسی برچسب کهنه در مورد شماره 2095
شماره 2095: 09-09-202020: 08: 44.9366059Z
2020-09-19T20: 08: 44.9367884Z بررسی نظرات در مورد شماره 2095 از 2020-09-15T18: 08: 35Z
2020-09-19T20: 08: 45.0366249Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 45.0367560Z شماره شماره 2095 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 45.0367970Z شماره شماره 2095 به روز شده است: درست است
2020-09-19T20: 08: 45.0368370Z قدیمی قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 45.0369370Z شماره یافت شده: شماره # 2062 - لیست EIPs / ERC بدون بیانیه حق چاپ آخرین به روزرسانی 2019-12-16T14: 46: 36Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 45.0369861Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.0370528Z شماره یافت شده: شماره # 2061 - بحث: آخرین بازپرداخت برای نویسندگان قرارداد آخرین به روزرسانی 2019-07-03T18: 06: 50Z (pr؟ false)
2020-09-19T20: 08: 45.0371001Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.0371748Z شماره یافت شده: شماره # 2060 - تحقیق در مورد Protobuffs برای سریال سازی نوع جدید تراکنش. آخرین به روزرسانی 2019-05-21T20: 16: 07Z (pr is false)
2020-09-19T20: 08: 45.0372326Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.0373109Z شماره یافت شده: شماره # 2054 - EIP-2054 افزودن شناسه منحصر به فرد ارزان قیمت و جستجو در سلسله مراتب تماس خارجی آخرین به روزرسانی 2019-11-06T09: 53: 08Z (اشتباه است؟)
2020-09-19T20: 08: 45.0373632Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.0376067Z موضوع یافت شده: شماره # 2050 - استاندارد محاسبه جبران کننده کربن را به EIP اضافه کنید آخرین بروزرسانی 2020-09-15T18: 08: 36Z (درست است؟)
2020-09-19T20: 08: 45.0376821Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 45.0377330Z بررسی برچسب قدیمی در مورد شماره 2050
2020-09-19T20: 08: 45.4240013Z شماره شماره 2050 در تاریخ بی اثر مشخص شد: 2020-09-15T18: 08: 36Z
2020-09-19T20: 08: 45.4241055Z بررسی نظرات در مورد شماره 2050 از 2020-09-15T18: 08: 36Z
2020-09-19T20: 08: 45.5121511Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 45.5121935Z شماره شماره 2050 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 45.5122565Z شماره شماره 2050 به روز شده است: درست است
2020-09-19T20: 08: 45.5123002Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 45.5123932Z شماره یافت شده: شماره # 2022 - EIP-2009: آخرین بار سرویس انطباق به روز شد 2019-05-13T14: 35: 22Z (درست است؟ نادرست است)
2020-09-19T20: 08: 45.5124424Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.5125318Z موضوع موجود: شماره # 1964 - به نظر می رسد استخراج کننده نوع eip-1767 از نوع Block نیازی به فیلتر نداشته باشد آخرین بروزرسانی: 2019-05-02T21: 36: 00Z
2020-09-19T20: 08: 45.5125816Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.5126862Z موضوع یافت شده: شماره # 1958 - EIP-1958: آخرین توابع قرارداد قابل پرداخت در رمزها آخرین به روزرسانی 09-09-09T10: 05: 05Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 45.5127608Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.5128405Z شماره یافت شده: شماره # 1940 - افزودن پروتکل جدید اقدام EK-X Ethereum Token آخرین به روزرسانی 2020-09-15T18: 08: 40Z (درست است)
2020-09-19T20: 08: 45.5128815Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 45.5129090Z بررسی برچسب کهنه در شماره # 1940
شماره 2040: 09-09-2020: 08: 40Z
2020-09-19T20: 08: 45.6500083Z بررسی نظرات در مورد شماره 1940 از 2020-09-15T18: 08: 40Z
2020-09-19T20: 08: 45.7287629Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 45.7288027Z شماره شماره 1940 در مورد نظر داده شده است: نادرست است
شماره شماره 1940 به روز شده است: درست است
2020-09-19T20: 08: 45.7289379Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 45.7290330Z شماره یافت شده: شماره # 1930 - EIP-1930: نوع تماس با گاز سخت برای اطمینان از ارسال مقدار مشخصی آخرین به روزرسانی 2020-03-03T18: 00: 37Z (آیا دروغ است؟)
2020-09-19T20: 08: 45.7290856Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.7291487Z شماره یافت شده: شماره # 1929 - ایجاد EIPsForHardfork.md آخرین بروزرسانی 2020-09-19T12: 10: 47Z (درست است؟)
2020-09-19T20: 08: 45.7292970Z شماره یافت شده: شماره # 1923 - EIP-1923: رابط استاندارد رجیستری تأیید کننده zk-SNARKs آخرین به روزرسانی 2019-05-20T14: 19: 35Z (درست است؟ نادرست است)
2020-09-19T20: 08: 45.7293678Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.7294427Z شماره یافت شده: شماره # 1922 - EIP-1922: رابط استاندارد Verified Verifier zk-SNARKs آخرین به روزرسانی 2019-05-20T14: 20: 13Z (آیا غلط است؟)
2020-09-19T20: 08: 45.7294915Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.7295608Z شماره یافت شده: شماره # 1921 - EIP-1921 dType - گسترش سیستم نوع غیرمتمرکز برای عملکردها آخرین بروزرسانی 2019-09-10T08: 57: 45Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 45.7296152Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.7296848Z شماره یافت شده: شماره شماره 1914 - EIP-1913: (ERC) استاندارد Casper PEPoW Token Standard for Layer 2 Solutions آخرین بروزرسانی 2020-09-15T19: 07: 28Z (درست است؟)
2020-09-19T20: 08: 45.7297292Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 45.7297589Z بررسی برچسب کهنه در شماره # 1914
شماره 2014: 09-09-2020: 08: 45.8534453Z تاریخ انتشار: 20.09.2009T19: 07: 28Z
2020-09-19T20: 08: 45.8535047Z بررسی نظرات در مورد شماره 1914 از 2020-09-15T19: 07: 28Z
2020-09-19T20: 08: 45.9627914Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 45.9628367Z شماره شماره 1914 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 45.9628989Z شماره شماره 1914 به روز شده است: درست است
2020-09-19T20: 08: 45.9629602Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 45.9631106Z شماره یافت شده: شماره # 1913 - ERC: استاندارد Casper PEPoW برای راه حل های لایه 2 آخرین به روز رسانی 2019-04-05T14: 14: 42Z (درست است؟ نادرست است)
2020-09-19T20: 08: 45.9631661Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.9632434Z شماره یافت شده: شماره # 1909 - آخرین بار در EIP برای آدرس وب سایت DApp و پسوند Web3 HTTP به روز شده 2019-04-23T08: 50: 29Z (اشتباه است؟)
2020-09-19T20: 08: 45.9632951Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 45.9634068Z شماره یافت شده: شماره # 1902 - بحث: EIP 1901 افزودن سرویس OpenRPC کشف به سرویس های JSON-RPC آخرین به روزرسانی 2019-09-04T16: 58: 08Z (pr is false)
2020-09-19T20: 08: 45.9635256Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 47.4013584Z شماره یافت شده: شماره # 1894 - بحث: EIP 1881 - معرفی پول و ذخیره ارزش به عنوان پاداش بلوک ثانویه آخرین بروزرسانی 2019-04-02T03: 59: 01Z (آیا اشتباه است؟ )
2020-09-19T20: 08: 47.4014617Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 47.4015734Z شماره یافت شده: شماره # 1893 - EIP 1881: معرفی پول و ذخیره ارزش به عنوان پاداش بلوک ثانویه آخرین بروزرسانی 2020-09-15T19: 07: 29Z (درست است؟)
2020-09-19T20: 08: 47.4016619Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 47.4017165Z بررسی برچسب قدیمی در شماره # 1893
2020-09-19T20: 08: 47.5572124Z شماره شماره 1893 مشخص شده در تاریخ مورخ: 2020-09-15T19: 07: 29Z
2020-09-19T20: 08: 47.5573273Z بررسی نظرات در مورد شماره 1893 از 2020-09-15T19: 07: 29Z
2020-09-19T20: 08: 47.6384842Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 47.6385385Z شماره شماره 1893 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 47.6385741Z شماره شماره 1893 به روز شده است: درست است
2020-09-19T20: 08: 47.6386183Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 47.6387816Z شماره یافت شده: شماره # 1889 - حذف مه از EIP-55 به دلیل منسوخ شدن آخرین به روزرسانی 2020-09-03T22: 48: 44Z (درست است؟)
2020-09-19T20: 08: 47.6389092Z شماره یافت شده: شماره # 1888 - ERC-1888: آخرین بار گواهی قابل انتقال (ادعا) آخرین بروزرسانی: 2020-06-24T17: 54: 29Z (اشتباه است)
2020-09-19T20: 08: 47.6389993Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 47.6391338Z شماره یافت شده: شماره # 1882 - ERC-1900: سیستم نوع غیرمتمرکز برای EVM آخرین به روز رسانی 2019-09-12T15: 10: 31Z (درست است؟ نادرست است)
2020-09-19T20: 08: 47.6392636Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 47.6393374Z شماره یافت شده: شماره # 1851 - آخرین بار بحث ERC 1850 به روز شده 2019-04-01T15: 50: 43Z (اشتباه است؟)
2020-09-19T20: 08: 47.6396092Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 47.6396921Z شماره یافت شده: شماره # 1850 - ERC 1850 - استاندارد قرارداد اصلی قفل شده با زمان Hashed آخرین بروزرسانی 2020-09-15T19: 07: 31Z (درست است؟)
2020-09-19T20: 08: 47.6397597Z Z
2020-09-19T20: 08: 47.6398149Z بررسی برچسب قدیمی در مورد شماره 1850
شماره شماره 1850 بیات در تاریخ: 2020-09-19T19: 07: 31Z منتشر شد شماره شماره 1850
2020-09-19T20: 08: 47.8293764Z بررسی نظرات در مورد شماره 1850 از 2020-09-15T19: 07: 31Z
2020-09-19T20: 08: 47.9133633Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 47.9134091Z شماره 1850 در مورد نظر داده شده است: نادرست است
شماره 2050-09-1920: 08: 47.9134454Z به روز شده است: درست است
2020-09-19T20: 08: 47.9134907Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 47.9136523Z شماره یافت شده: شماره # 1845 - آخرین پیشنهاد سیاست پولی تورم آخرین بروزرسانی 2020-09-15T19: 07: 34Z (درست است؟)
2020-09-19T20: 08: 47.9137033Z Z
2020-09-19T20: 08: 47.9138127Z بررسی برچسب کهنه در شماره 1845
2020-09-19T20: 08: 48.3285890Z شماره شماره 1845 بیات در تاریخ مشخص شد: 2020-09-15T19: 07: 34Z
2020-09-19T20: 08: 48.3286477Z بررسی نظرات در مورد شماره 1845 از 2020-09-15T19: 07: 34Z
2020-09-19T20: 08: 48.4128513Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 48.4129004Z شماره شماره 1845 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 48.4129667Z شماره شماره 1845 به روز شده است: درست است
2020-09-19T20: 08: 48.4130283Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 48.4131355Z شماره یافت شده: شماره # 1843 - ERC-1843 - Claims Token Standard آخرین بروزرسانی 2019-11-15T17: 07: 40Z (اشتباه است؟)
2020-09-19T20: 08: 48.4131821Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.4132537Z موضوع پیدا شده: شماره # 1840 - میثاق ثبت اختراع برای ارسال های EIP آخرین به روزرسانی 2020-08-29T01: 08: 48Z (pr؟ false)
2020-09-19T20: 08: 48.4133201Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.4134045Z موضوع یافت شده: شماره # 1837 - آخرین بار هزینه معاملات EIP-1837 به روز شده در تاریخ 2019-03-15T12: 44: 34Z (آیا اشتباه است؟)
2020-09-19T20: 08: 48.4134522Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.4135221Z شماره یافت شده: شماره # 1836 - ERC1836 - پروکسی هویت قابل ارتقا آخرین به روزرسانی 2019-03-08T22: 04: 51Z (اشتباه است؟)
2020-09-19T20: 08: 48.4135710Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.4136426Z شماره یافت شده: شماره # 1784 - بحث: آخرین بار اجرای طرح حراج کور 2019-02-28T08: 40: 26Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 48.4136955Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.4138148Z شماره یافت شده: شماره # 1781 - اضافه کردن بسته های امضا شده ethereum آخرین بروزرسانی 2020-09-15T19: 07: 36Z (درست است؟)
2020-09-19T20: 08: 48.4138567Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 48.4138811Z بررسی برچسب کهنه در شماره # 1781
2020-09-19T20: 08: 48.5421671Z شماره شماره 1781 بیات مشخص شده در: 2020-09-15T19: 07: 36Z
2020-09-19T20: 08: 48.5422299Z بررسی نظرات در مورد شماره 1781 از 2020-09-15T19: 07: 36Z
2020-09-19T20: 08: 48.6698390Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 48.6698751Z شماره شماره 1781 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 48.6699435Z شماره شماره 1781 به روز شده است: درست است
2020-09-19T20: 08: 48.6700051Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند آن را ببندد (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 48.6701624Z شماره یافت شده: شماره # 1780 - رجیستری رابط معنایی / پسوند ERC820 آخرین به روزرسانی 2020-09-15T19: 07: 37Z (درست است؟)
2020-09-19T20: 08: 48.6702347Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 48.6702877Z بررسی برچسب کهنه در شماره # 1780
2020-09-19T20: 08: 48.7925236Z شماره # 1780 کهنه در تاریخ: 2020-09-15T19: 07: 37Z مشخص شد
2020-09-19T20: 08: 48.7926051Z بررسی نظرات در مورد شماره 1780 از 2020-09-15T19: 07: 37Z
2020-09-19T20: 08: 48.8978162Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 48.8978643Z شماره شماره 1780 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 48.8979033Z شماره شماره 1780 به روز شده است: درست است
2020-09-19T20: 08: 48.8979933Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند آن را ببندد (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 48.8981549Z شماره یافت شده: شماره # 1776 - آخرین بار معاملات ERC-1776 Meta Meta آخرین بروزرسانی 2020-03-29T16: 21: 23Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 48.8982049Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8983307Z شماره یافت شده: شماره # 1761 - آخرین بار رابط تأیید ERC-1761 به روز شده 2019-02-20T03: 49: 20Z (اشتباه است؟)
2020-09-19T20: 08: 48.8983986Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8984895Z شماره یافت شده: شماره # 1760 - بحث: چرا استفاده از زنجیره عمومی ethereum برای قراردادهای STO ایده خوبی نیست آخرین بروزرسانی 2019-02-19T10: 07: 54Z (اشتباه است؟)
2020-09-19T20: 08: 48.8987518Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8988805Z شماره یافت شده: شماره # 1757 - ERC-1757: مکانیزم اعتبار برای صادرکنندگان ادعا آخرین بروزرسانی 2019-02-28T06: 50: 12Z (درست است؟ نادرست است)
2020-09-19T20: 08: 48.8989365Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8990206Z شماره یافت شده: شماره # 1756 - ERC-1756: تصادفی عملی از طریق قرارداد دوگانه آخرین به روزرسانی 2019-03-25T04: 24: 31Z (آیا غلط است)
2020-09-19T20: 08: 48.8990736Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8991625Z شماره یافت شده: شماره # 1750 - EIP-1750: آخرین بار مکانیزم عامل پرداخت گاز به روز شده است 2019-02-12T03: 47: 12Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 48.8992185Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8992977Z شماره یافت شده: شماره # 1745 - بحث: ERC-1815: آخرین رابط استاندارد برای حراجی های کور آخرین بروزرسانی: 2019-05-23T23: 51: 35Z (آیا غلط است؟)
2020-09-19T20: 08: 48.8993878Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8995198Z شماره یافت شده: شماره # 1726 - ERC-1726: استاندارد توکن پرداخت سود سهام آخرین به روزرسانی 2019-05-07T08: 47: 08Z (pr؟ false)
2020-09-19T20: 08: 48.8995868Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 48.8996778Z شماره یافت شده: شماره # 1725 - افزودن روند بررسی مخاطب به EIP قبل از آخرین تماس آخرین به روزرسانی 2020-09-15T19: 07: 39Z (درست است؟)
2020-09-19T20: 08: 48.8997392Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 48.8997768Z بررسی برچسب کهنه در شماره # 1725
2020-09-19T20: 08: 49.0556424Z شماره # 1725 در تاریخ: 2020-09-15T19 مشخص شده است: 07: 39Z
2020-09-19T20: 08: 49.0558763Z بررسی نظرات در مورد شماره 1725 از 2020-09-15T19: 07: 39Z
2020-09-19T20: 08: 49.1344801Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 49.1345239Z شماره شماره 1725 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 49.1345686Z شماره شماره 1725 به روز شده است: درست است
2020-09-19T20: 08: 49.1346674Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 49.1348915Z شماره یافت شده: شماره # 1724 - zkERC20: استاندارد محرمانه رمز آخرین بروزرسانی 2020-02-26T17: 23: 15Z (درست است؟ نادرست است)
2020-09-19T20: 08: 49.1349424Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.1350299Z شماره یافت شده: شماره # 1723 - ERC: استاندارد موتور رمزنگاری آخرین به روز رسانی 2019-02-07T10: 51: 12Z (درست است؟ نادرست است)
2020-09-19T20: 08: 49.1350719Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.1351515Z شماره یافت شده: شماره # 1715 - EIP-1715: بیت نسخه عمومی رای گیری برای اجماع نرم و سخت چنگال آخرین به روزرسانی 2020-09-15T19: 07: 40Z (درست است)
2020-09-19T20: 08: 49.1352001Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 49.1352288Z بررسی برچسب قدیمی در مورد شماره 1715
2020-09-19T20: 08: 49.2634731Z شماره شماره 1715 کهنه در تاریخ: 2020-09-15T19: 07: 40Z مشخص شد
2020-09-19T20: 08: 49.2635216Z بررسی نظرات در مورد شماره 1715 از 2020-09-15T19: 07: 40Z
2020-09-19T20: 08: 49.3677680Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 49.3679000Z شماره شماره 1715 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 49.3679706Z شماره شماره 1715 به روز شده است: درست است
2020-09-19T20: 08: 49.3680292Z قدیمی قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 49.3688487Z مسئله پیدا شده: شماره # 1711 - EIP-155 شبکه های سازگار باید دارای شناسه های مختلف Chain باشند ، درست است؟ آخرین به روزرسانی 2019-07-19T03: 33: 42Z (pr is false)
2020-09-19T20: 08: 49.3689798Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.3691691Z شماره یافت شده: شماره # 1700 - ERC1700: نشانه غیرقابل تمدید آخرین به روزرسانی 2019-01-16T15: 34: 44Z (درست است؟ نادرست است)
2020-09-19T20: 08: 49.3692274Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.3693439Z شماره یافت شده: شماره # 1698 - EIP-1014 نتوانست از گردش کار عبور کند و آخرین به روزرسانی 2020-01-08T14: 57: 01Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 49.3693968Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.3695143Z شماره یافت شده: شماره # 1693 - تولید /feed.xml با کلیه EIP ها آخرین بروزرسانی 2020-09-15T19: 07: 42Z (درست است؟)
2020-09-19T20: 08: 49.3695582Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 49.3695877Z بررسی برچسب کهنه در شماره # 1693
2020-09-19T20: 08: 49.6721567Z شماره # 1693 در تاریخ بیست و پنجم مشخص شده است: 2020-09-15T19: 07: 42Z
2020-09-19T20: 08: 49.6722267Z بررسی نظرات در مورد شماره 1693 از 2020-09-15T19: 07: 42Z
2020-09-19T20: 08: 49.7568041Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 49.7568398Z شماره شماره 1693 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 49.7568700Z شماره شماره 1693 به روز شده است: درست است
2020-09-19T20: 08: 49.7569097Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 49.7570172Z شماره یافت شده: شماره # 1691 - # 1690 استاندارد مرگ و میر اضافه شده آخرین بروزرسانی 2020-09-17T06: 08: 56Z (درست است؟)
2020-09-19T20: 08: 49.7571397Z موضوع یافت شده: شماره # 1690 - ERC-1690 - استاندارد مرگ و میر آخرین به روزرسانی 2019-02-10T15: 22: 19Z (آیا غلط است؟)
2020-09-19T20: 08: 49.7571872Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7572534Z شماره یافت شده: شماره # 1688 - بهبود فیدهای موجود در وب سایت EIPs آخرین به روزرسانی 2019-05-23T23: 51: 47Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 49.7573009Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7573681Z شماره یافت شده: شماره # 1683 - نشانی های اینترنتی با دارایی و قابلیت پردازش آخرین به روزرسانی 2019-01-08T16: 01: 35Z (pr is false)
2020-09-19T20: 08: 49.7574153Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7574971Z شماره یافت شده: شماره # 1673 - زنجیره ای برای مجموعه های POA و ARTIS اضافه شده است آخرین بروزرسانی 2020-09-16T11: 07: 38Z (درست است؟)
2020-09-19T20: 08: 49.7575674Z شماره یافت شده: شماره # 1671 - آخرین نشانه های قابل انعطاف به روز شده 2019-01-23T18: 40: 24Z (درست است؟ نادرست است)
2020-09-19T20: 08: 49.7576108Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7576701Z شماره یافت شده: شماره # 1668 - ERC-1668 - آخرین قرارداد ریشه آخرین بروزرسانی 2018-12-23T14: 50: 53Z (اشتباه است؟)
2020-09-19T20: 08: 49.7578101Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7581537Z شماره یافت شده: شماره # 1667 - ERC-1667 - آخرین پیشنهاد MVP پلاسما آخرین بروزرسانی 2018-12-23T01: 21: 38Z (درست است؟ نادرست است)
2020-09-19T20: 08: 49.7582078Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7582999Z شماره یافت شده: شماره # 1662 - حذف محدودیت اندازه قرارداد آخرین به روزرسانی 2020-02-27T11: 51: 54Z (آیا اشتباه است؟)
2020-09-19T20: 08: 49.7583449Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7584272Z شماره یافت شده: شماره # 1654 - فرآیند احراز هویت کیف پول Dapp-wallet با پشتیبانی از کیف پول های قراردادی آخرین بروزرسانی 2020-06-26T16: 12: 30Z آخرین بار
2020-09-19T20: 08: 49.7584880Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.7585777Z شماره یافت شده: شماره شماره 1652 - استاندارد افزودن قرارداد حقوقی به قرارداد هوشمند توکن آخرین بروزرسانی 2020-09-15T19: 07: 46Z (درست است؟)
2020-09-19T20: 08: 49.7586227Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 49.7586650Z بررسی برچسب قدیمی در شماره شماره 1652
2020-09-19T20: 08: 49.8775692Z شماره شماره 1652 بیات در تاریخ مشخص شد: 2020-09-15T19: 07: 46Z
2020-09-19T20: 08: 49.8776534Z بررسی نظرات در مورد شماره 1652 از 2020-09-15T19: 07: 46Z
2020-09-19T20: 08: 49.9554773Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 49.9555394Z شماره شماره 1652 در مورد نظر داده شده است: نادرست است
شماره شماره 1652 به روز شده است: درست است. 09-09-2020T20: 08: 49.9556134Z
2020-09-19T20: 08: 49.9556656Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 49.9558077Z شماره یافت شده: شماره # 1651 - یک پیشنهاد مدیریت اسناد برای توکن قانونی که آخرین بار به روز شده در تاریخ 2019-01-05T11: 16: 27Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 49.9558698Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.9559546Z شماره یافت شده: شماره # 1649 - ERC-1646: پروتکل هویت صفر خودمختار غیرمتمرکز آخرین بروزرسانی 2018-12-13T05: 17: 27Z (اشتباه است؟)
2020-09-19T20: 08: 49.9560174Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 49.9561158Z شماره یافت شده: شماره # 1646 - EIP-1646: پروتکل هویت صفر خودمختار غیرمتمرکز آخرین به روز رسانی 2020-09-15T19: 07: 47Z (درست است)
2020-09-19T20: 08: 49.9561791Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 49.9562139Z بررسی برچسب کهنه در شماره # 1646
2020-09-19T20: 08: 50.0774484Z شماره شماره 1646 در تاریخ بی اثر مشخص شده است: 2020-09-15T19: 07: 47Z
2020-09-19T20: 08: 50.0774996Z بررسی نظرات در مورد شماره 1646 از 2020-09-15T19: 07: 47Z
2020-09-19T20: 08: 50.1767480Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 50.1767859Z شماره شماره 1646 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 50.1768161Z شماره شماره 1646 به روز شده است: درست است
2020-09-19T20: 08: 50.1768555Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 50.1769592Z شماره یافت شده: شماره # 1644 - ERC-1644: استاندارد عملکرد توکن کنترل کننده آخرین به روزرسانی 2019-12-25T02: 28: 07Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 50.1770094Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.1770735Z شماره یافت شده: شماره # 1643 - ERC-1643: استاندارد مدیریت اسناد آخرین به روزرسانی 2020-01-13T22: 40: 22Z (اشتباه است؟
2020-09-19T20: 08: 50.1771226Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.1772474Z شماره یافت شده: شماره # 1641 - من در حال فکر کردن در مورد ارائه استاندارد برای ثبت ردیابی هستم آخرین بروزرسانی 2018-12-08T10: 35: 17Z (pr is false)
2020-09-19T20: 08: 50.1773044Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.1774001Z شماره یافت شده: شماره # 1638 - ERC1638: Ethereum GiftVault - استانداردی برای مراسم هدایت شده برای جعبه گشودن ایمن یک قرارداد هوشمند multisig قفل شده با زمان ، که دارای هدایایی است و آخرین بروزرسانی ها 2020-09-15T19: 07 : 49Z (درست است؟)
2020-09-19T20: 08: 50.1774821Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 50.1775100Z بررسی برچسب کهنه در شماره # 1638
2020-09-19T20: 08: 50.3068606Z شماره شماره 1638 در تاریخ بیست و پنجم مشخص شده است: 2020-09-15T19: 07: 49Z
2020-09-19T20: 08: 50.3069125Z بررسی نظرات در مورد شماره 1638 از 2020-09-15T19: 07: 49Z
2020-09-19T20: 08: 50.3941306Z نظرات توسط axic یا ربات دیگر ساخته نشده است: 0
2020-09-19T20: 08: 50.3941674Z شماره شماره 1638 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 50.3942024Z شماره شماره 1638 به روز شده است: درست است
2020-09-19T20: 08: 50.3942462Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 50.3944504Z مسئله موجود: شماره # 1637 - EIP 1637 - افزودن پارامتر chainId به eth_sendTransaction آخرین به روزرسانی 2019-05-18T13: 29: 47Z (درست است؟ نادرست است)
2020-09-19T20: 08: 50.3945515Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.3946469Z شماره یافت شده: شماره # 1634 - ERC 1633 - آخرین بار RFT (نشانه قابل استفاده) آخرین به روزرسانی 2019-03-29T15: 16: 50Z (اشتباه است؟)
2020-09-19T20: 08: 50.3947212Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.3968825Z شماره یافت شده: شماره # 1633 - آخرین بار RFT (نشانه قابل استفاده) آخرین به روز رسانی 2020-09-15T21: 07: 25Z (درست است؟)
2020-09-19T20: 08: 50.3969925Z شماره یافت شده: شماره # 1631 - بحث آخرین بار ERC 1630 به روز شده 2019-12-16T23: 37: 50Z (آیا غلط است؟)
2020-09-19T20: 08: 50.3970356Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.3971424Z شماره یافت شده: شماره # 1630 - ERC 1630 - استاندارد قرارداد قفل شده با زمان هشدار آخرین بروزرسانی 2020-09-15T19: 07: 52Z (درست است؟)
2020-09-19T20: 08: 50.3973157Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 50.3973655Z بررسی برچسب قدیمی در شماره شماره 1630
2020-09-19T20: 08: 50.5707124Z شماره شماره 1630 در تاریخ بیست و پنجم مشخص شد: 2020-09-15T19: 07: 52Z
2020-09-19T20: 08: 50.5707953Z بررسی نظرات در مورد شماره 1630 از 2020-09-15T19: 07: 52Z
2020-09-19T20: 08: 50.6580007Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 50.6580781Z شماره شماره 1630 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 50.6581267Z شماره شماره 1630 به روز شده است: درست است
2020-09-19T20: 08: 50.6582139Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 50.6583239Z شماره یافت شده: شماره # 1621 - EIP1621: آخرین مراجعه رابط ارجاع 2018-11-30T14: 01: 53Z (درست است؟ نادرست است)
2020-09-19T20: 08: 50.6583823Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.6584538Z شماره یافت شده: شماره # 1620 - ERC-1620: جریان پول آخرین به روز رسانی 2019-12-25T19: 52: 43Z (درست است؟ نادرست است)
2020-09-19T20: 08: 50.6585196Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.6598703Z شماره یافت شده: شماره # 1616 - ERC: استاندارد رجیستری ویژگی آخرین به روزرسانی 2018-11-25T20: 02: 42Z (اشتباه است؟)
2020-09-19T20: 08: 50.6600965Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.6602130Z شماره یافت شده: شماره # 1610 - EIP1607 - جداسازی محدودیت گاز بلوک و محدودیت گاز معامله. آخرین به روزرسانی 2019-01-29T19: 31: 13Z (pr is false)
2020-09-19T20: 08: 50.6602783Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.6603650Z شماره یافت شده: شماره # 1607 - EIP1607 - جداسازی محدودیت گاز بلوک و محدودیت گاز معامله. آخرین به روزرسانی 2020-09-15T19: 07: 53Z (درست است؟)
2020-09-19T20: 08: 50.6604196Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 50.6604542Z بررسی برچسب کهنه در شماره # 1607
2020-09-19T20: 08: 50.7823326Z شماره # 1607 در تاریخ بیگانه مشخص شده است: 2020-09-15T19: 07: 53Z
2020-09-19T20: 08: 50.7823909Z بررسی نظرات در مورد شماره 1607 از 2020-09-15T19: 07: 53Z
2020-09-19T20: 08: 50.8825742Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 50.8826140Z شماره شماره 1607 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 50.8828075Z شماره # 1607 به روز شده است: درست است
2020-09-19T20: 08: 50.8828648Z قدیمی قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روزرسانی شده است؟ درست است
2020-09-19T20: 08: 50.8829711Z شماره یافت شده: شماره # 1606 - EIP1606 - قراردادهای مبتنی بر متن در Solidity آخرین بروزرسانی 2018-11-21T09: 02: 53Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 50.8830508Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 50.8831270Z موضوع یافت شده: شماره # 1605 - ایجاد پیش نویس کدگذاری ABI برای آخرین بار که به روز شده است 2020-09-19T02: 08: 59Z (درست است؟)
2020-09-19T20: 08: 50.8831807Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 50.8832170Z بررسی برچسب کهنه در شماره # 1605
2020-09-19T20: 08: 51.0006185Z شماره # 1605 در تاریخ بیستون مشخص شد: 2020-09-19T02: 08: 59Z
2020-09-19T20: 08: 51.0007024Z بررسی نظرات در مورد شماره 1605 از 2020-09-19T02: 08: 59Z
2020-09-19T20: 08: 51.1781877Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 51.1782290Z شماره شماره 1605 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 51.1782646Z شماره شماره 1605 به روز شده است: درست است
2020-09-19T20: 08: 51.1783065Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 51.1784251Z شماره پیدا شده: شماره # 1602 - پاداش بلوک EIP1600 برای ماینرهای کارآمد هوشمند. آخرین به روزرسانی 2018-11-20T10: 28: 38Z (pr is false)
2020-09-19T20: 08: 51.1784794Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.1785619Z شماره یافت شده: شماره # 1597 - آدرس ERC1592 و قوانین انتقال سازگار با ERC20 آخرین به روزرسانی 2019-05-31T20: 49: 49Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 51.1786165Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.1786851Z شماره یافت شده: شماره # 1594 - ERC 1594: Core Security Token Standard آخرین به روزرسانی 2019-04-15T05: 35: 11Z (درست است؟ نادرست است)
2020-09-19T20: 08: 51.1787341Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.1788086Z شماره یافت: شماره # 1590 - روابط عمومی EIP-1485. ارتقا Anti Anti ETHASIC ethash به TETHASHV1 آخرین به روزرسانی 2019-01-10T20: 27: 13Z (آیا غلط است؟)
2020-09-19T20: 08: 51.1790773Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.1792260Z شماره یافت شده: شماره # 1586 - ERC1586: استاندارد توزیع مجدد ریسک برای پرداخت ارز رمزپایه آخرین بروزرسانی 2019-02-16T17: 40: 54Z (اشتباه است؟)
2020-09-19T20: 08: 51.1792905Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.1794045Z شماره یافت شده: شماره # 1585 - افزودن EIP برای استانداردسازی قالب رمزگذاری ABI آخرین بروزرسانی 2020-09-15T19: 07: 55Z (درست است؟)
2020-09-19T20: 08: 51.1794538Z Z
2020-09-19T20: 08: 51.1795673Z بررسی برچسب کهنه در شماره # 1585
2020-09-19T20: 08: 51.3124948Z شماره # 1585 در تاریخ بیگانه مشخص شده است: 2020-09-15T19: 07: 55Z
2020-09-19T20: 08: 51.3125446Z بررسی نظرات در مورد شماره 1585 از 2020-09-15T19: 07: 55Z
2020-09-19T20: 08: 51.4114168Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 51.4114497Z شماره شماره 1585 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 51.4114781Z شماره شماره 1585 به روز شده است: درست است
2020-09-19T20: 08: 51.4115129Z Stale pr هنوز به اندازه کافی سنی نیست که بتواند آن را ببندد (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 51.4116228Z شماره یافت شده: شماره # 1576 - EIP-1576: پروتکل مذاکره پیشنهاد ساده زمزمه آخرین بروزرسانی 2020-09-15T19: 07: 56Z (درست است؟)
2020-09-19T20: 08: 51.4116666Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 51.4116922Z بررسی برچسب کهنه در شماره # 1576
2020-09-19T20: 08: 51.5625082Z شماره # 1576 در تاریخ بی اثر مشخص شده است: 2020-09-15T19: 07: 56Z
2020-09-19T20: 08: 51.5625813Z بررسی نظرات در مورد شماره 1576 از 2020-09-15T19: 07: 56Z
2020-09-19T20: 08: 51.6885051Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 51.6885443Z شماره شماره 1576 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 51.6887819Z شماره شماره 1576 به روز شده است: درست است
2020-09-19T20: 08: 51.6888176Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 51.6889097Z شماره یافت شده: شماره # 1572 - ERC1572: آخرین بار کارت تماس با ما به روز شد 2018-12-05T10: 50: 55Z (آیا غلط است)
2020-09-19T20: 08: 51.6889487Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.6890077Z شماره یافت شده: شماره # 1553 - ERC1540: دارایی توکن استاندارد آخرین به روزرسانی 2018-11-26T12: 11: 16Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 51.6890478Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 51.6891063Z شماره یافت شده: شماره # 1550 - اضافه شده استاندارد کنترل دسترسی EIP-1480 آخرین بروزرسانی 2020-09-15T19: 07: 57Z (درست است؟)
2020-09-19T20: 08: 51.6891502Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 51.6891748Z بررسی برچسب قدیمی در مورد شماره 1550
2020-09-19T20: 08: 51.8123944Z شماره # 1550 در تاریخ بیست و پنجم مشخص شد: 2020-09-15T19: 07: 57Z
2020-09-19T20: 08: 51.8124965Z بررسی نظرات در مورد شماره 1550 از 2020-09-15T19: 07: 57Z
2020-09-19T20: 08: 51.9086094Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 51.9086694Z شماره شماره 1550 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 51.9087136Z شماره شماره 1550 به روز شده است: درست است
2020-09-19T20: 08: 51.9087663Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 51.9088719Z شماره یافت شده: شماره # 1540 - ERC1540: دارایی توکن استاندارد آخرین بروزرسانی 2020-09-15T19: 07: 59Z (درست است؟)
2020-09-19T20: 08: 51.9089310Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 51.9089704Z بررسی برچسب کهنه در شماره # 1540
2020-09-19T20: 08: 52.0306117Z شماره شماره 1540 کهنه در تاریخ مشخص شده: 2020-09-15T19: 07: 59Z
2020-09-19T20: 08: 52.0306645Z بررسی نظرات در مورد شماره 1540 از 2020-09-15T19: 07: 59Z
2020-09-19T20: 08: 52.1294104Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 52.1294450Z شماره شماره 1540 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 52.1294731Z شماره شماره 1540 به روز شده است: درست است
2020-09-19T20: 08: 52.1295096Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 52.1296038Z شماره یافت شده: شماره # 1538 - ERC1538: استاندارد قرارداد شفاف آخرین به روزرسانی 2020-02-25T22: 56: 47Z (اشتباه است؟)
2020-09-19T20: 08: 52.1296486Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.1298060Z شماره یافت شده: شماره # 1532 - استاندارد بدهی را اضافه کنید آخرین به روزرسانی 2020-09-15T19: 08: 00Z (درست است؟)
2020-09-19T20: 08: 52.1298408Z یک پرنده قدیمی پیدا کرد
2020-09-19T20: 08: 52.1298676Z بررسی برچسب کهنه در شماره # 1532
2020-09-19T20: 08: 52.2617911Z شماره شماره 1532 در تاریخ بیگانه مشخص شده است: 2020-09-15T19: 08: 00Z
2020-09-19T20: 08: 52.2618477Z بررسی نظرات در مورد شماره 1532 از 2020-09-15T19: 08: 00Z
2020-09-19T20: 08: 52.3767616Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 52.3768284Z شماره شماره 1532 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 52.3771839Z شماره شماره 1532 به روز شده است: درست است
2020-09-19T20: 08: 52.3772277Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 52.3773477Z شماره یافت شده: شماره # 1528 - دارایی قابل انعطاف ERC721 با Fungible ERC20 آخرین به روزرسانی 2018-12-02T14: 39: 53Z (اشتباه است؟)
2020-09-19T20: 08: 52.3773966Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.3774772Z شماره یافت شده: شماره # 1526 - بحث: آخرین تقسیم سود سهام آخرین تقسیم 2019-03-20T14: 01: 52Z (اشتباه است؟)
2020-09-19T20: 08: 52.3775213Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.3776084Z شماره یافت شده: شماره # 1523 - بحث: استاندارد سیاست های بیمه به عنوان ERC-721 توکن های غیرقابل انعطاف آخرین بروزرسانی: 2019-05-22T09: 38: 55Z (pr؟ false)
2020-09-19T20: 08: 52.3776640Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.3779198Z شماره یافت شده: شماره # 1513 - آخرین بار EIP برای RFT به روز شده 2020-09-15T21: 07: 27Z (درست است؟)
2020-09-19T20: 08: 52.3780123Z شماره یافت شده: شماره # 1511 - آخرین مدیر توکن استاندارد آخرین بروزرسانی 2020-09-15T19: 08: 04Z (درست است؟)
2020-09-19T20: 08: 52.3780921Z یافتن یک سکون قدیمی
2020-09-19T20: 08: 52.3781185Z بررسی برچسب کهنه در شماره # 1511
2020-09-19T20: 08: 52.5053368Z شماره # 1511 در تاریخ بیگانه مشخص شده است: 2020-09-15T19: 08: 04Z
2020-09-19T20: 08: 52.5053897Z بررسی نظرات در مورد شماره 1511 از 2020-09-15T19: 08: 04Z
2020-09-19T20: 08: 52.6203703Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 52.6204080Z شماره شماره 1511 در مورد نظر داده شده است: نادرست است
شماره شماره 229/11/2020: 09-02-19T20: 08: 52.6204386Z
2020-09-19T20: 08: 52.6204787Z Stale pr هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ false ، hasUpdate؟ true
2020-09-19T20: 08: 52.6205860Z شماره یافت شده: شماره # 1505 - آخرین ارسال Token (پسوند ERC20) آخرین بروزرسانی 2020-02-19T07: 06: 24Z (اشتباه است؟)
2020-09-19T20: 08: 52.6206509Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6207324Z موضوع یافت شده: شماره # 1503 - آخرین قرارداد ارتقاable پذیر ERC-54 (USC) آخرین به روزرسانی 2019-07-11T03: 49: 09Z (اشتباه است؟)
2020-09-19T20: 08: 52.6211152Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6214468Z شماره یافت شده: شماره # 1500 - ERC 1500: کوپن های غیرقابل انتقال و قابل تنظیم برای استفاده رایگان از dApps آخرین به روزرسانی 2018-12-22T06: 51: 05Z (pr is false)
2020-09-19T20: 08: 52.6215312Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6216289Z شماره یافت شده: شماره # 1499 - لایه پیام رسان استاندارد شده برای طبقه بندی ضعف قرارداد هوشمند آخرین بروزرسانی: 2020-05-29T15: 22: 26Z (آیا غلط است؟)
2020-09-19T20: 08: 52.6217093Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6218320Z شماره یافت شده: شماره # 1498 - روش استاندارد محاسبه بازپرداخت گاز رله آخرین بروزرسانی 2018-10-16T18: 42: 19Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.6218875Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6220930Z شماره یافت شده: شماره # 1497 - ERC 1497: آخرین بار شواهد به روز شده در تاریخ 2019-05-19T23: 29: 42Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.6221413Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6222105Z شماره یافت شده: شماره # 1495 - ERC-1484: آخرین تجمیع هویت دیجیتال آخرین به روز رسانی 2019-04-25T06: 35: 29Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.6222779Z رد شدن از مسئله به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6224594Z شماره یافت شده: شماره # 1481 - EIP-1480: استاندارد کنترل دسترسی آخرین به روزرسانی 2018-10-09T11: 00: 32Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.6225418Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6226141Z شماره یافت شده: شماره # 1469 - EIP-1470: طبقه بندی ضعف قرارداد هوشمند (SWC) آخرین به روزرسانی 2019-05-20T09: 35: 15Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.6226680Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6227318Z شماره یافت شده: شماره شماره 1467 - نقش ویراستاران در روند EIP آخرین بروزرسانی 2020-08-29T01: 09: 52Z (اشتباه است؟
2020-09-19T20: 08: 52.6227775Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.6231286Z شماره یافت شده: شماره # 1456 - ERC-1456 - آدرس متادادها JSON Schema آخرین بروزرسانی 2020-09-15T19: 08: 05Z (درست است؟)
2020-09-19T20: 08: 52.6231995Z یک پروانه قدیمی پیدا کرد
2020-09-19T20: 08: 52.6232436Z بررسی برچسب کهنه در شماره # 1456
2020-09-19T20: 08: 52.7839483Z شماره شماره 1456 در تاریخ بیگانه مشخص شده است: 2020-09-15T19: 08: 05Z
2020-09-19T20: 08: 52.7840528Z بررسی نظرات در مورد شماره 1456 از 2020-09-15T19: 08: 05Z
2020-09-19T20: 08: 52.8932045Z نظرات توسط axic یا ربات دیگری ساخته نشده است: 0
2020-09-19T20: 08: 52.8932524Z شماره شماره 1456 در مورد نظر داده شده است: نادرست است
2020-09-19T20: 08: 52.8932909Z شماره شماره 1456 به روز شده است: درست است
2020-09-19T20: 08: 52.8934562Z قدیمی هنوز به اندازه کافی قدیمی نیست که بتواند بسته شود (آیا نظرات؟ اشتباه است ، آیا به روز شده است؟ درست است
2020-09-19T20: 08: 52.8935798Z شماره یافت شده: شماره # 1449 - ERC1449: آخرین بار قابل اعتماد APC ERC20 به روز شده 2018-09-25T22: 13: 25Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 52.8936659Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8937585Z شماره یافت شده: شماره # 1448 - ERC - BeakerOS: یک پروتکل سیستم عامل آخرین بروزرسانی: 2018-09-25T13: 56: 30Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 52.8938193Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8939018Z شماره یافت شده: شماره # 1445 - آخرین معاملات در صف در آخرین بروزرسانی 2018-12-28T13: 51: 50Z (آیا غلط است؟)
2020-09-19T20: 08: 52.8939613Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8940854Z مسئله موجود: شماره # 1441 - معاملات هوشمند با افزایش قیمت گاز آخرین بروزرسانی 2018-09-23T14: 43: 41Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 52.8941441Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8942383Z شماره یافت شده: شماره # 1425 - ERC-1425: آخرین اقدام استاندارد آخرین به روز رسانی 2019-05-23T23: 54: 18Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.8942919Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8944004Z موضوع یافت شده: شماره # 1419 - پیشنهاد پیشنهادی تغییر ERC20: کل تأمین باید نشانه ها را در آدرس 0 کسر کند که آخرین به روزرسانی 2018-12-06T14: 25: 05Z (درست نیست؟ نادرست است)
2020-09-19T20: 08: 52.8944657Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8945447Z موضوع یافت شده: شماره # 1418 - اجاره بلاکچین: هزینه ثابت برای هر کلمه بلوک آخرین به روزرسانی 2019-03-16T18: 20: 34Z (اشتباه است؟ اشتباه است)
2020-09-19T20: 08: 52.8946021Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8946706Z شماره یافت شده: شماره # 1417 - EIP - 1417 نظرسنجی استاندارد 1417 آخرین به روز رسانی 2019-07-09T21: 05: 12Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.8947200Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8948143Z شماره یافت شده: شماره # 1412 - ERC1412: انتقال دسته ای برای علامت های غیر قابل دفع آخرین بروزرسانی 2018-10-17T06: 31: 44Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.8950229Z مسئله رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8952127Z شماره یافت شده: شماره # 1411 - ERC 1400: آخرین استاندارد Token Standard به روز شده در 2020-07-09T17: 44: 02Z (درست است؟ نادرست است)
2020-09-19T20: 08: 52.8952699Z مشکل رد شدن به دلیل خالی بودن پیام بیات
2020-09-19T20: 08: 52.8960537Z ## [هشدار] به حداکثر تعداد عملیات برای پردازش رسیده است. خارج شدن
2020-09-19T20: 08: 52.9015468Z پاکسازی فرایندهای یتیم
