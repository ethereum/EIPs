---
eip: 7928
title: Block-Level Access Lists
description: Enforced block access lists with storage locations and state diffs
author: Toni Wahrstätter (@nerolation), Dankrad Feist (@dankrad), Francesco D`Amato (@fradamt), Jochem Brouwer (@jochem-brouwer), Ignacio Hagopian (@jsign)
discussions-to: https://ethereum-magicians.org/t/eip-7928-block-level-access-lists/23337
status: Draft
type: Standards Track
category: Core
created: 2025-03-31
---

## Abstract

This EIP introduces Block-Level Access Lists (BALs) that record all accounts and storage locations accessed during block execution, along with their post-execution values. BALs enable parallel disk reads, parallel transaction validation, and executionless state updates.

## Motivation

Transaction execution cannot be parallelized without knowing in advance which addresses and storage slots will be accessed. While [EIP-2930](./eip-2930.md) introduced optional transaction access lists, they are not enforced.

This proposal enforces access lists at the block level, enabling:

- Parallel disk reads and transaction execution
- State reconstruction without executing transactions
- Reduced execution time to `parallel IO + parallel EVM`

## Specification

### Block Structure Modification

We introduce a new field to the block header:

```python
class Header:
    # Existing fields
    ...
    
    bal_hash: Hash32
```

The block body includes a `BlockAccessList` containing all account accesses and state changes.

### SSZ Data Structures

BALs use SSZ encoding following the pattern: `address -> field -> tx_index -> change`.

```python
# Type aliases using SSZ types
Address = Bytes20  # 20-byte Ethereum address
StorageKey = Bytes32  # 32-byte storage slot key  
StorageValue = Bytes32  # 32-byte storage value
CodeData = List[byte, MAX_CODE_SIZE]  # Variable-length contract bytecode
TxIndex = uint16  # Transaction index within block (max 65,535)
Balance = uint128  # Post-transaction balance in wei (16 bytes, sufficient for total ETH supply)
Nonce = uint64  # Account nonce

# Constants; chosen to support a 630m block gas limit
MAX_TXS = 30_000
MAX_SLOTS = 300_000
MAX_ACCOUNTS = 300_000
MAX_CODE_SIZE = 24_576  # Maximum contract bytecode size in bytes
MAX_CODE_CHANGES = 1

# Core change structures (no redundant keys)
class StorageChange(Container):
    """Single storage write: tx_index -> new_value"""
    tx_index: TxIndex
    new_value: StorageValue

class BalanceChange(Container):
    """Single balance change: tx_index -> post_balance"""
    tx_index: TxIndex
    post_balance: Balance

class NonceChange(Container):
    """Single nonce change: tx_index -> new_nonce"""
    tx_index: TxIndex
    new_nonce: Nonce

class CodeChange(Container):
    """Single code change: tx_index -> new_code"""
    tx_index: TxIndex
    new_code: CodeData

# Slot-level mapping (eliminates slot key redundancy)
class SlotChanges(Container):
    """All changes to a single storage slot"""
    slot: StorageKey
    changes: List[StorageChange, MAX_TXS]  # Only changes, no redundant slot

# Account-level mapping (groups all account changes)
class AccountChanges(Container):
    """
    All changes for a single account, grouped by field type.
    This eliminates address redundancy across different change types.
    """
    address: Address
    
    # Storage changes (slot -> [tx_index -> new_value])
    storage_changes: List[SlotChanges, MAX_SLOTS]
    # Read-only storage keys
    storage_reads: List[StorageKey, MAX_SLOTS]
    
    # Balance changes ([tx_index -> post_balance])
    balance_changes: List[BalanceChange, MAX_TXS]
    
    # Nonce changes ([tx_index -> new_nonce])
    nonce_changes: List[NonceChange, MAX_TXS]
    
    # Code changes ([tx_index -> new_code])
    code_changes: List[CodeChange, MAX_CODE_CHANGES]

# Block-level structure
class BlockAccessList(Container):
    """
    Block Access List
    """
    account_changes: List[AccountChanges, MAX_ACCOUNTS]
```

The `BlockAccessList` contains all addresses accessed during block execution:

- Addresses with state changes (storage, balance, nonce, or code)
- Addresses accessed without state changes (e.g., STATICCALL targets, BALANCE opcode targets)

Addresses with no state changes MUST still be included with empty change lists for parallel IO.

Ordering requirements:

- Addresses: lexicographic (bytewise)
- Storage keys: lexicographic within each account
- Transaction indices: ascending within each change list

Storage writes include:

- Value changes (different post-value than pre-value)
- Zeroed slots (pre-value exists, post-value is zero)

Storage reads:

- Slots accessed via `SLOAD` but not written
- Slots written with unchanged values (`SSTORE` with same value)
- Slots in pre-state but not written

Slots both read and written (with changed values) appear only in `storage_changes`.

Balance changes record post-transaction balances (`uint128`) for:

- Transaction senders (gas + value)
- Recipients
- Coinbase (rewards + fees)
- SELFDESTRUCT beneficiaries
- Withdrawal recipients (consensus layer withdrawals)

Zero-value transfers: NOT recorded in `balance_changes` but addresses MUST be included with empty `AccountChanges`.

Code changes track post-transaction runtime bytecode for deployed/modified contracts.

Nonce changes record post-transaction nonces for EOA senders, contracts that performed a successful `CREATE` or `CREATE2` operation, deployed contracts and [EIP-7702](./eip-7792.md) authorities.

### Important Implementation Details

#### Edge Cases

- **SELFDESTRUCT**: Beneficiary recorded as balance change
- **Accessed but unchanged**: Include with empty changes (`EXTCODEHASH`, `EXTCODESIZE`, `BALANCE` targets)
- **Zero-value transfers**: Include address, omit from balance_changes
- **Gas refunds**: Final balance of sender recorded after each transactions
- **Block rewards**: Final balance of fee recipient recorded after each transactions
- **STATICCALL/Read-only opcodes**: Include targets with empty changes
- **Exceptional halts**: Final nonce and balance of sender and balance of fee recipient recorded after each transactions
- **Consensus layer withdrawals**: Recipients recorded with final balance after withdrawal
- **System Contract caused changes**: Are recorded with transaction index `transaction_count + 1`
- **EIP-7002 withdrawals**: System contract storage diffs after dequeuing requests
- **EIP-7251 consolidations**: System contract storage diffs after dequeuing requests
- **EIP-2935 block hash**: ` BLOCKHASH_STORAGE_ADDRESS` storage containing new parent_hash
- **EIP-4788 beacon root**: `BEACON_ROOTS_ADDRESS` storage containing new parent_beacon_root

### Concrete Example

Example block:

1. Alice (0xaaaa...) sends 1 ETH to Bob (0xbbbb...), checks balance of 0x2222...
2. Charlie (0xcccc...) calls factory (0xffff...) deploying contract at 0xdddd...

Resulting BAL:

```python
BlockAccessList(
    account_changes=[
        AccountChanges(
            address=0xaaaa...,  # Alice
            storage_changes=[],
            storage_reads=[],
            balance_changes=[BalanceChange(tx_index=0, post_balance=0x00000000000000029a241a)],  # 50 ETH remaining
            nonce_changes=[NonceChange(tx_index=0, new_nonce=10)],  # EOA nonce after transaction
            code_changes=[]
        ),
        AccountChanges(
            address=0xbbbb...,  # Bob
            storage_changes=[],
            storage_reads=[],
            balance_changes=[BalanceChange(tx_index=0, post_balance=0x0000000000000003b9aca00)],  # 11 ETH
            nonce_changes=[],
            code_changes=[]
        ),
        AccountChanges(
            address=0xcccc...,  # Charlie (transaction sender)
            storage_changes=[],
            storage_reads=[],
            balance_changes=[BalanceChange(tx_index=1, post_balance=0x0000000000000001bc16d67)],  # After gas
            nonce_changes=[NonceChange(tx_index=1, new_nonce=5)],  # EOA nonce after transaction
            code_changes=[]
        ),
        AccountChanges(
            address=0xdddd...,  # Deployed contract
            storage_changes=[],
            storage_reads=[],
            balance_changes=[],
            nonce_changes=[NonceChange(tx_index=1, new_nonce=1)],  # New contracts start with nonce 1
            code_changes=[CodeChange(tx_index=1, new_code=b'\x60\x80\x60\x40...')]
        ),
        AccountChanges(
            address=0xeeee...,  # Coinbase
            storage_changes=[],
            storage_reads=[],
            balance_changes=[
                BalanceChange(tx_index=0, post_balance=0x000000000000000005f5e1),  # After tx 0
                BalanceChange(tx_index=1, post_balance=0x00000000000000000bebc2)   # After tx 1 + reward
            ],
            nonce_changes=[],
            code_changes=[]
        ),
        AccountChanges(
            address=0xffff...,  # Factory contract that performed CREATE
            storage_changes=[
                SlotChanges(
                    slot=b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01',
                    changes=[
                        StorageChange(tx_index=1, new_value=b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd')
                    ]
                )
            ],
            storage_reads=[],
            balance_changes=[],
            nonce_changes=[NonceChange(tx_index=1, new_nonce=5)],  # After CREATE
            code_changes=[]
        ),
        AccountChanges(
            address=0x1111...,  # Contract accessed via STATICCALL or BALANCE opcode
            storage_changes=[],
            storage_reads=b'\x00...\x05',  # Read slot 5
            balance_changes=[],
            nonce_changes=[],
            code_changes=[]
        ),
        AccountChanges(
            address=0x2222...,  # Address whose balance was checked via BALANCE opcode
            storage_changes=[],
            storage_reads=[],
            balance_changes=[],  # Just checked via BALANCE opcode
            nonce_changes=[],
            code_changes=[]
        )
    ]
)
```

SSZ-encoded and compressed: ~400-500 bytes.

### State Transition Function

Modify the state transition function to validate the block-level access lists:

```python 
def validate_bal(block):
    # Collect all state accesses and changes during block execution
    collected_accesses = {}
    
    # Process system contracts (EIP-7002, EIP-7251, EIP-2935, EIP-4788)
    process_system_contracts(block, len(block.transactions), collected_accesses)
    
    # Execute transactions and track all state accesses
    for tx_index, tx in enumerate(block.transactions):
        execute_and_track(tx, tx_index, collected_accesses)
    
    # Process withdrawals after all transactions
    for withdrawal in block.withdrawals:
        apply_withdrawal(withdrawal)
        track_withdrawal_changes(withdrawal, len(block.transactions), collected_accesses)
    
    # Process system contracts (EIP-7002, EIP-7251)
    process_system_contracts(block, len(block.transactions), collected_accesses)
    
    # Build BAL from collected data
    computed_bal = build_bal_from_accesses(collected_accesses)
    
    # Validate the BAL matches
    assert block.bal_hash == compute_bal_hash(computed_bal)

def execute_and_track(tx, tx_index, collected_accesses):
    # Execute transaction and get all touched addresses
    touched_addresses = execute_transaction(tx)
    
    for addr in touched_addresses:
        if addr not in collected_accesses:
            collected_accesses[addr] = {
                'storage_writes': {},  # slot -> [(tx_index, value)]
                'storage_reads': set(),
                'balance_changes': [],
                'nonce_changes': [],
                'code_changes': []
            }
        
        # Record storage accesses
        for slot, value in get_storage_writes(addr).items():
            if slot not in collected_accesses[addr]['storage_writes']:
                collected_accesses[addr]['storage_writes'][slot] = []
            collected_accesses[addr]['storage_writes'][slot].append((tx_index, value))
        
        # Record read-only storage accesses
        for slot in get_storage_reads(addr):
            if slot not in collected_accesses[addr]['storage_writes']:
                collected_accesses[addr]['storage_reads'].add(slot)
        
        # Record balance change if any
        if balance_changed(addr):
            collected_accesses[addr]['balance_changes'].append((tx_index, get_balance(addr)))
        
        # Record nonce change if any
        if nonce_changed(addr):
            collected_accesses[addr]['nonce_changes'].append((tx_index, get_nonce(addr)))
        
        # Record code change if any
        if code_changed(addr):
            collected_accesses[addr]['code_changes'].append((tx_index, get_code(addr)))

def track_withdrawal_changes(withdrawal, tx_index, collected_accesses):
    addr = withdrawal.address
    if addr not in collected_accesses:
        collected_accesses[addr] = {
            'storage_writes': {}, 'storage_reads': set(),
            'balance_changes': [], 'nonce_changes': [], 'code_changes': []
        }
    # Record post-withdrawal balance
    collected_accesses[addr]['balance_changes'].append((tx_index, get_balance(addr)))
    
def build_bal_from_accesses(collected_accesses):
    account_changes_list = []
    
    for addr, data in collected_accesses.items():
        storage_changes = [
            SlotChanges(slot=slot, changes=[StorageChange(tx_index=idx, new_value=val) 
                                           for idx, val in sorted(changes)])
            for slot, changes in data['storage_writes'].items()
        ]
        
        # Include pure reads and unchanged writes (excluded from storage_writes)
        storage_reads = [slot for slot in data['storage_reads'] 
                        if slot not in data['storage_writes']]
        
        account_changes_list.append(AccountChanges(
            address=addr,
            storage_changes=sorted(storage_changes, key=lambda x: x.slot),
            storage_reads=sorted(storage_reads, key=lambda x: x.slot),
            balance_changes=[BalanceChange(tx_index=idx, post_balance=bal) 
                           for idx, bal in sorted(data['balance_changes'])],
            nonce_changes=[NonceChange(tx_index=idx, new_nonce=nonce) 
                         for idx, nonce in sorted(data['nonce_changes'])],
            code_changes=[CodeChange(tx_index=idx, new_code=code) 
                        for idx, code in sorted(data['code_changes'])]
        ))
    
    return BlockAccessList(account_changes=sorted(account_changes_list, key=lambda x: x.address))

def process_system_contracts(block, tx_index, collected_accesses):
    # System contract changes use tx_index = transaction_count
    
    # EIP-7002: Execution layer triggered withdrawals
    if is_prague_fork():
        track_contract_changes('0x00A3ca265EBcb825B45F985A16CEFB49958cE017', tx_index, collected_accesses)
    
    # EIP-7251: Consolidation requests  
    if is_prague_fork():
        track_contract_changes('0x00b42dbF2194e931E80326D950320f7d9Dbeac02', tx_index, collected_accesses)
    
    # EIP-2935: Historical block hashes
    if is_prague_fork():
        addr = '0x0000000000000000000000000000000000000001'
        slot = (block.number - 1) % 8191
        record_storage_write(addr, slot, block.parent_hash, tx_index, collected_accesses)
    
    # EIP-4788: Beacon block root
    if is_cancun_fork():
        addr = '0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02'
        timestamp_slot = (block.timestamp % 8192) + 8192
        root_slot = block.timestamp % 8192
        record_storage_write(addr, timestamp_slot, block.timestamp, tx_index, collected_accesses)
        record_storage_write(addr, root_slot, block.parent_beacon_block_root, tx_index, collected_accesses)

def track_contract_changes(addr, tx_index, collected_accesses):
    """Track all storage changes for a system contract"""
    for slot, value in get_storage_changes(addr).items():
        record_storage_write(addr, slot, value, tx_index, collected_accesses)

def record_storage_write(addr, slot, value, tx_index, collected_accesses):
    if addr not in collected_accesses:
        collected_accesses[addr] = {
            'storage_writes': {}, 'storage_reads': set(),
            'balance_changes': [], 'nonce_changes': [], 'code_changes': []
        }
    if slot not in collected_accesses[addr]['storage_writes']:
        collected_accesses[addr]['storage_writes'][slot] = []
    collected_accesses[addr]['storage_writes'][slot].append((tx_index, value))
```

The BAL MUST be complete and accurate. Missing or spurious entries invalidate the block.

Clients MUST validate by comparing execution-gathered accesses (per [EIP-2929](./eip-2929.md)) with the BAL.

Clients MAY invalidate immediately if any transaction exceeds declared state.

## Rationale

### BAL Design Choice

This design variant was chosen for several key reasons:

1. **Size vs parallelization**: BALs include all accessed addresses (even unchanged) for complete parallel execution. Omitting read values reduces size while maintaining parallelization benefits.

2. **Storage values for writes**: Post-execution values enable state reconstruction during sync without individual proofs against state root.

3. **Overhead analysis**: Historical data shows ~40 KiB average BAL size with ~4.5 KiB for balance diffs - reasonable for performance gains.

4. **Transaction independence**: 60-80% of transactions access disjoint storage slots, enabling effective parallelization.

5. **SSZ encoding**: Enables efficient Merkle proofs for light clients. SSZ BAL embedded as opaque bytes in RLP block for compatibility.

### Block Size Considerations

Block size impact (historical analysis):

- Average: ~40 KiB (compressed)
- Balance diffs: ~4.5 KiB (compressed)
- Storage diffs: ~33.88 KiB (compressed)
- Nonce diffs: ~0.02 KiB (compressed)
- Code diffs: ~0.6 KiB (compressed)
- Worst-case (36m gas): ~0.93 MiB
- Worst-case balance diffs: ~0.12 MiB

Smaller than current worst-case calldata blocks.

An empirical analysis has been done [here](../assets/eip-7928/bal_size_analysis.md).

### Asynchronous Validation

BAL verification occurs alongside parallel IO and EVM operations without delaying block processing.

## Backwards Compatibility

This proposal requires changes to the block structure that are not backwards compatible and require a hard fork.

## Security Considerations

### Validation Overhead

Validating access lists and balance diffs adds validation overhead but is essential to prevent acceptance of invalid blocks.

### Block Size

Increased block size impacts propagation but overhead (~40 KiB average) is reasonable for performance gains.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
