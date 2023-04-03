#!/usr/bin/env python3
import pytest
import yaml
from dataclasses import dataclass
from deposit_snapshot import DepositTree,DepositTreeSnapshot
from eip_4881 import DepositData,DEPOSIT_CONTRACT_DEPTH,Eth1Data,Hash32,sha256,uint64,zerohashes

@dataclass
class DepositTestCase:
    deposit_data: DepositData
    deposit_data_root: Hash32
    eth1_data: Eth1Data
    block_height: uint64
    snapshot: DepositTreeSnapshot

def get_hex(some_bytes) -> str:
    return "0x{}".format(some_bytes.hex())

def get_bytes(hexstr) -> bytes:
    return bytes.fromhex(hexstr.replace("0x",""))

def read_test_cases(filename):
    with open(filename, "r") as file:
        try:
            test_cases = yaml.safe_load(file)
            result = []
            for test_case in test_cases:
                deposit_data = DepositData(
                    get_bytes(test_case['deposit_data']['pubkey']),
                    get_bytes(test_case['deposit_data']['withdrawal_credentials']),
                    int(test_case['deposit_data']['amount']),
                    get_bytes(test_case['deposit_data']['signature'])
                )
                eth1_data = Eth1Data(
                    get_bytes(test_case['eth1_data']['deposit_root']),
                    int(test_case['eth1_data']['deposit_count']),
                    get_bytes(test_case['eth1_data']['block_hash'])
                )
                finalized = []
                for block_hash in test_case['snapshot']['finalized']:
                    finalized.append(get_bytes(block_hash))
                snapshot = DepositTreeSnapshot(
                    finalized,
                    get_bytes(test_case['snapshot']['deposit_root']),
                    int(test_case['snapshot']['deposit_count']),
                    get_bytes(test_case['snapshot']['execution_block_hash']),
                    int(test_case['snapshot']['execution_block_height'])
                )
                result.append(DepositTestCase(
                    deposit_data,
                    get_bytes(test_case['deposit_data_root']),
                    eth1_data,
                    int(test_case['block_height']),
                    snapshot
                ))
            return result
        except yaml.YAMLError as exc:
            print(exc)
            assert(False)

def merkle_root_from_branch(leaf, branch, index) -> Hash32:
    root = leaf
    for (i, leaf) in enumerate(branch):
        ith_bit = (index >> i) & 0x1
        if ith_bit == 1:
            root = sha256(leaf + root)
        else:
            root = sha256(root + leaf)
    return root

def check_proof(tree, index):
    leaf, proof = tree.get_proof(index)
    calc_root = merkle_root_from_branch(leaf, proof, index)
    assert(calc_root == tree.get_root())

def compare_proof(tree1, tree2, index):
    assert(tree1.get_root() == tree2.get_root())
    check_proof(tree1, index)
    check_proof(tree2, index)

def clone_from_snapshot(snapshot, test_cases):
    copy = DepositTree.from_snapshot(snapshot)
    for case in test_cases:
        copy.push_leaf(case.deposit_data_root)
    return copy

def test_instantiate():
    DepositTree.new()

def test_empty_root():
    empty = DepositTree.new()
    assert(
        empty.get_root() ==
        bytes.fromhex(
            "d70a234731285c6804c2a4f56711ddb8c82c99740f207854891028af34e27e5e"
        )
    )

def test_deposit_cases():
    tree = DepositTree.new()
    test_cases = read_test_cases("test_cases.yaml")
    for case in test_cases:
        tree.push_leaf(case.deposit_data_root)
        expected = case.eth1_data.deposit_root
        assert(case.snapshot.calculate_root() == expected)
        assert(tree.get_root() == expected)

def test_finalization():
    tree = DepositTree.new()
    test_cases = read_test_cases("test_cases.yaml")[:128] # only need subset
    for case in test_cases:
        tree.push_leaf(case.deposit_data_root)
    original_root = tree.get_root()
    assert(original_root == test_cases[127].eth1_data.deposit_root)
    tree.finalize(test_cases[100].eth1_data, test_cases[100].block_height)
    # ensure finalization doesn't change root
    assert(tree.get_root() == original_root)
    snapshot = tree.get_snapshot()
    assert(snapshot == test_cases[100].snapshot)
    # create a copy of the tree from a snapshot by replaying
    # the deposits after the finalized deposit
    copy = clone_from_snapshot(snapshot, test_cases[101:128])
    # ensure original and copy have the same root
    assert(tree.get_root() == copy.get_root())
    # finalize original again to check double finalization
    tree.finalize(test_cases[105].eth1_data, test_cases[105].block_height)
    # root should still be the same
    assert(tree.get_root() == original_root)
    # create a copy of the tree by taking a snapshot again
    copy = clone_from_snapshot(tree.get_snapshot(), test_cases[106:128])
    # create a copy of the tree by replaying ALL deposits from nothing
    full_tree_copy = DepositTree.new()
    for case in test_cases:
        full_tree_copy.push_leaf(case.deposit_data_root)
    # ensure the proofs are the same and valid for each tree
    for index in range(106, 128):
        compare_proof(tree, copy, index)
        compare_proof(tree, full_tree_copy, index)

def test_snapshot_cases():
    tree = DepositTree.new()
    test_cases = read_test_cases("test_cases.yaml")
    for case in test_cases:
        tree.push_leaf(case.deposit_data_root)

    for case in test_cases:
        tree.finalize(case.eth1_data, case.block_height)
        assert(tree.get_snapshot() == case.snapshot)

def test_empty_tree_snapshot():
    with pytest.raises(AssertionError):
        # can't get snapshot from tree that hasn't been finalized
        snapshot = DepositTree.new().get_snapshot()

def test_invalid_snapshot():
    with pytest.raises(AssertionError):
        # invalid snapshot (deposit root doesn't match)
        invalid_snapshot = DepositTreeSnapshot([], zerohashes[0], 0, zerohashes[0], 0)
        tree = DepositTree.from_snapshot(invalid_snapshot)

