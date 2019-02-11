# EIPs [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ethereum/EIPs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
以太坊改进提案(Ethereum Improvement Proposals, EIPs)描述了以太坊平台的相关标准，包括核心协议规范、客户端APIs和合约的相关标准。

现有的所有EIPs和草案的一个浏览器版本可以查看这里[EIP官方地址](http://eips.ethereum.org/)，中文版本的可以查看[EIP中文版地址](https://posa88.github.io/EIPs-Chinese/)。

# 如何贡献

 1. 阅读[EIP-1](EIPS/eip-1.md)。
 2. 通过点击右上角的"Fork"按钮Fork本代码仓库。
 3. 向你的分支添加你的EIP。这里有一个[EIP模板](eip-X.md)。
 4. 向以太坊代码仓库提交一个Pull Request[EIPs代码仓库](https://github.com/ethereum/EIPs)，中文翻译则向中文代码仓库[中文翻译版EIPs仓库](https://github.com/posa88/EIPs-Chinese)提交。

你的第一个PR应当是EIP定稿的一个草稿。它必须满足构建所需的格式要求(主要是正确地填写header中的元数据)。编辑会手动地审查新EIP的第一个PR并在合并它之前赋予一个编号。请尽量加入一个指向用户讨论你的EIP的论坛或者Github issue的URL地址的`discussions-to`消息头。

如果你EIP包含图片，则这些图片之类的资源文件放在`assets`目录中的单独子目录中，并命名为: `assets/eip-X` (for eip **X**)的格式。当在EIP链接图片(文件)的时候，使用相对链接地址比如： `../assets/eip-X/image.png`。

一旦你的第一个PR被合并，我们会用一个机器人自动合并你的PRs到EIPs草案中，前提是你是该草案的所有者。请确保你的EIP的'author'消息头中包含了你的Github用户名或者你的邮箱(邮箱用<尖括号>括起来)。如果用的是你的邮箱，则该邮箱必须是公开展示在[你的github profile](https://github.com/settings/profile)上的那一个。

当你认为你的EIP已经足够成熟并可以通过草稿的最后征求意见阶段了的时候，你应该按下面两步中的一步来推进:

 - **对一个标准路径EIP中的核心EIP**，则申请将你的issue加入到[核心开发会议议程表](https://github.com/ethereum/pm/issues)中，在那里讨论是否将你的EIP中的内容加入到未来的一个分叉中。如果开发实施者们同意将其加入，EIP编辑们则会将EIP的状态变更为'Accepted'。
 - **对其它EIPs**，提交一个将EIP状态修改EIP状态为'Final'的PR。会有编辑审查你的草稿并询问是否有人不同意你的EIP进入定稿(Final)状态。如果编辑看到达成初步共识，比如，有贡献者指出了该EIP的重大问题，则编辑们可能会关闭PR并要求你在再次提交PR之前先处理该问题。

# EIP状态术语
* **草案(Draft)** - 一个正在快速迭代和修改的EIP草稿
* **最后征求意见(Last Call)** - EIP已经完成了初始迭代并且准备好给社区审查
* **接受(Accepted)** - 一个核心EIP进入Last Call状态最少已经经过了2周，并且被要求的技术修改已经被作者进行了处理后进入Accepted状态
* **定稿(Final,non-Core)** - 非核心EIP进入Last Call状态最少已经经过了2周，并且被要求的技术修改已经被作者进行了处理后进入Final状态
* **定稿(Final,Core)** - 核心EIP被核心开发者们决定实现并会在未来的硬分叉中发布，或者已经在过去的硬分叉中发布了
* **延期(Deferred)** - 一个不会考虑马上采用的EIP，但可能在未来考虑在硬分叉中采用

# 首选引用格式

查看达到Draft状态的EIP的权威地址是https://eips.ethereum.org/ 域名下，中文版的则在https://posa88.github.io/EIPs-Chinese/ 。比如ERC-165的权威地址是https://eips.ethereum.org/EIPS/eip-165 ，中文版则在https://posa88.github.io/EIPs-Chinese/EIPS/eip-1 。
