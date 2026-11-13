# AGENTS.md — what a pull request must look like before it needs an editor

This file is for authors of Ethereum Improvement Proposals and for the agents
helping them in a fresh clone of this repository. It describes the state a PR
should be in before it asks for editor attention. An editor-side agent runs the
same checks; a PR that follows this file produces no flags from that review and
goes straight to the editor's decision.

Everything here derives from [EIP-1](./EIPS/eip-1.md), [CONTRIBUTING.md](./CONTRIBUTING.md),
[eip-template.md](https://github.com/ethereum/EIPs/blob/master/eip-template.md) and the CI configuration under `config/`.
When this file and EIP-1 disagree, EIP-1 wins; report the discrepancy.

Throughout, `X` stands for the EIP number. Until an editor assigns one, `X` is
written literally.

**What the document is for.** The EIP is the root document for communication
and collaboration on the change, and it is the ecosystem's memory of it long
after the PR is closed. So it is as small as it can be, unambiguous,
self-contained, and readable in a single pass without outside context. Every
ambiguity costs a round trip with the author now and repeats that cost for
every implementer and reader later; this is why editors flag small things.

## 1. One PR, one change

- **New proposal.** Start from [eip-template.md](https://github.com/ethereum/EIPs/blob/master/eip-template.md). The PR
  adds exactly one file `EIPS/eip-X.md` plus, if needed, one directory
  `assets/eip-X/`. Nothing else is in the diff: no edits to other EIPs, no CI
  changes, no README edits.
- **Do not choose a number.** Use the literal placeholder `X` in the `eip:`
  header, the filename `EIPS/eip-X.md` and the assets path. An editor or
  associate editor assigns the number in a review comment on the PR. Expect
  the EIP Walidator job to fail on the filename until then; that is normal.
  When the number is assigned, apply it everywhere in one commit: the `eip:`
  header, the filename, the assets directory, every `../assets/eip-X/` link,
  and the `discussions-to` topic title if you can edit it.
- **Status change.** A PR that changes an EIP's status changes exactly one
  line: the `status:` field. Entering Last Call also adds
  `last-call-deadline`; entering Withdrawn also adds `withdrawal-reason`.
  Any other edit, however small, goes in a separate PR that is merged first.
  A status PR with other changes is sent back.
- **Edit to an existing EIP.** One EIP per PR and one kind of change per PR:
  a typo fix, a link fix, or a content change, not all three.
- Open a topic on <https://ethereum-magicians.org/c/eips/5> before the PR and
  put its URL in `discussions-to`. A GitHub PR, an issue, a chat link or a
  placeholder is not accepted and fails CI.
- Keep the PR out of GitHub draft state once it is ready for review. Draft PRs
  cannot be merged, and editors treat them as not yet submitted.
- The PR title is `Add EIP: <title>` for a new proposal, or
  `Update EIP-X: <what>` for an edit. The PR description says what the change
  does in a few sentences. Remove template boilerplate from it and keep it
  consistent with the text after every push.

## 2. Preamble

Fields appear in exactly this order and nothing else appears:

```
---
eip: X
title: <44 characters or fewer, Title Case>
description: <one full sentence, 140 characters or fewer>
author: Name (@githubhandle), Name <email@example.com>
discussions-to: https://ethereum-magicians.org/t/<topic>/<id>
status: Draft
last-call-deadline: yyyy-mm-dd   # Last Call only
type: Standards Track | Meta | Informational
category: Core | Networking | Interface   # Standards Track only
created: yyyy-mm-dd
requires: N, M                   # only if needed; ascending
withdrawal-reason: <sentence>    # Withdrawn only
---
```

Rules the linter and the reviewer enforce:

- `title` is a few words in Title Case, not a sentence. It does not contain
  the EIP number and does not contain the word "standard".
- `description` is one sentence with a verb ("Adds...", "Allows...",
  "Separates..."), in sentence case. It expands on the title instead of
  repeating it. No colon, no word like "standard", and any EIP reference
  written as `EIP-N`. A noun phrase is flagged.
- `author` entries are `Name (@handle)` or `Name <email>`. At least one entry
  must carry a GitHub handle or an email address, so that editors can reach
  you and the bot can accept your approval of edits. A real name is preferred
  over a bare handle.
- `discussions-to` is an ethereum-magicians.org topic.
- `status` is `Draft` for a new proposal.
- `last-call-deadline` appears only when `status` is Last Call.
- `category` is present if and only if `type` is Standards Track. ERC
  proposals belong in the ERCs repository, not here.
- `created` is the date of the PR, ISO format.
- `requires` lists every EIP the Specification cannot be understood or
  implemented without, and only those. An EIP mentioned for comparison is
  linked in the text but not listed. Every listed EIP must be linked somewhere
  in the text. See section 6 for what may be required.
- `withdrawal-reason` appears only when `status` is Withdrawn.

## 3. Sections

Headings, in this order, at level two. The linter rejects any other order and
any extra top-level section.

1. **Abstract.** A short technical paragraph a reader can take as the whole
   proposal. No normative keywords.
2. **Motivation.** The problem, not the solution, written for a reader
   years from now who needs to know why this change was made at all. May be
   omitted only when that is evident from the Abstract.
3. **Specification.** Everything an implementer needs, and nothing that is
   rationale. Starts with the RFC 2119 boilerplate below if any keyword is
   used anywhere in the section.
4. **Rationale.** Why each decision was made, alternatives considered, prior
   art cited. "TBD" is tolerated in a Draft.
5. **Backwards Compatibility.** Optional. Required as soon as the proposal
   introduces any incompatibility, and then it describes each one and how it
   is handled. No normative keywords.
6. **Test Cases.** Optional in general, required for consensus changes before
   Final. A visible "TBD" with a list of what the tests will cover is fine
   while Draft.
7. **Reference Implementation.** Optional. If present it points at code in
   `assets/` or at a permitted permalink; an empty section is flagged.
8. **Security Considerations.** Required, and specific to this proposal.
   Generic text such as "follow best practices" or "no new risks" is
   insufficient. `TODO` here is grounds for rejection. No normative keywords.
9. **Copyright.** Exactly:
   `Copyright and related rights waived via [CC0](../LICENSE.md).`

Delete every HTML comment from the template. Nothing in the file should read
"TODO", "Remove this comment", or "placeholder".

## 4. Normative language

- Put this exact paragraph at the top of Specification when any keyword is
  used:

  > The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
  > "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
  > "OPTIONAL" in this document are to be interpreted as described in
  > [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and
  > [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

  Link both RFCs. A subset of the keyword list, or an unlinked copy, is
  flagged. If no keyword is used anywhere, omit the paragraph.
- All-caps keywords (MUST, SHOULD, MAY, RECOMMENDED and the rest) appear only
  inside Specification, including its headings, notes and examples. Grep every
  other section before pushing. If a rule in Backwards Compatibility, Security
  Considerations or Rationale is genuinely normative, move it into
  Specification; otherwise write it in lowercase prose.
- Inside Specification, a rule that is meant to bind uses the keyword. A
  prohibition written as "may not be left out" or "should check" is flagged
  as ambiguous. Bold text is not a substitute for a keyword.
- A constant that is only a recommendation is not a constant. Put it in prose
  with RECOMMENDED, or label the table "Configuration parameters".

## 5. Completeness of the Specification

Each of these is checked and flagged when missing:

- The Specification defines the behavior itself. It never defers authoritative
  behavior to client code, a reference implementation, a report, an external
  or LaTeX specification, or a future companion proposal. Pointers to those
  are informative; the normative text is here.
- Every constant, type, function, message, opcode, request type, precompile
  address and selector used in the text is either defined in this EIP or
  attributed to the EIP or specification that defines it, at first use.
- An instruction is named with mnemonic and number together at least once,
  as in `REVERT (0xfd)`.
- Every type is representable: SSZ has no `uint40`; a Solidity `uint64` with
  a 40-bit bound needs the bound stated; byte layouts give offsets and sizes.
- Every number is right. Opcode numbers, gas costs, constants and hashes are
  copied from the merged EIP or specification they come from, not from
  memory. Worked examples recompute. The reviewer recomputes hashes, gas
  tables, byte encodings and curve constants, and flags any mismatch.
- No collisions. A new opcode, message code, request-type byte, transaction
  type, code prefix or precompile address is checked against every merged
  EIP in `EIPS/` and the open proposals you know of. State what you checked.
- Edge cases are decided, not left open: empty inputs, zero values, the
  point at infinity, reorgs, activation-order interactions with other EIPs.
- A dependency on another EIP uses that EIP's actual names and semantics.
  Before citing EIP-N for a definition, open `EIPS/eip-N.md` on the current
  `master` and confirm it is there. Proposals that attribute a helper,
  profile, field or request type to an EIP that does not contain it are
  flagged; this is the most common substantive flag.

## 6. Other proposals: what may be cited, required and mentioned

- **Only merged EIPs exist.** The text may link and require an EIP only if
  `EIPS/eip-N.md` is on `master`. An unmerged proposal cannot be linked, and
  CI rejects any attempt. A proposal that cannot be written without one is
  blocked by that PR: say so in the PR description, expect the `e-blocked`
  label, and wait. Do not describe the unmerged proposal in prose as a
  workaround.
- **A merged Draft is a valid dependency.** Its status does not matter for
  linking or for `requires`. While the dependency is itself a Draft, treat its
  content as a placeholder that may change, and expect to update your text
  when it does.
- **Never state another proposal's status.** Not "draft EIP-N", not "pending",
  not "included in the next fork", not "proposed". Write `EIP-N` and, if the
  relationship is a dependency, list it in `requires`. The only exception is
  a Meta EIP whose subject is that status.
- **Write as if already Final.** No future-tense process language ("this PR
  will"), no references to the PR's own state, no "once merged". The text
  describes the protocol, not the proposal's journey.
- **Ownership.** When two proposals touch the same behavior, one of them
  owns the normative definition and the other requires it. If that is
  unclear, decide it before asking for review; the reviewer asks otherwise.
- **No circular requires.** Watch especially for fork meta EIPs and for pairs
  of proposals that reference each other's activation constants.

## 7. Prose

- Expand every abbreviation at first use in the body, even common ones:
  execution layer (EL), consensus layer (CL), inclusion list (IL),
  Simple Serialize (SSZ), externally owned account (EOA), account abstraction
  (AA), Kate-Zaverucha-Goldberg (KZG), and so on. The preamble does not count
  as first use.
- Write `EIP-N` and `ERC-N` with the hyphen, everywhere. No article before a
  bare identifier: `ERC-20`, not `an ERC-20`; `an ERC-20 token` is fine.
- Titles and headings in Title Case without trailing punctuation;
  descriptions in sentence case; initialisms in uppercase.
- Use one spelling and one casing for each defined term throughout
  ("decoupled consensus" is not also "Decoupled Consensus").
- Backticks only for code, identifiers, opcodes, constants and literal values.
- `on-chain` and `off-chain` before a noun; `on chain` and `off chain` after.
  `Ethereum`, not `the Ethereum`. Reserved domains such as `example.com`, not
  real services. No product names unless the specification needs them.
- No section that consists only of a bulleted list; add a lead-in sentence.
  Avoid single-sentence sections.
- Leave a blank line after a list before the next paragraph. A sentence glued
  to the last bullet renders as part of that bullet.
- No LaTeX. `\(2^{24}\)` and `$x$` render literally. Write `2**24` or
  `2^24` in a code span.
- Code fences for formulas, encodings and pseudocode. Tables for parameters.
- Define before use. A term, constant or rule is introduced before the first
  place that relies on it, so a reader meets nothing unexplained on the first
  pass. Prefer back-references. Use a forward reference only when reordering
  is impossible, and then make it explicit, for example
  `see [Recovery](#recovery) below`; an unmarked forward dependency is flagged.
- Say each thing once, in the section where it belongs. Repetition between
  Abstract, Specification and Rationale invites the two copies to drift.

## 8. Links and references

The link checker and `eipw` reject anything not on this list:

- Other proposals: `[EIP-N](./eip-N.md)` and `[ERC-N](./eip-N.md)`, relative,
  never an absolute URL to eips.ethereum.org or GitHub, and only for files
  that exist on `master`.
- Assets of this proposal: `../assets/eip-X/<file>`.
- RFCs: `https://www.rfc-editor.org/rfc/rfcNNNN` (RFCs only, no drafts).
- Commit-pinned permalinks with a 40-character hash into
  `ethereum/consensus-specs`, `ethereum/execution-specs`, `ethereum/devp2p`,
  `ethereum/portal-network-specs`, `ethereum/sys-asm`, `ethereum/yellowpaper`,
  `bitcoin/bips`, `ChainAgnostic/CAIPs`. Branch links, tag links and `/pull/`
  links are rejected even into these repositories.
- W3C technical reports with a date, WHATWG commit snapshots, Unicode
  technical standards by version, DOIs via a `csl-json` block as EIP-1
  describes.

Not accepted, whatever the reason: ethresear.ch, hackmd, blogs, papers on
arXiv or eprint, documentation sites, other GitHub repositories including
`ethereum/EIPs` itself and `ethereum/ERCs`, open pull requests, Etherscan.
`ethereum/execution-apis` is permitted by EIP-1 but is missing from the
current `eipw` allowlist; name the method and PR in text until that is fixed.

For material that lives somewhere not accepted, in order of preference:
summarize the relevant content in the EIP; copy license-compatible material
into `assets/eip-X/` and link that; name the source in text without a link
("the partial-messages extension in `libp2p/specs`, file
`pubsub/gossipsub/partial-messages.md` at commit `6b6203e`"); or follow the
[EIP-5757](./EIPS/eip-5757.md) process to get the resource allowed.

A permalink must point at a path that exists at that commit, and link text
must point at the intended section, not a broad anchor. The reviewer fetches
it.

## 9. Assets

- Everything under `assets/eip-X/`. Images, fixtures, CSVs, source files.
- Source files carry `// SPDX-License-Identifier: CC0-1.0` (or the comment
  syntax of the language). `MIT`, `Apache-2.0`, `GPL`, `LGPL` or any other
  identifier conflicts with the CC0 waiver in the Copyright section and is
  flagged. Patches that introduce files with another project's license header
  are flagged. Vendored compiled output of code under a copyleft license is
  flagged for the editor to decide.
- Scripts reference files that exist at the paths given. Fixtures match the
  counts and shapes the Test Cases section describes. CSV numbers match the
  tables in the text row for row.
- No external repository is required to use the assets; a link to your own
  GitHub project is rejected.

## 10. CI

Every job must be green before the PR is ready, with the one exception of the
Walidator filename check while the number is still `X`. What each job checks:

| Job | What it enforces | Typical failure |
|---|---|---|
| EIP Walidator (`eipw`) | preamble fields, order and formats; section order; link allowlist; `EIP-N` form; `requires` status flow | a disallowed link; an empty `discussions-to`; a link to an EIP not on `master` |
| HTMLProofer | every internal link and anchor resolves on the rendered site | linking an EIP that is not yet on your branch; a wrong `#anchor` |
| Link Check | external URLs respond | a dead or moved URL |
| Markdown Linter | heading levels, list style, fenced blocks | a level-four heading under level two; mixed `-` and `*` bullets |
| CodeSpell | spelling | fix it or add a term to `config/.codespell-whitelist` only if it is a real word |

Run them locally before pushing:

```
eipw --config ./config/eipw.toml EIPS/eip-X.md
markdownlint-cli2 --config config/.markdownlint.yaml EIPS/eip-X.md
codespell --ignore-words config/.codespell-whitelist EIPS/eip-X.md
```

If CI fails because an EIP you link was merged after your branch was cut,
merge `master` into your branch. Read the failing job's log; the reviewer
will, and will quote the exact error and line back to you.

## 11. Responding to a review

- Apply suggestion blocks exactly. A suggestion replaces the whole line; check
  the result does not contain both the old and the new sentence.
- Reply on every thread, even with "done" or "disagree because ...". A
  reasoned disagreement is fine; silence is not, and the editor's re-review
  carries every unanswered item forward.
- Push the fixes, then say in one PR comment which commits address which
  threads. Do not resolve threads yourself.
- Do not rewrite the proposal in the same push that applies editorial fixes
  without saying so. A re-review is a diff against the commit the editor
  reviewed; a silent rewrite turns it into a first review again.
- Substantive design debate belongs on the magicians topic, not in PR
  threads. The editor will redirect it there.

## 12. Self-check before asking for an editor

Run through this list; each line is a flag the review would otherwise raise.

- [ ] One file under `EIPS/`, optional assets under `assets/`, nothing else;
      or, for a status change, exactly the status line.
- [ ] Number is `X` until assigned, then applied everywhere in one commit.
- [ ] `discussions-to` is a magicians topic.
- [ ] `title` ≤ 44 chars, Title Case, no number, no "standard";
      `description` one sentence ≤ 140 chars, no colon, no "standard",
      expands on the title.
- [ ] `author` has a handle or email; `category` only for Standards Track;
      `last-call-deadline` and `withdrawal-reason` only when the status says so.
- [ ] `requires` equals the set of merged EIPs the Specification depends on,
      and each is linked in the text.
- [ ] Sections present and in the enforced order; Security Considerations
      specific to this proposal; Copyright line exact.
- [ ] RFC boilerplate present, both RFCs linked, keywords only inside
      Specification; Specification rules use keywords, not "may" or "should".
- [ ] Specification defines behavior itself; every identifier defined or
      attributed; opcodes named with number; numbers verified; no collisions.
- [ ] Every EIP cited for a definition actually contains it on `master`;
      no unmerged proposal mentioned; no proposal's status stated; written as
      if Final.
- [ ] Abbreviations expanded; `EIP-N` form; consistent casing; no bullet-only
      sections; blank line after lists; no LaTeX; no template comments.
- [ ] Readable in one pass: everything defined before use, forward references
      explicit and rare, nothing said twice, nothing that needs the PR or the
      discussion thread to understand.
- [ ] Only permitted links; permalinks have a 40-hex hash and the path exists.
- [ ] Assets CC0, paths correct, fixtures and CSVs match the text.
- [ ] CI green apart from the placeholder filename; PR not a draft; PR
      description current.

## 13. For agents working on behalf of an author

- Read EIP-1 and this file first, then the proposal, then every EIP it cites,
  from `origin/master` in this clone, not from memory.
- Run the three local checks in section 10 and fix what they report before
  anything else.
- Verify, do not assume: fetch the permalinked file, recompute the example,
  grep the merged EIP for the name you are about to cite.
- Do not post to GitHub, open the PR, or reply to reviewers unless the author
  asked you to and you have shown them the text. Never submit, approve or
  dismiss a review.
- When you cannot verify a claim, say so to the author instead of leaving it
  in the text. Unverifiable figures in Motivation are tolerated in a Draft;
  unverifiable facts in Specification are not.
