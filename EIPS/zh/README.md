# EIPs 

以太坊改进提案（EIPs）描述了以太坊平台的标准，包括核心协议规范、客户端 APIs 和合约标准。  

## 贡献

首先，请阅读 [EIP-1](./eip-1.md)。然后复制 [repository](https://github.com/ethereum/EIPs) 并且添加你的 EIP。这里有一个 [EIP 模版](https://github.com/ethereum/EIPs/blob/master/eip-template.md)。然后提交 PR 到以太坊的 [EIPs repository](https://github.com/ethereum/EIPs)。

## EIP 状态术语

- **想法** - 这个想法仍在起草前阶段. 这还未被 EIP 仓库追踪。
<!-- - **Idea** - An idea that is pre-draft. This is not tracked within the EIP Repository. -->
- **草案** - 这是进展中的 EIP 的第一个正式跟踪阶段。在格式正确的情况下，EIP 将由 EIP 编辑合并到 EIP 库中。
<!-- - **Draft** - The first formally tracked stage of an EIP in development. An EIP is merged by an EIP Editor into the EIP repository when properly formatted. -->
- **审议** - 该 EIP 作者发出明确信号：该 EIP 已准备好接受外部审议。
<!-- - **Review** - An EIP Author marks an EIP as ready for and requesting Peer Review. -->
- **最后征求意见** - 这是 EIP 在转入“完结”之前的最后审核机会。EIP 编辑将分配“最后征求意见”状态，并设定审议结束日期（审核期结束），通常是 14 天后。如果这个阶段产生了必要的规范性修改，它将把 EIP 状态恢复为审议状态。 
<!-- - **Last Call** - This is the final review window for an EIP before moving to FINAL. An EIP -->
<!--  editor will assign Last Call status and set a review end date (`last-call-deadline`), typically 14 days later. If this period results in necessary normative changes it will revert the EIP to Review. -->
- **完结** - 本 EIP 代表最终标准。最终的 EIP 是以确定状态存在的，只应在纠正勘误和增加非规范性订正时进行更新。
<!-- - **Final** - This EIP represents the final standard. A Final EIP exists in a state of finality and should only be updated to correct errata and add non-normative clarifications. -->
- **停滞** - 任何处于草案或审议中的 EIP，如果在 6 个月或更长时间内没有进展，将被移至停滞状态。作者或 EIP 编辑可以通过将其移回草案，使 EIP 从这种状态中复活。
<!-- - **Stagnant** - Any EIP in Draft or Review if inactive for a period of 6 months or greater is moved to Stagnant. An EIP may be resurrected from this state by Authors or EIP Editors through moving it back to Draft. -->
- **已撤销** - EIP 作者已经撤回了拟议的 EIP。此状态具有终结性，不能再使用这个 EIP 号复活。如果继续这个提案内容，它将被视为一个新的提案。
<!-- - **Withdrawn** - The EIP Author(s) have withdrawn the proposed EIP. This state has finality and can no longer be resurrected using this EIP number. If the idea is pursued at later date it is considered a new proposal. -->
- **续用中** - 旨在为持续更新且未达到最终状态的 EIP 提供的一种特殊状态。这包括最有名的 EIP-1。
<!-- - **Living** - A special status for EIPs that are designed to be continually updated and not reach a state of finality. This includes most notably EIP-1. -->

## EIP 类型

EIP 有若干类型，每一种类型都有自己的 EIP 清单。

### [标准跟踪](./summary/standards-track.md)

描述影响大多数/ 全部以太坊实现的任何变化，例如网络协议的更改、块或交易有效性规则的更改、应用程序标准或约定，或影响以太坊应用程序交互的任何更改或添加。标准跟踪 EIP 细分为以下几类。

### [核心](./summary/core.md)

核心提案包含产生共识分叉的改进(如：[EIP-5](./eip-5.md), [EIP-101](./eip-101.md))，以及一些不一定是共识部分但可能与“核心开发”讨论相关的变更（例如，矿工/节点策略更改 EIP-86 的 2，3 和 4）。

### [网络](./summary/networking.md)

包括围绕 devp2p（[EIP-8](./eip-8.md)）和轻客户端子协议的改进，以及对 whisper 和 swarm 网络协议规范的改进建议。

### [接口](./summary/interface.md)

包括有关客户端 API/RPC 规范和标准的改进，以及某些语言层面的标准，如方法名（EIP6）和合约 ABI。标签"接口"与接口库一致，在 EIP 被提交到 EIP 库之前，讨论应该主要发生在该库中。

### [ERC](./summary/erc.md)

ERC 是 Ethereum Request for Comment 的缩写，包含如：代币标准合约（[ERC-20](./eip-20.md)），名称注册（[ERC-137](./eip-137.md)），URI schemes （[ERC-681](./eip-681.md)），库/包格式（[EIP190](./eip-190.md) 和钱包格式 ([EIP-85](https://github.com/ethereum/EIPs/issues/85))。

### [Meta](./summary/meta.md)

描述以太坊的改进过程（或事件），也被视为过程 EIP（Process EIP）。 流程 EIP 类似于标准跟踪 EIP，但也适用于描述以太坊协议外的内容。 他们可能会提出一个实现，但不会加入到以太坊的代码库; 这些提案经常需要社区共识; 与信息 EIP 不同，它们不仅仅是建议，用户通常不能随意忽略它们。 提案包括程序，指南，决策过程的变更以及以太坊开发中使用的工具或环境的变更。任何 Meta-EIP 也被称为是一个过程 EIP。

### [信息提案](./summary/informational.md)

描述以太坊设计问题，或向以太坊社区提供一般指导方针或信息，但没有提出新功能。 信息提案不一定代表以太坊社区的共识或推荐，因此用户和实施者可以自由地忽略信息 EIP 或遵循他们的建议。
