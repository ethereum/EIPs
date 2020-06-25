---
eip: <to be assigned>
title: Disable SELFDESTRUCT
author: Alexey Akhunov (@AlexeyAkhunov)
discussions-to: https://ethereum-magicians.org/t/eip-for-disabling-selfdestruct-opcode/4382
status: Draft
type: Standards Track
category: Core
created: 2020-06-25
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
Disable SELFDESTRUCT

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Make `SELFDESTRUCT` EVM operation no-op (effectively disable). Contracts will not be able to delete themselves.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Althouth `SELFDESTRUCT` originally came with EVM to help clean up the state, we learnt that in practice it did not achieve this objective on
sufficient scale, and is on balance a burden of extra complexity and unintended effects (GasToken2 and polymorphic contracts).

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Operation `SELFDESTRUCT` (formerly `SUICIDE`) was in the EVM from the beginning, and its purpose was to incentivise clearing the state, by giving the
caller gas refund. In practice, this incentivisation turned out to be very limited, and the designed purpose was not archieved. However, `SELFDESTRUCT`
brings significant amount of complexity to the EVM. It is responsible for some of the most arcane edge cases in the EVM semantics.
It is also used as a vehicle to run an efficient arbitrage of gas prices (GasToken2), which
ironically lead to the increase use of the state. Introduction of `CREATE2` opcode in Constantinople upgrade created a new phenomenom of
polymorthic contracts, i.e. contracts that can change their bytecode over time, while residing on the same address. Polymorphic contracts are limited
in their use, because changing the bytecode via `SELFDESTRUCT` + `CREATE2` clears all the contract storage, making contract lose all its data,
and making it unsuitable to replace Proxy Pattern as a technique for upgradable contracts. Removing the effect of `SELFDESTRUCT`
will reduce complexity of EVM going forward, disable GasToken2 (but not GasToken1, which is based on storage clearing refunds), and make
polymorthic contracts impossible.
## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
After certain block number, the semantics of `SELFDESTRUCT` becomes the same as the combination of `POP` followed by `STOP`. Gas cost is the same as the gas cost
of `POP`, which is 2 gas. No value transfer occurs and no gas refund is given.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Disabling `SELFDESTRUCT` is the simplest and most effective way to remove its negative effects.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
Backwards incompatible and requres a hard fork.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
There are a lot of test in the standards suite related to `SELFDESTRUCT` and its edge cases. These need to be modified for the new no-op semantics.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Implementation is likely to be trivial - introducing the eip flag and replacing the old, complex semantics, with the new, simple semantics.

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
At this point, author of this EIP is not aware of any class of smart contracts that rely on `SELFDESTRUCT` for their functionality and security, with the exception of
GasToken2 contract and similar.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
