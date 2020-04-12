---
eip: <to be assigned>
title: Graph Interface
author: enrique.arizonbenito@gmail.com
discussions-to: https://gitter.im/ethereum/EIPs
status: Draft
type: Standards
created: 2020-04-11
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less. { -->
Standard Network Graph interface

## Simple Summary
<!-- }
"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP. { -->
Provide and standarised set of interfaces for graphs structures.

## Abstract
<!--} 
A short (~200 word) description of the technical issue being addressed. {-->
Graphs provide a general mathematical description in terms of edge-node data relations that easily map to many different use-cases. It's to be expected that the use of graph instances will improve the quality and security of smart-contract and client software. 

## Motivation
<!-- }
The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright. {-->
 Graphs relations amongst distributed entities arise naturally in claim-based identity frameworks, trust-systems, machine-to-machine RBAC security models, voting-delegation mechanisms, transitive relationships, economics models, architecture modeling, et ce tera. 
 The implementation of graphs can easely grow in complexity, since many graph-related problems soon become NP-like problems. By having a set of standarised interfaces and most probably a set of reference library implementations many contracts will be able to profit.
 Taking into account that data in a blockchain must represent assets, or more generally speaking, rights and obligations among subjects, the graph interface will focus on network-of-value use cases.  For example, graphs can be directed or no, but in network-of-value only directed graphs are usefuls, since contract rights and obligations are always directed and leaving freedom to choose will promote implementation errors.

 Nodes in a Graph can be, a priori, of any time, but for the sake of simplification, and to avoid complex or flawed desings just nodes of type address will be considered. 

* Wallets can directly profit from graphs repesenting networks of neighbourgh trusts, opening the way to new business scenarios.
* Complex right-delegation patterns become simple with the introduction of graphs.
* Identity schemas will be much easier to implement with the help of graphs.
 
## Specification
<!--
}
The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)). { -->
Next interface is proposed on a first approach. 
```
pragma solidity ^0.5.17;
/**
 * *Graph represent a multiple directed graph.
 * 
 * multiple: More than one edge can exists from source to destination
 * 
 * directed: Edge have a direction from source to destination.
 *           source      node is called the observer node.
 *           destination node is called the observed node.
 *           This nomenclature is used to highlight the active role of source
 *           and the passive role of destination at edge creation.
 * 
 */
 
 interface GraphMeta {
    /*
     * Implementations are free to map addActorNode to empty Implementation
     * if, potentially, any address is considered part of the graph network.
     * 
     */
    function addActorNode(address) external returns (bool);
    
    /*
     * This function must fail if associated edges exists, either 
     * pointing to this node or from this node, since edge will in general
     * be associated with contractual obligations.
     * If graph is not owned, implementation must check that address == msg.sender
     * If graph is owned, address must be that of isOwned.
     */
    function removeActorNode(address) external returns (bool);
    
    /*
     * Most interesting cases will involve non-owned graphs.
     * A result different from empty array warns if this is not the case.
     * Owned graphs can be useful in consortium networks where
     * "a-priori" trust is established, allowing for agile
     * management (with decreased security).
     */
     function isOwned() view external returns (address[] memory);
    
    /*
     * Returns non-zero if this DirectedGraph acts as a proxy
     * while data "comes-in".
     */
     function isInputProxy() view external returns (address);
     
    /*
     * Returns non-zero if this DirectedGraph acts as a proxy
     * while data "comes-out". it's a subset or view of
     * the original Graph.
     */
     function isOutputProxy() view external returns (address);
}

interface NotarizationDirectedGraph {
    /*
     * Notarization edges are inmutable.
     * Edges will represent inmutable facts of some entity
     * as seen by other neighbours nodes.
     * For example, It can represent and observer notarizing 
     * a hash-probe related to observed or an observer notarizing
     * that observed had received the hash-probe, ...
     *
     * For non-owned graphs, observer must be msg.sender
     */
    function addFactEdge (address observer_, address _observed, bytes32 fact ) external returns (bool);
    
    /*
     * For a given (observed) node returns facts as seen by 
     * neighbours (observer) nodes.
     */
    function getObservedFacts (address _observed)  external returns (bytes32[] memory);
    /*
     * For a given (observer) node returns facts notarised about
     * neighbours (observed) nodes.
     */
    function getObserverFacts (address observer_)  external returns (bytes32[] memory);
}

interface ClaimDirectedGraph {
    /*
     * CLAIM is similar to notarization, but claim edges can be removed.
     * It can be useful to represent short-long standing temporal facts. 
     * For example, node represented by address A
     * establishes that node B as read/write permissions over itself.
     * Or it can represent delegation amongst nodes during voting period.
     * Event logs will also allow to trace claim history in a non-repudiable
     * way.
     */

    /*
     * For non-owned contracts Observer must be msg.sender.
     */
    function addClaimEdge(address observer_, address _observed, bytes32 claim) external returns (bool);
    
    /**
     * For non-owned contracts observer must be msg.sender.
     * Only the original observer can renounce to its claim.
     */
    function removeClaimEdge(address observer_, address _observed, bytes32 claim) external returns (bool) ;
    /*
     * For a given (observed) node returns claims done by neighbours (observer) nodes.
     */
    function getObservedClaims(address _observed)  external returns (bytes32[] memory);
     /*
      * For a given observer node returns claims done over neighbours observed nodes.
      */
    function getObserverClaims(address observer_)  external returns (bytes32[] memory);
}

interface ObligationDirectedGraph {
    /*
     * Obligation is an obligation accepted or right transferred 
     * from observer to observed.
     * 
     * COntractual obligations must be represented by two edge in
     * opposite directions.
     * For non-owned contracts Observer must be msg.sender.
     */

    /*
     * For non-owned contracts Observer must be msg.sender.
     */
    function addObligationEdge(address observer_, address _observed, bytes32 obligation) external returns (bool);
    
    /*
     * For non-owned contracts Observed must be msg.sender: 
     * Observer can not resign to its obligations once signed.
     * Only its counter part (observed) can cancel them.
     */
    function removeObligationEdge(address observer_, address _observed, bytes32 obligation) external returns (bool) ;

    /*
     * For a given (observed) node, return obligation accepted or right
     * transferred by observed  node to observed node.
     *
     */
    function getObservedObligations(address _observed)  external returns (bytes32[] memory);

    /*
     * For a given observer node returns obligations signed with observed node.
     */
    function getObserverObligations(address observer_)  external returns (bytes32[] memory);
}
```


## Rationale
<!-- }
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion. { -->

 Graphs interfaces are well known and studied. The proposed interface will try to also promote "best-patterns" to avoid flawed implementations.
 For example self-souvering identity systems easely introduce design flaws, by designing identity around the "Me" or "self" person, breaking all the security principles of a blockchain design.

 Simple but no evident and so error-biased patterns will be described through interfaces.

 Transitive Rights/obligations, identity-claims systems, RBAC systems, ...  can be implemented with or without the directed Graphs interface. The graph approach will promote a more visual and intuitive interpretation of the use-case, and so, pottentially to safer, more reusable code as well as gaining more developer "traction". Actually is to be expected that simple graph implementations will use maps and list under the hood, but hidding all subtle, non-intuitive and error-prone details with no business value.

 Smart-contract making use of deployed graph can play different roles. Some will act as graph builders, adding edges or nodes to the graphs, while othes can act as graph consumers. The concept of input/output proxy is introduced, again to promote best-development pattern approach.


 Once an standarized graph interface set is in place, it will promote a common language amongst developers in terms of high-level abstractions (vs low level Solidity data structures). The classification of graphs in terms of notarization, claims and obligations can cover many scenarios in a network-of-value. It's also expected that client tools will be able to profit from graph interfaces. 

## Backwards Compatibility
<!-- }
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright. { -->
N/A

## Test Cases
<!-- }
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable. { -->
To be done, once a reference implementation is in place.

## Implementation
<!-- }
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details. { -->

To be done. A simple reference implementation covering simple scenarios will help adoption.


## Security Considerations
<!-- }
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers. { -->
As discussed in previous sections, effort must be put to make the purpose of the interfaces clear enough, limiting to network-of-value use-cases and discouraging anti-patterns.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

<!-- }
Also, While the aim of an Ethereum blockchain is to offer a global vision, tamper-proof of the shared state, any interaction with the "Outside World" will soon trigger the necessity of local-aware data that can be modeled as graph. A decentralized type system like dType can profit from a dynamic graph system where data-compatible "neighbours" can be plugged/un-plugged. A DAO entity can profit from having data available like graphs. Any transitive relationship amongst entities can also profit from a graph "aware" vision (transitive package dependencies in tooling systems, security delegation patterns, ...).
-->
