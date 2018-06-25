---
eip: <to be assigned>
title: Merkle Airdrops
author: Richard Moore <me@ricmoo.com>, Nick Johnson <@arachnid>
type: Standards Track
category: ERC
status: Draft
created: 2018-06-24
---

## Simple Summary

A technique to provably allocate and claim tokens using Merkle trees.


## Abstract

A Merkle Airdrop is a technique to provide a provably pre-commited
list of tokens to a potentially large collection of accounts, with a
single, constant-time transaction by committing a root hash of a
merkle tree.


## Motivation

Currently, when a token issuer broadcasts tokens via an Airdrop, the
issuer creates hundreds of transactions, congesting the network,
consuming large portions of the block gas limit, increasing the gas
price and spending ether for the transactions.

In many cases the tokens given out in an airdrop are sent to accounts
which cannot spend the token; such as a contract with no means to
transfer out, private keys which have been lost or addresses which
have a balance, but do not have a coresponding private key. In these
cases, the transaction was completely wasteful.

A Merkle Airdop uses a single transaction to provide the root hash
of a Merkle-tree for validating issuance against. Each owner can then
issue a claim, providing a merkle proof of the entry.

This technique may be used for mapping accounts to token quantities
for ERC-20 tokens, or for mapping a token ID to an account owner
for ERC-721 tokens.

A key motivation for standardizing a method for Merkle Airdops and
for advertising the existance is allowing wallets, block explorers
and other tools to indicate to an account owner that tokens have
been made available for the account.


## Specification


### File Format

- We need a file format, which can store chunked merkle tree
- A root chunk file can store links to all the sub-chunks


### Discovery URL

- Should there be an on-chain registry? How do we keep it from being spammed?


### JavaScript Merkle-Proof Generation

See: [GitHub](https://github.com/ricmoo/ethers-airdrop/blob/master/index.js#L164)


### Solidity Merkle Tree Validation

```
function validateMerkleProof(uint256 index, bytes32 leafHash, bytes32 rootHash, bytes32[] merkleProof) pure returns (bool) {

    // Collapse the Merkle-proof
    bytes32 node = leafHash;
    uint256 path = index;
    for (uint i = 0; i < merkleProof.length; i++) {
        if ((path & 0x01) == 1) {
            node = keccak256(merkleProof[i], node);
        } else {
            node = keccak256(node, merkleProof[i]);
        }
        path /= 2;
    }
    
    // Check the resolved merkle proof matches our merkle root
    return (node == rootHash);
}
```

### Example of Marking an Index as Claimed

```
mapping (uint256 => uint256) _claimed;

// Returns true if the index is already claimed
function setIndexClaimed(uint256 index) returns (bool) {
    uint256 claimBlock = _claimed[index / 256];
    uint256 claimMask = (uint256(1) << uint256(index % 256));

    if((claimBlock & claimMask) != 0) { return true; }

    _claimed[index / 256] = claimBlock | claimMask;

    // Was unclaimed
    return false;
}
```

@TODO: Discuss the sorted [Merkle-proof validation](https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol#L5)
- Might be more expensive to mark claimed entries?


### General


```
contract Airdrop {
    // A Merkle Airdrop MUST have a rootHash
    bytes32 rootHash;

    // A Merkle Airdrop MUST have a URI to specify the root allocations
    // See File Format above
    string allocationURI;
}
```

### ERC-20: Commiting Balance Allocations

```
function claim(uint256 index, address owner, uint256 amount, bytes32[] merkleProof) {
    require(setIndexClaimed(index) == false);

    // See Security Considerations below
    bytes32 leaf = keccak256(index, owner, amount);

    require(validateMerkleProof, leaf, rootHash, merkleProof);

    // Perform allocation
    balances[owner] += amount;
    Transfer(0, owner, amount);
}
```

- Should contracts be allowed to restrict who can claim a token? If so,
how should the contract indicate the restriction. Perhaps, in these cases
a second method can be used for claiming (contract specific) and the claim
can just throw; wallets could detect this and realize there are tokens
available, but more work is necessary to claim them.


### ERC-721: Committing Token Allocation

```
function claim(uint256 index, uint256 tokenId, address owner, bytes32[] merkleProof) {
    require(owners[tokenId] == address(0));
    require(owner != address(0))

    // See Security Considerations below
    bytes32 leaf = keccak256(index, tokenId, owner);

    require(validateMerkleProof, leaf, rootHash, merkleProof);

    // Perform allocation
    owners[tokenId] = owner;
    Transfer(0, owner, tokenId);
}
```


### Security Considerations

- The method to encode leaves in the tree MUST be different than
encoding the intermediate nodes. For example, if the leaves simply
hash two entries, then an intermediate node could provide its two
children and claim ownership.
- Once a leaf is claimed, it MUST not be able to be claimed again
- For ERC-721 (and ilk), users should ensure the leaves do not
double-issue a token


### Other possibilities

- Tokens may also be subject to early-bird claims; is there some
generic way to specify conditions? Perhaps a constant method on
the contract that can be called?
- A token could also allow multiple root hashes, or for the roothash
to change over time;


## Implementation

This [Merkle Airdrop article](https://blog.ricmoo.com/merkle-air-drops-e6406945584d)
provides a working example, but this was pre-specification. Once we have a better
defined final draft, I will put together another example.


## Copyright 

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

