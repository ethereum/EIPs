# EIP-7928 Component Size & Compression Analysis - 1000 Blocks (60M Gas Limit)

## Dataset
- **Blocks Analyzed**: 1000 blocks (26,095,544 to 26,096,543)
- **Gas Limit**: 60M (avg gas used: 30.3M, avg transactions: 305)
- **Encoding**: RLP format
- **Compression**: Snappy algorithm

Attribution: each component is its RLP-encoded field (headers included) summed over accounts; touched-only accounts count as whole entries; overhead is the exact remainder, so components sum to the total. Compressed sizes are snappy over the concatenated per-account field encodings. The previous analysis booked field-list headers under overhead instead; full-BAL totals are directly comparable.

## Per-Block Component Statistics (KiB)

| Component | Avg Raw | Median Raw | Avg Compressed | Median Compressed | Avg Ratio | Median Ratio |
|-----------|---------|------------|----------------|-------------------|-----------|--------------|
| Storage Writes | 65.1 | 62.5 | 36.1 | 34.7 | 1.79x | 1.77x |
| Storage Reads | 39.5 | 36.4 | 25.8 | 23.0 | 1.57x | 1.58x |
| Balance Changes | 9.5 | 9.4 | 9.2 | 9.3 | 1.03x | 1.02x |
| Nonce Changes | 2.1 | 2.1 | 1.9 | 1.9 | 1.11x | 1.11x |
| Code Changes | 2.8 | 0.9 | 1.4 | 0.3 | 4.19x | 3.41x |
| Account Addresses (w/ Changes) | 12.6 | 12.6 | 12.5 | 12.6 | 1.00x | 1.00x |
| Touched-Only Addresses | 4.0 | 4.0 | 3.3 | 3.2 | 1.22x | 1.22x |
| RLP Encoding Overhead | 0.9 | 1.0 | 1.8 | 1.8 | — | — |
| **Full BAL** | **136.6** | **132.5** | **92.1** | **89.4** | **1.48x** | **1.47x** |

## Component Size Distribution (KiB)

| Component | Min Raw | Max Raw | Std Dev Raw | Min Compressed | Max Compressed | Std Dev Compressed |
|-----------|---------|---------|-------------|----------------|----------------|--------------------|
| Storage Writes | 6.9 | 207.7 | 26.2 | 4.2 | 90.7 | 13.4 |
| Storage Reads | 3.0 | 156.5 | 18.3 | 1.9 | 140.2 | 14.2 |
| Balance Changes | 0.4 | 22.0 | 2.9 | 0.3 | 20.3 | 2.7 |
| Nonce Changes | 0.1 | 5.1 | 0.7 | 0.1 | 4.1 | 0.6 |
| Code Changes | 0.0 | 51.8 | 5.3 | 0.0 | 29.9 | 3.0 |
| Account Addresses (w/ Changes) | 1.0 | 26.7 | 3.5 | 1.0 | 26.6 | 3.5 |
| Touched-Only Addresses | 0.3 | 15.1 | 1.6 | 0.3 | 12.6 | 1.3 |
| RLP Encoding Overhead | 0.1 | 1.9 | 0.3 | -7.2 | 8.4 | 1.3 |
| **Full BAL** | **15.9** | **322.2** | **49.4** | **10.9** | **234.6** | **32.2** |

## Compression Ratio Distribution

| Component | Min Ratio | Max Ratio | Std Dev | 25th Percentile | 75th Percentile |
|-----------|-----------|-----------|---------|-----------------|-----------------|
| Storage Writes | 1.55x | 2.89x | 0.12x | 1.73x | 1.82x |
| Storage Reads | 1.08x | 2.07x | 0.14x | 1.49x | 1.66x |
| Balance Changes | 1.00x | 2.19x | 0.06x | 1.00x | 1.04x |
| Nonce Changes | 0.99x | 1.50x | 0.05x | 1.09x | 1.14x |
| Code Changes | 1.18x | 18.70x | 2.96x | 2.18x | 5.09x |
| Account Addresses (w/ Changes) | 1.00x | 1.00x | 0.00x | 1.00x | 1.00x |
| Touched-Only Addresses | 1.12x | 1.41x | 0.02x | 1.21x | 1.23x |
| **Full BAL** | **1.22x** | **1.87x** | **0.08x** | **1.44x** | **1.51x** |

No ratio is reported for RLP Encoding Overhead: its compressed value is a remainder and can be negative for individual blocks.

## Block Activity Metrics (per block)

| Metric | Average | Median | Min | Max |
|--------|---------|--------|-----|-----|
| Total Accounts | 766 | 763 | 79 | 1519 |
| Storage Writes Count | 986 | 946 | 98 | 3132 |
| Storage Reads Count | 1201 | 1104 | 90 | 4820 |
| Balance Changes Count | 795 | 790 | 30 | 1797 |
| Nonce Changes Count | 314 | 309 | 6 | 793 |

## Component Percentage of Full BAL

| Component | % of Raw Size | % of Compressed Size |
|-----------|---------------|----------------------|
| Storage Writes | 47.7% | 39.2% |
| Storage Reads | 28.9% | 28.0% |
| Balance Changes | 7.0% | 10.0% |
| Nonce Changes | 1.6% | 2.1% |
| Code Changes | 2.0% | 1.5% |
| Account Addresses (w/ Changes) | 9.2% | 13.6% |
| Touched-Only Addresses | 3.0% | 3.6% |
| RLP Encoding Overhead | 0.7% | 1.9% |

## BAL vs Block Size Comparison

Comparison using compressed block average of **78.98 KiB**:

| Metric | BAL Size (KiB) | Block Size (KiB) | Ratio (BAL/Block) | Size Difference |
|--------|---------------|------------------|-------------------|------------------|
| **Full BAL (with reads)** | 92.1 | 79.0 | 1.17x | +13.1 KiB |
| **BAL without reads** | 61.1 | 79.0 | 0.77x | -17.9 KiB |

- Full BAL **with reads** is 1.17x the size of a compressed block
- BAL **without reads** is 0.77x the size of a compressed block
- Storage reads add **31.0 KiB** (50.7%) to BAL size
- BAL overhead vs blocks: **+16.6%** (with reads), **-22.7%** (without reads)

## Storage Reads Impact Analysis

- **WITH reads** (Full BAL): 92.1 KiB compressed
- **WITHOUT reads**: 61.1 KiB compressed
- **Storage reads overhead**: 31.0 KiB (50.7%)

## Compressed Full BAL Size Percentiles (KiB)

| P10 | P25 | P50 | P75 | P90 | P95 | P99 |
|-----|-----|-----|-----|-----|-----|-----|
| 61.0 | 76.3 | 89.5 | 106.2 | 132.0 | 150.0 | 185.1 |

## Comparison to Previous Analysis (blocks 23,991,474 to 23,992,473)

| Metric | Previous | This Analysis | Change |
|--------|----------|---------------|--------|
| Full BAL avg raw (KiB) | 110.8 | 136.6 | +23.3% |
| Full BAL avg compressed (KiB) | 72.5 | 92.1 | +27.0% |
| BAL w/o reads avg compressed (KiB) | 49.4 | 61.1 | +23.7% |
| Compressed block avg (KiB) | 55.4 | 79.0 | +42.6% |
| Total accounts (avg) | 606.7 | 765.6 | +26.2% |
| Storage writes count (avg) | 807.3 | 986.1 | +22.1% |
| Storage reads count (avg) | 981.5 | 1200.7 | +22.3% |
| Balance changes count (avg) | 611.6 | 794.8 | +30.0% |
| Nonce changes count (avg) | 228.6 | 314.3 | +37.5% |

Gas per block is unchanged (30.5M to 30.3M) while storage writes per Mgas rose from 26.5 to 32.6 (+23%) and raw BAL payload from 110.8 to 136.6 KiB (+23%): the growth comes from gas shifting toward state writes, not from higher gas usage.

## Summary

1. **Component dominance**: Storage writes are 47.7% of raw BAL size
2. **Account addressing**: Accounts with changes (13.6%) vs touched-only (3.6%) of compressed size
3. **Pure RLP overhead**: Encoding structure accounts for 1.9% of compressed size
4. **Compression efficiency**: Overall 1.48x compression ratio
5. **Size variability**: BAL sizes vary from 10.9 to 234.6 KiB compressed
6. **Block size ratio**: Full BALs are 1.17x compressed block size
