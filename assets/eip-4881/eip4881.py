#!/usr/bin/env python
from dataclasses import dataclass
from hashlib import sha256 as SHA256

DEPOSIT_CONTRACT_DEPTH = 32
Hash32 = bytes
Root = bytes
uint64 = int
BLSPubkey = bytes
Bytes32 = bytes
Gwei = uint64
BLSSignature = bytes

@dataclass
class DepositData:
    pubkey: BLSPubkey
    withdrawal_credentials: Bytes32
    amount: Gwei
    signature: BLSSignature

@dataclass
class Eth1Data:
    deposit_root: Root
    deposit_count: uint64
    block_hash: Hash32

def sha256(x) -> Hash32:
    return SHA256(x).digest()
def to_le_bytes(i: int) -> bytes:
    return i.to_bytes(32, byteorder='little')

zerohashes = [b'\x00' * 32]
for i in range(1, DEPOSIT_CONTRACT_DEPTH):
    zerohashes.append(sha256(zerohashes[i-1] + zerohashes[i-1]))

