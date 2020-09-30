# Ethereum Improvement Proposals (EIPs)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

**Before you initiate a pull request**, please read the [EIP-1](https://eips.ethereum.org/EIPS/eip-1) process document. Ideas should be thoroughly discussed prior to opening a pull request, such as on the [Ethereum Magicians forums](https://ethereum-magicians.org) or in a GitHub issue in this repository.

This repository tracks the ongoing status of EIPs. It contains:

- [Draft](https://eips.ethereum.org/all#draft) proposals which intend to complete the EIP review process.
- [Last Call](https://eips.ethereum.org/all#last-call) for proposals that may become final (see also [RSS feed](https://eips.ethereum.org/last-call.xml)).
- [Accepted](https://eips.ethereum.org/all#accepted) proposals which are awaiting implementation or deployment by Ethereum client developers.
- [Final](https://eips.ethereum.org/all#final) and [Active](https://eips.ethereum.org/all#active) proposals that are recorded.
- The [EIP process](./EIPS/eip-1.md#eip-work-flow) that governs the EIP repository.

Achieving "Final" status in this repository only represents that a proposal has been reviewed for technical accuracy. It is solely the responsibility of the reader to decide whether a proposal will be useful to them.

Browse all current and draft EIPs on [the official EIP site](https://eips.ethereum.org/).

Once your first PR is merged, we have a bot that helps out by automatically merging PRs to draft EIPs. For this to work, it has to be able to tell that you own the draft being edited. Make sure that the 'author' line of your EIP contains either your GitHub username or your email address inside <triangular brackets>. If you use your email address, that address must be the one publicly shown on [your GitHub profile](https://github.com/settings/profile).

## Project Goal

The Ethereum Improvement Proposals repository exists as a place to share concrete proposals with potential users of the proposal and the Ethereum community at large.

## Preferred Citation Format

The canonical URL for a EIP that has achieved draft status at any point is at https://eips.ethereum.org/. For example, the canonical URL for EIP-1 is https://eips.ethereum.org/EIPS/eip-1.

# Validation

EIPs must pass some validation tests.  The EIP repository ensures this by running tests using [html-proofer](https://rubygems.org/gems/html-proofer) and [eip_validator](https://rubygems.org/gems/eip_validator).

It is possible to run the EIP validator locally:
```sh
gem install eip_validator
eip_validator <INPUT_FILES>
```

# Automerger

The EIP repository contains an "auto merge" feature to ease the workload for EIP editors.  If a change is made via a PR to a draft EIP, then the authors of the EIP can GitHub approve the change to have it auto-merged by the [eip-automerger](https://github.com/eip-automerger/automerger) bot.

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
