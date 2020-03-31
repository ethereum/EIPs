---
eip: 2579
title: Merkle Tree Generalized Index
author: naxe (ngmachado @LogicB0x)
discussions-to: https://ethereum-magicians.org/t/merkle-tree-generalized-index/4162/
status: Draft
type: Standards Track
category: ERC
created: 2020-03-31
---

## Simple Summary

Using a Merkle Tree with a Generalized Index coordination system as used in other systems with the necessary adaptation to a smart contract environment, reducing the computation requirement and storage space.

## Motivation

Bring the capacity to the developer community to implement a selective proof or multi proof system “as a service” in the form of a library, helping the intercommunication between different ecosystems in Ethereum space by using the same library to process profs.

## Specification

### Definitions:

#### The tree must have the following properties:

The tree is defined as a Full Complete Binary Tree.

There is a one-way function that is easy to compute, but difficult to invert, ```hash(x)```.

For each node and leaves, there is a unique positive integer called generalized index, ```gi```.

The index is attributed for each node from top to bottom, left to right so that parent generalized index, ```parent=⌊(gi-1) / 2⌋ ```, left child ```left = 2gi + 1```,  right child ```right = 2gi + 2``` is computable to all cases.

Each node is composed of the hash of the two immediate children by, ```node = hash (hash( left child ) || hash( right child))```

Each leaf is composed of the hash of some proof such that  ```leaf = hash(proof)```.

Each leaf there is a sibling leaf, sibling = hash(proof), such that parent node can be computed as ```parent = hash(leaf || sibling)```

#### Attribution of index:

Starting at 0 from the root node, increment by 1 for each subnode found, following the direction top to bottom and left to right.
```
     1   
  2     3
4  5   6  7
     ...
```

The set of indexes are grouped in opposition of attribution, **bottom up, left to right**.

We called this set the Generalized Index Operation Order ```giop```.

#### Construction of proof:

Each node or leaf are given in the form of ```hash(proof)```.

For each verifier path is given the leaf and also the sibling leaf.

For each pair of leaf and sibling is given the generalized index that must be of the leaf and not the sibling.

For each tree path not in the construction proof set, is given the additional authentication information that minimizes the computation.

#### Reserved Word

All words are accepted with the exception of ```hash(0)```, called **BLANK POINT**.


#### Library

It defines within the library a structure of data that serves as a placeholder to computation results that are needed to reconstruct the tree.
```solidity
struct Data {
        mapping(uint256 => bytes32) ram;
    }
```

After all computations are completed, this information can be discarded.


The library as only one public function defined as:
``` solidity
function getRoot(Data storage self,  bytes32[] memory nodes,  uint256[] memory giop) public returns(bytes32)
```
| Argument  |  Description  |
| ----------| ------------------- |
| Data self |  Placeholder for computations results |
| Bytes32[] nodes | leaves and interceptions node information. Leaves and nodes are splitted with the BLANK POINT|
| uint256[] giop | Generalized Index information about given proofs and nodes |


| Return | Description |
| -------|-------------|
| bytes32 | Computed root of the tree |


## Rationale
Passing each leaf and node with adicional information about the position within the tree we can compute more efficient bigger trees.

The possibility of having one root that represents a multi proof system as we can discretionary select which proof we want to include. By using the same code base we can focus on the usage of the proof system and not with the implementation.

Is also important to notice that the usage of community libraries are residual in the space leading to a duplication of efforts solving the same problem many times.

## Backwards Compatibility

No backwards compatibility issues.

## Test Cases

TBD

## Implementations

Please refer to : [Gitlab](https://gitlab.com/ngmachado/MerkleTreeMultiProofs)

## Security Considerations

TBD

## References

[Merkle Tree](http://people.eecs.berkeley.edu/~raluca/cs261-f15/readings/merkle.pdf)
[Generalized Merkle Tree Index](https://github.com/ethereum/eth2.0-specs/blob/2787fea5feb8d5977ebee7c578c5d835cff6dc21/specs/light_client/merkle_proofs.md#generalized-merkle-tree-index)
[ERC 2429](https://gitlab.com/status-im/docs/EIPs/blob/secret-multisig-recovery/EIPS/eip-2429.md)


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
