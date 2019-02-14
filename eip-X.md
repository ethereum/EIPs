---
eip: <等待赋值>
title: <EIP标题>
author: <a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s), e.g. (use with the parentheses or triangular brackets): FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
discussions-to: <URL>
status: Draft
type: <Standards Track (Core, Networking, Interface, ERC)  | Informational | Meta>
category (*only required for Standard Track): <Core | Networking | Interface | ERC>
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
requires (*optional): <EIP number(s)>
replaces (*optional): <EIP number(s)>
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
这是创建新EIPs推荐使用的模版。

注意EIP编号会由EIP编辑来赋予。当给你的EIP提交第一次pull request的时候(还没有编号)，请在文件名中使用简短标题，类似`eip-草稿简短标题.md`.

EIP标题需要小于44个字符。

## 简单概要(Simple Summary)
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
“如果你不能简单地描述问题，说明你也没有理解很深” 。给EIP提供一个简单且通熟易懂的解释。

## 摘要(Abstract)
<!--A short (~200 word) description of the technical issue being addressed.-->
一个关于解决的技术问题的简短描述(~200 字)。

## 目的(Motivation)
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
动机对于期望修改以太坊协议的EIPs来说很关键。它需要清楚地解释为什么现有的协议规范不足以解决EIP提到的问题。没有足够的动机的EIP提交可能会直接被拒绝。

## 规范(Specification)
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
技术规范需要描述EIP的所有新特性的语法和语义。规范必须足够详细到能被现有的这些相互竞争或协作的以太坊平台(cpp-ethereum, go-ethereum, parity, ethereumJ, ethereumjs-lib, [以及其它](https://github.com/ethereum/wiki/wiki/Clients)所实现。

## 基本原理(Rationale)
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
基本原理需要具体化规范中的内容，包括描述设计的动机以及具体设计的逻辑。同时也需要描述将被替代的那些我们过去设计的内容和相关工作，比如：某个特性在其它地方是怎么支持的。基本原理还需要展示对其内容已经建立社区共识的证据，以及需要探讨在讨论过程中的重要反对观点和关注点。

## 向后兼容(Backwards Compatibility)
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
所有带来向后不兼容的EIPs都必须包含一个章节来描述这些不兼容以及它们的严重性。而且EIP中必须解释作者关于处理这些不兼容问题的措施。提交EIP但没有足够的向后兼容论述的话很可能会直接被拒绝。

## 测试用例(Test Cases)
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
对影响到共识的EIPs来说，给实现写测试用例是强制的。其它的EIPs可以选择引入可用的测试用例的链接。

## 实现(Implementation)
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
在EIP状态转为"Final"之前，所有的实现都必须完成，但在EIP合并为草案的时候不需要完成实现。尽管在代码实现之前在规范和基本原理上达成共识的意义很大，但当解决讨论API细节的时候，"粗糙的共识和可运行的代码"这个原则仍然有效。

## 版权(Copyright)
版权以及相关权利由此[CC0](https://creativecommons.org/publicdomain/zero/1.0/)声明弃权。