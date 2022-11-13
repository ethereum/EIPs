# Ethereum Improvement Proposals (EIPs)

The goal of the EIP project is to standardize and provide high-quality documentation for Ethereum client and application protocols. This repository tracks ongoing improvements to Ethereum in the form of Ethereum Improvement Proposals (EIPs). [EIP-1](https://eips.ethereum.org/EIPS/eip-1) governs how EIPs are published.

The [EIP status page](https://eips.ethereum.org/) tracks and lists Ethereum client and application protocols:

- [Core EIPs](https://eips.ethereum.org/core) are improvements to the Ethereum execution layer, data layer, or consensus layer. These often requie a fork.
- [Networking EIPs](https://eips.ethereum.org/networking) are improvements to the Networking layer, which determines how the Ethereum peer to peer network functions.
- [Interface EIPs](https://eips.ethereum.org/interface) are improvements to the Communication layer, which determines how conventional applications can interact with applications running on Ethereum.
- [ERCs](https://eips.ethereum.org/erc) are improvements to the Application layer, which determines how applications running on Ethereum can interact with each other. These generally detail one or more application-specific interfaces.
- [Meta EIPs](https://eips.ethereum.org/meta) are miscellaneous improvements that nonetheless require some sort of consensus. 
- [Informational EIPs](https://eips.ethereum.org/informational) are non-standard improvements that do not require any form of consensus.

**Before you write an EIP, ideas MUST be thoroughly discussed on [Ethereum Research](https://ethresear.ch/t/read-this-before-posting/8) or [Ethereum Magicians](https://ethereum-magicians.org/). Once consensus is reached, thouroughly read and review [EIP-1](https://eips.ethereum.org/EIPS/eip-1), which describes the EIP proess.**

This repository is not for help implementing an EIP. For that, please visit the [Ethereum Stack Exchange](https://ethereum.stackexchange.com). This repository is also not for discussing EIPs. If you have a question or comment about a non-final EIP, visit its discussion page and voice your thoughts. If you have a question or comment about a final EIP, please post a new thread on [Ethereum Magicians](https://ethereum-magicians.org/).

## Preferred Citation Format

The canonical URL for an EIP that has achieved draft status at any point is at <https://eips.ethereum.org/>. For example, the canonical URL for EIP-1 is <https://eips.ethereum.org/EIPS/eip-1>.

Please consider anything which is not published on <https://eips.ethereum.org/> as a working paper.

And please consider anything published at <https://eips.ethereum.org/> with a status of "draft" as an incomplete draft.

## Automerger

This repository contains an "auto-merge" feature to ease the workload for EIP editors. Pull requests to any EIP will be auto-merged if the EIP's authors approve the PR on GitHub. This is handled by [EIP-Bot](https://github.com/ethereum/EIP-Bot).

## Validation

Pull requests in this repository must pass automated validation checks:

- HTML formatting, broken links, and EIP front matter/formatting are [checked](https://github.com/ethereum/EIPs/blob/master/.github/workflows/ci.yml) using [html-proofer](https://rubygems.org/gems/html-proofer) and [`eipw`](https://github.com/ethereum/eipw).
- Required pull request reviews are [enforced](https://github.com/ethereum/EIPs/blob/master/.github/workflows/auto-review-bot.yml) using [EIP-Bot](https://github.com/ethereum/EIP-Bot/).

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
