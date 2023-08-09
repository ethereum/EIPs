---
eip: 1
title: EIP Content Guidelines
status: Living
type: Meta
author: Martin Becze <mb@ethereum.org>, Hudson Jameson <hudson@ethereum.org>, et al.
created: 2015-10-27
---

## What is an EIP?

EIP stands for Ethereum Improvement Proposal. An EIP is a design document providing information to the Ethereum community, or describing a new feature for Ethereum or its processes or environment. The EIP should provide a concise technical specification of the feature and a rationale for the feature. The EIP author is responsible for building consensus within the community and documenting dissenting opinions.

We intend EIPs to be the primary mechanisms for proposing new features, for collecting community technical input on an issue, and for documenting the design decisions that have gone into Ethereum. Because the EIPs are maintained as text files in a versioned repository, their revision history is the historical record of the feature proposal.

For Ethereum implementers, EIPs are a convenient way to track the progress of their implementation. Ideally each implementation maintainer would list the EIPs that they have implemented. This will give end users a convenient way to know the current status of a given implementation or library.

## EIP Editors? Topic Groups?

The EIP Editors are an organization that oversee the EIP process and provide editorial review of proposals submitted here. Topic Groups are dedicated groups that manage proposals in active development related by a common theme or _topic_.

For more information about EIP Editors, Topic Groups and how we govern ourselves, see [EIP-5069].

## Proposals

The following subsections apply to all proposals. Make sure to also follow the guidelines set out by your proposal's Topic Group.

### Identifiers

Proposals are assigned an identifier by the EIP Editors before being accepted into a Topic Group.

### Stewardship

The steward of a proposal defines the rules it must follow and is responsible for enforcing those rules. The steward is distinct from the authors of a proposal, who do the important bits, like writing the proposal in the first place.

When created, a proposal is first stewarded by a Topic Group. When the proposal moves into a semi-mutable or immutable status (more on those later), it changes hands and enters the stewardship of the EIP Editors.

The stewards of a proposal make sure that it is (or at least eventually becomes):

 - Relevant to Ethereum;
 - Necessary to coordinate multiple implementers;
 - Plausibly technically sound and implementable;
 - Reasonably well-written and understandable; and
 - Styled consistently with other proposals.

Stewards may make minor changes to proposals to keep things moving smoothly, but they should not make normative changes without author consent.

### Process & Statuses

Each proposal moves through several statuses as it progresses through the editorial process. Each Topic Group defines the statuses for proposals relevant to their topic, and how a proposal moves between them.

As alluded to earlier, there are three types of statuses: mutable, semi-mutable, and immutable. The ultimate goal of every Topic Group is to have their proposals graduate first to a semi-mutable status, then to an immutable one.

Mutable statuses are assigned to proposals in active development. Code review is not necessarily required for changes while in a mutable status, although individual Topic Groups may mandate otherwise. Proposals in mutable statuses are stewarded by their respective Topic Groups.

Semi-mutable statuses are assigned to proposals that are completely written, and are ready to be published. Semi-mutable statuses generally include a deadline for comments, and are the last opportunity for changes. If a proposal in a semi-mutable status undergoes major revisions, it must either revert to a mutable status or have its comment window extended. Proposals in semi-mutable statuses are stewarded by the EIP Editors, and changes made to them always require code review.

Finally, there are immutable statuses. Proposals in immutable statuses do not change, except for errata and markup/formatting. These proposals are either completed and ready for use, or permanently withdrawn. Proposals in immutable statuses are stewarded by the EIP Editors, and always require code reviews.

### Content, Formatting & Metadata

In addition to the requirements set out by each Topic Group, all proposals must adhere to some overarching rules.

#### General Notes

##### Dates & Times

Whenever present, dates should be in the `yyyy-mm-dd` format. If more precision is required, use a format from [RFC 3339].

##### Proposal References

When mentioning other proposals, use the format "EIP-X" or "ERC-X" as appropriate, without the quotes. There should be a single hyphen between the prefix and the number, with no intervening white space.

##### Auxiliary Files

Images, diagrams and auxiliary files should be included in a subdirectory of the `assets` folder for that proposal as follows: `assets/eip-N` (where **N** is to be replaced with the proposal's number). When linking to an auxiliary file, use relative paths such as `../assets/eip-1/image.png`.

##### Transitive Mutability

Keeping a proposal immutable upon completion is an important property of the EIP process. Mentioning/linking to other proposals or external resources pokes a hole in that immutability.

In practice, this means:

 * Proposals in immutable statuses may only mention/link to other immutable proposals;
 * Proposals in semi-mutable statuses may mention/link to semi-mutable and immutable proposals; and
 * Proposals in mutable statues can mention/link to any other proposals.

Similarly, external links (`http://...`, `doi:10.17487/RFC1034`, `The Hobbit by J.R.R. Tolkien`, etc.) are only allowed if they meet the requirements set out in [EIP-5757] and are approved by the proposal's Topic Group. See that Topic Group for more information.

##### Intellectual Property Rights

All content contained within a proposal's file must be available under [CC0 1.0 Universal][CC0], and may be made additionally available under other terms. For example, content released with an SPDX ID of `CC0 OR GPL-2.0` is acceptable, while `CC0 AND GPL-2.0` is not.

Auxiliary files should be made available under [CC0 1.0 Universal][CC0].

If you hold or are aware of any legal protections (copyright, patent, trademark, etc.) that might interact with a proposal, please inform the EIP Editors. We will do our best to publish this information, however we cannot guarantee its correctness or completeness.

#### Preamble

Each proposal must begin with an [RFC 822] style header preamble. The preamble must be preceded and followed by a single line containing three hyphens (`---`).

The first seven headers must be the following, in order: `eip`, `title`, `description`, `author`, `discussions-to`, `topic-group`, and `status`.

Only the headers explicitly listed here and by a proposal's Topic Group are permitted. Other headers must not be present.

##### Header: `eip`

A unique unsigned integer assigned by the EIP Editors as a permanent identifier for the proposal.

For example:

```
eip: 1234
```

##### Header: `title`

A short (44 octets or less) collection of words&mdash;not a sentence&mdash;identifying the proposal without too much ambiguity.

Avoid variations of the word "standard", because nearly all proposals are standards of some kind. Similarly, don't include the proposal's number.

For example:

```
title: Limit account nonce to 2^64-1
```

##### Header: `description`

A full, but short (140 octets or less), sentence that conveys the essence of the proposal.

Avoid variations of the word "standard", because nearly all proposals are standards of some kind. Similarly, don't include the proposal's number.

For example:

```
description: Introduce an instruction which pushes the constant value 0 onto the stack.
```

##### Header: `author`

List of the author(s) of the proposal, plus their username(s) and/or email address(es). Used for notifications and access control. Those who prefer anonymity may use a pseudonym in place of a real name.

The format of the `author` header value must be:

> Random J. User &lt;address@example.com&gt;

or

> Random J. User (@username)

or

> Random J. User (@username) &lt;address@example.com&gt;

if the email address and/or GitHub username is included, and

> Random J. User

if neither the email address nor the GitHub username are given.

At least one author must be paired with a GitHub username.

For example:

```
author: Paul Simon (@paulsimon) <paul.simon@example.com>, Art Garfunkel, Joni Mitchell (@jmitchell)
```

##### Header: `discussions-to`

Location (URL) where discussions related to the proposal can be found. This header should not change once a proposal is accepted.

The preferred location for discussions is the [Ethereum Magicians] forum, though Topic Groups may permit other locations that have a proven history of availability, openness, and the ability to continue the discussion after long periods of inactivity (unlike, for example, Reddit.)

For example:

```
discussions-to: https://ethereum-magicians.org/t/example/12345
```

##### Header: `topic-group`

The identifier of the Topic Group originally stewarding a proposal.

For example:

```
topic-group: Core
```

##### Header: `status`

Where the proposal sits in the EIP process. See the proposal's Topic Group documentation for permitted values.

For example:

```
status: Final
```

#### Body

Proposal content must be formatted with Markdown, specifically CommonMark as registered in [RFC 7764] with some extensions.

## Editors

### Current

See the [List of EIP Editors][editors].

### Emeritus

We thank the following Editors for their time and effort over the years:

 - Casey Detrio (@cdetrio)
 - Hudson Jameson (@Souptacular)
 - Martin Becze (@wanderer)
 - Micah Zoltu (@MicahZoltu)
 - Nick Johnson (@arachnid)
 - Nick Savers (@nicksavers)
 - Vitalik Buterin (@vbuterin)

## History

This document was derived heavily from Bitcoin's [BIP 1] written by Amir Taaki which in turn was derived from Python's [PEP 1]. In many places text was simply copied and modified. Although the PEP 1 text was written by Barry Warsaw, Jeremy Hylton, and David Goodger, they are not responsible for its use in the Ethereum Improvement Process, and should not be bothered with technical questions specific to Ethereum or the EIP Process. Please direct all comments to the EIP Editors.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

[editors]: https://github.com/ethereum/EIPs/blob/master/config/eip-editors.yml
[Ethereum Magicians]: https://ethereum-magicians.org/
[EIP-5757]: ./eip-5757.md
[RFC 822]: https://www.rfc-editor.org/rfc/rfc822
[RFC 2418]: https://www.rfc-editor.org/rfc/rfc2418
[RFC 3339]: https://www.rfc-editor.org/rfc/rfc3339
[RFC 7764]: https://www.rfc-editor.org/rfc/rfc7764
[BIP 0001]: https://github.com/bitcoin/bips
[PEP 1]: https://peps.python.org/
[CC0]: ../LICENSE.md
