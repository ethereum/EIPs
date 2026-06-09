# EIP-8131 Empirical Impact

Isolated EIP-8131 impact, assuming EIP-7976 is active. Mainnet, last 6 months (2025-11-08 to 2026-05-08), via Xatu.

|  |  |
|---|---:|
| All mainnet txs | 376,262,548 |
| All mainnet senders | 54,160,707 |
| Type-4 txs | 2,658,513 (0.71% of all) |
| Type-4 senders | 208,978 (0.39% of all) |
| **Affected txs** | **3,288** (0.124% of type-4 / 0.001% of all) |
| **Affected senders** | **689** (0.330% of type-4 senders) |
| **Total extra gas (6 mo)** | **27,648,764** |
| Δ per affected tx (median / p95 / p99) | 6,464 / 19,392 / 71,104 |
| Mean / median Δ as share of `gas_C_7976` (EIP-7976 baseline) | 5.53% / 5.18% |
| Affected-tx success rate | **22.0%** (725 succ / 2,563 reverted; vs. 93.6% across all type-4) |

Median Δ = `FLOOR_COST_PER_AUTH` exactly; 80.8% of affected txs are 1-auth delegations whose `intrinsic + execution` already sat below `floor_C`, so EIP-8131 layers cleanly on top. The bulk of the floor-bound population are *reverted* txs whose execution path doesn't burn enough gas to clear the new floor.

## Top affected senders

| # | sender | affected txs | extra gas | max auths | total auths |
|---|---|---:|---:|---:|---:|
| 1 | [`0x59aab1bd…25e16b`](https://etherscan.io/address/0x59aab1bd0d26290274398c07b55955c15425e16b) | 296 | 7,757,005 | 31 | 2,138 |
| 2 | [`0xfc152f3c…40e2b`](https://etherscan.io/address/0xfc152f3cf5c2d2370ee84555bf3d8b1320640e2b) | 7 | 1,639,149 | 130 | 640 |
| 3 | [`0xe46f81fa…0b99ae`](https://etherscan.io/address/0xe46f81faaf19199b3d68762fc3879e42ff0b99ae) | 120 | 771,627 | 1 | 120 |
| 4 | [`0xb9d00655…24da7c`](https://etherscan.io/address/0xb9d00655cae73b4d0905d199150c82d3b124da7c) | 99 | 610,031 | 1 | 99 |
| 5 | [`0x35f8f66c…b4586f`](https://etherscan.io/address/0x35f8f66c6c440433f971ae0775d3bf30f5b4586f) | 98 | 597,045 | 1 | 98 |
| 6 | [`0xbb4d1438…41bcf`](https://etherscan.io/address/0xbb4d14380a6272237cebeb05a98a1cd20bd41bcf) | 90 | 551,606 | 1 | 90 |
| 7 | [`0xec103c6e…58b915`](https://etherscan.io/address/0xec103c6e7e3a674eebc580797fea1b4f9258b915) | 53 | 338,304 | 1 | 53 |
| 8 | [`0x34f41c98…35404f`](https://etherscan.io/address/0x34f41c98898ed0c2f7d004538a7cbde33b35404f) | 53 | 332,248 | 1 | 53 |
| 9 | [`0x6d2ccc86…97df85`](https://etherscan.io/address/0x6d2ccc86fa7afcf6b1b79a32e3167d98ec97df85) | 50 | 312,367 | 1 | 50 |
| 10 | [`0x7d8f6522…1af30a`](https://etherscan.io/address/0x7d8f6522ff026b87e3ae7b202b1afd21191af30a) | 50 | 312,316 | 1 | 50 |

The top sender alone accounts for ~28% of all extra gas. #2 is the cleanest "bypass-shaped" sender: 7 txs at up to 130 auths each.

## Affected by auth count

| auths | type-4 | affected | extra gas | share |
|---:|---:|---:|---:|---:|
| 1 | 2,138,203 | 2,994 | 17,493,597 | 63% |
| 2 | 75,539 | 76 | 800,509 | 3% |
| 3 | 63,608 | 54 | 876,717 | 3% |
| 4-5 | 93,768 | 43 | 996,673 | 4% |
| 6-10 | 118,930 | 29 | 1,042,062 | 4% |
| 11-20 | 98,125 | 48 | 3,085,595 | 11% |
| 21-50 | 57,085 | 37 | 1,714,462 | 6% |
| 51-200 | 10,949 | 7 | 1,639,149 | 6% |
| >200 | 2,306 | 0 | 0 | 0% |

## Method

`num_authorizations` estimated from `tx.size − tx.call_data_size` (≈92 bytes/auth + 117-byte envelope on mainnet); bucket modes verified against the empirical histogram (boundary buckets disagree by ≤1 auth). Today's `gas_used` used as proxy for `intrinsic + execution`, exact for 99.95% of type-4 txs (1,248 rows / 0.05% have `gas_used == floor_A_today`, where the proxy is loose; the isolated metric `Δ = floor_D − floor_C` is invariant to the proxy in that regime, so unaffected). 0 spec violations (`gas_used < floor_A_today`). Long auth-tail (≥51 auths) contributes <6% of total Δ.

## Appendix: context deltas vs. today

| scenario | affected | senders | total extra gas | median Δ | mean Δ / `g` |
|---|---:|---:|---:|---:|---:|
| EIP-8131 only (10/token floor) | 1,595 | 358 | 10,670,600 | 6,464 | 6.2% |
| EIP-7976 only | 2,657 | 565 | 175,924,489 | 31,596 | 32.3% |
| EIP-7976 + EIP-8131 | 3,288 | 689 | 203,573,253 | 33,062 | 32.9% |

Isolated EIP-8131 portion = 27,648,764 (target row above).
