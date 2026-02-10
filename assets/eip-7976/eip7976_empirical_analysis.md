# EIP-7976 Empirical Report

*The following represents a summary with empirical findings from analyzing EIP-7976's impact on transactions.*
*Date: November, 2025*

## Dataset

- **Period**: 150 days of Ethereum mainnet data (June-November 2025)
- **Blocks analyzed**: 1,080,000 blocks
- **Total transactions**: 223,626,649

## Overall Impact Metrics

### Transaction Impact Summary

| Metric | Value |
|--------|-------|
| Total unaffected transactions | 220,322,233 (98.52%) |
| Total affected transactions | 3,304,416 (1.48%) |
| Transactions already affected by EIP-7623 | 2,808,580 (1.26%) |
| New transactions affected by EIP-7976 only | 495,836 (0.22%) |
| EIP-7623 overlap percentage | 85.0% |

### Address Distribution

| Metric | Value |
|--------|-------|
| Unique unaffected senders | 30,849,352 (98.4%) |
| Unique affected senders | 503,397 (1.6%) |
| Unique affected recipients | 711,303 (3.4%) |
| Avg transactions per affected sender | 6.56 |
| Avg transactions per affected recipient | 4.65 |

## Gas Usage Analysis (Affected Transactions)

### Basic Gas Metrics

| Metric | Value |
|--------|-------|
| Mean gas used | 86,968 |
| Median gas used | 22,280 |
| Average calldata bytes | 2,271 |
| Average zero bytes | 889 |
| Average non-zero bytes | 1,382 |

## Most Affected Senders

### Top 30 Senders by Additional Cost Impact

| Rank | Address | Transactions | Total Cost Increase (gas) | Avg Cost/Tx | Etherscan Link |
|------|---------|--------------|---------------------------|-------------|----------------|
| 1 | 0xe08cdadd44440e32ef153956a7ec40804a32dd74 | 1,941 | 9,617,746,280 | 4,955,047 | [View](https://etherscan.io/address/0xe08cdadd44440e32ef153956a7ec40804a32dd74) |
| 2 | 0x54b839d988c9e712cd36cbf7c95dedc2b9f9ae6c | 21,616 | 9,347,719,424 | 432,444 | [View](https://etherscan.io/address/0x54b839d988c9e712cd36cbf7c95dedc2b9f9ae6c) |
| 3 | 0xcbe6fbf5e3c427013688e04d0fde56705890c4be | 17,110 | 8,648,757,461 | 505,479 | [View](https://etherscan.io/address/0xcbe6fbf5e3c427013688e04d0fde56705890c4be) |
| 4 | 0x148ee7daf16574cd020afa34cc658f8f3fbd2800 | 6,757 | 5,722,544,035 | 846,906 | [View](https://etherscan.io/address/0x148ee7daf16574cd020afa34cc658f8f3fbd2800) |
| 5 | 0xfe325f97146124f3767bfa59899fa4177fd46d2f | 20,453 | 4,254,261,084 | 208,001 | [View](https://etherscan.io/address/0xfe325f97146124f3767bfa59899fa4177fd46d2f) |
| 6 | 0x7804405f18e134c3c47d71ae02eb454d25722d88 | 699 | 3,176,420,025 | 4,544,234 | [View](https://etherscan.io/address/0x7804405f18e134c3c47d71ae02eb454d25722d88) |
| 7 | 0xe2da046340e00264c4f0443243a0565007ae08ac | 5,311 | 3,168,185,085 | 596,532 | [View](https://etherscan.io/address/0xe2da046340e00264c4f0443243a0565007ae08ac) |
| 8 | 0x7835fb36a8143a014a2c381363cd1a4dee586d2a | 2,413 | 3,010,568,114 | 1,247,645 | [View](https://etherscan.io/address/0x7835fb36a8143a014a2c381363cd1a4dee586d2a) |
| 9 | 0xed9b8f05224b881a222ece2e20bd2f4bdb71d0f8 | 1,859 | 2,395,235,905 | 1,288,453 | [View](https://etherscan.io/address/0xed9b8f05224b881a222ece2e20bd2f4bdb71d0f8) |
| 10 | 0xf2099c4783921f44ac988b67e743daefd4a00efd | 1,131 | 2,164,837,191 | 1,914,091 | [View](https://etherscan.io/address/0xf2099c4783921f44ac988b67e743daefd4a00efd) |
| 11 | 0x570c531810ce02feb5eb2a9e1a2405464c82a7ec | 1,414 | 2,050,545,330 | 1,450,173 | [View](https://etherscan.io/address/0x570c531810ce02feb5eb2a9e1a2405464c82a7ec) |
| 12 | 0xb947d63b578fb48233de4076407dd0498dcf36ab | 608 | 2,034,689,485 | 3,346,528 | [View](https://etherscan.io/address/0xb947d63b578fb48233de4076407dd0498dcf36ab) |
| 13 | 0xf6309d5a91fa559cbf8f6ff3c5ec8fb67fe38577 | 702 | 1,848,495,220 | 2,633,184 | [View](https://etherscan.io/address/0xf6309d5a91fa559cbf8f6ff3c5ec8fb67fe38577) |
| 14 | 0x980c1999f4e0878c4910d4a1de2123ef040be07b | 832 | 1,785,823,230 | 2,146,422 | [View](https://etherscan.io/address/0x980c1999f4e0878c4910d4a1de2123ef040be07b) |
| 15 | 0x3f773dc3ccc70b3d2a549713ac8d556af949d4e8 | 974 | 1,713,010,497 | 1,758,737 | [View](https://etherscan.io/address/0x3f773dc3ccc70b3d2a549713ac8d556af949d4e8) |
| 16 | 0x89b2c022a08aa8c849c30d5e72e147932b76b628 | 723 | 1,455,357,225 | 2,012,942 | [View](https://etherscan.io/address/0x89b2c022a08aa8c849c30d5e72e147932b76b628) |
| 17 | 0x8934c6bfe73e8b43c78459744d7c373eedb10876 | 409 | 1,403,884,590 | 3,432,480 | [View](https://etherscan.io/address/0x8934c6bfe73e8b43c78459744d7c373eedb10876) |
| 18 | 0x9a05d4bc192ba1c73b47011652adaded3add8308 | 623 | 1,351,546,475 | 2,169,416 | [View](https://etherscan.io/address/0x9a05d4bc192ba1c73b47011652adaded3add8308) |
| 19 | 0x2c3b6e74be767cd9722cdf4a4ca08c6910012b0a | 311 | 1,301,603,445 | 4,185,220 | [View](https://etherscan.io/address/0x2c3b6e74be767cd9722cdf4a4ca08c6910012b0a) |
| 20 | 0xf6624e1a9cb8143091fa6916fa56c1cf3bb1be64 | 404 | 1,152,839,500 | 2,853,563 | [View](https://etherscan.io/address/0xf6624e1a9cb8143091fa6916fa56c1cf3bb1be64) |
| 21 | 0x8595753b4cbffba64cb2e8d167fd25a2d448b5fa | 422 | 892,776,365 | 2,115,583 | [View](https://etherscan.io/address/0x8595753b4cbffba64cb2e8d167fd25a2d448b5fa) |
| 22 | 0xf3d021d51a725f5dbdce253248e826a8644be3c1 | 3,168 | 829,432,199 | 261,815 | [View](https://etherscan.io/address/0xf3d021d51a725f5dbdce253248e826a8644be3c1) |
| 23 | 0x62815399f1bc394445ef9a47daed86b9061d9641 | 4,367 | 792,030,012 | 181,367 | [View](https://etherscan.io/address/0x62815399f1bc394445ef9a47daed86b9061d9641) |
| 24 | 0xf70da97812cb96acdf810712aa562db8dfa3dbef | 1,140,536 | 790,076,999 | 692 | [View](https://etherscan.io/address/0xf70da97812cb96acdf810712aa562db8dfa3dbef) |
| 25 | 0x0cad34b170a8e80b60f272d5ea9393f1b4cb7892 | 237 | 778,113,180 | 3,283,177 | [View](https://etherscan.io/address/0x0cad34b170a8e80b60f272d5ea9393f1b4cb7892) |
| 26 | 0x4cae788442670a46fd371850b0727224fcd63799 | 245 | 750,445,410 | 3,063,042 | [View](https://etherscan.io/address/0x4cae788442670a46fd371850b0727224fcd63799) |
| 27 | 0x3b17facdd5e8be0029a68e10743b4cf24f37d030 | 78 | 666,051,985 | 8,539,128 | [View](https://etherscan.io/address/0x3b17facdd5e8be0029a68e10743b4cf24f37d030) |
| 28 | 0x30c2f77eaa93aace5e56ea4dcba5f21f794b58be | 183 | 605,419,645 | 3,308,304 | [View](https://etherscan.io/address/0x30c2f77eaa93aace5e56ea4dcba5f21f794b58be) |
| 29 | 0xdfd3f1f53e8da33fff6851e7908ef472496d738a | 227 | 529,185,625 | 2,331,214 | [View](https://etherscan.io/address/0xdfd3f1f53e8da33fff6851e7908ef472496d738a) |
| 30 | 0x09b96417602ed6ac76651f7a8c4860e60e3aa6d0 | 46,490 | 484,677,580 | 10,425 | [View](https://etherscan.io/address/0x09b96417602ed6ac76651f7a8c4860e60e3aa6d0) |

### Key Observations

- **Top single address** (0xe08cdadd44440e32ef153956a7ec40804a32dd74) accounts for 9.6% of all additional costs with only 1,941 transactions
- **Highest volume address** (0xf70da97812cb96acdf810712aa562db8dfa3dbef) has 1,140,536 affected transactions but only 692 gas average increase per transaction
- **Highest per-transaction impact** (0x3b17facdd5e8be0029a68e10743b4cf24f37d030) shows 8.5M gas average increase per transaction

### Cost Impact

| Metric | Value |
|--------|-------|
| Mean cost increase per transaction | 30,287.65 gas units |
| Median cost increase per transaction | 640 gas units |

## Address Concentration Analysis

### Transaction Distribution

| Address Group | Count | Percentage |
|---------------|-------|------------|
| 1 affected transaction | 293,132 | 58.23% |
| ≤10 affected transactions | 492,333 | 97.80% |
| ≤50 affected transactions | 502,047 | 99.73% |
| ≤100 affected transactions | 502,640 | 99.85% |
| ≤200 affected transactions | 502,894 | 99.90% |
| ≤400 affected transactions | 503,041 | 99.93% |

### Transaction Volume Concentration

| Top Addresses | % of Affected Transactions |
|---------------|---------------------------|
| Top 10 | 42.40% |
| Top 20 | 46.89% |
| Top 30 | 49.18% |
| Top 40 | 50.87% |
| Top 50 | 52.08% |

### Transaction Volume by Percentiles

| Address Percentile | % of Affected Transactions |
|-------------------|---------------------------|
| Top 10% | 53.17% |
| Top 20% | 56.65% |
| Top 30% | 58.52% |
| Top 40% | 59.94% |
| Top 50% | 61.03% |

### Cost Impact Concentration

| Top Addresses | % of Additional Costs |
|---------------|----------------------|
| Top 10 | 51.46% |
| Top 20 | 67.55% |
| Top 30 | 74.66% |
| Top 40 | 78.46% |
| Top 50 | 81.25% |

### Cost Impact by Percentiles

| Address Percentile | % of Additional Costs |
|-------------------|----------------------|
| Top 1% | 96.99% |
| Top 10% | 98.98% |
| Top 20% | 99.59% |
| Top 30% | 99.81% |
| Top 40% | 99.91% |
| Top 50% | 99.95% |

## Method Analysis

### Top 20 Affected Function Selectors

| Rank | Function Selector | Transactions | Total Cost Increase | Avg Cost/Tx | Method Name |
|------|------------------|--------------|---------------------|-------------|-------------|
| 1 | 0x5578ceae | 25,178 | 11,105,139,785 | 441,065 | registerContinuousMemoryPage(...) |
| 2 | 0x538f9406 | 22,333 | 9,463,956,180 | 423,766 | updateState(uint256[],uint256[]) |
| 3 | 0xf074ba62 | 5,416 | 7,851,409,934 | 1,449,669 | verifyCheckpointProofs(...) |
| 4 | 0x46fa01fa | 2,714 | 7,039,378,930 | 2,593,645 | Unknown |
| 5 | 0xb910e0f9 | 6,757 | 5,722,544,035 | 847,133 | Unknown |
| 6 | 0x2217b211 | 5,348 | 3,177,136,180 | 594,095 | Unknown |
| 7 | 0xc1bceb8c | 1,849 | 2,357,236,963 | 1,274,873 | Unknown |
| 8 | 0xe85a6a28 | 12,971 | 1,862,516,315 | 143,591 | verifyFRI(...) |
| 9 | 0x46fa040c | 296 | 1,570,922,320 | 5,307,844 | Unknown |
| 10 | 0x46fa03a0 | 277 | 1,316,313,155 | 4,752,738 | Unknown |
| 11 | 0x46fa01f4 | 423 | 1,081,763,690 | 2,557,536 | Unknown |
| 12 | 0x46fa026d | 334 | 1,062,924,940 | 3,182,410 | Unknown |
| 13 | 0x46fa01f0 | 410 | 1,041,783,285 | 2,541,179 | Unknown |
| 14 | 0x6fadcf72 | 56,605 | 1,014,588,648 | 17,924 | forward(address,bytes) |
| 15 | 0x623b223d | 4,213 | 924,216,060 | 219,423 | Unknown |
| 16 | 0x46fa030d | 221 | 884,022,100 | 4,000,100 | Unknown |
| 17 | 0x3fe317a6 | 5,559 | 827,995,875 | 148,925 | verifyMerkle(...) |
| 18 | 0x46fa018f | 396 | 817,798,600 | 2,065,147 | Unknown |
| 19 | 0x46fa0e3d | 43 | 802,503,595 | 18,662,874 | Unknown |
| 20 | 0x46fa06b8 | 90 | 792,783,660 | 8,808,707 | Unknown |

### Key Methods by Category

#### Zero-Knowledge Proof Systems

- **registerContinuousMemoryPage**: 25,178 txs, avg 441,065 gas increase
- **updateState**: 22,333 txs, avg 423,766 gas increase
- **verifyCheckpointProofs**: 5,416 txs, avg 1,449,669 gas increase
- **verifyFRI**: 12,971 txs, avg 143,591 gas increase
- **verifyMerkle**: 5,559 txs, avg 148,925 gas increase

#### Multi-signature/Proxy Operations

- **forward**: 56,605 txs, avg 17,924 gas increase

## EIP-7623 Interaction Analysis

### Linear Cost Increase

The analysis reveals that **85.0% of transactions affected by EIP-7976 are already impacted by EIP-7623**. This means:

- **2,808,580 transactions** (1.26% of all transactions) will experience **linear cost increases** as calldata pricing moves from EIP-7623 rates to EIP-7976 rates
- **495,836 transactions** (0.22% of all transactions) represent new impact from EIP-7976

### Pricing Structure Comparison

| Byte Type | Current | EIP-7623 | EIP-7976 | 7623→7976 Increase |
|-----------|---------|----------|----------|-------------------|
| Zero bytes | 4 gas | 10 gas | 15 gas | +5 gas (50%) |
| Non-zero bytes | 16 gas | 40 gas | 60 gas | +20 gas (50%) |


### Key Findings

1. **High Concentration**: Cost impact is extremely concentrated with top 1% of addresses responsible for 96.99% of additional costs

2. **EIP-7623 Linear Escalation**: Most affected transactions (85.0%) will see linear cost increases from existing EIP-7623 pricing

3. **Address Distribution**: 58.23% of affected addresses have only 1 affected transaction, indicating diverse but minimal user impact

4. **Methods**: Impact is dominated by zero-knowledge proof operations, with additional impact from multi-signature/proxy operations

5. **Cost Variance**: Median increase (640 gas) vs mean increase (30,287.65 gas) shows high variance in impact severity
