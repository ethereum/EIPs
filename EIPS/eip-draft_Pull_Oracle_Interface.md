---
eip: xxxx
title: Pull Oracle Interface
author: Alliance of Decentralized Oracles (l.loya.b@gmail.com)
discussions-to: https://github.com/ethereum/EIPs/issues/
status: DRAFT
type: Standards Track
category: ERC
created: 2019-11-06
---

## Simple Summary

A standard interface for numeric pull oracles.

## Abstract

In order for ethereum smart contracts to interact with off-chain systems, oracles must be used. These oracles report values which are normally off-chain, allowing smart contracts to react to the state of off-chain systems. A standard interface for oracles is described here, allowing different oracle implementations to be interchangeable and lead to increased security for customers.  

## Motivation

As the value held by smart contracts that rely on off-chain data to execute grows, the security of oracles systems and the ability of these to be interchangeable and implemented in groups will grow in importance. 

The Ethereum ecosystem currently has many different oracle implementations available, but they do not provide a unified interface. Smart contract systems would be locked into a single set of oracle implementations, or they would require developers to write adapters/ports specific to the oracle system chosen in a given project.


## Background
EIP 1154, for standardizing an oracle interface, was not widely adopted and abandoned as too early and specificaly too broad/general to provide any efficiency gains. This new proposal is a cooperation between current oracle systems and direct users of these. The specification below reflects this collaboration and addresses the main reason why 1154 was not successful.

Link:  https://eips.ethereum.org/EIPS/eip-1154

#### EIP 1154 summary:
EIP 1154 prescribed two functions for pulling(resultFor) and pushing(receiveResult) data where the customer would pull data or the oracle provider would push data to the customer contract. Both functions specified inputs and results as bytes data (bytes32 and bytes) and had a conversion cost associated with them that was deemed insignificant through testing within the EIP discussion. More information available here: 

Proposal: https://eips.ethereum.org/EIPS/eip-1154
Discussion: https://github.com/ethereum/EIPs/issues/1161
 
EIP 1154 Conclusion: Standard not adopted
“It seems wasteful to specify something only to force proprietary interpretions of data on oracles anyway, and have silly things like putting ABI encoded stuff in data only to unwrap it and reinterpret it before putting it in a different format. At that point, just have the proprietary endpoint and use plain function calls.” Alan Lu (https://github.com/ethereum/EIPs/issues/1161#issuecomment-512535316) 
 

## Specification

In general there are two different types of oracles, push and pull oracles. Where push oracles are expected to send back a response to the consumer and pull oracles allow consumers to pull or call/read the data onto their own systems. This specification is for pull based oracles only.


Definitions


<dl>
<dt>Oracle</dt>
<dd>An entity which reports data to the blockchain and it can be any Ethereum account.</dd>
<dt>Oracle consumer</dt>
<dd>A smart contract which receives or reads data from an oracle.</dd>
<dt>ID</dt>
<dd>A way of indexing the data which an oracle reports. May be derived from or tied to a question for which the data provides the answer.</dd>
<dt>Result</dt>
<dd>Data associated with an id which is reported by an oracle. This data oftentimes will be the answer to a question tied to the id. Other equivalent terms that have been used include: answer, data, outcome.</dd>
<dt>Report</dt>
<dd>A pair (ID, result) which an oracle sends to an oracle consumer.</dd>
</dl>


### Pull-based Interface

The pull-based interface specs:

```solidity
interface Oracle {
function resultFor(bytes32 id) external view returns (uint timestamp, int outcome, int status);
function resultFor(bytes32 id) external view returns (uint timestamp,uint outcome, uint status);
function resultFor(bytes32 id) external view returns (uint timestamp, uint[] outcome, uint[] status);
function resultFor(bytes32 id) external view returns (uint timestamp, bytes32 outcome, uint status);
}
```

`resultFor` MUST revert if the result for an `id` is not available yet.
`resultFor` MUST return the same result for an `id` after that result is available.

```solidity
contract OracleIDDescriptions {
Bytes32 public id;
String public description;
Mapping(bytes32 =>string) BytesToString;
Mapping(string=>bytes32) StringToBytes;
function defineBytes32ID (bytes32 _id, string _description) external;
function whatIsBytes32ID (bytes32 _id) public returns(string _description);
function whatIsStringID (string _description) public returns(bytes32 _id);
}
```

## Rationale
Currently deployed contracts require oracles and individual companies to build specific adapters for each implementation. Future builds by both oracle adapters and new companies can create a world where oracles are interchangeable.  Diversity in oracle technology paired with oracle implementations being interchangeable can drastically increase security of oracle consumers since attacks on oracles can be minimized by projects utilizing multiple oracles in their design (averages, medians, etc.). 


#### Multiple Oracle Consumers

Oracle consumers can choose as many oracles as they wish and mix and match the types based on their needs (e.i. Average value from several oracles e.g. Compound’s and Maker’s open oracle designs).



#### Result Immutability

In the proposed specifications, oracle consumers determine when results are immutable once they use the value to execute and finalize a transaction. However, the use of multiple oracles and a dispute period is highly recommended for the oracle consumers to increase security since finality of a value can be affected by an oracle attack but as with any attack on chain, it becomes extremely expensive to attack over time and eventually “good/correct” values will make it on-chain. 


For data which mutates over time, the `id` field may be structured to specify "what" and "when" for the data (using 128 bits to specify "when" is still safe for many millennia).

## Implementation

* [Tidbit](https://github.com/levelkdev/tidbit) tracks this EIP.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).






