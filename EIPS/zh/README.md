# EIPs 

Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.

## Contributing

First review [EIP-1](./eip-1.md). Then clone the [repository](https://github.com/ethereum/EIPs) and add your EIP to it. There is a [template EIP here](https://github.com/ethereum/EIPs/blob/master/eip-template.md). Then submit a Pull Request to Ethereum's [EIPs repository](https://github.com/ethereum/EIPs).

## EIP status terms

- **Idea** - An idea that is pre-draft. This is not tracked within the EIP Repository.
- **Draft** - The first formally tracked stage of an EIP in development. An EIP is merged by an EIP Editor into the EIP repository when properly formatted.
- **Review** - An EIP Author marks an EIP as ready for and requesting Peer Review.
- **Last Call** - This is the final review window for an EIP before moving to FINAL. An EIP editor will assign Last Call status and set a review end date (review-period-end), typically 14 days later. If this period results in necessary normative changes it will revert the EIP to Review.
- **Final** - This EIP represents the final standard. A Final EIP exists in a state of finality and should only be updated to correct errata and add non-normative clarifications.
- **Stagnant** - Any EIP in Draft or Review if inactive for a period of 6 months or greater is moved to Stagnant. An EIP may be resurrected from this state by Authors or EIP Editors through moving it back to Draft.
- **Withdrawn** - The EIP Author(s) have withdrawn the proposed EIP. This state has finality and can no longer be resurrected using this EIP number. If the idea is pursued at later date it is considered a new proposal.
- **Living** - A special status for EIPs that are designed to be continually updated and not reach a state of finality. This includes most notably EIP-1.

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