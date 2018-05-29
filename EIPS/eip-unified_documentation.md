---
eip: <to be assigned>
title: Unified Documentation
author: Micah Dameron(@chronaeon)
Discussions-to: https://github.com/ethereum/EIPs/issues/1054 
status: Draft
type: Administrative
category: Emergent
created: 2018-05-03
---

## Simple Summary
Combine official Ethereum documentation into a unified reference that is maintained frictionlessly by the community.
## Abstract
We propose a comprehensive tagging system that signals sourcing on statements about Ethereum in a Wiki-based environment.
## Motivation
There are a variety of types and kinds of documentation about Ethereum; from the complete Solidity documentation, to the Ethereum Wiki, Whitepaper, Yellowpaper, to core-developer blogs, to comments inside Geth and other codebases, to articles on Medium, conversations in Gitter, and still more sources that remain unmentioned. 
Despite these thorough and quality sources of individual documentation, the overall state of Ethereum’s documentation is in many ways undeveloped. Like slivers of cracked glass, there are multiple reflections where one expects to see a single, comprehensive image. This causes difficulties on three layers:
Outsiders have trouble getting a unified view of Ethereum.
Client teams each work from slightly altered points of view.
Insiders can have different perspectives from each other about what is most important, depending on their primary sources for information about Ethereum.
## Specification
A Wiki-like environment with a tagging system to automatically and seamlessly display the verifiability of statements made about Ethereum. Statements are tagged via **source badges**. There can be a default set of badges accessible to everyone, along with the option for users to create custom badges. The default set includes badges for:
Yellowpaper (for statements made in the Yellowpaper)
Whitepaper (for statements made in the Whitepaper)
Wiki (for statements made in the Ethereum Wiki)
Solidity Docs (for statements made in the Solidity docs)
Core-Blog (for statements made in Ethereum core blog posts)
Core-Dev (for statements made in core-developer code or comments)
Core-Gitter (for statements made by the core team on Gitter)
Custom Badges (for emerging statements from sources that don’t exist yet) 
Statements about Ethereum that have multiple source-badges will be seen intrinsically as “more justified.” 
For example, The Yellowpaper and the Ethereum Wiki each have different descriptions of **RLP**. Statements about **RLP** that can be found in both would have a Yellowpaper badge and an Ethereum Wiki badge, while statements that can only be found in one or the other would only have a single corresponding badge.

## Rationale
This will be a community managed and a decentralized endeavor. Content development should be driven solely or mostly by interested community members. Quality standards must be stringent in providing good results, but easily enforced in action. This avoids the problem of needing to hire an entire team to code and maintain **authoritative** documentation.
Community interest helps ensure the creation of content and badges help ensure the authority of content. It can be taken for granted that *the more a statement is repeated independently and in multiple credible sources the more authoritative that statement is, regardless of the credibility of any single trustworthy source containing that statement on its own.*
The badge system is one way to make quality content float to the top and be recognized easily as a valid contribution without the necessity of invoking a bunch of contribution rules.
## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

