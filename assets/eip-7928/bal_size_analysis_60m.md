# EIP-7928 Block Access List Size Analysis

## Storage Reads Impact on BAL Sizes

*Dataset: 50 Ethereum mainnet blocks (23934306–23934355)*

## Summary
Storage reads add **30.4 KB (32.7%)** to compressed BAL size per block.

## 1. Size Analysis

### 1.1 BAL Sizes

| Configuration | Raw (KB) | Compressed (KB) | Ratio |
|---------------|----------|------------------|--------|
| WITH Reads | 137.7 | 92.0 | 1.50x |
| WITHOUT Reads | 90.1 | 61.7 | 1.46x |
| Reduction | 47.6 | 30.4 | — |
| % Reduction | 34.5% | 32.7% | — |

### 1.2 Distribution

| Metric | With (KB) | Without (KB) | Diff |
|--------|-----------|--------------|------|
| Mean | 92.0 | 61.7 | 30.4 |
| Median | 85.1 | 57.2 | 27.9 |
| Min | 20.7 | 16.3 | 4.4 |
| Max | 169.8 | 109.6 | 60.2 |
| Std Dev | 32.7 | 22.1 | — |

## 2. Impact on Block Size

(Reference block compressed mean: 71.71 KB)

| Config | BAL | BAL % of Block | Block+BAL | Multiplier |
|--------|-----|----------------|-----------|------------|
| WITH Reads | 92.0 KB | 128.3% | 163.7 KB | 2.28x |
| WITHOUT Reads | 61.7 KB | 86.0% | 133.4 KB | 1.86x |
| Difference | 30.4 KB | 42.3% | 30.3 KB | 0.42x |

Observations:
- Reads push BALs above block size (128.3%).
- Without reads, BALs are smaller than blocks (86.0%).

## 3. Component Breakdown

| Component | Count/block | Size (KB) | % of BAL |
|----------|-------------|-----------|-----------|
| Storage Writes | 931 | 31.6 | 34.3% |
| Storage Reads | 1,296 | 30.4 | 32.7% |
| Total Ops | 2,227 | 62.0 | 67.4% |

Additional:
- Accounts with reads: 764/block
- Without reads: 557/block (27.2% fewer)
- Total reads: 64,822 (50 blocks)

## 4. Network Impact

### 4.1 Bandwidth

| Interval | WITH Reads | WITHOUT Reads | Savings |
|----------|------------|---------------|---------|
| Per Block | 92.0 KB | 61.7 KB | 30.4 KB |
| Per Hour (50 blocks) | 4.49 MB | 3.01 MB | 1.48 MB |
| Per Day | 107.8 MB | 72.3 MB | 35.5 MB |
| Per Year | 38.4 GB | 25.8 GB | 12.6 GB |
