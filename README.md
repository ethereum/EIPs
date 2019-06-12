# SIPs [![Discord](https://img.shields.io/discord/413890591840272394.svg?color=768AD4&label=discord&logo=https%3A%2F%2Fdiscordapp.com%2Fassets%2F8c9701b98ad4372b58f13fd9f65f966e.svg)](https://discordapp.com/channels/413890591840272394/) [![Twitter Follow](https://img.shields.io/twitter/follow/synthetix_io.svg?label=synthetix_io&style=social)](https://twitter.com/synthetix_io)
Synthetix Improvement Proposals (SIPs) describe standards for the Synthetix platform, including core protocol specifications, client APIs, and contract standards.

WIP: A browsable version of all current and draft SIPs can be found on [the official SIP site](https://sips.synthetix.io/).

# Contributing

 1. Review [SIP-1](SIPS/sip-1.md).
 2. Fork the repository by clicking "Fork" in the top right.
 3. Add your SIP to your fork of the repository. There is a [template SIP here](sip-X.md).
 4. Submit a Pull Request to Synthetix's [SIPs repository](https://github.com/synthetixio/SIPs).

Your first PR should be a first draft of the final SIP. It must meet the formatting criteria enforced by the build (largely, correct metadata in the header). An editor will manually review the first PR for a new SIP and assign it a number before merging it. Make sure you include a `discussions-to` header with the URL to a discussion forum or open GitHub issue where people can discuss the SIP as a whole.

If your SIP requires images, the image files should be included in a subdirectory of the `assets` folder for that SIP as follow: `assets/sip-X` (for sip **X**). When linking to an image in the SIP, use relative links such as `../assets/sip-X/image.png`.

When you believe your SIP is mature and ready to progress past the WIP phase, you should ask to have your issue added to the next governance call where it can be discussed for inclusion in a future platform upgrade. If the community agrees to include it, the SIP editors will update the state of your SIP to 'Approved'.


# SIP Statuses

* **WIP** - a SIP that is still being developed.
* **Proposed** - a SIP that is ready to be reviewed in a governance call.
* **Approved** - a SIP that has been accepted for implementation by the Synthetix community.
* **Implemented** - a SIP that has been released to mainnet.
