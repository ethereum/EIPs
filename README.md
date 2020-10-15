# SIPs [![Discord](https://img.shields.io/discord/413890591840272394.svg?color=768AD4&label=discord&logo=https%3A%2F%2Fdiscordapp.com%2Fassets%2F8c9701b98ad4372b58f13fd9f65f966e.svg)](https://discordapp.com/channels/413890591840272394/) [![Twitter Follow](https://img.shields.io/twitter/follow/synthetix_io.svg?label=synthetix_io&style=social)](https://twitter.com/synthetix_io)

Synthetix Improvement Proposals (SIPs) describe standards for the Synthetix platform, including core protocol specifications, client APIs, and contract standards.

WIP: A browsable version of all current and draft SIPs can be found on [the official SIP site](https://sips.synthetix.io/).

# Contributing

1.  Review [SIP-1](sips/sip-1.md).
2.  Fork the repository by clicking "Fork" in the top right.
3.  Add your SIP to your fork of the repository. There is a [template SIP here](sip-x.md).
4.  Submit a Pull Request to Synthetix's [SIPs repository](https://github.com/synthetixio/SIPs).

Your first PR should be a first draft of the final SIP. It must meet the formatting criteria enforced by the build (largely, correct metadata in the header). An editor will manually review the first PR for a new SIP and assign it a number before merging it. Make sure you include a `discussions-to` header with the URL to a new thread on [research.synthetix.io](https://research.synthetix.io) where people can discuss the SIP as a whole.

If your SIP requires images, the image files should be included in a subdirectory of the `assets` folder for that SIP as follow: `assets/sip-X` (for sip **X**). When linking to an image in the SIP, use relative links such as `../assets/sip-X/image.png`.

When you believe your SIP is mature and ready to progress past the WIP phase, you should ask to have your issue added to the next governance call where it can be discussed for inclusion in a future platform upgrade. If the community agrees to include it, the SIP editors will update the state of your SIP to 'Approved'.

There is a 500 sUSD bounty for proposing a SIP that reaches the 'Implemented' phase.

# SIP Statuses

- **WIP** - a SIP that is still being developed.
- **Proposed** - a SIP that is ready to be reviewed in a governance call.
- **Approved** - a SIP that has been accepted for implementation by the Synthetix community.
- **Implemented** - a SIP that has been released to mainnet.
- **Rejected** - a SIP that has been rejected.

# Validation

SIPs must pass some validation tests. The SIP repository ensures this by running tests using [html-proofer](https://rubygems.org/gems/html-proofer) and [sip_validator](https://rubygems.org/gems/sip_validator).

It is possible to run the SIP validator locally:

```
gem install sip_validator
sip_validator <INPUT_FILES>
```

# Automerger

The SIP repository contains an "auto merge" feature to ease the workload for SIP editors. If a change is made via a PR to a draft SIP, then the authors of the SIP can Github approve the change to have it auto-merged by the [sip-automerger](https://github.com/bakaoh/sip_automerger) bot.
