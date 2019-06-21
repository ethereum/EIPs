---
sccp: 1
title: SCCP Purpose and Guidelines
status: Proposed
author: Kain Warwick <@kaiynne>
discussions-to: https://discord.gg/aApjG26
created: 2019-06-17
updated: N/A
---

## What is an SCCP?

SCCP stands for Synthetix Configuration Change Proposal. SCCP's are documents to make a case for modifying one of the system configuration variables. The intent is to provide a clear and detailed history behind each configuration change and the rationale behind it at the time it was implemented. The author of the document is responsible for building consensus within the community and documenting dissenting opinions.

## SCCP Rationale

We intend SCCPs to be the primary mechanisms for proposing configuration changes to Synthetix. Because they are maintained as text files in a versioned repository, their revision history is the historical record of the configuration change proposal.

It is highly recommended that a single SCCP contain a single variable change. The more focused the SCCP, the more successful it is likely to be.

An SCCP must meet certain minimum criteria. It must be a clear and complete description of the proposed variable change.

## SCCP Work Flow

Parties involved in the process are the *author*, the [*SIP editors*](#sip-editors), and the [Synthetix Engineering Team].

:warning: Before you begin, vet your idea, this will save you time. Ask the Synthetix community first if the proposed change is original to avoid wasting time on something that will be rejected based on prior research (searching the Internet does not always do the trick). It also helps to make sure the idea is applicable to the entire community and not just the author. Just because an idea sounds good to the author does not mean it will have the intend effect. The appropriate public forum to gauge interest around your SCCP is [the Synthetix Discord].

Your role as the champion is to write the SCCP using the style and format described below, shepherd the discussions in the appropriate forums, and build community consensus around the idea. Following is the process that a successful SCCP will move along:

```
[ WIP ] -> [ PROPOSED ] -> [ APPROVED ] -> [ IMPLEMENTED ]
```

Each status change is requested by the SCCP author and reviewed by the SIP editors. Use a pull request to update the status. Please include a link to where people should continue discussing your SCCP. The SIP editors will process these requests as per the conditions below.

* **Work in progress (WIP)** -- Once the champion has asked the Synthetix community whether an idea has any chance of support, they will write a draft SCCP as a [pull request].

* **Proposed** If agreeable, SIP editor will assign the SCCP a number (generally the issue or PR number related to the SCCP) and merge your pull request. The SIP editor will not unreasonably deny an SCCP. Proposed SCCPs will be discussed on governance calls and in Discord. If there is a reasonable level of consensus around the change on the governance call the change will be moved to approved. If the change is contentious a vote of token holders may be held to resolve the issue or approval may be delayed until consensus is reached.

* **Approved** -- This SCCP has passed community governance and is now being prioritised.
  
* **Implemented** -- This SCCP has been implemented and the variable changed on mainnet.

## What belongs in a successful SCCP?

Each SCCP should have the following parts:

- Preamble - RFC 822 style headers containing metadata about the SCCP, including the SCCP number, a short descriptive title (limited to a maximum of 44 characters), and the author details.
- Simple Summary - “If you can’t explain it simply, you don’t understand it well enough.” Provide a simplified and layman-accessible explanation of the SCCP.
- Abstract - a short (~200 word) description of the variable change proposed.
- Motivation (*optional) - The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.
- Copyright Waiver - All SCCPs must be in the public domain. See the bottom of this SCCP for an example copyright waiver.

## SCCP Formats and Templates

SCCPs should be written in [markdown] format.
Image files should be included in a subdirectory of the `assets` folder for that SCCP as follows: `assets/sccp-X` (for sccp **X**). When linking to an image in the SCCP, use relative links such as `../assets/sccp-X/image.png`.

## SCCP Header Preamble

Each SCCP must begin with an [RFC 822](https://www.ietf.org/rfc/rfc822.txt) style header preamble, preceded and followed by three hyphens (`---`). This header is also termed ["front matter" by Jekyll](https://jekyllrb.com/docs/front-matter/). The headers must appear in the following order. Headers marked with "*" are optional and are described below. All other headers are required.

` sip:` <SCCP number> (this is determined by the SIP editor)

` title:` <SCCP title>

` author:` <a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s). Details are below.>

` * discussions-to:` \<a url pointing to the official discussion thread\>

` status:` < WIP | PROPOSED | APPROVED | IMPLEMENTED >

` created:` <date created on>

` * updated:` <comma separated list of dates>

` * requires:` <SIP number(s)>

Headers that permit lists must separate elements with commas.

Headers requiring dates will always do so in the format of ISO 8601 (yyyy-mm-dd).

#### `author` header

The `author` header optionally lists the names, email addresses or usernames of the authors/owners of the SCCP. Those who prefer anonymity may use a username only, or a first name and a username. The format of the author header value must be:

> Random J. User &lt;address@dom.ain&gt;

or

> Random J. User (@username)

if the email address or GitHub username is included, and

> Random J. User

if the email address is not given.

#### `discussions-to` header

While an SCCP is in WIP or Proposed status, a `discussions-to` header will indicate the mailing list or URL where the SCCP is being discussed.

#### `created` header

The `created` header records the date that the SCCP was assigned a number. Both headers should be in yyyy-mm-dd format, e.g. 2001-08-14.

#### `updated` header

The `updated` header records the date(s) when the SCCP was updated with "substantial" changes. This header is only valid for SCCPs of Draft and Active status.

#### `requires` header

SCCPs may have a `requires` header, indicating the SCCP numbers that this SCCP depends on.

## Auxiliary Files

SCCPs may include auxiliary files such as diagrams. Such files must be named SCCP-XXXX-Y.ext, where “XXXX” is the SCCP number, “Y” is a serial number (starting at 1), and “ext” is replaced by the actual file extension (e.g. “png”).

## SIP Editors

The current SIP editors are

` * Kain Warwick (@kaiynne)`

` * Justin Moses (@justinjmoses)`

` * Clinton Ennis (@clints)`

## SIP Editor Responsibilities

For each new SCCP that comes in, an editor does the following:

- Read the SCCP to check if it is ready: sound and complete. The ideas must make technical sense, even if they don't seem likely to get to final status.
- The title should accurately describe the content.
- Check the SCCP for language (spelling, grammar, sentence structure, etc.), markup (Github flavored Markdown), code style

If the SCCP isn't ready, the editor will send it back to the author for revision, with specific instructions.

Once the SCCP is ready for the repository, the SIP editor will:

- Assign an SCCP number (generally the PR number or, if preferred by the author, the Issue # if there was discussion in the Issues section of this repository about this SCCP)

- Merge the corresponding pull request

- Send a message back to the SCCP author with the next step.

Many SCCPs are written and maintained by developers with write access to the Ethereum codebase. The SIP editors monitor SCCP changes, and correct any structure, grammar, spelling, or markup mistakes we see.

The editors don't pass judgment on SCCPs. We merely do the administrative & editorial part.

## History

The SCCP document was derived heavily from the EIP Ethereum Improvement Proposal document in many places text was simply copied and modified. Any comments about the SCCP document should be directed to the SIP editors. The history of the EIP is quoted below from the EIP document  for context:

* *"This document (EIP) was derived heavily from [Bitcoin's BIP-0001] written by Amir Taaki which in turn was derived from [Python's PEP-0001]. In many places text was simply copied and modified. Although the PEP-0001 text was written by Barry Warsaw, Jeremy Hylton, and David Goodger, they are not responsible for its use..."* *

June 10, 2019: SCCP-1 has been drafted and submitted as a PR.


See [the revision history for further details](https://github.com/synthetixio/**), which is also available by clicking on the History button in the top right of the SCCP.

### Bibliography

[the Synthetix Discord]: https://discord.gg/a2E6uxk
[pull request]: https://github.com/Synthetixio/SIPs/SCCP/pulls
[markdown]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
[Bitcoin's BIP-0001]: https://github.com/bitcoin/bips
[Python's PEP-0001]: https://www.python.org/dev/peps/
[Synthetix Engineering Team]: https://github.com/orgs/Synthetixio/people

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
