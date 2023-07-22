---
title: Add time-weighted averaging to the base fee mechanism
description: Using geometric weights to average past block sizes into consideration
author: Guy Goren <guy.nahsholim@gmail.com>
discussions-to: https://ethereum-magicians.org/t/add-time-weighted-averaging-to-the-base-fee-mechanism/15142
status: Draft
type: Standard Track
category: Core
created: 2023-07-22
# requires: <EIP number(s)> Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

## Abstract
The current formula for setting the base fee follows the original EIP1559:
$$b[i+1]\triangleq  b[i] \cdot \left( 1+\frac{1}{8} \cdot \frac{s[i]-s^* }{s^* }\right)$$ where $i$ enumerates the blocks, $s^*$ is a predetremined block size (the "desired" size, aka gas amount), $b[i]$ is the base fee at block $i$, and $s[i]$ is the size of the block at height $i$. This formula considers only the last block size $s[i]$. This mechanism might lead to incentives for users to bribe miners in order to reduce the base fee, or (in analogous manner) for miners to intiate a collusion with sophisticated users for the benefit of both. (See Motivation section.)

We propose to consider the history of block sizes via a past wheighted average with a geometric sequence as the weights. In particular, we suggest the following update rule:
$$b[i+1]\triangleq  b[i] \cdot \left( 1+\frac{1}{8} \cdot \frac{s_{\textit{avg}}[i]-s^* }{s^* }\right)$$ where $s_{\textit{avg}}[i]$ is defined by
$$s_{\textit{avg}}[i] \triangleq \frac{1-q}{q}\sum_{k=1}^{\infty} q^k\cdot s[i-k+1], \hspace{1cm}   q\in (0,1).$$ 
<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

## Motivation
Mainly, to reduce bribe motivation (in particular in case the demand for blockspace is high (see Incentive Considerations section). Additionaly, to reduce oscillations and have a more stable fee setting mechanism.

For determining which messages enter a block, Filecoin uses a mechnism that was proposed in [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md). This mechanism introduced a base fee, which is a portion of the transaction fee that is burned and not awarded to miners, and which varies according to the fill rate of blocks. A target block size is defined, such that if a block is fuller than the target size, the base fee increases and if it is emptier, the base fee reduces.

Research on the subject have revealed issues with this transaction fee mechanism. It has been shown to be [unstable in cases](https://arxiv.org/pdf/2102.10567.pdf). Moreover, it has been shown that the dynamic nature of the base fee, which is influenced by the fill rate of blocks, opens the door for [manipulation by miners and users](https://arxiv.org/abs/2304.11478). The desired behavior of the system under a stable high demand, is for it to reach an equalibrium where the base fee -- $b$ -- is the significant part of the gas fee, and the tip is relatively small -- denoted $\varepsilon$ (for reference, Ethereum's base fee often has $\frac{b}{\varepsilon}\approx 20$). According to [Roughgarden](https://timroughgarden.org/papers/eip1559.pdf) this is a rational equalibrium under the assumption that miners do not think ahead. However, we expect a miner to optimize its behavior by also considering its future payoffs. In essence, since neither the miner nor the user are getting the burnt fee, by colluding they can both tap into the burnt fee for a win-win situation for them both.

A [theorethical work](https://arxiv.org/abs/2304.11478) describes how both miners and users can initiate an attack. For example, we can imagine that users who wish to pay lower costs will coordinate the attack. Roughly, a user (or group of users) that has transactions with a total $g$ amount of gas bribes the miner of the current block (no matter the miner's power) to propose an empty block instead. The cost of such a bribe is only $\varepsilon \times {s^* }$ -- the tip times the target block size. Consequently, the base fee reduces in the next block. If we accept that EIP1559 reaches its goals, e.g., users would typicaly use a simple and honest bidding strategy of reporting their maximal willingness to pay plus adding a small tip ($\varepsilon$), then in the honest users' steady state, gas proposals leave the miners with an $\varepsilon$ tip. Given that other users are na\"ive (or slow to react), our bribing user will include its transactions with any tip larger than $\varepsilon$ -- making the attack profitable whenever $g \frac{b^* }{8} >s^* \varepsilon$.

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification
The following equation describes the main part of the change, that is, replacing $s[i]$ by $s_{\textit{avg}}[i]$. For $q\in (0,1)$,

$$s_{\textit{avg}}[i] \triangleq \frac{1-q}{q}\sum_{k=1}^{\infty } q^k\cdot s[i-k+1]$$ 

which simplifies to the recursive form
$$s_{\textit{avg}}[i] = (1-q)\cdot s[i] + q\cdot s_{\textit{avg} }[i-1].$$

This scheme is parametrized by $q$ which determins the concentration of the average. Roughly, smaller $q$ values result in $s_\textit{avg}$ resembling the very last block sizes, while larger $q$ values smoothen the average over a longer history.


<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting


The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.
-->
## Rationale
An intuitive option for the Transaction Fee Mechanism (TFM) that adjusts supply and demand economically is *First price auction*, which is well known and studied. Nevertheless, the Ethereum network choice was to use EIP-1559 for the TFM (one stated reason was to try and simplify the fee estimation for users, and reduce the advantage of sophisticated users). In this proposal, our design goal is to improve the TFM (of EIP-1559) by mitigating known problems that it raises. It is important to note that these problems severity are in direct relation to the demand for block space, and currently only mildly impact the Ethereum network. If demand to use Ethereum increases, however, these problems are expected to exacerbate. We may want to prepare for this beforehand.

The change is based on [this work](https://arxiv.org/abs/2304.11478) that described a rational strategy in which bribes are profitabe. Choosing to average based on a geometric series weights results in two desired properties: (i) the computation and space complexity are both in O(1), and (ii) the average gradually phases out the impact of a single outlier block without causing significant future fluctuations in the base fee.

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Backwards Compatibility
This change requires a hard fork since the base fee is enforced (for blocks to be considerd valid).
<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Test Cases
Too early to say
<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

<!--
## Reference Implementation

  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Incentive Considerations
The proposal is designed to improve the incentive compatability of the TFM. A [game theoretic analysys](https://arxiv.org/abs/2304.11478) shows that a TFM based on EIP-1559 encourages bribes. Roughly, because the base fee in the next block depends on the size of the the current block, a miner that creates an empty block reduces the base fee of the next block by a factor of $\frac{1}{8}$. The opportunity cost for mining an empty block instead of a normal block is only the tips it contains. Thus, the cost of bribing a miner is only compansating it for the lost tips. In case the base fee is significantly larger than the tips, the bribing user gains a siginificant reduction in the base fees of the next block, making the bribe profitable. 

One of the main goals of EIP-1559 was to simplify the bidding for users. It was articulated [theoreticaly by Roughgarden](https://timroughgarden.org/papers/eip1559.pdf) as users bidding their honest valuations being an optimal strategy. In contrast, when using first price auctions for the TFM (as done by Bitcoin and previously in Ethereum), it is typically sub-optimal for a user to bid its honest valuation. In other words, a TFM that encourages users to not fully reveal their preferences is considerd less good. However, one may argue that a TFM that encourages bribes is worse than a TFM that encourages not revealing one's full preferences.

Although a first price auction is a safe bet regarding TFMs, the Ethereum network chose to use EIP-1559 and burn transaction fees (perhaps for reasons other than game-theoretic ones). We therefore suggest to mitigate the current incentives for bribes using the above proposal.


## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
