---
eip: TBD
title: Automatically Reset Tesnet
description: Testnet network that periodically rolls back to genesis
author: Mário Havel (@taxmeifyoucan), pk910 (@pk910), Rémy Roy (@remyroy)
discussions-to: 
status: Draft
type: Standards Track
category: Core
created: 2023-04-10
---

## Abstract

This EIP proposes a specification for an automatically reset testnet, a novel approach to testnets which can be implemented within Ethereum clients. It enables a single testing infrastructure consisting of ephemeral networks with deterministic parameters. Each network iteration is created by a specified function which deterministically generates genesis states.

## Motivation

This kind of testnet can provide an alternative environment for short-term testing of applications, validators and also breaking changes in client implementations. It avoids issues of long running testnets which suffer from state bloat, lack of testnet funds or consensus issues. Periodically resetting the network back to genesis cleans the validator set, returns funds back to faucets while keeping the network reasonably small for easy bootstraping. 

## Specification

The testnet is set to always reset after a predefined time period. The reset means generating next genesis and starting new network. This is possible by introducing functions for the genesis generation and the client reset.

### Genesis 

To connect to the current instance of the network, client must implement the genesis function. This function defines how the client stores information about the testnet and generates the current genesis. With each reset, network starts from a new genesis which needs to be build based on given parameters and correspond in EL and CL clients. 

The network always starts from a genesis which is deterministically created based on the original one, `genesis 0`. Expiration of the genesis is given by its `MIN_GENESIS_TIME` and `period` (a predefined constant, length of time a single ephemeral network runs). Therfore once timestamp reaches the terminal time of ephemeral network, it has to switch to a new genesis. The main changes in the genesis iteration are chainId, timestamp and the withdrawal credentials of the first validator. 

Clients shall include a hardcoded `genesis 0`, similarly to other predefined networks. But this genesis is only used at the very beginning of the testnet existence, in its first iteration `0`. Later on, with iteration `1` and further, client does not initialize this genesis but uses it to derive the current one. Given a known `period` and current timestamp, client can always calculate the number of lifecycle iterations from `genesis 0` and create a new genesis with latest parameters. 

When the client starts with the option of ephemeral testnet, it checks whether a genesis for the network is present. If it doesn't exist or the current genesis timestamp is older than `genesis_timestamp + period`, it triggers the generation of a new genesis. This new genesis, derived from the `genesis 0`, will be written to the database and used to run the current network.

#### Execution client

* Number of iterations:
    *  `i` = `int((latest_timestamp` - `genesis_0.timestamp) / period)`
* Timestamp of current genesis:
    * `genesis_timestamp` = `period` * `i` + `genesis_0.timestamp`
* Current EL ChainId:
    * `chainId` = `genesis_0.chainId` + `i`

#### Consensus client

Genesis generation in CL client uses the same parameters as EL but also requires to generate updated genesis state ssz with minor changes. 

The genesis state includes a deposit contract ready to launch a merged network with the validator set created by trusted entities within community. 
In order to keep the `ForkVersions` of the network static for better tooling support, the withdrawal credentials of the first validator in the validator set need to be overridden by a calculated value (this way there is still a unique `ForkDigest` for each iteration).
* `genesis.validators[0].withdrawal_credentials` = `0x0100000000000000000000000000000000000000000000000000000000000000` + `i`
* `genesis.genesis_validators_root` =  `hash_tree_root(genesis.validators)`

The change of `genesis.validators[0]` creates a new genesis state, therfore clients has to be able to generate it. `genesis_validators_root` is normally hardcoded in the client but in this case, it needs to be computed. Generating the genesis in ssz format might be missing feature in some clients and potentially break current architecture. For example light clients which are relying on hardcoded `genesis_validators_root` will break. 

`MIN_GENESIS_TIME` is set to the latest genesis timestamp and defines when the current period starts. It is recommended to add also a small `GENESIS_DELAY`, for example 15 minutes, to avoid issues while infrastructure is restarting with the new genesis. 

### Reset

The reset function defines an automatic process of throwing away the old data and starting with a new genesis. It depends on the previously defined function for genesis generation and client should implement it to automatically follow the latest network iteration. 

For the reset function, we can introduce `terminal_timestamp` value which marks when the network expires. It can be the same genesis timestamp of the next iteration or can be calculated simply as `terminal_timestamp = genesis_timestamp + period`. 

When the network reaches a slot with a timestamp `>= terminal_timestamp`: 

- Client stops accepting/creating new blocks
    - This should be implemented without further functions to create a minimal version which is safe from forks 
- Current genesis, all blockchain and beacon data are discarded 
- Client triggers Genesis function (defined above):
    - Like on regular client startup, if genesis is not present
    - New genesis is written into db and initialized
- After new genesis time is reached, network starts again from the new genesis

Clients should be able to do this without restarting, operating the network fully independently and with minimal downtime. This is necessary for infrastructure providers but redundant for users just joining the network for a short term testing. 

## Rationale

Ephemeral testnets with deterministic parameters and the same infrastracture provides a sustainable alernative to traditional testnets. At each reset, faucets are filled again so a lot of testnet ETH is available for contract or validator testing. 

The whole state with all contracts are purged which on one hand keeps the network small and easy to bootstrap but introduces problem for advanced testing of applications. Generally, using the network is recommended for short term testing, deploying `Hello World` kind of contracts which don't need to stay forever on a long term testnet. However, there can be an offchain mechanism which automatically deploys basic contract primitives after each reset so contract developers can also utilize the network more.

By defining two functions for Genesis and Reset, this EIP enables two levels of how a client implementation can support the testnet. 

* Basic support requires the client to determine the current network specs and enables only connecting to the network. 
    * This means support of the Genesis function
    * Enough to participate in the network for short term testing
    * To follow the latest iteration, the user has to manually shut down the client and delete the database
* Full support enables client which can also follow the reset process and always sync the latest chain iteration
    * This would require also support of the Reset feature
    * Needed for running infrastructure, genesis validators and bootnodes

The design is also compatible with nodes managed by external tooling, i.e. even if client doesn't implement these features, it can run on the same network as other nodes which are automatically reset by scripts.

### Constants and variables

Constants and variables defining testnet properties are arbitrary but need to be crafted minding certain limitations and security properties.

#### Reset Period 

Constant hardcoded in the client defining period of time after which network resets. 

It can be defined based on users' needs but for security reasons, it also depends on the number of validators in genesis. Considering the time to active a validator, the number of trusted validators should be high enough so the network cannot be overtaken by a malicious actor.
```
Genesis Validators => Epochs until < 66% majority
10k  => 1289 Epochs (5,7 days)
50k  => 6441 Epochs (28,6 days)
75k  => 9660 Epochs (42,9 days)
100k => 12877 Epochs (57,2 days)
150k => 19323 Epochs (85,9 days)
200k => 25764 Epochs (114,5 days)
```

#### ChainId 

ChainId is a variable because it needs to keep changing with each new genesis to avoid replay attack. The function for new ChainId value is a simple iteration (+1). The ChainId in `genesis 0` is hardcoded constant and network iterates it with new gensis. 

It shouldn't collide with any other existing EVM chain even after longer period of iterations. 

## Security Considerations

The network itself is providing a secure environment thanks to regular resets. Even if some sort of vulnerability is exploited, it will be cleared on the next reset. This is also reason why to keep periods relatively shorter (weeks/months opposed to months/years) with big enough genesis validator set to keep honest majority. 

Changes in clients caused by the implementation of features for resetting networks need to be reviewed with standard security procedures. Especially the mechanism for trigger reset which needs to be separated from other networks which are not configured as ephemeral. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
