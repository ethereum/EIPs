# New gas proposal

> Gas estimates use an anchor of 75 Mgas/s. These estimates differ from the EIP’s selected values. See the [supporting report](gas-cost-report.md).

_Generated 2026-10-15 12:39:41Z, fork `osaka`, anchor_rate 75 Mgas/s_

## Contents

- [Client comparison](#client-comparison)
- [Worst-case provenance](#worst-case-provenance-per-gas-param)
- [Warnings](#warnings)
- [Poor-fit selections](#poor-fit-selections)

## Client comparison

This table compares the slowest client with the next slowest client for each parameter. The ratio is their gas estimates divided. A ratio close to 1 means the estimates are similar. A larger ratio shows a greater gap.

| Gas param | Worst client | Worst gas | Second-worst client | Second-worst gas | Ratio |
| --- | --- | --- | --- | --- | --- |
| COLD_STORAGE_ACCESS | besu | 1823 | geth | 1645 | 1.11× |
| COLD_STORAGE_WRITE | erigon | 12551 | geth | 11466 | 1.09× |
| WARM_ACCESS | besu | 51 | nethermind | 30 | 1.70× |
| COLD_ACCOUNT_NOCODE_ACCESS | geth | 1617 | besu | 1388 | 1.16× |
| COLD_ACCOUNT_NOCODE_WRITE | besu | 14964 | erigon | 14491 | 1.03× |
| COLD_ACCOUNT_CODE_ACCESS | geth | 3494 | besu | 2110 | 1.66× |
| COLD_ACCOUNT_CODE_WRITE | geth | 11405 | reth | 10004 | 1.14× |

Per-client proposed gas for each parameter. Blank cells mark (parameter, client) pairs with no fit.

| Gas param | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| COLD_STORAGE_ACCESS | 1823 | 286 | 560 | 1645 | 583 | 409 |
| COLD_STORAGE_WRITE | 8292 | 12551 | 1680 | 11466 | 6755 | 9063 |
| WARM_ACCESS | 51 | 6 | 10 | 17 | 30 | 6 |
| COLD_ACCOUNT_NOCODE_ACCESS | 1388 | 312 | 195 | 1617 | 292 | 398 |
| COLD_ACCOUNT_NOCODE_WRITE | 14964 | 14491 | 3039 | 9061 | 7765 | 11583 |
| COLD_ACCOUNT_CODE_ACCESS | 2110 | 1150 | 784 | 3494 | 248 | 391 |
| COLD_ACCOUNT_CODE_WRITE | 7818 | 5676 | 2600 | 11405 | 5965 | 10004 |

## Worst-case provenance per gas param

Each block lists the candidate models for one gas parameter. Rows identify the source test, opcode, coefficient, and model configuration. Labels omit fields that are constant within the block. Each cell shows a gas estimate. Bold values mark the selected model for each client.

<details>
<summary><code>COLD_STORAGE_ACCESS</code>: 4 combos × 6 clients</summary>

| Label | Combo |
| --- | --- |
| `M1` | test_name=test_sload_bloated / target_opcode=SLOAD / model_coef_name=target_coef / param_existing_slots=False / selected_test=test_sload_bloated / selected_opcode=SLOAD / selected_model_coef_name=target_coef |
| `M2` | test_name=test_sload_bloated / target_opcode=SLOAD / model_coef_name=target_coef / param_existing_slots=True / selected_test=test_sload_bloated / selected_opcode=SLOAD / selected_model_coef_name=target_coef |
| `M3` | test_name=test_sstore_bloated / target_opcode=SSTORE / model_coef_name=target_coef / param_existing_slots=False / selected_test=test_sstore_bloated / selected_opcode=SSTORE / selected_model_coef_name=target_coef |
| `M4` | test_name=test_sstore_bloated / target_opcode=SSTORE / model_coef_name=target_coef / param_existing_slots=True / selected_test=test_sstore_bloated / selected_opcode=SSTORE / selected_model_coef_name=target_coef |

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `M1` | 754 | 263 | 139 | 1626 | 190 | 399 |
| `M2` | 1215 | 285 | 557 | 1640 | 571 | 404 |
| `M3` | 1419 | 258 | 140 | 1608 | 187 | 398 |
| `M4` | **1823** | **286** | **560** | **1645** | **583** | **409** |

</details>

<details>
<summary><code>COLD_STORAGE_WRITE</code>: 2 combos × 6 clients</summary>

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `False` | **8292** | **12551** | 0 | **11466** | **6755** | **9063** |
| `True` | 6686 | 8278 | **1680** | 8257 | 5915 | 6248 |

</details>

<details>
<summary><code>WARM_ACCESS</code>: 8 combos × 6 clients</summary>

| Label | Combo |
| --- | --- |
| `M1` | test_name=test_ext_account_query_warm / target_opcode=BALANCE / model_coef_name=target_coef / param_opcode=BALANCE / selected_test=test_ext_account_query_warm / selected_opcode=BALANCE / selected_model_coef_name=target_coef |
| `M2` | test_name=test_ext_account_query_warm / target_opcode=CALL / model_coef_name=target_coef / param_opcode=CALL / selected_test=test_ext_account_query_warm / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M3` | test_name=test_ext_account_query_warm / target_opcode=CALLCODE / model_coef_name=target_coef / param_opcode=CALLCODE / selected_test=test_ext_account_query_warm / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M4` | test_name=test_ext_account_query_warm / target_opcode=DELEGATECALL / model_coef_name=target_coef / param_opcode=DELEGATECALL / selected_test=test_ext_account_query_warm / selected_opcode=DELEGATECALL / selected_model_coef_name=target_coef |
| `M5` | test_name=test_ext_account_query_warm / target_opcode=EXTCODEHASH / model_coef_name=target_coef / param_opcode=EXTCODEHASH / selected_test=test_ext_account_query_warm / selected_opcode=EXTCODEHASH / selected_model_coef_name=target_coef |
| `M6` | test_name=test_ext_account_query_warm / target_opcode=EXTCODESIZE / model_coef_name=target_coef / param_opcode=EXTCODESIZE / selected_test=test_ext_account_query_warm / selected_opcode=EXTCODESIZE / selected_model_coef_name=target_coef |
| `M7` | test_name=test_ext_account_query_warm / target_opcode=STATICCALL / model_coef_name=target_coef / param_opcode=STATICCALL / selected_test=test_ext_account_query_warm / selected_opcode=STATICCALL / selected_model_coef_name=target_coef |
| `M8` | test_name=test_sload_same_key_benchmark / target_opcode=SLOAD / model_coef_name=target_coef / selected_test=test_sload_same_key_benchmark / selected_opcode=SLOAD / selected_model_coef_name=target_coef |

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `M1` | 9 | 1 | 2 | 3 | 6 | 2 |
| `M2` | **51** | **6** | **10** | 12 | 17 | **6** |
| `M3` | 45 | 3 | 10 | 16 | 10 | 6 |
| `M4` | 41 | 3 | 9 | 14 | **30** | 6 |
| `M5` | 9 | 2 | 2 | 4 | 11 | 2 |
| `M6` | 13 | 1 | 2 | 3 | 9 | 1 |
| `M7` | 42 | 5 | 9 | **17** | 17 | 6 |
| `M8` | 17 | 1 | 3 | 6 | 7 | 1 |

</details>

<details>
<summary><code>COLD_ACCOUNT_NOCODE_ACCESS</code>: 16 combos × 6 clients</summary>

| Label | Combo |
| --- | --- |
| `M1` | test_name=test_account_access / target_opcode=BALANCE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=BALANCE / selected_test=test_account_access / selected_opcode=BALANCE / selected_model_coef_name=target_coef |
| `M2` | test_name=test_account_access / target_opcode=BALANCE / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=BALANCE / selected_test=test_account_access / selected_opcode=BALANCE / selected_model_coef_name=target_coef |
| `M3` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M4` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M5` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M6` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M7` | test_name=test_account_access / target_opcode=DELEGATECALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=DELEGATECALL / selected_test=test_account_access / selected_opcode=DELEGATECALL / selected_model_coef_name=target_coef |
| `M8` | test_name=test_account_access / target_opcode=DELEGATECALL / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=DELEGATECALL / selected_test=test_account_access / selected_opcode=DELEGATECALL / selected_model_coef_name=target_coef |
| `M9` | test_name=test_account_access / target_opcode=EXTCODECOPY / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=EXTCODECOPY / selected_test=test_account_access / selected_opcode=EXTCODECOPY / selected_model_coef_name=target_coef |
| `M10` | test_name=test_account_access / target_opcode=EXTCODECOPY / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=EXTCODECOPY / selected_test=test_account_access / selected_opcode=EXTCODECOPY / selected_model_coef_name=target_coef |
| `M11` | test_name=test_account_access / target_opcode=EXTCODEHASH / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=EXTCODEHASH / selected_test=test_account_access / selected_opcode=EXTCODEHASH / selected_model_coef_name=target_coef |
| `M12` | test_name=test_account_access / target_opcode=EXTCODEHASH / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=EXTCODEHASH / selected_test=test_account_access / selected_opcode=EXTCODEHASH / selected_model_coef_name=target_coef |
| `M13` | test_name=test_account_access / target_opcode=EXTCODESIZE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=EXTCODESIZE / selected_test=test_account_access / selected_opcode=EXTCODESIZE / selected_model_coef_name=target_coef |
| `M14` | test_name=test_account_access / target_opcode=EXTCODESIZE / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=EXTCODESIZE / selected_test=test_account_access / selected_opcode=EXTCODESIZE / selected_model_coef_name=target_coef |
| `M15` | test_name=test_account_access / target_opcode=STATICCALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=STATICCALL / selected_test=test_account_access / selected_opcode=STATICCALL / selected_model_coef_name=target_coef |
| `M16` | test_name=test_account_access / target_opcode=STATICCALL / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=STATICCALL / selected_test=test_account_access / selected_opcode=STATICCALL / selected_model_coef_name=target_coef |

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `M1` | 1174 | 290 | 1362 | 1563 | 261 | 360 |
| `M2` | 1127 | 261 | 187 | 1489 | 230 | 363 |
| `M3` | 1363 | 311 | 1381 | 1576 | 282 | 393 |
| `M4` | 1382 | 266 | 193 | 1543 | 251 | 371 |
| `M5` | 1265 | 273 | 1387 | 1571 | 268 | 363 |
| `M6` | 1122 | 252 | 191 | 1571 | 240 | 365 |
| `M7` | 1282 | 278 | 1389 | 1601 | **292** | 371 |
| `M8` | 1151 | 254 | 193 | 1593 | 269 | 374 |
| `M9` | 1220 | 266 | 1384 | 1612 | 267 | 374 |
| `M10` | 1139 | 249 | 188 | 1532 | 250 | 366 |
| `M11` | 1209 | 304 | 1371 | 1568 | 266 | 368 |
| `M12` | 1130 | 249 | 187 | 1513 | 251 | 359 |
| `M13` | 1218 | 272 | 1355 | 1584 | 268 | 371 |
| `M14` | 1130 | 245 | 189 | 1516 | 238 | 369 |
| `M15` | 1359 | **312** | 1378 | 1596 | 276 | **398** |
| `M16` | **1388** | 310 | **195** | **1617** | 251 | 372 |

</details>

<details>
<summary><code>COLD_ACCOUNT_NOCODE_WRITE</code>: 4 combos × 6 clients</summary>

| Label | Combo |
| --- | --- |
| `M1` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M2` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M3` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_EOA / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M4` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.NON_EXISTING_ACCOUNT / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `M1` | 6841 | 4644 | **3039** | 8052 | 3945 | 7447 |
| `M2` | **14964** | **14491** | 2206 | **9061** | **7765** | **11583** |
| `M3` | 1565 | 282 | 1293 | 2219 | 601 | 511 |
| `M4` | 1594 | 245 | 239 | 2215 | 446 | 509 |

</details>

<details>
<summary><code>COLD_ACCOUNT_CODE_ACCESS</code>: 24 combos × 6 clients</summary>

| Label | Combo |
| --- | --- |
| `M1` | test_name=test_account_access / target_opcode=BALANCE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=BALANCE / selected_test=test_account_access / selected_opcode=BALANCE / selected_model_coef_name=target_coef |
| `M2` | test_name=test_account_access / target_opcode=BALANCE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=BALANCE / selected_test=test_account_access / selected_opcode=BALANCE / selected_model_coef_name=target_coef |
| `M3` | test_name=test_account_access / target_opcode=BALANCE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=BALANCE / selected_test=test_account_access / selected_opcode=BALANCE / selected_model_coef_name=target_coef |
| `M4` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M5` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M6` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M7` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M8` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M9` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M10` | test_name=test_account_access / target_opcode=DELEGATECALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=DELEGATECALL / selected_test=test_account_access / selected_opcode=DELEGATECALL / selected_model_coef_name=target_coef |
| `M11` | test_name=test_account_access / target_opcode=DELEGATECALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=DELEGATECALL / selected_test=test_account_access / selected_opcode=DELEGATECALL / selected_model_coef_name=target_coef |
| `M12` | test_name=test_account_access / target_opcode=DELEGATECALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=DELEGATECALL / selected_test=test_account_access / selected_opcode=DELEGATECALL / selected_model_coef_name=target_coef |
| `M13` | test_name=test_account_access / target_opcode=EXTCODECOPY / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=EXTCODECOPY / selected_test=test_account_access / selected_opcode=EXTCODECOPY / selected_model_coef_name=target_coef |
| `M14` | test_name=test_account_access / target_opcode=EXTCODECOPY / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=EXTCODECOPY / selected_test=test_account_access / selected_opcode=EXTCODECOPY / selected_model_coef_name=target_coef |
| `M15` | test_name=test_account_access / target_opcode=EXTCODECOPY / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=EXTCODECOPY / selected_test=test_account_access / selected_opcode=EXTCODECOPY / selected_model_coef_name=target_coef |
| `M16` | test_name=test_account_access / target_opcode=EXTCODEHASH / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=EXTCODEHASH / selected_test=test_account_access / selected_opcode=EXTCODEHASH / selected_model_coef_name=target_coef |
| `M17` | test_name=test_account_access / target_opcode=EXTCODEHASH / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=EXTCODEHASH / selected_test=test_account_access / selected_opcode=EXTCODEHASH / selected_model_coef_name=target_coef |
| `M18` | test_name=test_account_access / target_opcode=EXTCODEHASH / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=EXTCODEHASH / selected_test=test_account_access / selected_opcode=EXTCODEHASH / selected_model_coef_name=target_coef |
| `M19` | test_name=test_account_access / target_opcode=EXTCODESIZE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=EXTCODESIZE / selected_test=test_account_access / selected_opcode=EXTCODESIZE / selected_model_coef_name=target_coef |
| `M20` | test_name=test_account_access / target_opcode=EXTCODESIZE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=EXTCODESIZE / selected_test=test_account_access / selected_opcode=EXTCODESIZE / selected_model_coef_name=target_coef |
| `M21` | test_name=test_account_access / target_opcode=EXTCODESIZE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=EXTCODESIZE / selected_test=test_account_access / selected_opcode=EXTCODESIZE / selected_model_coef_name=target_coef |
| `M22` | test_name=test_account_access / target_opcode=STATICCALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=STATICCALL / selected_test=test_account_access / selected_opcode=STATICCALL / selected_model_coef_name=target_coef |
| `M23` | test_name=test_account_access / target_opcode=STATICCALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=STATICCALL / selected_test=test_account_access / selected_opcode=STATICCALL / selected_model_coef_name=target_coef |
| `M24` | test_name=test_account_access / target_opcode=STATICCALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=STATICCALL / selected_test=test_account_access / selected_opcode=STATICCALL / selected_model_coef_name=target_coef |

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `M1` | 1719 | 321 | 771 | 1303 | 227 | 376 |
| `M2` | 932 | 266 | 196 | 1500 | 207 | 349 |
| `M3` | 954 | 293 | 201 | 1476 | 219 | 348 |
| `M4` | **2110** | 1148 | 764 | 3439 | 1589 | 3134 |
| `M5` | 1008 | 315 | 205 | 1541 | 242 | 389 |
| `M6` | 1010 | 340 | 206 | 1533 | 238 | 391 |
| `M7` | 2020 | 1112 | 767 | 3432 | 1640 | 3053 |
| `M8` | 977 | 285 | 209 | 1532 | **248** | 358 |
| `M9` | 982 | 303 | 216 | 1532 | 237 | 357 |
| `M10` | 2014 | 1123 | 767 | 3426 | 1612 | 3038 |
| `M11` | 989 | 284 | 204 | 1523 | 245 | 360 |
| `M12` | 989 | 320 | 208 | 1531 | 244 | 353 |
| `M13` | 1793 | 1097 | 762 | 3487 | 1583 | 3032 |
| `M14` | 945 | 267 | 200 | 1548 | 223 | 358 |
| `M15` | 964 | 273 | 199 | 1523 | 219 | 356 |
| `M16` | 1758 | 328 | 763 | 1300 | 211 | 364 |
| `M17` | 944 | 269 | 202 | 1484 | 211 | 351 |
| `M18` | 940 | 302 | 197 | 1503 | 210 | 351 |
| `M19` | 1752 | 438 | **784** | **3494** | 1573 | 3031 |
| `M20` | 946 | 263 | 202 | 1500 | 204 | 359 |
| `M21` | 940 | 288 | 208 | 1502 | 223 | 356 |
| `M22` | 2093 | **1150** | 770 | 3416 | 1646 | 3144 |
| `M23` | 1010 | 308 | 207 | 1523 | 232 | 390 |
| `M24` | 1004 | 342 | 208 | 1522 | 246 | **391** |

</details>

<details>
<summary><code>COLD_ACCOUNT_CODE_WRITE</code>: 6 combos × 6 clients</summary>

| Label | Combo |
| --- | --- |
| `M1` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M2` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M3` | test_name=test_account_access / target_opcode=CALL / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=CALL / selected_test=test_account_access / selected_opcode=CALL / selected_model_coef_name=target_coef |
| `M4` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M5` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |
| `M6` | test_name=test_account_access / target_opcode=CALLCODE / model_coef_name=target_coef / param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX / param_opcode=CALLCODE / selected_test=test_account_access / selected_opcode=CALLCODE / selected_model_coef_name=target_coef |

| Combo | besu | erigon | ethrex | geth | nethermind | reth |
| --- | --- | --- | --- | --- | --- | --- |
| `M1` | **7818** | **5676** | **2600** | **11405** | **5965** | **10004** |
| `M2` | 5739 | 4309 | 1907 | 8041 | 3927 | 7446 |
| `M3` | 5674 | 4993 | 1890 | 8063 | 3964 | 7482 |
| `M4` | 3116 | 1619 | 1132 | 5516 | 2735 | 3206 |
| `M5` | 1390 | 570 | 282 | 2073 | 606 | 492 |
| `M6` | 1385 | 481 | 267 | 2133 | 609 | 496 |

</details>

## Warnings

### Missing parameters

_None._

### Incomplete client coverage

_None._

### Missing glue adjustments

<details>
<summary><b>Priced glue opcodes with a poor fit</b>: 21 (glue_opcode, client) fits skipped</summary>

The fits below failed at least one quality threshold. Their p value was at least 0.05 or their R² was below 0.5. Their runtime contributions were skipped during glue adjustment. The affected target estimates still include that auxiliary runtime. See the [glue opcode report](glue_opcodes_autogenerated_report.md) for the metrics.

| Glue opcode | Affected clients | Affected gas params |
| --- | --- | --- |
| `ADD` | `erigon` (R²) | — |
| `AND` | `erigon` (R²) | — |
| `CALLDATALOAD` | `besu` (R²), `erigon` (R²), `ethrex` (R²), `geth` (R²), `nethermind` (R²), `reth` (both) | — |
| `EXP` | `nethermind` (both) | — |
| `ISZERO` | `nethermind` (R²) | — |
| `JUMPDEST` | `erigon` (R²) | — |
| `KECCAK256` | `besu` (R²), `erigon` (R²), `ethrex` (both), `geth` (R²), `nethermind` (both), `reth` (both) | — |
| `LT` | `besu` (R²) | — |
| `MSTORE` | `erigon` (R²), `reth` (R²) | — |
| `SUB` | `erigon` (R²) | — |

</details>

### Other

_None._

## Poor-fit selections

This section lists fits that failed the quality thresholds. A p value of at least 0.05 or an R² below 0.5 marks a weak fit. Any weak winners still determine the proposal. Other weak candidates lost to a qualifying fit. See the [runtime report](runtime_estimation_autogenerated_report.md) for the metrics.

### Winners with poor fit

_None._

### Other weak candidates

<details>
<summary><code>COLD_STORAGE_WRITE</code>: 1 weak combo</summary>

| Test | Target opcode | Coef | Combo | Failing clients |
| --- | --- | --- | --- | --- |
| `test_sstore_bloated` | `SSTORE` | `target_coef` | — | `ethrex` (both) |

</details>

<details>
<summary><code>WARM_ACCESS</code>: 2 weak combos</summary>

| Test | Target opcode | Coef | Combo | Failing clients |
| --- | --- | --- | --- | --- |
| `test_ext_account_query_warm` | `CALLCODE` | `target_coef` | `param_opcode=CALLCODE` / `selected_test=test_ext_account_query_warm` / `selected_opcode=CALLCODE` | `nethermind` (R²) |
| `test_sload_same_key_benchmark` | `SLOAD` | `target_coef` | `selected_test=test_sload_same_key_benchmark` / `selected_opcode=SLOAD` | `besu` (R²), `erigon` (R²), `nethermind` (R²) |

</details>

<details>
<summary><code>COLD_ACCOUNT_NOCODE_ACCESS</code>: 8 weak combos</summary>

| Test | Target opcode | Coef | Combo | Failing clients |
| --- | --- | --- | --- | --- |
| `test_account_access` | `BALANCE` | `target_coef` | `param_opcode=BALANCE` / `selected_opcode=BALANCE` | `ethrex` (R²) |
| `test_account_access` | `CALL` | `target_coef` | `param_opcode=CALL` / `selected_opcode=CALL` | `ethrex` (R²) |
| `test_account_access` | `CALLCODE` | `target_coef` | `param_opcode=CALLCODE` / `selected_opcode=CALLCODE` | `ethrex` (R²) |
| `test_account_access` | `DELEGATECALL` | `target_coef` | `param_opcode=DELEGATECALL` / `selected_opcode=DELEGATECALL` | `ethrex` (R²) |
| `test_account_access` | `EXTCODECOPY` | `target_coef` | `param_opcode=EXTCODECOPY` / `selected_opcode=EXTCODECOPY` | `ethrex` (R²) |
| `test_account_access` | `EXTCODEHASH` | `target_coef` | `param_opcode=EXTCODEHASH` / `selected_opcode=EXTCODEHASH` | `ethrex` (R²) |
| `test_account_access` | `EXTCODESIZE` | `target_coef` | `param_opcode=EXTCODESIZE` / `selected_opcode=EXTCODESIZE` | `ethrex` (R²) |
| `test_account_access` | `STATICCALL` | `target_coef` | `param_opcode=STATICCALL` / `selected_opcode=STATICCALL` | `ethrex` (R²) |

</details>

<details>
<summary><code>COLD_ACCOUNT_CODE_ACCESS</code>: 6 weak combos</summary>

| Test | Target opcode | Coef | Combo | Failing clients |
| --- | --- | --- | --- | --- |
| `test_account_access` | `CALL` | `target_coef` | `param_opcode=CALL` / `selected_opcode=CALL` | `nethermind` (R²), `reth` (R²) |
| `test_account_access` | `CALLCODE` | `target_coef` | `param_opcode=CALLCODE` / `selected_opcode=CALLCODE` | `nethermind` (R²), `reth` (R²) |
| `test_account_access` | `DELEGATECALL` | `target_coef` | `param_opcode=DELEGATECALL` / `selected_opcode=DELEGATECALL` | `nethermind` (R²), `reth` (R²) |
| `test_account_access` | `EXTCODECOPY` | `target_coef` | `param_opcode=EXTCODECOPY` / `selected_opcode=EXTCODECOPY` | `nethermind` (R²), `reth` (R²) |
| `test_account_access` | `EXTCODESIZE` | `target_coef` | `param_opcode=EXTCODESIZE` / `selected_opcode=EXTCODESIZE` | `nethermind` (R²), `reth` (R²) |
| `test_account_access` | `STATICCALL` | `target_coef` | `param_opcode=STATICCALL` / `selected_opcode=STATICCALL` | `nethermind` (R²), `reth` (R²) |

</details>

<details>
<summary><code>COLD_ACCOUNT_CODE_WRITE</code>: 3 weak combos</summary>

| Test | Target opcode | Coef | Combo | Failing clients |
| --- | --- | --- | --- | --- |
| `test_account_access` | `CALLCODE` | `target_coef` | `param_account_mode=AccountMode.EXISTING_CONTRACT_DIFF_MAX` | `reth` (R²) |
| `test_account_access` | `CALLCODE` | `target_coef` | `param_account_mode=AccountMode.EXISTING_CONTRACT_MINIMAL` | `ethrex` (R²) |
| `test_account_access` | `CALLCODE` | `target_coef` | `param_account_mode=AccountMode.EXISTING_CONTRACT_SAME_MAX` | `ethrex` (R²) |

</details>
