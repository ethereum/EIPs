# EIP-7825 Empirical Report

*The following represents a summary with empirical findings from analyzing a `2**24` transaction gas limit cap.*
*Date: July, 2025*

## Dataset
- **Period**: 6 months of Ethereum mainnet data (Q1 25)
- **Blocks analyzed**: 1,296,000
- **Total transactions**: 251,922,669

## Impact Metrics

### Transaction Impact
| Metric | Value |
|--------|-------|
| Affected transactions | 96,564 |
| Impact rate | 0.0383% |
| Unique affected addresses | 4,601 |
| Avg transactions per affected address | 21.0 |

### Gas Analysis (of Affected)
| Metric | Value |
|--------|-------|
| Average gas limit (affected txs) | 24,734,127 |
| Average gas used | 17,668,721 |
| Gas efficiency | 71.4% |
| Min gas used | 21,000 |
| Max gas used | 35,888,566 |
| Transactions with unnecessary high limits | 18,490 (19.15%) |

### Economic Impact
| Metric | Value |
|--------|-------|
| Total additional gas cost | 2,095,905,000 gas units |
| Avg additional gas per address | 455,532 gas units |
| Avg additional gas per transaction | 21,705 gas units |
| Avg cost per address | 0.0004873 ETH |

## Distribution Analysis

### Concentration
| Metric | Value |
|--------|-------|
| Gini coefficient | 0.870 |
| Top 10% addresses impact | 79.7% of affected transactions |
| Top 50 addresses impact | 37.6% of affected transactions |
| Addresses with 1 transaction | 1,848 (40.2%) |
| Addresses with >100 transactions | 197 (4.3%) |

## Cumulative Distribution Function

### Sample
- **Total transactions analyzed**: 244,628,466
- **Blocks**: 1,317,600 (183 days)

### Distribution
| Gas Limit | Cumulative % | Transaction Count |
|-----------|--------------|-------------------|
| ≤21,000 | 26.02% | 63,660,952 |
| ≤50,000 | 36.85% | 90,137,805 |
| ≤100,000 | 60.31% | 147,541,155 |
| ≤200,000 | 69.50% | 170,005,321 |
| ≤500,000 | 92.81% | 227,033,454 |
| ≤1,000,000 | 96.65% | 236,444,479 |
| ≤2,000,000 | 98.39% | 240,708,106 |
| ≤5,000,000 | 99.29% | 242,903,913 |
| ≤10,000,000 | 99.76% | 243,975,982 |
| ≤16,777,216 | 99.96% | 244,535,902 |
| >16,777,216 | 0.04% | 92,564 |

## Address Analysis

### Top 10 From Addresses
| Rank | Address | Transactions | Avg Gas Limit | Max Gas Limit |
|------|---------|--------------|---------------|---------------|
| 1 | 0x22dcb...e1 | 2,555 | 19,940,819 | 20,025,269 |
| 2 | 0xc87a8...85 | 2,205 | 22,766,999 | 30,000,000 |
| 3 | 0x78ec5...fe | 1,712 | 25,950,213 | 36,000,000 |
| 4 | 0x2a8b4...1c | 1,559 | 34,411,392 | 35,947,097 |
| 5 | 0xcde69...ff | 1,543 | 23,456,520 | 32,400,000 |
| 6 | 0x61fbb...6f | 1,345 | 19,439,482 | 32,400,000 |
| 7 | 0x4abf0...32 | 1,287 | 20,403,859 | 25,267,151 |
| 8 | 0xd6aaa...77 | 1,189 | 24,467,657 | 25,416,303 |
| 9 | 0x7340d...78 | 1,100 | 20,093,929 | 20,094,357 |
| 10 | 0xb5b3f...d9 | 1,089 | 19,461,632 | 34,508,005 |

### Top 10 To Addresses
| Rank | Address | Transactions | % of Total |
|------|---------|--------------|------------|
| 1 | 0x06450...f6 | 9,443 | 9.8% |
| 2 | 0x00000...0b | 6,645 | 6.9% |
| 3 | 0x3c7cb...97 | 3,017 | 3.1% |
| 4 | 0xca2b1...44 | 2,907 | 3.0% |
| 5 | 0x0a252...59 | 2,817 | 2.9% |
| 6 | 0x5b12a...d9 | 2,728 | 2.8% |
| 7 | 0xd6da1...29 | 2,651 | 2.7% |
| 8 | 0x00000...00 | 2,607 | 2.7% |
| 9 | 0xb0cd7...a3 | 2,413 | 2.5% |
| 10 | 0x22e4a...ad | 2,369 | 2.5% |

### Concentration Ratios
| Metric | Value |
|--------|-------|
| Unique from addresses | 4,601 |
| Unique to addresses | 3,834 |
| Concentration ratio | 0.83 |
| Top 10 to addresses share | 38.8% |
| Top 50 to addresses share | 71.5% |
| Top 100 to addresses share | 82.0% |

## Migration Analysis

### Transaction Splitting Requirements
| Splits Required | Address Count | Percentage |
|-----------------|---------------|------------|
| 2 | 4,502 | 97.8% |
| 3 | 99 | 2.2% |

### Gas Cost Distribution
| Percentile | Additional Gas per Transaction | ETH Cost (Historical) |
|------------|-------------------------------|----------------------|
| Min | 21,000 | 0.00000636 |
| 25th | 21,000 | 0.00000843 |
| 50th | 21,000 | 0.00000966 |
| 75th | 21,000 | 0.00001175 |
| 95th | 42,000 | 0.00002306 |
| Max | 84,000 | 0.00003670 |

## Summary Statistics

### 6-Month Period
- **Affected transactions**: 96,564 (0.0383%)
- **Affected addresses**: 4,601
- **Total ETH impact**: 2.2419 ETH
- **Average splits required**: 2.02

### CDF Analysis (183 days)
- **Transactions ≤16,777,216 gas**: 99.96%
- **Transactions >16,777,216 gas**: 0.04%
