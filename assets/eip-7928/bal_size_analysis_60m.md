# EIP-7928 Component Size - 1000 Blocks

## Dataset
- **Blocks Analyzed**: 1000 blocks (23,991,474 to 23,992,473)
- **Encoding**: RLP format
- **Compression**: Snappy algorithm

## Per-Block Component Statistics (KiB)

| Component | Avg Raw | Median Raw | Avg Compressed | Median Compressed | Avg Ratio | Median Ratio |
|-----------|---------|------------|----------------|-------------------|-----------|--------------
| Storage Writes | 52.6 | 49.6 | 29.2 | 28.0 | 1.79x | 1.78x |
| Storage Reads | 31.7 | 29.7 | 18.7 | 17.5 | 1.71x | 1.71x |
| Balance Changes | 6.8 | 6.6 | 6.7 | 6.5 | 1.02x | 1.00x |
| Nonce Changes | 1.1 | 1.0 | 1.1 | 1.0 | 0.99x | 1.00x |
| Code Changes | 2.1 | 0.2 | 1.2 | 0.2 | 1.37x | 1.16x |
| **Full BAL** | **74.3** | **70.9** | **49.4** | **47.9** | **1.50x** | **1.48x** |

## Component Size Distribution (KiB)

| Component | Min Raw | Max Raw | Std Dev Raw | Min Compressed | Max Compressed | Std Dev Compressed |
|-----------|---------|---------|-------------|----------------|----------------|-------------------|
| Storage Writes | 4.5 | 197.0 | 23.7 | 2.8 | 113.8 | 12.8 |
| Storage Reads | 1.2 | 105.7 | 15.0 | 0.9 | 88.9 | 9.2 |
| Balance Changes | 0.7 | 22.4 | 2.8 | 0.7 | 22.4 | 2.7 |
| Nonce Changes | 0.1 | 4.4 | 0.5 | 0.1 | 4.5 | 0.5 |
| Code Changes | 0.0 | 72.6 | 5.6 | 0.0 | 25.3 | 2.9 |
| **Full BAL** | **8.4** | **223.5** | **30.7** | **6.8** | **141.8** | **19.5** |

## Compression Ratio Distribution

| Component | Min Ratio | Max Ratio | Std Dev | 25th Percentile | 75th Percentile |
|-----------|-----------|-----------|---------|-----------------|-----------------
| Storage Writes | 1.54x | 2.86x | 0.12x | 1.74x | 1.83x |
| Storage Reads | 1.07x | 2.33x | 0.16x | 1.61x | 1.81x |
| Balance Changes | 1.00x | 1.50x | 0.04x | 1.00x | 1.03x |
| Nonce Changes | 0.97x | 1.07x | 0.00x | 0.99x | 1.00x |
| Code Changes | 0.93x | 8.67x | 0.65x | 0.99x | 1.56x |
| **Full BAL** | **1.20x** | **2.23x** | **0.10x** | **1.44x** | **1.53x** |

## Block Activity Metrics (per block)

| Metric | Average | Median | Min | Max |
|--------|---------|--------|-----|-----|
| Total Accounts | 432 | 428 | 67 | 1124 |
| Storage Writes Count | 700 | 667 | 65 | 2521 |
| Storage Reads Count | 982 | 922 | 36 | 3279 |
| Balance Changes Count | 612 | 598 | 62 | 1812 |
| Nonce Changes Count | 229 | 224 | 18 | 770 |

## Component Percentage of Full BAL

| Component | % of Raw Size | % of Compressed Size |
|-----------|---------------|---------------------|
| Storage Writes | 70.7% | 59.1% |
| Balance Changes | 9.2% | 13.5% |
| Nonce Changes | 1.5% | 2.2% |
| Code Changes | 2.8% | 2.4% |
| Storage Reads | 28.6% | 25.8% |

## BAL vs Block Size Comparison

Comparison using compressed block average of **71.71 KiB**:

| Metric | BAL Size (KiB) | Block Size (KiB) | Ratio (BAL/Block) | Size Difference |
|--------|---------------|------------------|-------------------|------------------|
| **WITHOUT reads** | 49.4 | 71.7 | 0.69x | -22.3 KiB |
| **WITH reads** | 72.4 | 71.7 | 1.01x | +0.7 KiB |

### Key Insights:
- BAL **without reads** is 0.69x the size of a compressed block
- BAL **with reads** is 1.01x the size of a compressed block
- Storage reads add **23.0 KiB** (46.6%) to BAL size
- BAL overhead vs blocks: **-31.1%** (without reads), **+1.0%** (with reads)

## Storage Reads Impact Analysis

- **WITH reads**: 72.4 KiB compressed
- **WITHOUT reads**: 49.4 KiB compressed
- **Storage reads overhead**: 23.0 KiB (46.6%)

## Summary

1. **Component dominance**: Storage writes are 70.7% of raw BAL size
2. **Compression efficiency**: Overall 1.50x compression ratio
3. **Size variability**: BAL sizes vary from 6.8 to 141.8 KiB compressed
4. **Block size ratio**: BALs are 0.69x compressed block size (without reads)
