#!/usr/bin/env python3
from __future__ import annotations
from typing import List, Union
from dataclasses import dataclass
from abc import ABC,abstractmethod
from eip4881 import DEPOSIT_CONTRACT_DEPTH,Hash32,sha256,to_le_bytes,zerohashes

@dataclass
class DepositTreeSnapshot:
    finalized: List[Hash32]
    deposits: uint64
    execution_block_hash: Hash32

@dataclass
class DepositTree:
    tree: MerkleTree
    mix_in_length: uint
    finalized_execution_block: Hash32
    def new() -> DepositTree:
        merkle = MerkleTree.create([], DEPOSIT_CONTRACT_DEPTH)
        return DepositTree(merkle, 0, zerohashes[0])
    def get_snapshot(self) -> DepositTreeSnapshot:
        # omitted check to ensure this DepositTree has been finalized before
        finalized = []
        deposits = self.tree.get_finalized(finalized)
        return DepositTreeSnapshot(finalized, deposits, self.finalized_execution_block)
    def from_snapshot(snapshot: DepositTreeSnapshot) -> DepositTree:
        # omitted snapshot validation checks
        tree = MerkleTree.from_snapshot_parts(
            snapshot.finalized, snapshot.deposits, DEPOSIT_CONTRACT_DEPTH)
        return DepositTree(tree, snapshot.deposits, snapshot.execution_block_hash)
    def finalize(self, eth1_data: Eth1Data):
        self.finalized_execution_block = eth1_data.block_hash
        self.tree.finalize(eth1_data.deposit_count, DEPOSIT_CONTRACT_DEPTH)
    def get_proof(self, index: uint) -> Union[Hash32, List[Hash32]]:
        # omitted check to ensure index > finalized deposit index
        leaf, proof = self.tree.generate_proof(index, DEPOSIT_CONTRACT_DEPTH)
        proof.append(to_le_bytes(self.mix_in_length))
        return leaf, proof
    def get_root(self) -> Hash32:
        return sha256(self.tree.get_root() + to_le_bytes(self.mix_in_length))
    def push_leaf(self, leaf: Hash32):
        self.mix_in_length += 1
        self.tree = self.tree.push_leaf(leaf, DEPOSIT_CONTRACT_DEPTH)

class MerkleTree():
    @abstractmethod
    def get_root(self) -> Hash32:
        pass
    @abstractmethod
    def is_full(self) -> bool:
        pass
    @abstractmethod
    def push_leaf(self, leaf: Hash32, level: uint) -> MerkleTree:
        pass
    @abstractmethod
    def finalize(self, deposits_to_finalize: uint, level: uint) -> MerkleTree:
        pass
    @abstractmethod
    def get_finalized(self, result: List[Hash32]) -> uint:
        # returns the number of finalized deposits in the tree
        # while populating result with the finalized hashes
        pass
    def create(leaves: List[Hash32], depth: uint) -> MerkleTree:
        if not(leaves):
            return Zero(depth)
        if not(depth):
            return Leaf(leaves[0])
        split = min(2**(depth - 1), len(leaves))
        left = MerkleTree.create(leaves[0:split], depth - 1)
        right = MerkleTree.create(leaves[split:], depth - 1)
        return Node(left, right)
    def from_snapshot_parts(finalized: List[Hash32], deposits: uint, level: uint) -> MerkleTree:
        if not(finalized) or not(deposits):
            # empty tree
            return Zero(level)
        if deposits == 2**level:
            return Finalized(deposits, finalized[0])
        left_subtree = 2**(level - 1)
        if deposits <= left_subtree:
            left = MerkleTree.from_snapshot_parts(finalized, deposits, level - 1)
            right = Zero(level - 1)
            return Node(left, right)
        else:
            left = Finalized(left_subtree, finalized[0])
            right = MerkleTree.from_snapshot_parts(finalized[1:], deposits - left_subtree, level - 1)
            return Node(left, right)
    def generate_proof(self, index: uint, depth: uint) -> Union[Hash32, List[Hash32]]:
        proof = []
        node = self
        while depth > 0:
            ith_bit = (index >> (depth - 1)) & 0x1
            if ith_bit == 1:
                proof.append(node.left.get_root())
                node = node.right
            else:
                proof.append(node.right.get_root())
                node = node.left
            depth -= 1
        proof.reverse()
        return node.get_root(), proof

@dataclass
class Finalized(MerkleTree):
    deposits: uint
    hash: Hash32
    def get_root(self) -> Hash32:
        return self.hash
    def is_full(self) -> bool:
        return True
    def finalize(self, deposits_to_finalize: uint, level: uint) -> MerkleTree:
        return self
    def get_finalized(self, result: List[Hash32]) -> uint:
        result.append(self.hash)
        return self.deposits

@dataclass
class Leaf(MerkleTree):
    hash: Hash32
    def get_root(self) -> Hash32:
        return self.hash
    def is_full(self) -> bool:
        return True
    def finalize(self, deposits_to_finalize: uint, level: uint) -> MerkleTree:
        return Finalized(1, self.hash)
    def get_finalized(self, result: List[Hash32]) -> uint:
        return 0

@dataclass
class Node(MerkleTree):
    left: MerkleTree
    right: MerkleTree
    def get_root(self) -> Hash32:
        return sha256(self.left.get_root() + self.right.get_root())
    def is_full(self) -> bool:
        return self.right.is_full()
    def push_leaf(self, leaf: Hash32, level: uint) -> MerkleTree:
        if not(self.left.is_full()):
            self.left = self.left.push_leaf(leaf, level - 1)
        else:
            self.right = self.right.push_leaf(leaf, level - 1)
        return self
    def finalize(self, deposits_to_finalize: uint, level: uint) -> MerkleTree:
        deposits = 2**level
        if deposits <= deposits_to_finalize:
            return Finalized(deposits, self.get_root())
        self.left = self.left.finalize(deposits_to_finalize, level - 1)
        if deposits_to_finalize > deposits / 2:
            remaining = deposits_to_finalize - deposits / 2
            self.right = self.right.finalize(remaining, level - 1)
        return self
    def get_finalized(self, result: List[Hash32]) -> uint:
        return self.left.get_finalized(result) + self.right.get_finalized(result)

@dataclass
class Zero(MerkleTree):
    n: uint64
    def get_root(self) -> Hash32:
        if self.n == DEPOSIT_CONTRACT_DEPTH:
            # Handle the entirely empty tree case. This is included for
            # consistency/clarity as the zerohashes array is typically
            # only defined from 0 to DEPOSIT_CONTRACT_DEPTH - 1.
            return sha256(zerohashes[self.n - 1] + zerohashes[self.n - 1])
        return zerohashes[self.n]
    def is_full(self) -> bool:
        return False
    def push_leaf(self, leaf: Hash32, level: uint) -> MerkleTree:
        return MerkleTree.create([leaf], level)
    def get_finalized(self, result: List[Hash32]) -> uint:
        return 0


