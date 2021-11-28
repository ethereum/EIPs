# Ethereum Improvement Proposals (EIPs)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards. **Browse all current and draft EIPs on [the official EIP site](https://eips.ethereum.org/).**

**Before you initiate a pull request**, please read the [EIP-1](https://eips.ethereum.org/EIPS/eip-1) process document.

Once your first PR is merged, we have a bot that helps out by automatically merging PRs to draft EIPs. For this to work, it has to be able to tell that you own the draft being edited. Make sure that the 'author' line of your EIP contains either your GitHub username or your email address inside \<triangular brackets>. If you use your email address, that address must be the one publicly shown on [your GitHub profile](https://github.com/settings/profile).

## Project Goal

The Ethereum Improvement Proposals repository exists as a place to share concrete proposals with potential users of the proposal and the Ethereum community at large.

## Preferred Citation Format

The canonical URL for a EIP that has achieved draft status at any point is at https://eips.ethereum.org/. For example, the canonical URL for EIP-1 is https://eips.ethereum.org/EIPS/eip-1.

Please consider anything which is not published on https://eips.ethereum.org/ as a working paper.

And please consider anything published at https://eips.ethereum.org/ with a status of "draft" as an incomplete draft.

# Validation

EIPs must pass some validation tests.  The EIP repository ensures this by running tests using [html-proofer](https://rubygems.org/gems/html-proofer) and [eipv](https://github.com/lightclient/eipv).

It is possible to run the EIP validator locally:
```sh
cargo install eipv
eipv <INPUT FILE / DIRECTORY>
```

# Automerger

The EIP repository contains an "auto merge" feature to ease the workload for EIP editors.  If a change is made via a PR to a draft EIP, then the authors of the EIP can GitHub approve the change to have it auto-merged. This is handled by the [EIP-Bot](https://github.com/ethereum/EIP-Bot).

# Local development

## Prerequisites

1. Open Terminal.

2. Check whether you have Ruby 2.1.0 or higher installed:

```sh
$ ruby --version
```

3. If you don't have Ruby installed, install Ruby 2.1.0 or higher.

4. Install Bundler:

```sh
$ gem install bundler
```

5. Install dependencies:

```sh
$ bundle install
```

## Build your local Jekyll site

1. Bundle assets and start the server:

```sh
$ bundle exec jekyll serve
```

2. Preview your local Jekyll site in your web browser at `http://localhost:4000`.

More information on Jekyll and GitHub pages [here](https://help.github.com/en/enterprise/2.14/user/articles/setting-up-your-github-pages-site-locally-with-jekyll).
