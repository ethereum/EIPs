# EIP-7928 Component Size & Compression Analysis - 1000 Blocks

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
| **Full BAL** | **110.8** | **106.0** | **72.4** | **70.5** | **1.52x** | **1.52x** |

## Component Size Distribution (KiB)

| Component | Min Raw | Max Raw | Std Dev Raw | Min Compressed | Max Compressed | Std Dev Compressed |
|-----------|---------|---------|-------------|----------------|----------------|-------------------|
| Storage Writes | 4.5 | 197.0 | 23.7 | 2.8 | 113.8 | 12.8 |
| Storage Reads | 1.2 | 105.7 | 15.0 | 0.9 | 88.9 | 9.2 |
| Balance Changes | 0.7 | 22.4 | 2.8 | 0.7 | 22.4 | 2.7 |
| Nonce Changes | 0.1 | 4.4 | 0.5 | 0.1 | 4.5 | 0.5 |
| Code Changes | 0.0 | 72.6 | 5.6 | 0.0 | 25.3 | 2.9 |
| **Full BAL** | **10.9** | **301.9** | **45.5** | **8.6** | **191.4** | **28.8** |

## Compression Ratio Distribution

| Component | Min Ratio | Max Ratio | Std Dev | 25th Percentile | 75th Percentile |
|-----------|-----------|-----------|---------|-----------------|-----------------
| Storage Writes | 1.54x | 2.86x | 0.12x | 1.74x | 1.83x |
| Storage Reads | 1.07x | 2.33x | 0.16x | 1.61x | 1.81x |
| Balance Changes | 1.00x | 1.50x | 0.04x | 1.00x | 1.03x |
| Nonce Changes | 0.97x | 1.07x | 0.00x | 0.99x | 1.00x |
| Code Changes | 0.93x | 8.67x | 0.65x | 0.99x | 1.56x |
| **Full BAL** | **1.19x** | **1.98x** | **0.09x** | **1.47x** | **1.56x** |

## Block Activity Metrics (per block)

| Metric | Average | Median | Min | Max |
|--------|---------|--------|-----|-----|
| Total Accounts | 603 | 600 | 98 | 1474 |
| Storage Writes Count | 700 | 667 | 65 | 2521 |
| Storage Reads Count | 982 | 922 | 36 | 3279 |
| Balance Changes Count | 612 | 598 | 62 | 1812 |
| Nonce Changes Count | 229 | 224 | 18 | 770 |

## Component Percentage of Full BAL

| Component | % of Raw Size | % of Compressed Size |
|-----------|---------------|---------------------|
| Storage Writes | 47.5% | 40.3% |
| Storage Reads | 28.6% | 25.8% |
| Balance Changes | 6.2% | 9.2% |
| Nonce Changes | 1.0% | 1.5% |
| Code Changes | 1.9% | 1.6% |

## BAL vs Block Size Comparison

Comparison using compressed block average of **71.71 KiB**:

| Metric | BAL Size (KiB) | Block Size (KiB) | Ratio (BAL/Block) | Size Difference |
|--------|---------------|------------------|-------------------|------------------|
| **Full BAL (with reads)** | 72.4 | 71.7 | 1.01x | +0.7 KiB |
| **BAL without reads** | 49.4 | 71.7 | 0.69x | -22.3 KiB |

### Key Insights:
- Full BAL **with reads** is 1.01x the size of a compressed block
- BAL **without reads** is 0.69x the size of a compressed block
- Storage reads add **23.0 KiB** (46.6%) to BAL size
- BAL overhead vs blocks: **+1.0%** (with reads), **-31.1%** (without reads)

## Storage Reads Impact Analysis

- **WITH reads** (Full BAL): 72.4 KiB compressed
- **WITHOUT reads**: 49.4 KiB compressed
- **Storage reads overhead**: 23.0 KiB (46.6%)

## Summary

1. **Component dominance**: Storage writes are 47.5% of raw BAL size
2. **Compression efficiency**: Overall 1.52x compression ratio
3. **Size variability**: BAL sizes vary from 8.6 to 191.4 KiB compressed
4. **Block size ratio**: Full BALs are 1.01x compressed block size
