# Ethereum Improvement Proposals (EIPs)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

A browsable version of all current and draft EIPs can be found on [the official EIP site](https://eips.ethereum.org/).

# Contributing

 1. Review [EIP-1](EIPS/eip-1.md).
 2. Fork the repository by clicking "Fork" in the top right.
 3. Add your EIP to your fork of the repository. There is a [template EIP here](eip-template.md).
 4. Submit a Pull Request to Ethereum's [EIPs repository](https://github.com/ethereum/EIPs).

Your first PR should be a first draft of the final EIP. It must meet the formatting criteria enforced by the build (largely, correct metadata in the header). An editor will manually review the first PR for a new EIP and assign it a number before merging it. Make sure you include a `discussions-to` header with the URL to a discussion forum or open GitHub issue where people can discuss the EIP as a whole.

If your EIP requires images, the image files should be included in a subdirectory of the `assets` folder for that EIP as follows: `assets/eip-N` (where **N** is to be replaced with the EIP number). When linking to an image in the EIP, use relative links such as `../assets/eip-1/image.png`.

Once your first PR is merged, we have a bot that helps out by automatically merging PRs to draft EIPs. For this to work, it has to be able to tell that you own the draft being edited. Make sure that the 'author' line of your EIP contains either your Github username or your email address inside <triangular brackets>. If you use your email address, that address must be the one publicly shown on [your GitHub profile](https://github.com/settings/profile).

When you believe your EIP is mature and ready to progress past the draft phase, you should do one of two things:

 - **For a Standards Track EIP of type Core**, ask to have your issue added to [the agenda of an upcoming All Core Devs meeting](https://github.com/ethereum/pm/issues), where it can be discussed for inclusion in a future hard fork. If implementers agree to include it, the EIP editors will update the state of your EIP to 'Accepted'.
 - **For all other EIPs**, open a PR changing the state of your EIP to 'Final'. An editor will review your draft and ask if anyone objects to its being finalised. If the editor decides there is no rough consensus - for instance, because contributors point out significant issues with the EIP - they may close the PR and request that you fix the issues in the draft before trying again.

# EIP Status Terms

* **Draft** - an EIP that is undergoing rapid iteration and changes.
* **Last Call** - an EIP that is done with its initial iteration and ready for review by a wide audience.
* **Accepted** - a core EIP that has been in Last Call for at least 2 weeks and any technical changes that were requested have been addressed by the author. The process for Core Devs to decide whether to encode an EIP into their clients as part of a hard fork is not part of the EIP process. If such a decision is made, the EIP will move to final.
* **Final (non-Core)** - an EIP that has been in Last Call for at least 2 weeks and any technical changes that were requested have been addressed by the author.
* **Final (Core)** - an EIP that the Core Devs have decided to implement and release in a future hard fork or has already been released in a hard fork. 

# Preferred Citation Format

The canonical URL for a EIP that has achieved draft status at any point is at https://eips.ethereum.org/. For example, the canonical URL for EIP-1 is https://eips.ethereum.org/EIPS/eip-1.

# Validation

EIPs must pass some validation tests.  The EIP repository ensures this by running tests using [html-proofer](https://rubygems.org/gems/html-proofer) and [eip_validator](https://rubygems.org/gems/eip_validator).

It is possible to run the EIP validator locally:
```
gem install eip_validator
eip_validator <INPUT_FILES>
```

# Automerger

The EIP repository contains an "auto merge" feature to ease the workload for EIP editors.  If a change is made via a PR to a draft EIP, then the authors of the EIP can Github approve the change to have it auto-merged by the [eip-automerger](https://github.com/eip-automerger/automerger) bot.

# Local development

## Prerequisites

1. Open Terminal.

2. Check whether you have Ruby 2.1.0 or higher installed:

```
$ ruby --version
```

3. If you don't have Ruby installed, install Ruby 2.1.0 or higher.

4. Install Bundler:

```
$ gem install bundler
```

5. Install dependencies:

```
$ bundle install
```

## Build your local Jekyll site

1. Bundle assets and start the server:

```
$ bundle exec jekyll serve
```

2. Preview your local Jekyll site in your web browser at `http://localhost:4000`.

More information on Jekyll and Github pages [here](https://help.github.com/en/enterprise/2.14/user/articles/setting-up-your-github-pages-site-locally-with-jekyll).
