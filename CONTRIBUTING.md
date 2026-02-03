# EIP Contribution Guidelines

This document outlines how authors, contributors, and editors can collaborate effectively in the [Ethereum Improvement Proposals (EIPs)](https://eips.ethereum.org/) repository. 
The goal is to keep contributions consistent, transparent, and easy to review - while respecting the authors’ intent.

## For EIP Authors

> You are listed as an author in the EIP header.

### Do’s

#### Text

* Avoid mentioning specific commercial products.
* Don't use [RFC 2119](https://www.ietf.org/rfc/rfc2119.html) keywords (all-caps SHOULD/MUST/etc.) outside of the specification section.
* Prefer "on-chain" and "off-chain" when appearing before the noun they describe, and "on chain" or "off chain" when appearing after. 
* Do not include punctuation at the end of headings (so no # Example A:).
* Titles should be in title case.
* Descriptions should be in sentence case.
* Do not use articles (the/a/an/etc.) in front of EIP identifiers (so not "an ERC-20"), unless the EIP identifier is used as an adjective/compound noun (so "an ERC-20 token" is fine.)
* Initialisms should be written in uppercase (eg. "NFT" instead of "nft".)
* Only use backticks (\`) for code snippets.
* Avoid single paragraph sentences and sections containing only bulleted lists.
* Put abbreviations after the expanded form (so liquidity provider (LP) and not LP (liquidity provider).)
* Use [example domains](https://en.wikipedia.org/wiki/Example.com) in examples, not real services.
* It's "Ethereum", not "the Ethereum".
* Unless you're writing a fork meta EIP, don't include a fork block number constant.

#### Diagrams

* Prefer SVG, but PNG is acceptable.
* If possible, use [media queries](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Media_queries/Using) (specifically prefers-color-scheme) to support dark mode. If not, provide light-mode compatible images.

#### Other

* **Monitor feedback regularly**: Respond to comments or PRs that relate to your EIP, especially specification clarifications or typo fixes.
* **Acknowledge helpful community edits**: You don’t need to merge every PR yourself, but a short confirmation (“LGTM”) helps editors move things forward.
* **Communicate before major revisions**: If changing motivation, specification, or rationale, explain reasoning in the PR or linked issue (recommended).
* **Keep contact details up to date**: Editors use your listed email or GitHub for coordination; please keep them valid.
* Draft pull requests prevent automatic merges and are effective in gauging agreement among authors.

### Don’ts
TBA.  

## For Contributors (Non-Authors)

> You are contributing to an existing EIP you did not author - to fix typos, formatting, or clarify technical descriptions.

### Do’s

* **Add in PR Description**  
   Explain the purpose and scope -  e.g., “Fixing typos in EIP-1559” or “Updating broken link in EIP-4844.”
* **Make objective, non-semantic edits.**
   Acceptable edits include:
   * Typo, grammar, and style corrections 
   * Markdown and formatting fixes 
   * Broken or outdated link replacements 
   * Small clarifications (e.g., referencing a spec or renaming variables for clarity)
> Note: Non-authors may, and are often encouraged to, submit subjective or substantive pull requests; however, such changes require explicit approval from the EIP authors before they can be merged.
> Once an EIP reaches Final status, pull requests should be limited to objective, non-semantic edits only (for example, corrections to grammar, formatting, or references). The restrictions described above apply exclusively to EIPs in Final status.
> For EIPs that have not yet reached Final, contributors are welcome to open any relevant pull requests. Contributors should expect active review and potential pushback from the EIP authors, as the proposal may still be evolving.
* **Cite authoritative sources.** 
   When clarifying or aligning text, link to:
   * [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf) 
   * [Consensus Specs](https://github.com/ethereum/consensus-specs) 
   * Relevant client implementation notes
* **Work with the authors.** 
   Use `@username` for all listed authors, and if possible, connect with the author when making this PR.
* **Keep PRs focused.** 
   Only one EIP per PR and one topic per change (e.g., typo fix, link fix, or formatting fix - not multiple at once).
* **Use clear PR titles.**  
   Examples:
   * “Fix typo in EIP-1559 rationale section.”  
   * “Update broken link to EIP-1 reference.”  
   * “Clarify \`gasUsed\` variable in EIP-4844 spec”

### Don’ts

* Don’t change semantics, logic, or intent.  
* Don’t move or renumber EIPs.  
* Don’t alter author metadata or statuses without the permission of existing authors.  

## For Editors & Reviewers

> Editors manage review and merging of EIP PRs. Their role is to maintain process integrity and consistency.

### Do’s

* **Check ownership and status.**  
   * Authors, co-authors & champion can request status changes (Draft - Review - Last Call - Final). 
   * Confirm that non-author edits are non-semantic and author-approved if applicable.
* **Enforce structure and format.**  
   * Confirm all required header fields match [EIP-1](https://eips.ethereum.org/EIPS/eip-1).  
   * Validate Markdown rendering, metadata, and links.
* **Require author acknowledgment for community PRs.**  
    * For content edits, ensure the author acknowledges or confirms changes before merging.
    * In case the author is non-responsive (for over 2 weeks) and the change is trivial or approved by 2 editors, the PR can be merged to update an EIP without the author's approval. 
* **Apply clear labels.**
To clarify the merge blocker if needed, add applicable labels.  
* **Communicate clearly.**  
   If unclear, request additional context before rejecting or closing a PR.
* **Maintain clean commit history.**  
   Squash redundant commits and check that links, formatting, and front matter are valid.
* **Handle typo-only PRs pragmatically.**  
   * If a typo or formatting PR is approved by at least one editor and no author response is received within two weeks,  
     it may be merged at the editor’s discretion.  
   * This ensures small maintenance fixes don’t remain blocked indefinitely.

### Don’ts

* Don’t merge substantive changes without author approval.  
* Don’t alter author list, status, or numbering silently.  
* Don’t override the author’s technical intent or interpretation.  

### Thank You

Your contributions help maintain the integrity and accessibility of Ethereum’s open-source governance process.  
Together, we make the protocol and its documentation stronger, clearer, and more collaborative.

## References

* [EIP-1: EIP Purpose and Guidelines](https://eips.ethereum.org/EIPS/eip-1) 
* [EIP-5069: EIP Editor Handbook](https://eips.ethereum.org/EIPS/eip-5069)
 

