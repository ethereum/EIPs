# EIPs [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
以太坊改进提案(Ethereum Improvement Proposals, EIPs)描述了以太坊平台的相关标准，包括核心协议规范、客户端APIs和合约的相关标准。

现有的所有EIPs和草案的一个浏览器版本可以查看这里[EIP官方地址](http://eips.ethereum.org/)，中文版本的可以查看[EIP中文版地址](https://posa88.github.io/EIPs-Chinese/)。

# 如何贡献

 1. 阅读[EIP-1](EIPS/eip-1.md)。
 2. 通过点击右上角的"Fork"按钮Fork本代码仓库。
 3. 向你的分支添加你的EIP。这里有一个[EIP模板](eip-X.md)。
 4. 向以太坊代码仓库提交一个Pull Request[EIPs代码仓库](https://github.com/ethereum/EIPs)，中文翻译则向中文代码仓库[中文翻译版EIPs仓库](https://github.com/posa88/EIPs-Chinese)提交。

你的第一个PR应当是EIP定稿的一个草稿。 It must meet the formatting criteria enforced by the build (largely, correct metadata in the header). An editor will manually review the first PR for a new EIP and assign it a number before merging it. Make sure you include a `discussions-to` header with the URL to a discussion forum or open GitHub issue where people can discuss the EIP as a whole.

If your EIP requires images, the image files should be included in a subdirectory of the `assets` folder for that EIP as follow: `assets/eip-X` (for eip **X**). When linking to an image in the EIP, use relative links such as `../assets/eip-X/image.png`.

Once your first PR is merged, we have a bot that helps out by automatically merging PRs to draft EIPs. For this to work, it has to be able to tell that you own the draft being edited. Make sure that the 'author' line of your EIP contains either your Github username or your email address inside <triangular brackets>. If you use your email address, that address must be the one publicly shown on [your GitHub profile](https://github.com/settings/profile).

When you believe your EIP is mature and ready to progress past the draft phase, you should do one of two things:

 - **For a Standards Track EIP of type Core**, ask to have your issue added to [the agenda of an upcoming All Core Devs meeting](https://github.com/ethereum/pm/issues), where it can be discussed for inclusion in a future hard fork. If implementers agree to include it, the EIP editors will update the state of your EIP to 'Accepted'.
 - **For all other EIPs**, open a PR changing the state of your EIP to 'Final'. An editor will review your draft and ask if anyone objects to its being finalised. If the editor decides there is no rough consensus - for instance, because contributors point out significant issues with the EIP - they may close the PR and request that you fix the issues in the draft before trying again.

# EIP Status Terms
* **Draft** - an EIP that is undergoing rapid iteration and changes
* **Last Call** - an EIP that is done with its initial iteration and ready for review by a wide audience
* **Accepted** - a core EIP that has been in Last Call for at least 2 weeks and any technical changes that were requested have been addressed by the author
* **Final (non-Core)** - an EIP that has been in Last Call for at least 2 weeks and any technical changes that were requested have been addressed by the author.
* **Final (Core)** - an EIP that the Core Devs have decide to implement and release in a future hard fork or has already been released in a hard fork
* **Deferred** - an EIP that is not being considered for immediate adoption. May be reconsidered in the future for a subsequent hard fork.

# Preferred Citation Format

The canonical URL for a EIP that has achieved draft status at any point is at https://eips.ethereum.org/. For example, the canonical URL for ERC-165 is https://eips.ethereum.org/EIPS/eip-165.
