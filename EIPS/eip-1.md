---
extip: 1
title: ExtIP Purpose and Guidelines
status: Draft
type: Meta
author: Primavera De Filippi <pdefilippi@cyber.harvard.edu>
created: 2022-09-22
---

## What is an ExtIP?

ExtIP stands for Extitute Improvement Proposal. An ExtIP is a design document providing information to the Extitute or describing a new feature for the Extitute or its processes or environment. The ExtIP should provide a concise technical specification of the feature and a rationale for the feature. The ExtIP author is responsible for building consensus within the community and documenting dissenting opinions.

## ExtIP Rationale

We intend ExtIPs to be the primary mechanisms for proposing new features, for collecting community technical input on an issue, and for documenting the design decisions that have gone into the Extitute. Because the ExtIPs are maintained as text files in a versioned repository, their revision history is the historical record of the feature proposal.

## ExtIP Schema
![image](assets/extip-schema.png "ExtIP Schema")
## ExtIP Types

There are three types of ExtIP:

  - **Governance ExtIP** describes any change that affects the core governance processes of the Extitute. Examples include a change to the governance protocol, procedures, guidelines, or decision-making process, or a change in the constitutional principles and values of the Extitute.

  - **Operational** ExtIP describes any change that affects the core operational processes of the Extitute. Examples include the addition of a new qualification badge, the introduction of a new sphere of activity, and any change or addition that affects the operations and/or the missions of the Extitute.

  - **Informational** ExtIP describes an extitutional design issue, or provides general guidelines or information to the Extitute, but does not propose a new feature.

It is highly recommended that a single ExtIP contain a single key proposal or new idea. The more focused the ExtIP, the more successful it tends to be. An ExtIP must be a clear and complete description of the proposed enhancement, which must be solid and must not complicate the governance or operations of the Extitute unduly.

## ExtIP Status

 - **Draft** status indicates that  the ExtIP is under active development by its authors. It can be expected to evolve. Draft Status ExtIPs may be transitioned to Provisional Status.
 - **Provisional** status indicates that the ExtIP has been frozen for provisional adoption and community feedback. Provisional ExtIPs may be refined based on feedback or advanced to Accepted Status.
 - **Accepted** status indicates that the ExtIP has been adopted by the Extitute.

## What belongs in a successful ExtIP?

Each ExtIP should have the following parts:

- Preamble - RFC 822 style headers containing metadata about the ExtIP, including the ExtIP number, a short descriptive title (limited to a maximum of 44 characters), a description (limited to a maximum of 140 characters), and the author details. Irrespective of the category, the title and description should not include ExtIP number. 

- Abstract - Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

- Motivation (optional) - A motivation section is critical for ExtIPs that want to change the Extitute. It should clearly explain why the existing protocol specification is inadequate to address the problem that the ExtIP solves. This section may be omitted if the motivation is evident.

- Specification - The technical specification should describe the syntax and semantics of any new feature. 

- Rationale - The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale should discuss important objections or concerns raised during discussion around the ExtIP.

- Reference Implementation (optional) - An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification. This section may be omitted for all ExtIPs.

- Copyright Waiver - All ExtIPs must be in the public domain. The copyright waiver MUST link to the license file and use the following wording: Copyright and related rights waived via [CC0](/LICENSE).

ExtIP Formats and Templates
-------------------------

ExtIPs should be written in [markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) format.