# EIPs 

以太坊改进提案（EIPs）描述了以太坊平台的标准，包括核心协议规范、客户端 APIs 和合约标准。  

## 贡献

首先，请阅读 [EIP-1](./eip-1.md)。然后复制 [repository](https://github.com/ethereum/EIPs) 并且添加你的 EIP。这里有一个 [EIP 模版](https://github.com/ethereum/EIPs/blob/master/eip-template.md)。然后提交 PR 到以太坊的 [EIPs repository](https://github.com/ethereum/EIPs)。

## EIP 状态术语

- **想法** - 这个想法仍在起草前阶段. 这还未被 EIP 仓库追踪。
- **草案** - 这是进展中的 EIP 的第一个正式跟踪阶段。在格式正确的情况下，EIP 将由 EIP 编辑合并到 EIP 库中。
- **审议** - 该 EIP 作者发出明确信号：该 EIP 已准备好接受外部审议。
- **最后征求意见** - 这是 EIP 在转入完结（FINAL）之前的最后审核机会。EIP 编辑将分配 Last Call 状态，并设定 review 结束日期（审核期结束），通常是 14 天后。如果这个阶段产生了必要的规范性修改，它将把 EIP 状态恢复为审议状态。
- **完结** - 本 EIP 代表最终标准。最终的 EIP 是以确定状态存在的，只应在纠正勘误和增加非规范性订正时进行更新。
- **停滞** - 任何处于草案或审议中的 EIP，如果在 6 个月或更长时间内没有进展，将被移至停滞状态。作者或 EIP 编辑可以通过将其移回草案，使 EIP 从这种状态中复活。
- **已撤销** - EIP 作者已经撤回了拟议的 EIP。此状态具有终结性，不能再使用这个 EIP 号复活。如果继续这个提案内容，它将被视为一个新的提案。
- **续用中** - 旨在为持续更新且未达到最终状态的 EIP 提供的一种特殊状态。这包括最有名的 EIP-1。

## EIP Types

EIPs are separated into a number of types, and each has its own list of EIPs.

### [Standard Track](./summary/standards-track.md)

Describes any change that affects most or all Ethereum implementations, such as a change to the network protocol, a change in block or transaction validity rules, proposed application standards/conventions, or any change or addition that affects the interoperability of applications using Ethereum. Furthermore Standard EIPs can be broken down into the following categories.

### [Core](./summary/core.md)

Improvements requiring a consensus fork (e.g. [EIP-5](./eip-5.md), [EIP-101](./eip-101.md)), as well as changes that are not necessarily consensus critical but may be relevant to “core dev” discussions (for example, the miner/node strategy changes 2, 3, and 4 of EIP-86).

### [Networking](./summary/networking.md)

Includes improvements around devp2p ([EIP-8](./eip-8.md)) and Light Ethereum Subprotocol, as well as proposed improvements to network protocol specifications of whisper and swarm.

### [Interface](./summary/interface.md)

Includes improvements around client API/RPC specifications and standards, and also certain language-level standards like method names (EIP-6) and contract ABIs. The label “interface” aligns with the interfaces repo and discussion should primarily occur in that repository before an EIP is submitted to the EIPs repository.

### [ERC](./summary/erc.md)

Application-level standards and conventions, including contract standards such as token standards ([ERC-20](./eip-20.md)), name registries ([ERC-137](./eip-137.md)), URI schemes ([ERC-681](./eip-681.md)), library/package formats ([EIP190](./eip-190.md)), and wallet formats ([EIP-85](https://github.com/ethereum/EIPs/issues/85)).

### [Meta](./summary/meta.md)

Describes a process surrounding Ethereum or proposes a change to (or an event in) a process. Process EIPs are like Standards Track EIPs but apply to areas other than the Ethereum protocol itself. They may propose an implementation, but not to Ethereum's codebase; they often require community consensus; unlike Informational EIPs, they are more than recommendations, and users are typically not free to ignore them. Examples include procedures, guidelines, changes to the decision-making process, and changes to the tools or environment used in Ethereum development. Any meta-EIP is also considered a Process EIP.

### [Informational](./summary/informational.md)

Describes a Ethereum design issue, or provides general guidelines or information to the Ethereum community, but does not propose a new feature. Informational EIPs do not necessarily represent Ethereum community consensus or a recommendation, so users and implementers are free to ignore Informational EIPs or follow their advice.
