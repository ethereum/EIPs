# Ethereum Improvement Proposals (EIPs)

**Before you initiate a pull request**, please read the [EIP-1](https://eips.ethereum.org/EIPS/eip-1) process document. Ideas should be thoroughly discussed on [Ethereum Research](https://ethresear.ch/t/read-this-before-posting/8) or [Ethereum Magicians](https://ethereum-magicians.org/) first.

This repository tracks ongoing improvements to Ethereum. It contains:

- The [EIP status page](https://eips.ethereum.org), tracking protocols for Ethereum clients and applications
- The [process document](https://eips.ethereum.org/EIPS/eip-1) that governs how protocols are published here

For help *implementing* an EIP, please visit [Ethereum Stack Exchange](https://ethereum.stackexchange.com).

If you would like to become an EIP Editor, please check [EIP-5069](./EIPS/eip-5069.md).

## Mission

The goal of the EIP project is to document standardized protocols for Ethereum clients and applications and to document them in a high-quality and implementable way.

## Preferred Citation Format

The canonical URL for an EIP that has achieved draft status at any point is at <https://eips.ethereum.org/>. For example, the canonical URL for EIP-1 is <https://eips.ethereum.org/EIPS/eip-1>.

Consider any document not published at <https://eips.ethereum.org/> as a working paper. Additionally, consider published EIPs with a status of "draft", "review", or "last call" to be incomplete drafts, and note that their specification is likely to be subject to change.

## Validation and Automerging

All pull requests in this repository must pass automated checks before they can be automatically merged:

- [EIP-Bot](https://github.com/ethereum/EIP-Bot/) determines when PRs can be automatically merged [^1]
- EIP-1 rules are enforced using [`eipw`](https://github.com/ethereum/eipw)[^2]
- HTML formatting and broken links are enforced using [HTMLProofer](https://github.com/gjtorikian/html-proofer)[^2]
- Spelling is enforced with [CodeSpell](https://github.com/codespell-project/codespell)[^2]
- False positives sometimes occur. When this happens, please submit a PR editing [.codespell-whitelist](https://github.com/ethereum/EIPs/blob/master/config/.codespell-whitelist).
- Markdown best practices are checked using [markdownlint](https://github.com/DavidAnson/markdownlint)[^2]

[^1]: https://github.com/ethereum/EIPs/blob/master/.github/workflows/auto-review-bot.yml
[^2]: https://github.com/ethereum/EIPs/blob/master/.github/workflows/ci.yml

It is possible to run the EIP validator locally:

```sh
cargo install eipv
eipv <INPUT FILE / DIRECTORY>
```

## Build the status page locally

### Install prerequisites

1. Open Terminal.

2. Check whether you have Ruby 2.1.0 or higher installed:

   ```sh
   ruby --version
   ```

3. If you don't have Ruby installed, install Ruby 2.1.0 or higher.

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

2. Preview your local Jekyll site in your web browser at <http://localhost:4000>.

More information on Jekyll and GitHub Pages [here](https://help.github.com/en/enterprise/2.14/user/articles/setting-up-your-github-pages-site-locally-with-jekyll).
