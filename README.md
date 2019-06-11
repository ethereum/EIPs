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

Once your first PR is merged, we have a bot that helps out by automatically merging PRs to draft SIPs. For this to work, it has to be able to tell that you own the draft being edited. Make sure that the 'author' line of your SIP contains either your Github username or your email address inside <triangular brackets>. If you use your email address, that address must be the one publicly shown on [your GitHub profile](https://github.com/settings/profile).

When you believe your SIP is mature and ready to progress past the draft phase, you should do one of two things:

 - **For a Standards Track SIP of type Core**, ask to have your issue added to [the agenda of an upcoming All Core Devs meeting](https://github.com/ethereum/pm/issues), where it can be discussed for inclusion in a future hard fork. If implementers agree to include it, the SIP editors will update the state of your SIP to 'Accepted'.
 - **For all other SIPs**, open a PR changing the state of your SIP to 'Final'. An editor will review your draft and ask if anyone objects to its being finalised. If the editor decides there is no rough consensus - for instance, because contributors point out significant issues with the SIP - they may close the PR and request that you fix the issues in the draft before trying again.

# SIP Status Terms

* **Draft** - an SIP that is undergoing rapid iteration and changes.
* **Last Call** - an SIP that is done with its initial iteration and ready for review by a wide audience.
* **Accepted** - a core SIP that has been in Last Call for at least 2 weeks and any technical changes that were requested have been addressed by the author. The process for Core Devs to decide whether to encode an SIP into their clients as part of a hard fork is not part of the SIP process. If such a decision is made, the SIP will move to final.
* **Final (non-Core)** - an SIP that has been in Last Call for at least 2 weeks and any technical changes that were requested have been addressed by the author.
* **Final (Core)** - an SIP that the Core Devs have decided to implement and release in a future hard fork or has already been released in a hard fork. 
* **Deferred** - an SIP that is not being considered for immediate adoption. May be reconsidered in the future for a subsequent hard fork.
