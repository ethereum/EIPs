# EIP-7976 Empirical Report (64/64 Pricing at the Floor)

*The following represents a summary with empirical findings from analyzing EIP-7976's impact on transactions.*
*Date: January, 2026*

## Dataset

- **Period**: 150 days of Ethereum mainnet data (August 2025 - January 2026)
- **Blocks analyzed**: 1,080,000 blocks
- **Total transactions**: 245,624,335

## Overall Impact Metrics

### Transaction Impact Summary

| Metric | Value |
|--------|-------|
| Total unaffected transactions | 240,588,721 (97.95%) |
| Total affected transactions | 5,035,614 (2.05%) |
| Transactions already affected by EIP-7623 | 2,093,004 (0.85%) |
| New transactions affected by EIP-7976 only | 2,942,610 (1.20%) |
| EIP-7623 overlap percentage | 41.6% |

### Address Distribution

| Metric | Value |
|--------|-------|
| Unique affected senders | 636,577 |
| Unique affected recipients | 521,874 |
| Avg transactions per affected sender | 7.91 |
| Avg transactions per affected recipient | 9.65 |

## Gas Usage Analysis (Affected Transactions)

### Basic Gas Metrics

| Metric | Value |
|--------|-------|
| Mean gas used | 140,959 |
| Median gas used | 38,031 |
| Average calldata bytes | 3,460 |
| Average zero bytes | 1,883 |
| Average non-zero bytes | 1,577 |

## Most Affected Senders

### Top 30 Senders by Additional Cost Impact

| Rank | Address | Transactions | Total Cost Increase (gas) | Avg Cost/Tx | Etherscan Link |
|------|---------|--------------|---------------------------|-------------|----------------|
| 1 | 0x54b839d988c9e712cd36cbf7c95dedc2b9f9ae6c | 44,296 | 100,215,386,242 | 2,262,402 | [View](https://etherscan.io/address/0x54b839d988c9e712cd36cbf7c95dedc2b9f9ae6c) |
| 2 | 0xcbe6fbf5e3c427013688e04d0fde56705890c4be | 27,031 | 93,199,568,422 | 3,447,877 | [View](https://etherscan.io/address/0xcbe6fbf5e3c427013688e04d0fde56705890c4be) |
| 3 | 0xe08cdadd44440e32ef153956a7ec40804a32dd74 | 3,360 | 24,782,661,408 | 7,375,792 | [View](https://etherscan.io/address/0xe08cdadd44440e32ef153956a7ec40804a32dd74) |
| 4 | 0xc17ea94008d5a8ee86f120e092cd35a679166416 | 59,548 | 12,647,040,432 | 212,383 | [View](https://etherscan.io/address/0xc17ea94008d5a8ee86f120e092cd35a679166416) |
| 5 | 0x148ee7daf16574cd020afa34cc658f8f3fbd2800 | 4,409 | 11,475,576,948 | 2,602,761 | [View](https://etherscan.io/address/0x148ee7daf16574cd020afa34cc658f8f3fbd2800) |
| 6 | 0x16f09b37b20bfbb07130bba8226299926e39b488 | 14,598 | 9,858,634,629 | 675,341 | [View](https://etherscan.io/address/0x16f09b37b20bfbb07130bba8226299926e39b488) |
| 7 | 0x6860c4ee678d847ae67771f2e5eea96ccb7fdf8d | 81,588 | 8,129,909,932 | 99,645 | [View](https://etherscan.io/address/0x6860c4ee678d847ae67771f2e5eea96ccb7fdf8d) |
| 8 | 0xf4ceb19b2467ef784b5e83b863418c50997b1646 | 18,119 | 7,588,481,162 | 418,813 | [View](https://etherscan.io/address/0xf4ceb19b2467ef784b5e83b863418c50997b1646) |
| 9 | 0x646c4fbdf82b5766c5eaf1fab9a8927fb5992d38 | 118,451 | 7,384,356,334 | 62,341 | [View](https://etherscan.io/address/0x646c4fbdf82b5766c5eaf1fab9a8927fb5992d38) |
| 10 | 0x0373b1ed3b9e601bb8b17afde70b0ccab76a981d | 158,514 | 7,277,663,018 | 45,911 | [View](https://etherscan.io/address/0x0373b1ed3b9e601bb8b17afde70b0ccab76a981d) |
| 11 | 0xe2da046340e00264c4f0443243a0565007ae08ac | 3,944 | 5,940,541,350 | 1,506,222 | [View](https://etherscan.io/address/0xe2da046340e00264c4f0443243a0565007ae08ac) |
| 12 | 0xa7ec2be4ed79ef315b4301aeca424a2dfdeaf09a | 65,856 | 5,616,659,491 | 85,286 | [View](https://etherscan.io/address/0xa7ec2be4ed79ef315b4301aeca424a2dfdeaf09a) |
| 13 | 0x7835fb36a8143a014a2c381363cd1a4dee586d2a | 2,887 | 5,601,056,603 | 1,940,095 | [View](https://etherscan.io/address/0x7835fb36a8143a014a2c381363cd1a4dee586d2a) |
| 14 | 0xf2099c4783921f44ac988b67e743daefd4a00efd | 1,436 | 4,201,896,151 | 2,926,111 | [View](https://etherscan.io/address/0xf2099c4783921f44ac988b67e743daefd4a00efd) |
| 15 | 0x7804405f18e134c3c47d71ae02eb454d25722d88 | 678 | 4,153,379,856 | 6,125,928 | [View](https://etherscan.io/address/0x7804405f18e134c3c47d71ae02eb454d25722d88) |
| 16 | 0xfe9dcec48761d2826e3e3d95597462dfb281db79 | 48,221 | 4,047,228,659 | 83,930 | [View](https://etherscan.io/address/0xfe9dcec48761d2826e3e3d95597462dfb281db79) |
| 17 | 0x1346d9c6315f6c23fe280b49ef215aebd49338b2 | 6,211 | 3,673,122,501 | 591,389 | [View](https://etherscan.io/address/0x1346d9c6315f6c23fe280b49ef215aebd49338b2) |
| 18 | 0x5f62d006c10c009ff50c878cd6157ac861c99990 | 7,952 | 3,655,219,300 | 459,660 | [View](https://etherscan.io/address/0x5f62d006c10c009ff50c878cd6157ac861c99990) |
| 19 | 0x3f773dc3ccc70b3d2a549713ac8d556af949d4e8 | 1,323 | 3,653,595,781 | 2,761,599 | [View](https://etherscan.io/address/0x3f773dc3ccc70b3d2a549713ac8d556af949d4e8) |
| 20 | 0xc8a5849a02ad01b572a0108aebf5a0d27777a552 | 63,707 | 3,484,943,560 | 54,702 | [View](https://etherscan.io/address/0xc8a5849a02ad01b572a0108aebf5a0d27777a552) |
| 21 | 0x30c2f77eaa93aace5e56ea4dcba5f21f794b58be | 687 | 3,326,641,119 | 4,842,272 | [View](https://etherscan.io/address/0x30c2f77eaa93aace5e56ea4dcba5f21f794b58be) |
| 22 | 0xcbeb5d484b54498d3893a0c3eb790331962e9e9d | 7,602 | 2,716,498,081 | 357,339 | [View](https://etherscan.io/address/0xcbeb5d484b54498d3893a0c3eb790331962e9e9d) |
| 23 | 0xd312535f0104a45ebd16cd29756fe9e6f8fe633c | 42,892 | 2,461,082,112 | 57,378 | [View](https://etherscan.io/address/0xd312535f0104a45ebd16cd29756fe9e6f8fe633c) |
| 24 | 0xb947d63b578fb48233de4076407dd0498dcf36ab | 584 | 2,431,099,134 | 4,162,840 | [View](https://etherscan.io/address/0xb947d63b578fb48233de4076407dd0498dcf36ab) |
| 25 | 0x1c9a7a489f62a75e276d3790ba92aaf12af13469 | 6,923 | 2,145,392,271 | 309,893 | [View](https://etherscan.io/address/0x1c9a7a489f62a75e276d3790ba92aaf12af13469) |
| 26 | 0xf3d021d51a725f5dbdce253248e826a8644be3c1 | 3,693 | 2,063,909,478 | 558,870 | [View](https://etherscan.io/address/0xf3d021d51a725f5dbdce253248e826a8644be3c1) |
| 27 | 0x2b4820042fe6a5b8ab01b29ede19203181d625fa | 18,285 | 1,880,349,910 | 102,835 | [View](https://etherscan.io/address/0x2b4820042fe6a5b8ab01b29ede19203181d625fa) |
| 28 | 0xf6309d5a91fa559cbf8f6ff3c5ec8fb67fe38577 | 628 | 1,830,917,976 | 2,915,474 | [View](https://etherscan.io/address/0xf6309d5a91fa559cbf8f6ff3c5ec8fb67fe38577) |
| 29 | 0x000cb000e880a92a8f383d69da2142a969b93de7 | 5,223 | 1,787,396,594 | 342,216 | [View](https://etherscan.io/address/0x000cb000e880a92a8f383d69da2142a969b93de7) |
| 30 | 0x785cd82bb016c740d41ca9e0b1bacc3a2439dc0d | 23,798 | 1,666,264,939 | 70,017 | [View](https://etherscan.io/address/0x785cd82bb016c740d41ca9e0b1bacc3a2439dc0d) |

### Key Observations

- **Top single address** (0x54b839d988c9e712cd36cbf7c95dedc2b9f9ae6c) accounts for 19.6% of all additional costs with 44,296 transactions
- **Highest volume address** (0x0373b1ed3b9e601bb8b17afde70b0ccab76a981d) has 158,514 affected transactions but only 45,911 gas average increase per transaction
- **Highest per-transaction impact** (0xe08cdadd44440e32ef153956a7ec40804a32dd74) shows 7.4M gas average increase per transaction

### Cost Impact

| Metric | Value |
|--------|-------|
| Mean cost increase per transaction | 101,489.08 gas units |
| Median cost increase per transaction | 11,444 gas units |

## Address Concentration Analysis

### Transaction Distribution

| Address Group | Count | Percentage |
|---------------|-------|------------|
| 1 affected transaction | 388,216 | 60.98% |
| ≤10 affected transactions | 611,619 | 96.08% |
| ≤50 affected transactions | 632,916 | 99.43% |
| ≤100 affected transactions | 634,730 | 99.71% |
| ≤200 affected transactions | 635,491 | 99.83% |
| ≤400 affected transactions | 635,926 | 99.90% |

### Transaction Volume Concentration

| Top Addresses | % of Affected Transactions |
|---------------|---------------------------|
| Top 10 | 26.79% |
| Top 20 | 33.47% |
| Top 30 | 37.17% |
| Top 40 | 39.70% |
| Top 50 | 41.76% |

### Transaction Volume by Percentiles

| Address Percentile | % of Affected Transactions |
|-------------------|---------------------------|
| Top 10% | 47.70% |
| Top 20% | 54.00% |
| Top 30% | 56.74% |
| Top 40% | 58.57% |
| Top 50% | 59.92% |

### Cost Impact Concentration

| Top Addresses | % of Additional Costs |
|---------------|----------------------|
| Top 10 | 55.28% |
| Top 20 | 63.90% |
| Top 30 | 68.26% |
| Top 40 | 71.15% |
| Top 50 | 73.64% |

### Cost Impact by Percentiles

| Address Percentile | % of Additional Costs |
|-------------------|----------------------|
| Top 1% | 91.44% |
| Top 10% | 97.31% |
| Top 20% | 98.75% |
| Top 30% | 99.40% |
| Top 40% | 99.72% |
| Top 50% | 99.87% |

## Method Analysis

### Top 20 Affected Function Selectors

| Rank | Function Selector | Transactions | Total Cost Increase | Avg Cost/Tx | Method Name |
|------|------------------|--------------|---------------------|-------------|-------------|
| 1 | 0x5578ceae | 28,355 | 94,835,044,230 | 3,343,786 | registerContinuousMemoryPage(...) |
| 2 | 0x538f9406 | 27,826 | 93,972,171,674 | 3,377,149 | updateState(uint256[],uint256[]) |
| 3 | 0x87201b41 | 70,794 | 26,600,051,568 | 375,772 | fulfillAvailableAdvancedOrders(...) |
| 4 | 0x5e10b3f0 | 379,355 | 22,244,424,770 | 58,646 | workMyDirefulOwner(uint256,uint256) |
| 5 | 0xfd9f1e10 | 191,576 | 18,205,559,712 | 95,012 | cancel(...) |
| 6 | 0xf074ba62 | 3,827 | 9,634,717,355 | 2,517,565 | verifyCheckpointProofs(...) |
| 7 | 0x09c5eabe | 42,105 | 8,765,393,130 | 208,186 | execute(bytes) |
| 8 | 0x6fadcf72 | 72,208 | 5,516,170,528 | 76,366 | forward(address,bytes) |
| 9 | 0xe85a6a28 | 16,654 | 4,985,983,858 | 299,377 | verifyFRI(...) |
| 10 | 0x415e2848 | 74,876 | 3,076,701,516 | 41,091 | swap_6269342730() |
| 11 | 0x3fe317a6 | 7,137 | 2,743,013,450 | 384,350 | verifyMerkle(...) |
| 12 | 0x55944a42 | 35,064 | 2,610,534,480 | 74,445 | matchAdvancedOrders(...) |
| 13 | 0x82ad56cb | 19,638 | 2,582,341,458 | 131,491 | aggregate3((address,bool,bytes)[]) |
| 14 | 0xe7acab24 | 25,484 | 2,080,247,964 | 81,621 | fulfillAdvancedOrder(...) |
| 15 | 0x13d79a0b | 21,713 | 1,555,462,876 | 71,652 | settleOrders(bytes) |
| 16 | 0xbb2f45e1 | 4,214 | 1,061,775,096 | 251,964 | submitV1(...) |
| 17 | 0x64971c46 | 13,972 | 1,002,671,000 | 71,750 | swap(...) |
| 18 | 0x4c2c47bd | 630 | 931,755,480 | 1,478,976 | bulkRegisterValidator(...) |

### Key Methods by Category

#### Zero-Knowledge Proof Systems

- **registerContinuousMemoryPage**: 28,355 txs, avg 3,343,786 gas increase
- **updateState**: 27,826 txs, avg 3,377,149 gas increase
- **verifyCheckpointProofs**: 3,827 txs, avg 2,517,565 gas increase
- **verifyFRI**: 16,654 txs, avg 299,377 gas increase
- **verifyMerkle**: 7,137 txs, avg 384,350 gas increase

#### NFT Marketplace Operations

- **fulfillAvailableAdvancedOrders**: 70,794 txs, avg 375,772 gas increase
- **matchAdvancedOrders**: 35,064 txs, avg 74,445 gas increase
- **fulfillAdvancedOrder**: 25,484 txs, avg 81,621 gas increase
- **cancel**: 191,576 txs, avg 95,012 gas increase

#### Multi-signature/Proxy Operations

- **forward**: 72,208 txs, avg 76,366 gas increase
- **execute**: 42,105 txs, avg 208,186 gas increase
- **aggregate3**: 19,638 txs, avg 131,491 gas increase

## EIP-7623 Interaction Analysis

### Linear Cost Increase

The analysis reveals that **41.6% of transactions affected by EIP-7976 are already impacted by EIP-7623**. This means:

- **2,093,004 transactions** (0.85% of all transactions) will experience **linear cost increases** as calldata pricing moves from EIP-7623 rates to EIP-7976 rates
- **2,942,610 transactions** (1.20% of all transactions) represent new impact from EIP-7976

### Pricing Structure Comparison

| Byte Type | Current | EIP-7623 | EIP-7976 | 7623→7976 Increase |
|-----------|---------|----------|----------|-------------------|
| Zero bytes | 4 gas | 10 gas | 64 gas | +54 gas (540%) |
| Non-zero bytes | 16 gas | 40 gas | 64 gas | +24 gas (60%) |


### Key Findings

1. **High Concentration**: Cost impact is extremely concentrated with top 1% of addresses responsible for 91.44% of additional costs

2. **EIP-7623 Linear Escalation**: A significant portion of affected transactions (41.6%) will see linear cost increases from existing EIP-7623 pricing

3. **Address Distribution**: 60.98% of affected addresses have only 1 affected transaction, indicating diverse but minimal user impact

4. **Methods**: Impact is dominated by zero-knowledge proof operations and NFT marketplace operations, with additional impact from multi-signature/proxy operations

5. **Cost Variance**: Median increase (11,444 gas) vs mean increase (101,489.08 gas) shows high variance in impact severity

6. **Broader Impact**: With 64/64 pricing, 2.05% of transactions are affected (vs 1.48% with 15/60 pricing), representing a 38.5% increase in affected transaction count