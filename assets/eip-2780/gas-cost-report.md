# EIP-2780 gas cost report

This report presents gas estimates at **75 Mgas/s** for [EIP-2780](../../EIPS/eip-2780.md), using `test_ether_transfers_onchain_receivers` results collected from **September 25 to October 12, 2026**. The source analysis was generated on October 13, 2026 at 12:08:22 UTC and targets the Amsterdam fork.

## Gas parameter estimates by client

Each cell is the client's highest estimate for the indicated transaction case, at **75 Mgas/s**:

- **Transfer to self:** the higher of `ZERO_VALUE_TRANSFER` and `VALUE_TRANSFER` for the self receiver.
- **No-value transfer:** the highest `ZERO_VALUE_TRANSFER` across existing EOAs and all non-delegated contract receivers.
- **Value transfer:** the highest `VALUE_TRANSFER` across the same existing-EOA and non-delegated contract receivers.
- **No-value transfer to delegated account:** the highest `ZERO_VALUE_TRANSFER` across delegated receivers.
- **Value transfer to delegated account:** the highest `VALUE_TRANSFER` across delegated receivers.

Non-existent receivers are excluded from every row. All contract variants are included, at both 24 KiB and 64 KiB. Self-transfers appear only in their own row, and delegated receivers appear only in the delegated rows.

| Transaction case | Besu | Erigon | Ethrex | Geth | Nethermind | Reth | EIP value |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Transfer to self | 9,108 | 9,825 | 3,454 | 9,436 | 5,493 | 4,137 | 12,000 |
| No-value transfer | 13,106 | 13,238 | 7,827 | 16,039 | 9,901 | 8,507 | 15,000 |
| Value transfer | 18,344 | 28,366 | 9,718 | 22,164 | 12,473 | 11,106 | 21,000 |
| No-value transfer to delegated account | 11,112 | 9,343 | 4,062 | 15,411 | 9,511 | 7,530 | 18,000 |
| Value transfer to delegated account | 15,606 | 13,962 | 5,835 | 20,811 | 11,933 | 10,116 | 24,000 |

The EIP value column shows execution-gas costs before separately metered contract execution, with a cold delegation-target access for delegated recipients.

`ZERO_VALUE_TRANSFER` and `VALUE_TRANSFER` are full per-transaction estimates for zero-value and value-bearing transfers. The marginal `TX_VALUE_COST` is the estimated additional cost of moving value for the same receiver case.

## Runtime results

The following results drive the five transaction-case maxima above. The correspond to the results of fitting a non-negative least-squares model on the benchmark data. Estimated runtimes are in **milliseconds per transaction**.

### Transfer to self

| Client | Receiver case | Worst parameter | Runtime (ms/tx) | R² |
| --- | --- | --- | ---: | ---: |
| Besu | `diff_to_self` | `VALUE_TRANSFER` | 0.121430 | 0.968 |
| Erigon | `diff_to_self` | `ZERO_VALUE_TRANSFER` | 0.130996 | 0.997 |
| Ethrex | `diff_to_self` | `ZERO_VALUE_TRANSFER` | 0.046041 | 0.955 |
| Geth | `diff_to_self` | `VALUE_TRANSFER` | 0.125803 | 0.996 |
| Nethermind | `diff_to_self` | `ZERO_VALUE_TRANSFER` | 0.073236 | 0.716 |
| Reth | `diff_to_self` | `ZERO_VALUE_TRANSFER` | 0.055148 | 0.840 |

### No-value transfer

| Client | Worst receiver case | Parameter | Runtime (ms/tx) | R² |
| --- | --- | --- | ---: | ---: |
| Besu | `diff_to_unique_code_jumpdest_contract_64kib` | `ZERO_VALUE_TRANSFER` | 0.174743 | 0.900 |
| Erigon | `diff_to_contract_24kib` | `ZERO_VALUE_TRANSFER` | 0.176505 | 0.996 |
| Ethrex | `diff_to_unique_code_jumpdest_contract_24kib` | `ZERO_VALUE_TRANSFER` | 0.104347 | 0.946 |
| Geth | `diff_to_contract_diff_max_64kib` | `ZERO_VALUE_TRANSFER` | 0.213846 | 0.997 |
| Nethermind | `diff_to_unique_code_jumpdest_contract_64kib` | `ZERO_VALUE_TRANSFER` | 0.132007 | 0.853 |
| Reth | `diff_to_unique_code_jumpdest_contract_64kib` | `ZERO_VALUE_TRANSFER` | 0.113426 | 0.968 |

### Value transfer

| Client |  Worst receiver case | Parameter | Runtime (ms/tx) | R² |
| --- | --- | --- | ---: | ---: |
| Besu | `diff_to_unique_code_jumpdest_contract_64kib` | `VALUE_TRANSFER` | 0.244578 | 0.917 |
| Erigon | `diff_to_contract_24kib` | `VALUE_TRANSFER` | 0.378210 | 0.998 |
| Ethrex | `diff_to_unique_code_jumpdest_contract_24kib` | `VALUE_TRANSFER` | 0.129572 | 0.975 |
| Geth | `diff_to_contract_diff_max_64kib` | `VALUE_TRANSFER` | 0.295519 | 0.997 |
| Nethermind | `diff_to_contract_diff_max_64kib` | `VALUE_TRANSFER` | 0.166300 | 0.769 |
| Reth | `diff_to_unique_code_jumpdest_contract_64kib` | `VALUE_TRANSFER` | 0.148070 | 0.949 |

### No-value transfer to delegated account

| Client | Worst receiver case | Parameter | Runtime (ms/tx) | R² |
| --- | --- | --- | ---: | ---: |
| Besu | `diff_to_delegated_contract_diff_24kib` | `ZERO_VALUE_TRANSFER` | 0.148150 | 0.951 |
| Erigon | `diff_to_delegated_contract_diff_64kib` | `ZERO_VALUE_TRANSFER` | 0.124570 | 0.995 |
| Ethrex | `diff_to_delegated_contract_diff_64kib` | `ZERO_VALUE_TRANSFER` | 0.054153 | 0.956 |
| Geth | `diff_to_delegated_contract_diff_64kib` | `ZERO_VALUE_TRANSFER` | 0.205476 | 0.998 |
| Nethermind | `diff_to_delegated_contract_diff_64kib` | `ZERO_VALUE_TRANSFER` | 0.126812 | 0.834 |
| Reth | `diff_to_delegated_contract_diff_64kib` | `ZERO_VALUE_TRANSFER` | 0.100398 | 0.968 |

### Value transfer to delegated account

| Client | Worst receiver case | Parameter | Runtime (ms/tx) | R² |
| --- | --- | --- | ---: | ---: |
| Besu | `diff_to_delegated_contract_diff_24kib` | `VALUE_TRANSFER` | 0.208075 | 0.967 |
| Erigon | `diff_to_delegated_contract_diff_24kib` | `VALUE_TRANSFER` | 0.186152 | 0.997 |
| Ethrex | `diff_to_delegated_contract_diff_64kib` | `VALUE_TRANSFER` | 0.077788 | 0.954 |
| Geth | `diff_to_delegated_contract_diff_24kib` | `VALUE_TRANSFER` | 0.277477 | 0.996 |
| Nethermind | `diff_to_delegated_contract_diff_24kib` | `VALUE_TRANSFER` | 0.159093 | 0.741 |
| Reth | `diff_to_delegated_contract_diff_64kib` | `VALUE_TRANSFER` | 0.134872 | 0.949 |

The [complete runtime results](runtime_estimation.csv) include all 180 fits across 90 client/receiver pairs, with observation counts, intercepts, slopes, R², and bootstrap intervals. All pairs have both value and zero-value fits; the fits contain 47,520 observations in total.

## Fit warnings

**No fits meet the source analysis's poor-fit threshold of R² ≤ 0.5.** No reported slope diagnostic has a p-value above 0.05. The marginal-value p-value is inherited from the two underlying fits and is not a significance test of their difference.

Fit quality still varies. The table below identifies weaker fits using R² < 0.9 as an additional review threshold, rather than the source's poor-fit cutoff. These fits remain included in the estimates.

| Client | R² range | Fits with R² ≤ 0.5 | Fits with R² < 0.9 (of 30) |
| --- | ---: | ---: | ---: |
| Besu | 0.900–0.982 | 0 | 0 |
| Erigon | 0.993–0.998 | 0 | 0 |
| Ethrex | 0.834–0.975 | 0 | 4 |
| Geth | 0.933–0.998 | 0 | 0 |
| Nethermind | 0.592–0.853 | 0 | 30 |
| Reth | 0.840–0.968 | 0 | 16 |

All 30 Nethermind fits in the complete source results are below 0.9. Each of its five displayed transaction-case maxima also relies on a fit below 0.9; their R² values are shown in the runtime tables. The fit-quality summary covers the complete source results, including non-existent receivers, which are excluded from the transaction-case maxima. Interpret these estimates with their fit diagnostics; interval bounds remain available in the supporting CSVs.

## Supporting files

- [Gas estimates](new_gas.csv): all 270 estimates at 75 Mgas/s, with fitted runtimes, gas and runtime interval bounds, R², and significance diagnostics.
- [Runtime estimation results](runtime_estimation.csv): all fitted models and their diagnostics.
- [Data collection configuration](fetch.yaml): suite, date range, fork, and client run filter. Data was collected with benchmarkoor-fetch 0.3.1.
