# Block Access List (BAL) Size Analysis

> Analysis done with the BAL version https://github.com/ethereum/EIPs/blob/5cff3c4c11d2e06a269ade5b9ca005bb674f6b5f/EIPS/eip-7928.md

## Executive Summary

This report presents an empirical analysis of Block Access List (BAL) sizes across 100 historical Ethereum blocks. The analysis examines BAL encoding efficiency using SSZ format and compares configurations with and without storage read tracking.

## Methodology

- **Sample Size**: 100 blocks from the Ethereum mainnet
- **Block Range**: Blocks 22615032 to 22616022 (sampled every 10 blocks)
- **Encoding Format**: SSZ
- **Compression**: Snappy compression
- **Configurations**: Analysis performed both with and without storage read tracking

## Key Findings

### 1. Overall BAL Sizes

#### Configuration: With Storage Reads
- **Raw Size**: 91.3 KB average (25.1 - 164.8 KB range)
- **Compressed Size**: 42.7 KB average (11.7 - 78.7 KB range)
- **Compression Ratio**: 2.1x

#### Configuration: Without Storage Reads  
- **Raw Size**: 63.6 KB average (17.4 - 117.3 KB range)
- **Compressed Size**: 29.3 KB average (7.9 - 56.2 KB range)
- **Compression Ratio**: 2.2x

#### Impact of Storage Reads
- **Size Increase**: 45.6% when including storage reads
- **Absolute Difference**: 13.4 KB average increase

### 2. Component Breakdown

Average compressed sizes by component type (with storage reads):

- **Storage Writes**: 23.0 KB (54.0% of total)
- **Storage Reads**: 13.4 KB (31.3% of total)
- **Balance Changes**: 5.8 KB (13.6% of total)
- **Code Deployments**: 0.5 KB (1.1% of total)
- **Nonce Updates**: 0.0 KB (0.0% of total)

### 3. Block Activity Metrics

Average per block:
- **Transactions**: 183.4 (min: 54, max: 365)
- **Unique Accounts**: 407.0
- **Storage Writes**: 583.2
- **Storage Reads**: 818.2

### 4. Size Distribution

Compressed BAL size percentiles (with reads):
- **P10**: 21.7 KB
- **P25**: 28.9 KB  
- **P50**: 42.6 KB (median)
- **P75**: 54.6 KB
- **P90**: 64.7 KB
- **P95**: 73.7 KB
- **P99**: 78.7 KB

### 5. Correlation Analysis

- **Size vs Transactions**: Pearson correlation = 0.876
- **Size vs Storage Writes**: Pearson correlation = 0.973
- **Size vs Unique Accounts**: Pearson correlation = 0.956

## Technical Details

### BAL Structure

The Block Access List uses an account-centric design with hierarchical organization:

```
BlockAccessList
└── AccountChanges[]
    ├── address: Address (20 bytes)
    ├── storage_changes: SlotChanges[]
    │   ├── slot: StorageKey (32 bytes)
    │   └── changes: StorageChange[]
    │       ├── tx_index: uint16
    │       └── new_value: StorageValue (32 bytes)
    ├── storage_reads: SlotRead[]
    │   └── slot: StorageKey (32 bytes)
    ├── balance_changes: BalanceChange[]
    │   ├── tx_index: uint16
    │   └── post_balance: Balance (12 bytes)
    ├── nonce_changes: NonceChange[]
    │   ├── tx_index: uint16
    │   └── new_nonce: uint64
    └── code_changes: CodeChange[]
        ├── tx_index: uint16
        └── new_code: CodeData (variable)
```

### Encoding Efficiency Features

1. **Address Deduplication**: Each address appears only once, regardless of how many changes it has
2. **Slot Deduplication**: Each storage slot appears only once per account
3. **Transaction Indexing**: Uses uint16 (2 bytes) instead of full transaction hashes
4. **Optimized Field Sizes**: 
   - Balance: 12 bytes (sufficient for total ETH supply)
   - Transaction index: 2 bytes (supports up to 65,535 transactions)
   - Address: 20 bytes (standard Ethereum address)

## Key Insights

1. **Storage Operations Dominate**: Storage changes and reads account for 85.3% of the total BAL size, making storage optimization critical.

2. **Read Tracking Cost**: Including storage reads adds approximately 13.4 KB per block on average, a 45.6% increase.

3. **Scalability**: The median block (178 transactions) produces a 42.6 KB compressed BAL, while the 95th percentile block (286 transactions) produces 73.7 KB.

4. **Network Impact**: At current block production rates (12 seconds), BALs would add approximately 300.2 MB/day to node bandwidth requirements.

## Conclusions

The SSZ-encoded Block Access List provides an efficient method for recording state access patterns:

- **Typical blocks** (25th-75th percentile) generate compressed BALs of 28.9-54.6 KB
- **Large blocks** (95th percentile) remain under 73.7 KB compressed
- **Compression effectiveness** of 2.1x makes network transmission practical
- **Read tracking overhead** of 45.6% is still considered acceptable for the benefits provided, but might be removed in the future.
