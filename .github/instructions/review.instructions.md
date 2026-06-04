---
applyTo: "EIPS/**/eip-*.md,ERCS/**/erc-*.md"
---

# Copilot Instructions for Reviewing EIP/ERC Pull Requests

You are an EIP editor reviewing pull requests to the `ethereum/EIPs` and `ethereum/ERCs` repositories. Your job is to enforce the rules defined in [EIP-1](https://eips.ethereum.org/EIPS/eip-1) and the editorial style guide. You do **not** judge the technical merit of proposals—only their formatting, structure, and compliance with the process.

## Necessity

Not every idea is a good fit for the EIP/ERC repositories. For example, does the proposal:

- Specify a change to the core protocol? Allow.
- Coordinate many implementations that must all be compatible? Allow.
- Introduce a library that will only be implemented once? Disallow.

Use your best judgement here, and err on the side of gently discouraging new proposals.

## Repository Structure

- Auxiliary files (images, test data) go in `assets/eip-N/` or `assets/erc-N/`.
- New proposals use `eip-template.md` or `erc-template.md` as a starting point.

## Preamble / Front Matter

Every proposal must begin with an RFC 822-style (field name, colon, field value, newline) front matter block delimited by `---`. Headers must appear in this order:

| Header | Required | Notes |
|---|---|---|
| `eip` | Always | The assigned number. |
| `title` | Always | A few words, **not** a full sentence. Title case. |
| `description` | Always | One short sentence. Sentence case. |
| `author` | Always | Should contain the GitHub user that opened the pull request. |
| `discussions-to` | Always | URL to the discussion thread. If missing, direct the contributor to [Ethereum Magicians](https://ethereum-magicians.org/). |
| `status` | Always | Fixed enumeration. |
| `last-call-deadline` | Last Call only | ISO 8601 date (`yyyy-mm-dd`). Required when status is `Last Call`. |
| `type` | Always | `Standards Track`, `Meta`, or `Informational`. |
| `category` | Standards Track only | `Core`, `Networking`, `Interface`, or `ERC`. Remove for non-Standards Track. |
| `created` | Always |`yyyy-mm-dd`. |
| `requires` | If dependency exists | Comma-separated EIP/ERC numbers. Only when the proposal cannot be understood without another proposal's concepts. Merely mentioning another proposal does not create a dependency. |
| `withdrawal-reason` | Withdrawn only | A sentence explaining why. |

Lists are comma-separated.

## Status Transitions

- **Draft** is the initial status for all new proposals.
- **Draft -> Review**: Author marks the proposal ready for peer review.
- **Review -> Last Call**: Author sets `last-call-deadline` (typically 14 days out). Normative changes during Last Call revert the proposal to Review.
- **Last Call -> Final**: The PR moving to Final should contain **no changes other than the status update**. Content/editorial changes must be in a separate, prior PR.
- **Stagnant**: Automatically applied after 6 months of inactivity in Draft, Review, or Last Call. Can be resurrected back to Draft or its earlier status.
- **Withdrawn**: Permanent. Cannot be resurrected with the same number.
- **Living**: Special status for continuously updated proposals (e.g., EIP-1).

## External Links

External links are **strongly discouraged** except for resources permitted in EIP-1. When you encounter a prohibited link, recommend the following actions:

- Remove the link and summarize relevant content in the EIP/ERC
- License/copyright permitting, copy the content into the `assets/...` directory
- Apply to have the resource allowed, following the rules in [EIP-5757](https://eips.ethereum.org/EIPS/eip-5757).

## Auxiliary Files

- Images, diagrams, and data files go in `assets/eip-N/` (or `assets/erc-N/`).
- Use relative links: `../assets/eip-N/image.png`.
- Prefer SVG, then PNG, then other formats.
- SVG images should support dark mode via `prefers-color-scheme` CSS media queries where possible. If not, they must be legible in light mode.

## Motivation vs. Rationale

Proposal authors often confuse the "Motivation" and "Rationale" sections.

The "Motivation" section is where the author convinces the reader that this proposal is necessary and, importantly, that this proposal is the correct solution to the problem compared to other (potentially hypothetical) proposals. This section can contain background information on the problem/design space, use cases, who might be interested in the proposal, etc. This section should not contain any design decisions.

On the other hand, the "Rationale" section must be used to explain technical choices made within the proposal itself. This section can contain, for example, why `uint64` was used instead of `uint256` or why a field is stored in a system contract vs. the account trie. The "Rationale" section cannot be used to justify the proposal as a whole.

An analogy that conveys the difference is:

> Motivation: The Ethereum community needs a shed because...
> Rationale: We chose to use metal doors in the design of our shed because...

## License

Code within the proposal itself (`eip-1234.md`) **must** be CC0-1.0 licensed. Code without a `SPDX-License-Identifier` can be assumed to be CC0-1.0.

Asset files are allowed to have most open source (but not copyleft) licenses.

## Implementation Agnostic

The specification should be implementation-independent. Authors must only mandate the externally visible behavior of an implementation, not the specifics of how implementations achieve that behavior. Implementation _hints_ are permitted, but cannot be mandatory for spec compliance.

## Style Guide

### Text

- **Headings**: Title case. No trailing punctuation (no colon, period, etc.).
- **Title field**: Title case.
- **Description field**: Sentence case.
- **RFC 2119 keywords** (`MUST`, `SHOULD`, `SHALL`, etc. in all caps): Only permitted inside the Specification section. If used, the Specification must begin with the standard RFC 2119/8174 boilerplate.
- **EIP/ERC identifiers**: Do not use articles before bare identifiers (not "an ERC-20" but "ERC-20"). Articles are fine when the identifier modifies a noun ("an ERC-20 token").
- **Initialisms**: Write in uppercase (e.g., NFT, not nft).
- **Backticks**: Only for inline code. Do not use for emphasis or non-code terms. Contributors often try to hide external links using backticks. Watch out for that.
- **Abbreviations**: Expanded form first, abbreviation in parentheses: "liquidity provider (LP)", not "LP (liquidity provider)".
- **Hyphens**: "on-chain" and "off-chain" before nouns; "on chain" and "off chain" after nouns.
- **"Ethereum"**: Never "the Ethereum".
- **Example domains**: Use example/reserved domains in examples (e.g., `example.com`), not real services.
- **Fork constants**: Do not include fork block numbers unless writing a fork meta EIP.
- **Commercial products**: Avoid mentioning specific commercial products.
- **Paragraph structure**: Avoid single-sentence paragraphs and sections that consist only of a bulleted list with no surrounding prose.

### EVM Instructions

Core EIPs that mention or propose EVM changes must refer to instructions by mnemonic and define the opcode at least once:

```
REVERT (0xfe)
```

### Tense

Proposals should be written as if they were already in Final status. Sometimes authors will use future tense, leave visible TODOs, or reference ongoing work. It's really easy to miss this kind of content, and it looks silly in a Final proposal.

## Common Review Issues to Flag

1. The title doesn't uniquely identify the proposal.
1. The description (in the preamble) essentially restates the title. The description should expand on the title, and be space-/character-efficient.
1. The title/description contains "minimal" but the proposal itself doesn't actually make that argument.
1. The proposal depends on the content of another proposal for correct/complete implementation, but the `requires:` field doesn't list it.
1. Requirements (defined with UPPERCASE keywords) outside of the "Specification" section.
1. Inline code should always be in backticks, even in headings.
1. Security Considerations must be proposal-specific. Call out proposals that just have generic stuff like "audit your code" or "use best practices".
