---
eip: 1
title: EIP 宗旨和指南
status: Active
type: Meta
author: Martin Becze <mb@ethereum.org>, Hudson Jameson <hudson@ethereum.org>, and others
        https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md
created: 2015-10-27, 2017-02-01
---

## 什么是EIP?

EIP是以太坊改进提案(Ethereum Improvement Proposal)的缩写。一个EIP是一个提供信息给以太坊社区的设计文档，或者是描述了关于以太坊或其相关程序或环境的新特性。EIP必须能提供某个特性的简明技术规范及其基本原理。 EIP作者有责任在以太坊社区中建立该EIP的共识以及记录相关异议。

## EIP基本原理

我们旨在让EIP成为提议新特性、收集社区对issue的技术投入，以及对以太坊中的设计决策的文档化的主要方式。由于EIPs以文本文件形式在版本仓库中进行管理，它们的校订历史便很自然地成为了特性提案的历史记录。

对于以太坊开发人员来说，EIPs是一个追踪他们的开发进度的便捷方式。理论上每一个实现的维护者都可以将他们的实现整理成EIPs。这将给用户一个方便地理解对应实现或库的通道。

## EIP类型

总的来说有三种EIP:

- **标准路径(Standard Track)EIP** 描述会影响以太坊大部分甚至全部实现的修改，比如对网络协议的修改、区块或交易有效性规则的修改、应用程序标准/约定的提案，或对以太坊网络中的应用的互联互通有影响的任何修改或增项。这些标准路径EIPs可以归类到以下的几个类别。标准路径EIPs包含了三个部分：设计文档，实现和对[formal specification] (正式的规范说明书)的更新。
  - **核心(core)** - 需要一次分叉来实现的改进 (比如 [EIP5], [EIP101])，同时包括一些跟[“core dev” discussions](https://github.com/ethereum/pm)"讨论相关但不涉及共识层面的修改 (例如, 在<a href="EIPS/eip-86">EIP86</a>第2、3和第4条中关于矿工/节点 策略的修改)。
  - **网络(Networking)** - 包括了关于[devp2p] ([EIP8])和[Light Ethereum Subprotocol] (以太坊轻节点子协议)的改进，以及关于[whisper]和[swarm]的网络协议规范的改进。
  - **接口(interface)** - 包括了关于客户端[API/RPC]的规范和标准的改进，以及关于特定语言级别的标准比如方法名 ([EIP59], [EIP6])和[contract ABIs]的改进。[interfaces repo] (接口仓库)和相关讨论中的"接口"标签应该在EIP被提交到EIPs仓库之前被打上。
  - **以太坊征求意见稿(ERC,Ethereum Request for Comments)** - 应用级别的标准和约定，包括合约标准比如代币标准([ERC20])、命名注册([ERC26], [ERC137])、URI方案 ([ERC67])、库/包的格式 ([EIP82])和钱包格式([EIP75], [EIP85])。
- **信息(Informational)EIP** 关于以太坊设计问题的描述，或者提供给以太坊社区的通用指南或信息，但不会包含新的特性。信息类EIPs不一定是以太坊社区的共识或者推荐，因此用户和开发人员可以自由选择是否遵循这些信息类EIPs。
- **元(Meta)EIP** 描述关于以太坊的一个相关过程(process)或者提议某个程序的修改(或事件)的提案。过程(Process)EIPs和Standards Track EIPs类似，不同的是适用于非以太坊协议相关部分。它们可能提议一项非提交到以太坊代码库的实现，且通常需要达成社区共识；与信息EIPs不同，它们的级别高于推荐, 因此用户一般不能忽略它们。例子包括：规程、指南、对决议流程的修改以及对以太坊开发工具和环境的修改。所有的元EIPs也都是Process EIPs。

我们建议一个EIP通常只包含一个关键提案或想法。让EIP专注单一问题，有利于该EIP成功。对单一客户端的修改不需要用EIP来定义；而对许多客户端的修改，或者定义一个被许多程序使用的标准，则需要。

EIP必须满足一些最小准则。它们必须能简明且完整地描述提案修改的内容。提议的增强项必须有确实的提高。提议的实现方案，如果可实施，也必须是牢靠且不会过度增加协议的复杂性的。

## EIP工作流程

流程中的参与方包括你、*EIP作者*、[*EIP编辑*](#eip-editors)，以及[*以太坊核心开发者*](https://github.com/ethereum/pm).

:warning: 在你开始前，请审查你的想法，这将节省你的时间。询问以太坊社区以了解该想法是否是第一次被提出，以免你的提案因为过去的一些研究被拒绝而浪费时间(在网上搜索有时候不一定能搞定)。同时这也能够帮助确认你的想法是否能被整个社区认可，而不是作者自己。一个在作者看来不错的主意不代表它在大多数人和大多数以太坊涉及的领域也很好。衡量你的EIP是否被认可的合适公共论坛有[the Ethereum subreddit]、[the Issues section of this repository]和[one of the Ethereum Gitter chat rooms]。特别说明的是，[the Issues section of this repository] 是一个非常好的和社区讨论你的EIP以及开始创建关于你的EIP的正式描述的地方。

你作为EIP的领导者需要根据以下的风格和格式，在合适的讨论组中引导讨论，并在社区中建立关于该想法的共识。下面是一个成功的EIP会经过的推进阶段：

```
[ WIP ] -> [ DRAFT ] -> [ LAST CALL ] -> [ ACCEPTED ] -> [ FINAL ]
```

每次状态变化都需要由EIP作者提交请求并由EIP编辑进行审查。请使用PR(pull request)来更新状态。请加入一个链接指向大家讨论你的EIP的地方。EIP编辑会根据下面的条件处理这些PR。

* **活跃(Active)** -- 一些信息类EIPs和过程类EIPs可能也会有一个"活跃"状态，只要它们是需要持续进行的。比如：EIP 1(当前这个EIP)。
* **进行中(Work in progress,WIP)** -- 一旦EIP领导者向以太坊社区询问了关于某个想法是否能提供支持后，他就会写一个EIP草稿并提交一次[pull request] (PR)。在对人们学习该EIP有帮助的情况下，请考虑在这个阶段加入EIP的实现。
  * :arrow_right: Draft -- 如果可通过，EIP编辑会给EIP赋予一个编号 (通常是EIP对应的issue或PR的编号)，然后合并你的PR。EIP编辑不会无理由地拒绝一个EIP。
  * :x: Draft -- 拒绝进入草稿状态的原因包括：问题不够专注、问题太宽泛、问题和过去有重复、技术上不靠谱、没有合理的动机，或者需要向后兼容，又或者和[以太坊哲学](https://github.com/ethereum/wiki/wiki/White-Paper#philosophy)不一致。
* **草案(Draft)** -- 一旦第一份草稿被合并后，你就可以在接下来提交PR来修改你的草稿直到你认为该EIP已经成熟并可以进入下个状态了。 一个EIP在Draft状态必须得到实现，才能被考虑进入下一个状态(核心EIPs则可以忽略此要求)。
  * :arrow_right: Last Call -- 如果可通过，EIP编辑会将状态改为Last Call并设置一个最迟审查日期(`review-period-end`)，这通常是14天之后。
  * :x: Last Call -- 如果草案还有内容需要修改，则进入Last Call状态的请求会遭到拒绝。我们希望EIPs只会进入Last Call状态一次，以避免对RSS feed造成不必要的干扰。
* **最后征求意见(Last Call)** -- 这状态的EIP会被列在http://eips.ethereum.org/ 网站上的明显位置(通过RSS [last-call.xml](/last-call.xml) 进行订阅)。
  * :x: -- Last Call状态如果出现内容修改或者较多未知的技术上的冲突将会导致EIP回退到Draft状态。
  * :arrow_right: Accepted (仅核心EIPs) -- 一个成功的核心EIP如果在Last Call状态既没有内容修改也不存在技术上的冲突将会进入Accepted状态。
  * :arrow_right: Final (非核心EIPs) -- 一个成功的非核心EIP如果在Last Call状态既没有内容修改也不存在技术上的冲突将会进入Final状态。
* **接受(Accepted，仅对核心EIPs)** -- 这个状态的EIP交由以太坊客户端开发者处理。他们会决定是否将此EIP打包进他们的客户端作为硬分叉的一部分内容，但这不在EIP流程中。
  * :arrow_right: Final -- 在成为Final状态之前，标准路径核心EIPs必须被最少三个可用的以太坊客户端实现。当实现完成并被以太坊社区采用，此EIP的状态就会进入“Final”.
* **定稿(Final)** -- 这个状态的EIP代表最新技术状态。Final状态的EIP需要被更新到正确的分类表中。

其它特殊状态包括：

* **延期(Deferred)** -- 这是核心EIPs被推迟到未来一个硬分叉时进入的状态。
* **拒绝(Rejected)** -- 一个EIP如果基础不成立或者一个核心EIP如果被核心开发团队拒绝并且未来不会被实现时进入的状态。
* **活跃(Active)** -- 类似于Final状态，不同的是此状态代表这个EIP可能会被更新，但不会更改EIP编号。
* **作废(Superseded)** -- 一个之前进入Final状态的EIP但已经技术过时了。另一个EIP会进入Final状态，并引用这个作废的EIP。

## 一个成功的EIP是怎样的？

每一个成功的EIP都需要兼顾以下内容:

- 报文头 - EIP的元数据用RFC 822的风格包含在headers中，包括EIP number、一个简短的描述标题(不超过44个字符)，以及作者信息。查看更多内容 [below](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-header-preamble) 。
- 简单概要 - “如果你不能简单地描述问题，说明你也没有理解很深” 。给EIP提供一个简单且通熟易懂的解释。
- 摘要 - 一个关于解决的技术问题的简短描述(~200 字)。
- 目的 (*可选) - 动机对于期望修改以太坊协议的EIPs来说很关键。它需要清楚地解释为什么现有的协议规范不足以解决EIP提到的问题。没有足够的动机的EIP提交可能会直接被拒绝。
- 规范 - 技术规范需要描述EIP的所有新特性的语法和语义。规范必须足够详细到能被现有的这些相互竞争或协作的以太坊平台(cpp-ethereum, go-ethereum, parity, ethereumJ, ethereumjs-lib, [以及其它](https://github.com/ethereum/wiki/wiki/Clients)所实现。
- 基本原理 - 基本原理需要具体化规范中的内容，包括描述设计的动机以及具体设计的逻辑。同时也需要描述将被替代的那些我们过去设计的内容和相关工作，比如：某个特性在其它地方是怎么支持的。基本原理还需要展示对其内容已经建立社区共识的证据，以及需要探讨在讨论过程中的重要反对观点和关注点。
- 向后兼容 - 所有带来向后不兼容的EIPs都必须包含一个章节来描述这些不兼容以及它们的严重性。而且EIP中必须解释作者关于处理这些不兼容问题的措施。提交EIP但没有足够的向后兼容论述的话很可能会直接被拒绝。
- 测试用例 - 对影响到共识的EIPs来说，给实现写测试用例是强制的。其它的EIPs可以选择引入可用的测试用例的链接。
- 实现 - 在EIP状态转为"Final"之前，所有的实现都必须完成，但在EIP合并为草案的时候不需要完成实现。尽管在代码实现之前在规范和基本原理上达成共识的意义很大，但当解决讨论API细节的时候，"粗糙的共识和可运行的代码"这个原则仍然有效。
- 放弃版权声明 - 所有的EIPs必须不受版权限制。从这个EIP的底部查看一个放弃版权声明的样例。

## EIP格式和模板

EIPs必须用 [markdown] 格式来编写.
图片之类的资源文件放在`assets`目录中的单独子目录中，并命名为: `assets/eip-X` (for eip **X**)的格式。当在EIP链接图片(文件)的时候，使用相对链接地址比如： `../assets/eip-X/image.png`。

## EIP消息报文头

每一个EIP都必须以RFC 822风格的报文头开始，紧跟着三个连字符(`---`)，消息头必须以下面的顺序出现。标记了"*"的消息头是可选的下文中会描述，其它的消息头都是必须的。

` eip:` <EIP number> (这个需要由EIP编辑决定)

` title:` <EIP title>

` author:` <一个作者或作者们的姓名或用户名的列表，也可以是姓名和邮件的列表。具体细节见下面。>

` * discussions-to:` <一个指向官方讨论地方的链接>

` status:` <Draft \| Last Call \| Accepted \| Final \| Active \| Deferred \| Rejected \| Superseded>

`* review-period-end:` <最迟审查日期>

` type:` <Standards Track (Core, Networking, Interface, ERC) \| Informational \| Meta>

` * category:` <Core \| Networking \| Interface \| ERC>

` created:` <创建日期>

` * requires:` <EIP number(s)>

` * replaces:` <EIP number(s)>

` * superseded-by:` <EIP number(s)>

` * resolution:` <一个指向这个EIP的决议的url>

消息头中有列表的话必须用逗号隔开元素。

消息头中有日期的话都需要用ISO 8601格式的日期(yyyy-mm-dd)。

#### `author`消息头

 `author`消息头可选择地列出作者的姓名、邮件地址和EIP的作者/所有者的用户名。那些期望匿名的则可以只是用用户名，或者名字(first name)以及用户名。author消息头的值的格式必须是:

> Random J. User &lt;address@dom.ain&gt;

or

> Random J. User (@username)

如果包含了邮件或者Github用户名则使用上面的格式，否则使用下面的格式

> Random J. User


#### `resolution`消息头

`resolution`消息头仅对标准路径EIPs(Standards Track EIPs)要求。它需要包含指向一个关于作出该EIP的声明的邮件信息或者其它网络资源的url。

#### `discussions-to`消息头

当一个EIP在草案状态时，一个`discussions-to` 消息头可以指明这个EIP正在进行讨论的邮件列表或地址。正如上述所提到，讨论你的EIP的地方的地方有：[Ethereum topics on Gitter](https://gitter.im/ethereum/topics)这个仓库或者这个仓库的一个分支中的一个issue， [Ethereum Magicians](https://ethereum-magicians.org/) (这里适合讨论有争议或者有强管理需要的EIPs)，和这里 [Reddit r/ethereum](https://www.reddit.com/r/ethereum/)。

如果EIP是和作者私下讨论的，则不需要 `discussions-to` 消息头。

作为一个特例，`discussions-to` 消息头不能指向Github pull requests。

#### `type`消息头

`type`消息头指定了EIP的类型: Standards Track、Meta或Informational。如果是标准路径类型则还需要指定子分类(core、networking、interface或ERC)。

#### `category`消息头

`category`消息头指定了EIP的分类。但仅标准路径EIP需要指定。

#### `created`消息头

`created`消息头记录该EIP被赋予一个EIP number的日期，需要以这个：yyyy-mm-dd格式填写，比如：2001-08-14／。

#### `requires`消息头

EIPs可能会包括一个`requires`消息头，指定该EIP所依赖的EIPs的编号。

#### `superseded-by`和`replaces`消息头

EIPs可能还会有`superseded-by`(被取代)消息头指示这个EIP被后面的某个EIP所取代，它的值是那个取代它的EIP。而那个新的EIP必须有一个`replaces`消息头值为这个被取代的EIP的number。

## 辅助文件

EIPs可能包含如图表这样的辅助文件，这些文件必须以EIP-XXXX-Y.ext的形式命名，其中“XXXX”是EIP number，“Y”是序列号(从1开始)，“ext”替换为真实的文件扩展名(如 “png”)。

## 转让EIP所有权

有时候需要将EIPs的拥有权转让给另一个领导者。通常，我们还会保留原有的作者作为这个EIP的co-author，但这根据原来作者的意愿来。转让所有权的原因可能包括原来的作者没有时间或者兴趣更新这个EIP或者跟进EIP流程，又或者找不着了(比如联系不到或者没有回复邮件)。 你不同意EIP的方向是一个不合适的转让控制权的理由。我们会尝试在社区中围绕一个EIP建立广泛共识，但如果这不能达成一致，你可以随时提交一个竞争的EIP。

如果你对承担一个EIP的所有权有兴趣，可以发送一条消息请求接管，向原来的作者和EIP编辑都发信说明。如果原来的作者没有及时回复这个邮件，EIP则会自主作出决定(但这些决定并不是不能被撤销 :))。

## EIP编辑们

当前的EIP编辑有：

` * Nick Johnson (@arachnid)`

` * Casey Detrio (@cdetrio)`

` * Hudson Jameson (@Souptacular)`

` * Vitalik Buterin (@vbuterin)`

` * Nick Savers (@nicksavers)`

` * Martin Becze (@wanderer)`

## EIP编辑责任

对每个进入的EIP，EIP编辑需要做到以下几点:

- 阅读EIP看EIP是否准备好：健全和完备。EIP中的想法必须在技术上可靠，即使它们看起来可能不会走到final状态。
- 标题需要精确地描述内容。
- 从语言(拼写、语法、句子结构等等)、标记(Github风格的Markdown)和代码风格上检查EIP。

如果EIP没有准备好，编辑会把它退回给作者审查，并给出指导。

一旦EIP准备好可以提交，EIP编辑会:

- 赋予一个EIP编号(通常是PR number，或者如果作者更喜欢Issue number也可以。# 如果仓库中对该EIP有相关Issue进行讨论的话)

- 合并对应的pull request

- 给EIP作者发送消息提示进行下一步操作。

许多EIPs是由具有以太坊代码库写权限的开发者编写和维护的。EIP编辑会监控EIP变化并矫正任何的结构、语法、拼写或者标记错误。

编辑们编辑的时候不会传递自己对EIPs的观点。我们仅仅管理和编辑EIPs。

## 历史

这个文档大部分派生于Amir Taaki编写的[Bitcoin's BIP-0001]，而它这个也是派生自[Python's PEP-0001]。文本的很多地方仅仅是拷贝和修改。尽管PEP-0001是由Barry Warsaw、Jeremy Hylton和David Goodger几个人写的，但他们对这些文本在Ethereum Improvement Process中的使用没有责任，也不应该被和以太坊或者EIP相关的问题打扰。如有任何问题，都反馈给以太坊编辑。

December 7, 2016: EIP 1 被通过并且提交为PR。

February 1, 2016: EIP 1 加入了编辑，在过程中对草稿进行了改进，并合并到了主分支。

March 21, 2018: 为了适应新的在[eips.ethereum.org](http://eips.ethereum.org/)自动生成的EIP目录进行了小的编辑。

May 29, 2018: 在流程中加入了Last Call状态

更多历史看这里： [the revision history for further details](https://github.com/ethereum/EIPs/commits/master/EIPS/eip-1.md)，你也可以通过在EIP的右上角点击历史按钮来查看。

### 参考目录

[EIP5]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5.md
[EIP101]: https://github.com/ethereum/EIPs/issues/28
[EIP90]: https://github.com/ethereum/EIPs/issues/90
[EIP86]: https://github.com/ethereum/EIPs/issues/86#issue-145324865
[devp2p]: https://github.com/ethereum/wiki/wiki/%C3%90%CE%9EVp2p-Wire-Protocol
[EIP8]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-8.md
[Light Ethereum Subprotocol]: https://github.com/ethereum/wiki/wiki/Light-client-protocol
[whisper]: https://github.com/ethereum/go-ethereum/wiki/Whisper-Overview
[swarm]: https://github.com/ethereum/go-ethereum/pull/2959
[API/RPC]: https://github.com/ethereum/wiki/wiki/JSON-RPC
[EIP59]: https://github.com/ethereum/EIPs/issues/59
[EIP6]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-6.md
[contract ABIs]: https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
[interfaces repo]: https://github.com/ethereum/interfaces
[ERC20]: https://github.com/ethereum/EIPs/issues/20
[ERC26]: https://github.com/ethereum/EIPs/issues/26
[ERC137]: https://github.com/ethereum/EIPs/issues/137
[ERC67]: https://github.com/ethereum/EIPs/issues/67
[EIP82]: https://github.com/ethereum/EIPs/issues/82
[EIP75]: https://github.com/ethereum/EIPs/issues/75
[EIP85]: https://github.com/ethereum/EIPs/issues/85
[the Ethereum subreddit]: https://www.reddit.com/r/ethereum/
[one of the Ethereum Gitter chat rooms]: https://gitter.im/ethereum/
[pull request]: https://github.com/ethereum/EIPs/pulls
[formal specification]: https://github.com/ethereum/yellowpaper
[the Issues section of this repository]: https://github.com/ethereum/EIPs/issues
[markdown]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
[Bitcoin's BIP-0001]: https://github.com/bitcoin/bips
[Python's PEP-0001]: https://www.python.org/dev/peps/

## 版权

版权以及相关权利由此[CC0](https://creativecommons.org/publicdomain/zero/1.0/)声明弃权。