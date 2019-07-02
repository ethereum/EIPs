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

We propose a registry to store data and hashes for a limited period of time. This lets another smart contract find the data (alongside its timestamp) after the origin contract has disappeared. We envision the data registry will be used to record logs of on-chain events which is useful for accountable watching services. Given a signed receipt and the on-chain event logs, a client can use this as indisputable proof a third party watching service has failed to respond on their behalf and thus hold them financially accountable. 
As well, we envision a central data registry is useful for cross-smart contract communication such that a future contract can *subscribe* and watch for logs from other smart contracts. 
Again, it is crucial the logs are only kept around for a limited period of time, to avoid bloating the Ethereum state, thus the motivation for a DataRegistry with a simple API. 

## High-level overview

We can modify an existing smart contract *sc* to log important events in the DataRegistry.

The API is simple:
 * **Store Record** A smart contract can store data using dataregsitry.setRecord(id, bytes), where *id* is an identifier for the record.
 * **Fetch Record** Another smart contract can look up the data using dataregistry.fetchRecord(datashard, sc, id, index).
 * **Store Hash** A smart contract can post the data using dataregistry.setHash(id, bytes), where *id* is an identifier for the record and only its hash is stored. 
 * **Fetch Hash** Another smart contract can simply fetch the hash using dataregistry.fetchRecord(datashard, sc, id, index) to confirm the data was indeed stored. 
 
In practice-- we assume there will be two DataShard which is responsible for storing the data/records. The DataRegistry will rotate which DataShard is used to store data based on a fixed interval (i.e. every week a new data shard is used). When we re-visit a DataShard for storing data--we can simply delete and re-create the it. This lets us guarantee that data will be kept by the registry for a minimum period of time *INTERVAL* and eventually it will be discarded when the DataShard is reset. 

Inside a DataShard: 

All records are stored based on the mapping:

 * address -> uint[] -> bytes[]
 * sc -> id[] -> data[]

All hashes are stored based on the mapping: 
 * address -> uint[] -> bytes32[] 
 * sc -> id[] -> hashes[]
 
The smart contract *sc* that sends data to the DataRegistry is responsible for selecting an identifier *id*. For example, this is useful if a single smart contract manages hundreds of off-chain payment channels as each channel can have its own unique identifier.

All new data for an *id* is simply appended to the list *bytes[]*. We recommend all data is encoded (i.e. abi.encode) to permit for a simple API. (We repeat this process for storing hashes)

Given the smart contract address *sc*, the datashard *datashard* and an identifier *id*, any other smart contract on Ethereum can fetch records from the registry.


## Specification

**NOTES**:
 - The following specifications use syntax from Solidity `0.5.0` (or above)


## No signatures
This standard does not require any signatures. It is only concerned with storing data on behalf of smart contracts.

## DataRegistry -- READ THIS IF YOU CARE ABOUT USING IT 

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

#### setRecord (data)

``` js
function setRecord(uint _id, bytes memory _data) public;
```
Store the data record and emits the event:

``` js
emit NewRecord(uint datashard, address sc, uint id, uint index, bytes data)
```

The data recorded is listed according to *msg_sender* and the data is appended to corresponding list. The record will be stored in the *datashard* at *index* in the list. 

#### fetchRecords (data)

``` js
function fetchRecords(uint _datashard, address _sc, uint _id) public returns (bytes[] memory)
```

Fetches the list of data records for a given smart contract. The *_datashard* informs the DataRegistry which DataShard to use when fetching the records.

``` js
function fetchRecord(uint _datashard, address _sc, uint _id, uint _index) public returns (bytes memory)
```

Returns a single data record. Note the smart contract will return an empty record if the *_index* is out of bounds. It will NOT throw an exception and revert the transaction. Again, it requires the *_datashard* to inform the DataRegistry which DataShard to use when fetching the records. 


#### Storing a Record Hash

``` js
function setHash(address _sc, uint _id, bytes memory _data) onlyOwner public
```

Stores a hash of the data and emits the event: 

``` js
event NewHash(uint datashard, address sc, uint id, uint index, bytes data, bytes32 h)
```

As mentioned previously, the *datashard* and *index* can be used later to fetch the data. 

#### Fetching a Record Hash

``` js
function fetchHash(address _datashard, address _sc, uint _id, uint _index) onlyOwner public view returns(bytes32) {
```

Given the data shard *_datashard*, a smart contract address *_sc*, the unique identifier *_id* and the *_index*, it will return the hash. If the request is out-of-bands, then it just returns an empty byte32.

``` js
function fetchHashes(uint _datashard, address _sc, uint _id) onlyOwner public view returns(byte32[] memory) {
```
Given the data shard *_datashard*, a smart contract address *_sc* and the unique identifier *_id*, it returns the entire list of hashes. 

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

## DataShard -- READ THIS IF YOU CARE HOW THE DATA SHARDS WORK UNDER THE HOOD

Each DataShard has a minimum life-span and it stores a list of data records. All functions can ONLY be executed by the owner of this contract - which should be the DataRegistry.


#### Storing a Record (data)

``` js
function setRecord(address _sc, uint _id, bytes memory _data) onlyOwner public {
```

DataShard has a mapping to link a contract address to a list of data items. This appends a new data item to the list.


#### Fetching Records (data)

``` js
function fetchRecord(address _sc, uint _id, uint _index) onlyOwner public view returns(bytes memory) {
```

Given a smart contract address, returns a single data record at index *_index*. If the request is out-of-bounds, it just returns an empty bytes.

``` js
function fetchRecords(address _sc, uint _id) onlyOwner public view returns(bytes[] memory) {
```
Returns the entire list *bytes[]* for the smart contract and the respective ID.

#### Storing a Record Hash

``` js
function setHash(address _sc, uint _id, bytes memory _data) onlyOwner public {
```
Given a data shard and a unique identifier, it will emit an event with the *_data* before appending its hash to a list. 


#### Fetching a Record Hash

``` js
function fetchHash(address _sc, uint _id, uint _index) onlyOwner public view returns(bytes32) {
```

Given a smart contract address, the unique identifier *_id* and the *_index*, it will return the hash. If the request is out-of-bands, then it just returns an empty byte32.

``` js
function fetchHashes(address _sc, uint _id) onlyOwner public view returns(byte32[] memory) {
```
Given a smart contract address and the unique identifier *_id*, it returns the entire list of hashes. 

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
