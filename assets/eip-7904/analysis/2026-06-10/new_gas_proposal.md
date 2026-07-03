# New gas proposal

_Generated 2026-06-10 07:09:53Z · fork `osaka` · anchor_rate 100 Mgas/s_

> Note: this is a bundled snapshot of the analysis output. The accompanying figures (heatmaps and per-parameter provenance plots) are omitted here; the figure-rich version is published on the live analysis site linked from the EIP's discussions-to thread.

**Summary:** 18 parameters proposed — 1 increased, 16 decreased, 0 new, 0 unresolved · 0 warnings · 3 poor-fit selections

## Contents

- [Proposed parameters](#proposed-gas-parameters)
- [Client comparison](#client-comparison)
- [Worst-case provenance](#worst-case-provenance-per-gas-param)
- [Warnings](#warnings)
- [Poor-fit selections](#poor-fit-selections)

## Proposed gas parameters

| Gas param | Current gas | Proposed gas | Diff | Diff % |
| --- | --- | --- | --- | --- |
| OPCODE_DIV | 5 | 2 | -3 | -60% |
| OPCODE_SDIV | 5 | 2 | -3 | -60% |
| OPCODE_MOD | 5 | 2 | -3 | -60% |
| OPCODE_SMOD | 5 | 3 | -2 | -40% |
| OPCODE_ADDMOD | 8 | 3 | -5 | -62% |
| OPCODE_MULMOD | 8 | 4 | -4 | -50% |
| OPCODE_KECCAK256_BASE | 30 | 12 | -18 | -60% |
| OPCODE_KECCAK256_PER_WORD | 6 | 3 | -3 | -50% |
| PRECOMPILE_ECRECOVER | 3000 | 841 | -2159 | -72% |
| PRECOMPILE_BLAKE2F_BASE | 0 | 94 | +94 | n/a |
| PRECOMPILE_BLAKE2F_PER_ROUND | 1 | 1 | 0 | 0% |
| PRECOMPILE_BLS_G1ADD | 375 | 236 | -139 | -37% |
| PRECOMPILE_BLS_G2ADD | 600 | 277 | -323 | -54% |
| PRECOMPILE_ECADD | 150 | 108 | -42 | -28% |
| PRECOMPILE_ECPAIRING_BASE | 45000 | 8247 | -36753 | -82% |
| PRECOMPILE_ECPAIRING_PER_POINT | 34000 | 11712 | -22288 | -66% |
| PRECOMPILE_POINT_EVALUATION | 50000 | 23825 | -26175 | -52% |
| PRECOMPILE_P256VERIFY | 6900 | 3814 | -3086 | -45% |

## Client comparison

Worst client vs. second-worst client per gas parameter. The `Ratio` column is `worst gas / second-worst gas` — values close to 1× mean the worst case sits next to the rest of the field, while large ratios flag the worst client as an outlier.

| Gas param | Worst client | Worst gas | Second-worst client | Second-worst gas | Ratio |
| --- | --- | --- | --- | --- | --- |
| OPCODE_DIV | besu | 2 | erigon | 2 | 1.00× |
| OPCODE_SDIV | besu | 2 | erigon | 2 | 1.00× |
| OPCODE_MOD | besu | 2 | erigon | 2 | 1.00× |
| OPCODE_SMOD | besu | 3 | erigon | 2 | 1.50× |
| OPCODE_ADDMOD | besu | 3 | erigon | 2 | 1.50× |
| OPCODE_MULMOD | besu | 4 | nethermind | 4 | 1.00× |
| OPCODE_KECCAK256_BASE | besu | 12 | geth | 9 | 1.33× |
| OPCODE_KECCAK256_PER_WORD | nethermind | 3 | besu | 2 | 1.50× |
| PRECOMPILE_ECRECOVER | erigon | 841 | geth | 781 | 1.08× |
| PRECOMPILE_BLAKE2F_BASE | erigon | 94 | besu | 41 | 2.29× |
| PRECOMPILE_BLAKE2F_PER_ROUND | besu | 1 | erigon | 1 | 1.00× |
| PRECOMPILE_BLS_G1ADD | ethrex | 236 | besu | 175 | 1.35× |
| PRECOMPILE_BLS_G2ADD | ethrex | 277 | besu | 212 | 1.31× |
| PRECOMPILE_ECADD | erigon | 108 | reth | 96 | 1.12× |
| PRECOMPILE_ECPAIRING_BASE | reth | 8247 | ethrex | 8182 | 1.01× |
| PRECOMPILE_ECPAIRING_PER_POINT | nethermind | 11712 | ethrex | 6162 | 1.90× |
| PRECOMPILE_POINT_EVALUATION | ethrex | 23825 | nethermind | 23399 | 1.02× |
| PRECOMPILE_P256VERIFY | ethrex | 3814 | erigon | 1411 | 2.70× |

Per-client proposed gas for each parameter. Cells are colored by `log2(proposed / current)` — red means the proposal is more expensive than the current gas cost, green means cheaper, and white sits at unchanged. Annotations show the absolute proposed gas value; blank rows are parameters with no prior baseline (see warnings below).


## Worst-case provenance per gas param

One collapsible block per gas parameter showing every per-client candidate that the worst-case selector saw. Rows are model combos (the source regression's `test_name`, `target_opcode`, `model_coef_name`, and any `model_by` factors — components constant within a parameter are dropped from the label). Cells carry each candidate's proposed gas; the cell the per-client selector picked is outlined in black. Colors are `log2(proposed / current)` against that parameter's baseline on a per-parameter symmetric scale.

_Single-combo parameters omitted (see proposal table for the sole estimation): `OPCODE_DIV`, `OPCODE_SDIV`, `OPCODE_ADDMOD`, `OPCODE_MULMOD`, `PRECOMPILE_ECRECOVER`, `PRECOMPILE_BLS_G1ADD`, `PRECOMPILE_BLS_G2ADD`._

<details>
<summary><code>OPCODE_MOD</code> — 4 combos × 6 clients</summary>


</details>

<details>
<summary><code>OPCODE_SMOD</code> — 4 combos × 6 clients</summary>


</details>

<details>
<summary><code>OPCODE_KECCAK256_BASE</code> — 4 combos × 6 clients</summary>


</details>

<details>
<summary><code>OPCODE_KECCAK256_PER_WORD</code> — 4 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_BLAKE2F_BASE</code> — 2 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_BLAKE2F_PER_ROUND</code> — 2 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_ECADD</code> — 5 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_ECPAIRING_BASE</code> — 2 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_ECPAIRING_PER_POINT</code> — 2 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_POINT_EVALUATION</code> — 2 combos × 6 clients</summary>


</details>

<details>
<summary><code>PRECOMPILE_P256VERIFY</code> — 2 combos × 6 clients</summary>


</details>

## Warnings

### Missing parameters

_None._

### Incomplete client coverage

_None._

### Missing glue adjustments

<details>
<summary><b>Priced glue opcodes with a poor fit</b> — 28 (glue_opcode, client) fits skipped</summary>

`p_value >= glue_contribution_p_value_threshold` (0.05) or `rsquared < glue_contribution_rsquared_threshold` (0.5) — the contribution of these (glue_opcode, client) fits was **skipped** when computing the glue adjustment, so the listed gas params carry a target coefficient that is not net of this glue opcode's runtime on the affected clients. See `glue_opcodes_autogenerated_report.md` for per-fit metrics.

| Glue opcode | Affected clients | Affected gas params |
| --- | --- | --- |
| `AND` | `erigon` (R²), `ethrex` (R²) | — |
| `CALLDATALOAD` | `besu` (both), `erigon` (R²), `ethrex` (R²), `geth` (R²), `nethermind` (R²), `reth` (R²) | `OPCODE_ADDMOD`, `OPCODE_MOD`, `OPCODE_MULMOD`, `OPCODE_SMOD` |
| `EXP` | `erigon` (R²), `nethermind` (both) | — |
| `GT` | `besu` (R²) | `PRECOMPILE_BLAKE2F_BASE`, `PRECOMPILE_ECADD`, `PRECOMPILE_ECPAIRING_BASE`, `PRECOMPILE_P256VERIFY`, `PRECOMPILE_POINT_EVALUATION` |
| `JUMP` | `besu` (R²) | `OPCODE_ADDMOD`, `OPCODE_MULMOD` |
| `JUMPDEST` | `besu` (R²) | `OPCODE_ADDMOD`, `OPCODE_MULMOD`, `PRECOMPILE_BLAKE2F_BASE`, `PRECOMPILE_ECADD`, `PRECOMPILE_ECPAIRING_BASE`, `PRECOMPILE_ECRECOVER`, `PRECOMPILE_P256VERIFY`, `PRECOMPILE_POINT_EVALUATION` |
| `JUMPI` | `besu` (R²), `erigon` (R²) | `PRECOMPILE_BLAKE2F_BASE`, `PRECOMPILE_ECADD`, `PRECOMPILE_ECPAIRING_BASE`, `PRECOMPILE_P256VERIFY`, `PRECOMPILE_POINT_EVALUATION` |
| `KECCAK256` | `besu` (R²), `erigon` (R²), `ethrex` (both), `geth` (R²), `nethermind` (both), `reth` (both) | — |
| `LT` | `besu` (R²) | — |
| `MSTORE` | `reth` (R²) | `OPCODE_KECCAK256_BASE`, `PRECOMPILE_ECPAIRING_BASE`, `PRECOMPILE_ECRECOVER`, `PRECOMPILE_P256VERIFY`, `PRECOMPILE_POINT_EVALUATION` |
| `RETURNDATASIZE` | `besu` (R²), `erigon` (R²) | — |
| `SELFBALANCE` | `besu` (R²), `nethermind` (R²) | — |
| `SWAP` | `besu` (R²) | — |

</details>

## Poor-fit selections

Rows where the winning fit's p-value exceeded `modeling.poor_fit_p_value_threshold` (0.05) or its R² fell below `modeling.poor_fit_rsquared_threshold` (0.5). The failing threshold(s) are noted alongside each row; selections in `### Winners with poor fit` still drive the proposal, while `### Other weak candidates` lists losing candidates that the selector dropped in favor of a qualified alternative. See `runtime_estimation_autogenerated_report.md` for per-fit `runtime_ms`, `pvalue`, and `rsquared` metrics.

### Winners with poor fit

| Gas param | Client | Test | Target opcode | Coef | runtime_ms | pvalue | rsquared | Failed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `PRECOMPILE_BLAKE2F_PER_ROUND` | `reth` | `test_blake2f_benchmark` | `BLAKE2F` | `num_rounds` | 0 | 1 | 0.9896 | p-value |
| `PRECOMPILE_BLS_G1ADD` | `ethrex` | `test_bls12_381` | `BLS12_G1ADD` | `target_coef` | 0.002351 | 0.001 | 0.05318 | R² |
| `PRECOMPILE_BLS_G2ADD` | `ethrex` | `test_bls12_381` | `BLS12_G2ADD` | `target_coef` | 0.00277 | 0.001 | 0.06885 | R² |

### Other weak candidates

<details>
<summary><code>PRECOMPILE_BLAKE2F_PER_ROUND</code> — 1 weak combo</summary>

| Test | Target opcode | Coef | Combo | Failing clients |
| --- | --- | --- | --- | --- |
| `test_blake2f_uncachable` | `BLAKE2F` | `num_rounds` | — | `erigon` (p-value), `reth` (p-value) |

</details>
