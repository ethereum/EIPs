# EIP-7883 ModExp Analysis Report

*Generated on 2025-07-21 13:34:56*

## Executive Summary

This report provides an analysis of EIP-7883's impact on ModExp operations based on 304,301 historical Ethereum mainnet calls using the pricing formula from the latest EIP-7883 specification.

### Key Metrics

**Overall Impact:**
- **Total ModExp calls analyzed**: 304,301
- **Unique transactions**: 75,134
- **Calls with cost increases**: 304301 (100.0%)
- **Total additional gas required**: 542947771 gas
- **Average cost increase**: 1,784.25 gas per call
- **Maximum single call increase**: 64027 gas

**Economic Impact:**
- **Network congestion**: Average 0.006% of block gas limit
- **Cost predictability**: 100% of calls affected with 2.81x average increase

## Updated Pricing Formula

The EIP-7883 specification introduces three key changes:

1. **Minimum gas cost**: Increased from 200 to 500
2. **General multiplier**: Removed division by 3 (effectively 3x increase)
3. **Large exponent multiplier**: Doubled from 8 to 16 for exponents > 32 bytes
4. **Base multiplication complexity**: Minimum of 16, doubles for sizes > 32 bytes

## Parameter Analysis

### Input Size Distributions

**Statistical Summary:**

| Parameter | Min | Max | Mean | Median | Std Dev |
|-----------|-----|-----|------|--------|---------|
| Bsize | 32 | 385 | 32.0 | 32.0 | 2.7 |
| Esize | 1 | 32 | 32.0 | 32.0 | 0.4 |
| Msize | 32 | 384 | 32.0 | 32.0 | 2.7 |

**Common Size Combinations:**

| Base Size | Exponent Size | Modulus Size | Count | Percentage |
|-----------|---------------|--------------|-------|------------|
| 32 | 32 | 32 | 304,225 | 100.0% |
| 256 | 3 | 256 | 31 | 0.0% |
| 128 | 1 | 128 | 27 | 0.0% |
| 128 | 32 | 128 | 10 | 0.0% |
| 128 | 3 | 128 | 6 | 0.0% |
| 385 | 3 | 384 | 2 | 0.0% |

### Exponent Analysis

**Fermat Prime Usage**: 1,351 calls (0.4%)

**Most Common Exponent Values:**

| Rank | Exponent | Count | Percentage |
|------|----------|-------|------------|
| 1 | 0x30644e72... | 66,115 | 21.73% |
| 2 | 0xffffffff... | 54,656 | 17.96% |
| 3 | 0x1000000 | 50,599 | 16.63% |
| 4 | 0xffffff | 43,887 | 14.42% |
| 5 | 0xffffffff... | 28,955 | 9.52% |
| 6 | 0xc19139cb... | 20,644 | 6.78% |
| 7 | 0x3fffffff... | 15,463 | 5.08% |
| 8 | 0x1000002 | 6,703 | 2.20% |
| 9 | 0xa59c34 | 6,352 | 2.09% |
| 10 | 0x2000000 | 1,699 | 0.56% |

## Gas Cost Analysis

### Cost Distribution

| Cost Increase Range | Call Count | Percentage |
|-------------------|------------|------------|
| <500 gas | 116,974 | 38.4% |
| 500-1K gas | 0 | 0.0% |
| 1K-5K gas | 187,278 | 61.5% |
| 5K-10K gas | 16 | 0.0% |
| 10K-50K gas | 31 | 0.0% |
| >50K gas | 2 | 0.0% |

### Cost Increase Percentiles

| Percentile | Gas Increase |
|------------|--------------|
| 10th | 300 |
| 25th | 300 |
| 50th | 2,699 |
| 75th | 2,720 |
| 90th | 2,720 |
| 95th | 2,720 |
| 99th | 2,720 |

## Entity Analysis

### Most Impacted Senders

| Rank | Address | Total Increase (gas) | Avg Increase | Call Count | Current Cost | New Cost |
|------|---------|---------------------|--------------|------------|--------------|----------|
| 1 | [0x00000062...](https://etherscan.io/address/0x000000629fbcf27a347d1aeba658435230d74a5f) | 14,062,311 | 1,499.50 | 9,378 | 7,263,261 | 21,325,572 |
| 2 | [0x7202932b...](https://etherscan.io/address/0x7202932b3be70edf0657d5bada261d610e0d7db9) | 8,315,040 | 2,720 | 3,057 | 4,157,520 | 12,472,560 |
| 3 | [0xaaf7b278...](https://etherscan.io/address/0xaaf7b278bac078aa4f9bdc8e0a93cde604aa67d9) | 7,219,891 | 902.37 | 8,001 | 3,908,541 | 11,128,432 |
| 4 | [0x454ef2f6...](https://etherscan.io/address/0x454ef2f69f91527856e06659f92a66f464c1ca4e) | 7,190,430 | 2,678 | 2,685 | 3,592,530 | 10,782,960 |
| 5 | [0x54ab716d...](https://etherscan.io/address/0x54ab716d465be3d5eeca64e63ac0048d7a81659a) | 6,794,898 | 913.29 | 7,440 | 3,673,398 | 10,468,296 |
| 6 | [0xfcb73f64...](https://etherscan.io/address/0xfcb73f6405f6b9be91013d9477d81833a69c9c0d) | 6,216,927 | 1,499.50 | 4,146 | 3,211,077 | 9,428,004 |
| 7 | [0xf3b07f67...](https://etherscan.io/address/0xf3b07f6744e06cd5074b7d15ed2c33760837ce1f) | 3,045,348 | 912.33 | 3,338 | 1,646,548 | 4,691,896 |
| 8 | [0x4337001f...](https://etherscan.io/address/0x4337001fff419768e088ce247456c1b892888084) | 2,777,120 | 2,720 | 1,021 | 1,388,560 | 4,165,680 |
| 9 | [0x4337003f...](https://etherscan.io/address/0x4337003fcd2f56de3977ccb806383e9161628d0e) | 2,717,280 | 2,720 | 999 | 1,358,640 | 4,075,920 |
| 10 | [0x4337002c...](https://etherscan.io/address/0x4337002c5702ce424cb62a56ca038e31e1d4a93d) | 2,652,000 | 2,720 | 975 | 1,326,000 | 3,978,000 |
| 11 | [0x4337005d...](https://etherscan.io/address/0x4337005db25dbad41da5692ba1188751ee5d98b6) | 2,589,440 | 2,720 | 952 | 1,294,720 | 3,884,160 |
| 12 | [0x4337004e...](https://etherscan.io/address/0x4337004ec9c1417f1c7a26ebd4b4fbed6acf9e5d) | 2,586,720 | 2,720 | 951 | 1,293,360 | 3,880,080 |
| 13 | [0x58d14960...](https://etherscan.io/address/0x58d14960e0a2be353edde61ad719196a2b816522) | 1,476,481 | 939.84 | 1,571 | 795,631 | 2,272,112 |
| 14 | [0x6f9d816c...](https://etherscan.io/address/0x6f9d816c4ec365fe8fc6898c785be0e2d51bec2c) | 1,416,975 | 2,699 | 525 | 708,225 | 2,125,200 |
| 15 | [0xc2adcfcc...](https://etherscan.io/address/0xc2adcfccee33a417064d1a45d3b202de6d9fa474) | 1,232,589 | 1,499.50 | 822 | 636,639 | 1,869,228 |

### Most Impacted Contracts

| Rank | Contract | Total Increase (gas) | Avg per Call | Calls | Unique Users | Current Cost | New Cost |
|------|----------|---------------------|--------------|-------|--------------|--------------|----------|
| 1 | [0x5ff137d4...](https://etherscan.io/address/0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789) | 30,654,400 | 2,720 | 11,270 | 73 | 15,327,200 | 45,981,600 |
| 2 | [0x68d30f47...](https://etherscan.io/address/0x68d30f47f19c07bccef4ac7fae2dc12fca3e0dc9) | 14,062,311 | 1,499.50 | 9,378 | 1 | 7,263,261 | 21,325,572 |
| 3 | [0x8c0bfc04...](https://etherscan.io/address/0x8c0bfc04ada21fd496c55b8c50331f904306f564) | 13,028,282 | 951.25 | 13,696 | 17 | 7,011,182 | 20,039,464 |
| 4 | [0x5d8ba173...](https://etherscan.io/address/0x5d8ba173dc6c3c90c8f7c04c9288bef5fdbad06e) | 9,141,460 | 899.75 | 10,160 | 9 | 4,950,460 | 14,091,920 |
| 5 | [0x870679e1...](https://etherscan.io/address/0x870679e138bcdf293b7ff14dd44b70fc97e12fc0) | 7,190,430 | 2,678 | 2,685 | 1 | 3,592,530 | 10,782,960 |
| 6 | [0x3b4d794a...](https://etherscan.io/address/0x3b4d794a66304f130a4db8f2551b0070dfcf5ca7) | 6,216,927 | 1,499.50 | 4,146 | 1 | 3,211,077 | 9,428,004 |
| 7 | [0xa13baf47...](https://etherscan.io/address/0xa13baf47339d63b743e7da8741db5456dac1e556) | 1,416,975 | 2,699 | 525 | 1 | 708,225 | 2,125,200 |
| 8 | [0xd7f86b4b...](https://etherscan.io/address/0xd7f86b4b8cae7d942340ff628f82735b7a20893a) | 1,260,433 | 2,699 | 467 | 3 | 629,983 | 1,890,416 |
| 9 | [0x02993cdc...](https://etherscan.io/address/0x02993cdc11213985b9b13224f3af289f03bf298d) | 1,232,589 | 1,499.50 | 822 | 1 | 636,639 | 1,869,228 |
| 10 | [0xece9cf6a...](https://etherscan.io/address/0xece9cf6a8f2768a3b8b65060925b646afeaa5167) | 1,130,574 | 1,752.83 | 645 | 1 | 577,746 | 1,708,320 |
| 11 | [0x7cf3876f...](https://etherscan.io/address/0x7cf3876f681dbb6eda8f6ffc45d66b996df08fae) | 1,124,625 | 1,499.50 | 750 | 1 | 580,875 | 1,705,500 |
| 12 | [0x150fe8db...](https://etherscan.io/address/0x150fe8dbb943c372f3e8c31d9c89f1e6a13cbbfd) | 792,688 | 2,678 | 296 | 1 | 396,048 | 1,188,736 |
| 13 | [0x00000000...](https://etherscan.io/address/0x0000000071727de22e5e9d8baf0edac6f37da032) | 685,440 | 2,720 | 252 | 7 | 342,720 | 1,028,160 |
| 14 | [0xd19d4b5d...](https://etherscan.io/address/0xd19d4b5d358258f05d7b411e21a1460d11b0876f) | 575,808 | 1,499.50 | 384 | 1 | 297,408 | 873,216 |
| 15 | [0x92ef6af4...](https://etherscan.io/address/0x92ef6af472b39f1b363da45e35530c24619245a4) | 477,723 | 2,699 | 177 | 1 | 238,773 | 716,496 |

## Key Findings and Recommendations

### Impact Summary

1. **Universal Impact**: 100% of ModExp calls will see cost increases under the updated EIP-7883
2. **Significant Increases**: Average 2.8x cost increase across all operations
3. **Predictable Changes**: Cost increases follow clear patterns based on input sizes

### Recommendations by Stakeholder

**For Affected Users:**
- Review and update gas limits for all ModExp operations
- Budget for an average 1,784.25 gas increase per call
- Consider optimizing input sizes where possible

**For Infrastructure Providers:**
- Update gas estimation algorithms immediately
- Prepare for universal cost increases across all ModExp calls

---

*Report generated from historical Ethereum mainnet data. All gas calculations verified against the latest EIP-7883 specification.*
