# Ethereum Improvement Proposals (EIPs)

> **_ATTENTION_**: The EIPs repository has recently [undergone](https://github.com/ethereum/EIPs/pull/7206) a separation of ERCs and EIPs. ERCs are now accessible at [https://github.com/ethereum/ercs](https://github.com/ethereum/ercs). All new ERCs and updates to existing ones must be directed at this new repository. The editors apologize for this inconvenience.

| Content | Canonical repository | Canonical published URL | Where changes go |
| --- | --- | --- | --- |
| EIPs | `ethereum/EIPs` | `https://eips.ethereum.org/EIPS/eip-<n>` | `ethereum/EIPs` |
| ERCs | `ethereum/ERCs` | ERC publication site, if applicable | `ethereum/ERCs` |
| Historical ERC material | This repository only where explicitly documented as archival or redirected | The documented archival or redirect policy | No new edits here |

The goal of the EIP project is to standardize and provide high-quality documentation for Ethereum itself and conventions built upon it. This repository tracks past and ongoing improvements to Ethereum in the form of Ethereum Improvement Proposals (EIPs). [EIP-1](https://eips.ethereum.org/EIPS/eip-1) governs how EIPs are published.

The [status page](https://eips.ethereum.org/) tracks and lists EIPs, which can be divided into the following categories:

- [Core EIPs](https://eips.ethereum.org/core) are improvements to the Ethereum consensus protocol.
- [Networking EIPs](https://eips.ethereum.org/networking) specify the peer-to-peer networking layer of Ethereum.
- [Interface EIPs](https://eips.ethereum.org/interface) standardize interfaces to Ethereum, which determine how users and applications interact with the blockchain.
- ERC standards are maintained in the [ERCs repository](https://github.com/ethereum/ERCs). This repository may retain historical references or publication artifacts where documented, but new ERC proposals and amendments belong in `ethereum/ERCs`.
- [Meta EIPs](https://eips.ethereum.org/meta) are miscellaneous improvements that nonetheless require some sort of consensus.
- [Informational EIPs](https://eips.ethereum.org/informational) are non-standard improvements that do not require any form of consensus.

**Before you write an EIP, ideas MUST be thoroughly discussed on [Ethereum Magicians](https://ethereum-magicians.org/) or [Ethereum Research](https://ethresear.ch/t/read-this-before-posting/8). Once consensus is reached, thoroughly read and review [EIP-1](https://eips.ethereum.org/EIPS/eip-1), which describes the EIP process.**

Please note that this repository is for documenting standards and not for help implementing them. These types of inquiries should be directed to the [Ethereum Stack Exchange](https://ethereum.stackexchange.com). For specific questions and concerns regarding EIPs, it's best to comment on the relevant discussion thread of the EIP denoted by the `discussions-to` tag in the EIP's preamble.

If you would like to become an EIP Editor, please read [EIP-5069](./EIPS/eip-5069.md).

## Preferred Citation Format

The canonical URL for an EIP that has achieved draft status at any point is at <https://eips.ethereum.org/>. For example, the canonical URL for EIP-1 is <https://eips.ethereum.org/EIPS/eip-1>.

Consider any document not published at <https://eips.ethereum.org/> as a working paper. Additionally, consider published EIPs with a status of "draft", "review", or "last call" to be incomplete drafts, and note that their specification is likely to be subject to change.

## Canonicality and versioning

- The canonical representation of an EIP is the version published at `https://eips.ethereum.org/EIPS/eip-<number>`.
- Git commits and pull requests are working history, not authoritative proposal versions.
- The EIP status, preamble, and published content together determine the proposal's current normative meaning.
- Implementers targeting a particular EIP revision should record the canonical URL, commit SHA, and retrieval date.
- Final EIPs change only for errata and non-normative clarifications, consistent with [EIP-1](https://eips.ethereum.org/EIPS/eip-1).

## Where to start

Do you want a new application-layer standard? Start discussion, then submit an ERC to `ethereum/ERCs`.

Do you propose a consensus, execution, networking, or interface change? Start discussion, then submit an EIP here.

Do you need implementation help or debugging? Use [Ethereum Stack Exchange](https://ethereum.stackexchange.com/) or the proposal's `discussions-to` forum.

Do you want to amend an existing proposal? First identify its repository, status, and `discussions-to` link.

## Validation and Automerging

Automated checks verify formatting, repository policy, and mechanically testable requirements. See [GOVERNANCE.md](./GOVERNANCE.md) for the boundary between automation and human technical judgment.

All pull requests in this repository must pass automated checks before they can be automatically merged:

- [eip-review-bot](https://github.com/ethereum/eip-review-bot/) determines when PRs can be automatically merged [^1]
- EIP-1 rules are enforced using [`eipw`](https://github.com/ethereum/eipw)[^2]
- HTML formatting and broken links are enforced using [HTMLProofer](https://github.com/gjtorikian/html-proofer)[^2]
- Spelling is enforced with [CodeSpell](https://github.com/codespell-project/codespell)[^2]
  - False positives sometimes occur. When this happens, please submit a PR editing [.codespell-whitelist](https://github.com/ethereum/EIPs/blob/master/config/.codespell-whitelist) and **ONLY** .codespell-whitelist
- Markdown best practices are checked using [markdownlint](https://github.com/DavidAnson/markdownlint)[^2]

### Workflow validation

Workflow validation is reproducible on Linux (AMD64) without adding tooling to the repository:

```sh
./tests/workflows/actionlint.sh
./tests/workflows/run.sh
git diff --check
```

`actionlint.sh` downloads actionlint v1.7.7 from its GitHub release into a temporary directory, verifies the published SHA-256 checksum for the Linux AMD64 archive, and runs actionlint across `.github/workflows`. `run.sh` executes 10 focused artifact-handoff assertions covering permissions, missing-artifact behavior, unexpected download failures, downstream step gating, and visible Auto Review Bot failures. The workflow security audit also checks immutable third-party action pins, declared token permissions, disabled checkout credential persistence, and direct untrusted-input interpolation into shell commands. These checks run continuously on pull requests and pushes in [Workflow Security](./.github/workflows/workflow-security.yml).

### Validation compatibility contract

CI is expected to be reproducible from a clean Linux AMD64 environment using the documented commands. Validation tooling, configuration, and expected diagnostics are versioned with this repository. A pull request must not depend on unpublished credentials, mutable external state, or undocumented maintainer-only tooling to pass validation.

The repository-neutral rules and report schema are documented in [VALIDATION_SPEC.md](./VALIDATION_SPEC.md), and the public vector suite is in [tests/validation/vectors.json](./tests/validation/vectors.json).

See [GOVERNANCE.md](./GOVERNANCE.md) for automation limits and rule ownership, [MIGRATION.md](./MIGRATION.md) for the EIPs/ERCs boundary, and [SECURITY.md](./SECURITY.md) for security reporting and continuity.

Run the offline vector contract independently of GitHub Actions:

```sh
tests/validation/run.sh
```

The suite covers five published cases: a valid EIP, an invalid EIP with an expected diagnostic, an ERC boundary case, a missing cross-repository source, and conflicting shared infrastructure metadata. The reference verifier writes a JSON report; a failed proposal produces a non-zero exit code and a report rather than an opaque CI-only result.

The longer-term shared-workflow, behavioral-fixture, and provenance roadmap is documented in [Workflow Reliability and Supply-Chain Plan](./WORKFLOW_RELIABILITY_PLAN.md).

The current GitHub Actions audit and prioritized security migration plan is documented in [GitHub Actions Security Improvement Plan](./SECURITY_IMPROVEMENT_PLAN.md).

The executable rollout procedure is documented in [GitHub Actions Security Migration Guide](./SECURITY_MIGRATION_GUIDE.md).

[^1]: https://github.com/ethereum/EIPs/blob/master/.github/workflows/auto-review-bot.yml
[^2]: https://github.com/ethereum/EIPs/blob/master/.github/workflows/ci.yml

It is possible to run the reference EIP validator locally without GitHub Actions or privileged tokens:

Make sure to add cargo's `bin` directory to your environment (typically `$HOME/.cargo/bin` in your `PATH` environment variable)

```sh
cargo install eipw --version 0.11.0 --locked
./scripts/verify-eip --commit "$(git rev-parse HEAD)" --source EIPS/eip-1.md --report validation.json
```

The verifier emits a deterministic JSON report containing the commit, validator version, rule-file digest, source list, result, exit code, and diagnostics. See [SECURITY_MIGRATION_GUIDE.md](./SECURITY_MIGRATION_GUIDE.md) for continuity and recovery procedures.

The local reference verifier uses public `eipw` v0.11.0. The current CI `eipw-action` additionally applies the repository TOML options through its action wrapper; migrating CI to `scripts/verify-eip` is required before the local report is the complete byte-for-byte CI equivalent. Until then, both the validator version and this parity boundary are published in [VALIDATION_SPEC.md](./VALIDATION_SPEC.md).

## Before requesting review

- [ ] The proposal has a public `discussions-to` link.
- [ ] The specification is precise enough for an independent implementation.
- [ ] Rationale explains key design decisions and rejected alternatives.
- [ ] Backwards-compatibility effects are documented.
- [ ] Security considerations include relevant abuse, denial-of-service, consensus, privacy, and economic risks.
- [ ] Test cases or test vectors are included where behavior can be tested.
- [ ] Cross-client or cross-implementation interoperability implications are addressed.

## Build the status page locally

### Install prerequisites

1. Open Terminal.

2. Check whether you have Ruby 3.1.4 installed. Later [versions are not supported](https://stackoverflow.com/questions/14351272/undefined-method-exists-for-fileclass-nomethoderror).

   ```sh
   ruby --version
   ```

3. If you don't have Ruby installed, install Ruby 3.1.4.

4. Install Bundler:

   ```sh
   gem install bundler
   ```

5. Install dependencies:

   ```sh
   bundle install
   ```

### Build your local Jekyll site

1. Bundle assets and start the server:

   ```sh
   bundle exec jekyll serve
   ```

2. Preview your local Jekyll site in your web browser at `http://localhost:4000`.

More information on Jekyll and GitHub Pages [here](https://docs.github.com/en/enterprise/2.14/user/articles/setting-up-your-github-pages-site-locally-with-jekyll).
