## Preamble

    EIP: <to be assigned>
    Title: Tip on transactions to fund building a global commons
    Author: James Ray, with [attribution to Rhys Lindmark](https://medium.com/@RhysLindmark/co-evolving-the-phase-shift-to-cryptocapitalism-by-founding-the-ethereum-commons-co-op-f4771e5f0c83)
    Type: Standard Track
    Category: Core
    Status: Draft
    Created: 2017-03-07
    
## Simple Summary
Have a voluntary contribution on transactions in order to fund building a global commons (e.g. infrastructure, healthcare, education, UBI, a governance platform, etc.).

## Abstract
The current dominant paradigms of capitalism and representative democracy are flawed, favouring the elite and incumbent: rich people, state and industry. The centralised nature of state-based political and economic structures such as representative democracy, state-based communism, dictatorships, monarchies, central banks, etc., makes such such ideologies and institutions prone to corruption. This EIP proposes to set up a way to pay a voluntary contribution on transactions, to go to a pool of funds that will be used to fund building a global commons such as infrastructure, healthcare, education and a universal basic income. The distribution of funds can be managed by a decentralized governance platform that can run on top of Ethereum, such as [Democracy Earth](https://democracy.earth), which can be used for voting and signalling in organizations and proposals for projects. Additionally, this voting and signalling should be used as a precursor to establishing [rough consensus](https://www.rfc-editor.org/rfc/rfc7282.txt). 

It is more controversial to have a mandatory fee/tax on every transaction, so that will be left outside the scope of this EIP. Making the contribution more like an investment has problems as well for commons like infrastructure, healthcare and education, where it is more difficult. However, by building a global commons with ETH, the usage of ETH will increase and thus the value of ETH will go up, thus by making small voluntary contributions over time, the value of one's ETH should go up and voluntary contributions need not be purely philanthropic.

<!--## Motivation
The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.

This is done in the abstract. There are no such fees for this purpose in the current protocol.-->

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumj, ethereumjs, ...).-->

During client setup there can be a prompt to ask the user how much to pay as a percentage of every transaction to be used for building a global commons. A link can be provided for further info. Alternatively there can be a less intrusive option to set this, which can be found via the --help option and the Wiki. This value can also be changed at any time via the client. The user can choose to put in any value above zero. For example, if a user opts to pay 10%, then if they want to send 1 ETH, they would actually send 1.1 ETH.

<!--## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

<!--## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

<!--## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

<!--## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
