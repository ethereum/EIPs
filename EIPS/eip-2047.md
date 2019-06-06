---
eip: ??
title: Temporary Data Persistence (DataRegistry)
author:
type: Standards Track
category: ERC
status: Draft
created: 2019-06-03
---

## Abstract

We propose a registry to store data for a limited period of time. The motivation is to let another smart contract find the data (and check its timestamp) after the origin contract has disappeared.
We envision the data registry will be used to record on-chain dispute logs for off-chain channels.
Given a signed receipt and the dispute logs, the client can use this as indisputable proof a third party watching service has cheated and thus hold them financially accountable.
However we envision that a central data registry will be useful for cross-smart contract communication and for extending accountable watching services to support several applications in the Ethereum eco-system.

## High-level overview

We can modify an existing smart contract *sc* to log important events in the DataRegistry.

The API is simple:
 * **Store Data** A smart contract can store data using dataregsitry.setData(id, bytes), where *id* is an identifier for the record
 * **Fetch Data** Another smart contract can look up the data using dataregistry.fetchRecord(datashard, sc, id, index).

To enforce temporary data persistence, there may be two or more DataShards. The DataRegistry will rotate which DataShard is used to store data based on a fixed interval (i.e. every week a new datashard is used). This lets us delete and re-create the DataShard when it is selected to store new data. Thus it lets us guarantee that data will remain in the registry for a minimum period of time *INTERVAL* and eventually it will be discarded when the DataShard is reset.

Inside a DataShard, all data is stored based on the mapping:

 * address -> uint[] -> bytes[]
 * sc -> id[] -> data[]

The smart contract *sc* that sends data to the DataRegistry is responsible for selecting an identifier *id*. For example, this is useful if a single smart contract manages hundreds of channels as each channel can have its own unique identifier.

All new data for an *id* is simply appended to the list *bytes[]*. We recommend all data is encoded (i.e. abi.encode) to permit for a simple API.

Given the smart contract address *sc*, the datashard *datashard* and an identifier *id*, any other smart contract on Ethereum can fetch records from the registry.


## Specification

**NOTES**:
 - The following specifications use syntax from Solidity `0.5.0` (or above)


## No signatures
This standard does not require any signatures. It is only concerned with storing data on behalf of smart contracts.

## DataRegistry

The DataRegistry is responsible for maintaining a list of DataShards. Each DataShard maintains a list of encoded bytes for a list of smart contracts. All DataShards have the same life-span (i.e. 1 day, 2 weeks, etc). It is eventually reset by self-destructing and re-creating the data shard after its life-span.

#### Total Data Shards

``` js
uint constant INTERVAL;
uint constant TOTAL_SHARDS;
```

Every DataShard has a life-span of *INTERVAL* and there is a total of *TOTAL_SHARDS* in the smart contract. After each interval, the next data shard can be created by the data registry. When we re-visit an existing shard, the data registry will destory and re-create it.

#### Uniquely identifying stored data

All data is stored according to the format:

``` js
uint _datashard, address _sc, uint _id, uint _index;
```

A brief overview: `

* **_datashard** - Index for the DataShard that stores the relevant data.

* **_sc** - Smart contract's address that stored data in the registry.

* **_id** - An application-specific identifier to index data in the registry.

* **_index** - *[optional]* All data is stored as *bytes[]*. The *_index* lets us look up one element in the list. If *_index* is not supplied, then the entire array is returned.

#### Computing the unique identifier for a data record

How the smart contract computes *_id*  is application-specific. For off-chain protocols, we'll propose a future EIP (or SCIP) to standardise the process.

#### setData

``` js
function setData(uint _id, bytes memory _data) public;
```

Store the encoded data and emits the event:

``` js
emit NewRecord(uint datashard, address sc, uint id, uint index, bytes data)
```
As mentioned previously, the data recorded is listed according to *msg_sender* and the data is appended to corresponding list.

#### fetchRecords

``` js
function fetchRecords(uint _datashard, address _sc, uint _id) public returns (bytes[] memory)
```

Fetches the list of data records for a given smart contract. The *_datashard* informs the DataRegistry which DataShard to use when fetching the records.

``` js
function fetchRecord(uint _datashard, address _sc, uint _id, uint _index) public returns (bytes memory)
```

Returns a single data record according to the index. Note the smart contract will return an empty record if the *_index* is out of bounds. It will NOT throw an exception and revert the transaction.

#### getDataShardIndex

``` js
function getDataShardIndex(uint _timestamp) public returns (uint8)
```
Given a timestamp, it will return the index for a data shard. This ranges from 0 to TOTAL_DAYS.

#### getDataShardAddress

``` js
function getDataShardAddress(uint _timestamp) public returns (address)
```

Given a timestamp information, this will return the address for a DataShard.

## DataShard

Each DataShard has a minimum life-span and it stores a list of data records. All functions can ONLY be executed by the owner of this contract - which should be the DataRegistry.


#### Storing data

``` js
function setData(address _sc, uint _id, bytes memory _data) onlyOwner public {
```


DataShard has a mapping to link a contract address to a list of data items. This appends a new data item to the list.


#### Fetch Data

``` js
function fetchItem(address _sc, uint _id, uint _index) onlyOwner public view returns(bytes memory) {
```
Given a smart contract address, returns a single data item at index *_index*. If the request is out-of-bounds, it just returns an empty bytes.

``` js
function fetchList(address _sc, uint _id) onlyOwner public view returns(bytes[] memory) {
```
Returns the entire list *bytes[]* for the smart contract and the respective ID.

#### kill
``` js
function kill() onlyOwner public {
```

This kills the DataShard. It is only callable by the DataRegistry contract. This is used to let us destroy mapping records.

## Implementation

There is a single implementation by PISA Research Limited.

#### Example implementation of DataRegistry and an example contract
- [Data Registry] https://github.com/PISAresearch/pisa/blob/master/sol/contracts/DataRegistry.sol
- [Challenge Contract] https://github.com/PISAresearch/pisa/blob/master/sol/contracts/ChallengeCommandContract.sol


## History

Historical links related to this standard:

- PISA Paper https://www.cs.cornell.edu/~iddo/pisa.pdf


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
