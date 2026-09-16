# Runtime estimation report

Per-spec NNLS fits of `test_runtime_ms` against `opcount`, one row per (target opcode, test, model_by combo, client).

> Note: this is a bundled snapshot of the analysis output. The per-client regression, bootstrap, and diagnostic plots are omitted here; the figure-rich version is published on the live analysis site linked from the EIP's discussions-to thread.

## Contents

- [DIV](#div)
- [SDIV](#sdiv)
- [MOD](#mod)
- [SMOD](#smod)
- [ADDMOD](#addmod)
- [MULMOD](#mulmod)
- [KECCAK256](#keccak256)
- [ECRECOVER](#ecrecover)
- [BLAKE2F](#blake2f)
- [BLS12_G1ADD](#bls12_g1add)
- [BLS12_G2ADD](#bls12_g2add)
- [ECADD](#ecadd)
- [ECPAIRING](#ecpairing)
- [POINT_EVALUATION](#point_evaluation)
- [P256VERIFY](#p256verify)

## DIV

### test_arithmetic

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.7121 | 1.517e-05 | 1.00e-03 | [1.487e-05, 1.547e-05] |
| `erigon` | 231 | 0.8953 | 1.012e-05 | 1.00e-03 | [9.693e-06, 1.054e-05] |
| `ethrex` | 1562 | 0.8405 | 9.341e-06 | 1.00e-03 | [9.109e-06, 9.565e-06] |
| `geth` | 4092 | 0.798 | 9.484e-06 | 1.00e-03 | [9.331e-06, 9.646e-06] |
| `nethermind` | 1155 | 0.6416 | 7.747e-06 | 1.00e-03 | [7.305e-06, 8.208e-06] |
| `reth` | 99 | 0.8305 | 7.01e-06 | 1.00e-03 | [6.317e-06, 7.706e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.712
Model:                  NNLS                    Adj. R-squared:          0.712
No. Observations:       3652                              RMSE:          76.17
Df Residuals:           3650                               MAE:          61.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    141.9384      3.5555       0.001    134.9084    148.7499
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.895
Model:                  NNLS                    Adj. R-squared:          0.895
No. Observations:       231                               RMSE:          27.32
Df Residuals:           229                                MAE:          23.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     23.9785      5.9218       0.001     12.7086     35.5325
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.840
Model:                  NNLS                    Adj. R-squared:          0.840
No. Observations:       1562                              RMSE:          32.13
Df Residuals:           1560                               MAE:          27.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     72.4046      3.1072       0.001     66.3321     78.7320
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.798
Model:                  NNLS                    Adj. R-squared:          0.798
No. Observations:       4092                              RMSE:          37.67
Df Residuals:           4090                               MAE:          30.77
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     75.8186      2.1321       0.001     71.8208     79.8344
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.642
Model:                  NNLS                    Adj. R-squared:          0.641
No. Observations:       1155                              RMSE:          45.71
Df Residuals:           1153                               MAE:          36.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    129.0635      6.1217       0.001    116.3925    141.1473
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.830
Model:                  NNLS                    Adj. R-squared:          0.829
No. Observations:       99                                RMSE:          25.00
Df Residuals:           97                                 MAE:          21.02
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     55.0211      9.3538       0.001     36.6781     74.0580
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## SDIV

### test_arithmetic

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.7859 | 1.656e-05 | 1.00e-03 | [1.628e-05, 1.683e-05] |
| `erigon` | 231 | 0.8208 | 1.105e-05 | 1.00e-03 | [1.025e-05, 1.17e-05] |
| `ethrex` | 1562 | 0.8416 | 9.448e-06 | 1.00e-03 | [9.222e-06, 9.67e-06] |
| `geth` | 4092 | 0.8293 | 1.015e-05 | 1.00e-03 | [9.992e-06, 1.031e-05] |
| `nethermind` | 1155 | 0.8646 | 1.32e-05 | 1.00e-03 | [1.29e-05, 1.351e-05] |
| `reth` | 99 | 0.8431 | 8.962e-06 | 1.00e-03 | [8.178e-06, 9.826e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.786
Model:                  NNLS                    Adj. R-squared:          0.786
No. Observations:       3652                              RMSE:          68.25
Df Residuals:           3650                               MAE:          56.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    133.1578      3.6254       0.001    126.3311    140.6890
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.821
Model:                  NNLS                    Adj. R-squared:          0.820
No. Observations:       231                               RMSE:          40.76
Df Residuals:           229                                MAE:          28.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     40.8380     11.1047       0.001     21.8948     64.9287
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.842
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       1562                              RMSE:          32.36
Df Residuals:           1560                               MAE:          27.41
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     75.0055      3.2793       0.001     68.5648     81.4451
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.829
Model:                  NNLS                    Adj. R-squared:          0.829
No. Observations:       4092                              RMSE:          36.33
Df Residuals:           4090                               MAE:          30.35
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     79.4371      2.1093       0.001     75.3166     83.5254
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.865
Model:                  NNLS                    Adj. R-squared:          0.864
No. Observations:       1155                              RMSE:          41.24
Df Residuals:           1153                               MAE:          32.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     68.1618      3.5384       0.001     60.9392     74.8485
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.843
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       99                                RMSE:          30.52
Df Residuals:           97                                 MAE:          24.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     76.1655     11.2760       0.001     53.4124     97.1894
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## MOD

### test_mod — combo `127`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8417 | 1.955e-05 | 1.00e-03 | [1.928e-05, 1.984e-05] |
| `erigon` | 231 | 0.8884 | 1.219e-05 | 1.00e-03 | [1.166e-05, 1.262e-05] |
| `ethrex` | 1562 | 0.8376 | 1.036e-05 | 1.00e-03 | [1.011e-05, 1.063e-05] |
| `geth` | 4092 | 0.8334 | 1.157e-05 | 1.00e-03 | [1.14e-05, 1.174e-05] |
| `nethermind` | 1155 | 0.8847 | 1.011e-05 | 1.00e-03 | [9.904e-06, 1.031e-05] |
| `reth` | 99 | 0.8527 | 7.02e-06 | 1.00e-03 | [6.409e-06, 7.626e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.842
Model:                  NNLS                    Adj. R-squared:          0.842
No. Observations:       3652                              RMSE:          66.83
Df Residuals:           3650                               MAE:          55.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    131.8563      3.8783       0.001    124.2440    139.0374
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.888
Model:                  NNLS                    Adj. R-squared:          0.888
No. Observations:       231                               RMSE:          34.06
Df Residuals:           229                                MAE:          29.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     36.7815      7.0218       0.001     24.1740     51.4539
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.838
No. Observations:       1562                              RMSE:          35.96
Df Residuals:           1560                               MAE:          30.16
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     83.1718      3.6730       0.001     75.5832     90.0965
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.833
Model:                  NNLS                    Adj. R-squared:          0.833
No. Observations:       4092                              RMSE:          40.79
Df Residuals:           4090                               MAE:          34.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     88.0946      2.4571       0.001     83.2459     92.9181
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.885
Model:                  NNLS                    Adj. R-squared:          0.885
No. Observations:       1155                              RMSE:          28.78
Df Residuals:           1153                               MAE:          22.56
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     44.3388      2.3979       0.001     39.8336     49.1209
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.853
Model:                  NNLS                    Adj. R-squared:          0.851
No. Observations:       99                                RMSE:          23.01
Df Residuals:           97                                 MAE:          19.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     50.7237      8.6950       0.001     34.7373     67.9577
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_mod — combo `191`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8314 | 1.784e-05 | 1.00e-03 | [1.759e-05, 1.81e-05] |
| `erigon` | 231 | 0.8406 | 1.177e-05 | 1.00e-03 | [1.128e-05, 1.221e-05] |
| `ethrex` | 1562 | 0.8405 | 8.857e-06 | 1.00e-03 | [8.66e-06, 9.061e-06] |
| `geth` | 4092 | 0.834 | 1.108e-05 | 1.00e-03 | [1.091e-05, 1.126e-05] |
| `nethermind` | 1155 | 0.8955 | 1.122e-05 | 1.00e-03 | [1.102e-05, 1.142e-05] |
| `reth` | 99 | 0.8484 | 9.667e-06 | 1.00e-03 | [8.782e-06, 1.059e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.831
Model:                  NNLS                    Adj. R-squared:          0.831
No. Observations:       3652                              RMSE:          63.37
Df Residuals:           3650                               MAE:          52.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.5314      3.3678       0.001    126.0903    139.1599
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.841
Model:                  NNLS                    Adj. R-squared:          0.840
No. Observations:       231                               RMSE:          40.42
Df Residuals:           229                                MAE:          29.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     35.5724      6.6088       0.001     23.1426     49.5225
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.840
Model:                  NNLS                    Adj. R-squared:          0.840
No. Observations:       1562                              RMSE:          30.42
Df Residuals:           1560                               MAE:          25.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     70.9856      3.0064       0.001     65.1218     76.7602
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.834
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       4092                              RMSE:          38.96
Df Residuals:           4090                               MAE:          32.81
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     83.9228      2.3436       0.001     79.1851     88.4416
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.895
Model:                  NNLS                    Adj. R-squared:          0.895
No. Observations:       1155                              RMSE:          30.23
Df Residuals:           1153                               MAE:          23.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     50.9802      2.5763       0.001     46.2622     56.1335
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.848
Model:                  NNLS                    Adj. R-squared:          0.847
No. Observations:       99                                RMSE:          32.22
Df Residuals:           97                                 MAE:          26.80
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     80.1545     12.0225       0.001     57.1653    103.6467
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_mod — combo `255`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8029 | 1.454e-05 | 1.00e-03 | [1.43e-05, 1.477e-05] |
| `erigon` | 231 | 0.7683 | 1.167e-05 | 1.00e-03 | [1.111e-05, 1.226e-05] |
| `ethrex` | 1562 | 0.8369 | 6.94e-06 | 1.00e-03 | [6.752e-06, 7.112e-06] |
| `geth` | 4092 | 0.8343 | 1.014e-05 | 1.00e-03 | [9.99e-06, 1.028e-05] |
| `nethermind` | 1155 | 0.9198 | 1.033e-05 | 1.00e-03 | [1.015e-05, 1.051e-05] |
| `reth` | 99 | 0.8313 | 8.048e-06 | 1.00e-03 | [7.341e-06, 8.779e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.803
Model:                  NNLS                    Adj. R-squared:          0.803
No. Observations:       3652                              RMSE:          56.80
Df Residuals:           3650                               MAE:          47.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    103.0783      3.0838       0.001     96.8893    108.9770
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.768
Model:                  NNLS                    Adj. R-squared:          0.767
No. Observations:       231                               RMSE:          50.55
Df Residuals:           229                                MAE:          32.57
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.8941      6.6814       0.001     15.1897     41.4582
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.837
Model:                  NNLS                    Adj. R-squared:          0.837
No. Observations:       1562                              RMSE:          24.16
Df Residuals:           1560                               MAE:          19.71
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     54.7166      2.5082       0.001     49.9655     59.9829
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.834
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       4092                              RMSE:          35.62
Df Residuals:           4090                               MAE:          30.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     76.1088      2.0554       0.001     72.2294     80.1210
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.920
Model:                  NNLS                    Adj. R-squared:          0.920
No. Observations:       1155                              RMSE:          24.05
Df Residuals:           1153                               MAE:          19.19
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     50.0879      2.3025       0.001     45.7861     54.8095
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.831
Model:                  NNLS                    Adj. R-squared:          0.830
No. Observations:       99                                RMSE:          28.59
Df Residuals:           97                                 MAE:          23.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     74.8179      9.8075       0.001     55.6624     93.6979
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_mod — combo `63`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8188 | 1.452e-05 | 1.00e-03 | [1.428e-05, 1.476e-05] |
| `erigon` | 231 | 0.7559 | 9.076e-06 | 1.00e-03 | [8.568e-06, 9.67e-06] |
| `ethrex` | 1562 | 0.8289 | 5.599e-06 | 1.00e-03 | [5.462e-06, 5.734e-06] |
| `geth` | 4092 | 0.8316 | 8.187e-06 | 1.00e-03 | [8.061e-06, 8.308e-06] |
| `nethermind` | 1155 | 0.9012 | 6.91e-06 | 1.00e-03 | [6.797e-06, 7.034e-06] |
| `reth` | 99 | 0.8596 | 6.34e-06 | 1.00e-03 | [5.802e-06, 6.885e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.819
Model:                  NNLS                    Adj. R-squared:          0.819
No. Observations:       3652                              RMSE:          53.86
Df Residuals:           3650                               MAE:          44.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.0392      3.1849       0.001     92.0876    104.0915
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.756
Model:                  NNLS                    Adj. R-squared:          0.755
No. Observations:       231                               RMSE:          40.66
Df Residuals:           229                                MAE:          21.41
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.1955      5.5091       0.002      4.8600     27.3480
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.829
Model:                  NNLS                    Adj. R-squared:          0.829
No. Observations:       1562                              RMSE:          20.05
Df Residuals:           1560                               MAE:          16.99
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     44.3450      1.9118       0.001     40.4827     48.0979
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.832
Model:                  NNLS                    Adj. R-squared:          0.832
No. Observations:       4092                              RMSE:          29.05
Df Residuals:           4090                               MAE:          24.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     62.0235      1.7256       0.001     58.7117     65.4521
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.901
Model:                  NNLS                    Adj. R-squared:          0.901
No. Observations:       1155                              RMSE:          18.04
Df Residuals:           1153                               MAE:          12.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     31.4773      1.3868       0.001     28.7883     34.0949
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.860
Model:                  NNLS                    Adj. R-squared:          0.858
No. Observations:       99                                RMSE:          20.20
Df Residuals:           97                                 MAE:          16.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     51.8488      6.9785       0.001     37.9509     65.7563
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## SMOD

### test_mod — combo `127`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8466 | 2.015e-05 | 1.00e-03 | [1.987e-05, 2.045e-05] |
| `erigon` | 231 | 0.895 | 1.286e-05 | 1.00e-03 | [1.23e-05, 1.33e-05] |
| `ethrex` | 1562 | 0.8344 | 1.055e-05 | 1.00e-03 | [1.032e-05, 1.081e-05] |
| `geth` | 4092 | 0.8316 | 1.216e-05 | 1.00e-03 | [1.199e-05, 1.234e-05] |
| `nethermind` | 1155 | 0.9335 | 1.103e-05 | 1.00e-03 | [1.085e-05, 1.121e-05] |
| `reth` | 99 | 0.8675 | 7.022e-06 | 1.00e-03 | [6.457e-06, 7.574e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.847
Model:                  NNLS                    Adj. R-squared:          0.847
No. Observations:       3652                              RMSE:          67.64
Df Residuals:           3650                               MAE:          56.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    142.8678      4.0678       0.001    134.6763    150.7313
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.895
Model:                  NNLS                    Adj. R-squared:          0.895
No. Observations:       231                               RMSE:          34.73
Df Residuals:           229                                MAE:          30.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     32.0862      7.1611       0.001     19.6539     48.1089
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.834
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       1562                              RMSE:          37.08
Df Residuals:           1560                               MAE:          31.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     81.5883      3.5414       0.001     74.6095     88.3820
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.832
Model:                  NNLS                    Adj. R-squared:          0.832
No. Observations:       4092                              RMSE:          43.15
Df Residuals:           4090                               MAE:          36.48
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     88.0482      2.5544       0.001     82.9009     92.9295
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.933
Model:                  NNLS                    Adj. R-squared:          0.933
No. Observations:       1155                              RMSE:          23.21
Df Residuals:           1153                               MAE:          18.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     48.9030      2.2200       0.001     44.5088     53.2733
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.867
Model:                  NNLS                    Adj. R-squared:          0.866
No. Observations:       99                                RMSE:          21.64
Df Residuals:           97                                 MAE:          17.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     56.1200      7.9813       0.001     40.9087     72.0673
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_mod — combo `191`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8303 | 1.876e-05 | 1.00e-03 | [1.846e-05, 1.901e-05] |
| `erigon` | 231 | 0.8949 | 1.247e-05 | 1.00e-03 | [1.192e-05, 1.293e-05] |
| `ethrex` | 1562 | 0.8394 | 8.982e-06 | 1.00e-03 | [8.76e-06, 9.192e-06] |
| `geth` | 4092 | 0.831 | 1.156e-05 | 1.00e-03 | [1.139e-05, 1.175e-05] |
| `nethermind` | 1155 | 0.9136 | 1.238e-05 | 1.00e-03 | [1.217e-05, 1.258e-05] |
| `reth` | 99 | 0.8589 | 1.058e-05 | 1.00e-03 | [9.658e-06, 1.152e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.830
Model:                  NNLS                    Adj. R-squared:          0.830
No. Observations:       3652                              RMSE:          66.87
Df Residuals:           3650                               MAE:          55.78
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    133.6374      3.7811       0.001    126.9613    141.4523
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.895
Model:                  NNLS                    Adj. R-squared:          0.894
No. Observations:       231                               RMSE:          33.68
Df Residuals:           229                                MAE:          29.71
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     33.4731      6.9291       0.001     21.4734     48.7536
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.839
Model:                  NNLS                    Adj. R-squared:          0.839
No. Observations:       1562                              RMSE:          30.97
Df Residuals:           1560                               MAE:          26.16
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     70.3621      3.0443       0.001     64.8521     76.5328
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.831
Model:                  NNLS                    Adj. R-squared:          0.831
No. Observations:       4092                              RMSE:          41.11
Df Residuals:           4090                               MAE:          34.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     85.7090      2.4385       0.001     80.5961     90.5012
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.914
Model:                  NNLS                    Adj. R-squared:          0.914
No. Observations:       1155                              RMSE:          30.02
Df Residuals:           1153                               MAE:          23.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     55.4057      2.6612       0.001     50.4132     60.8283
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.859
Model:                  NNLS                    Adj. R-squared:          0.857
No. Observations:       99                                RMSE:          33.81
Df Residuals:           97                                 MAE:          28.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     66.7033     13.2193       0.001     40.6144     94.4093
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_mod — combo `255`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8109 | 1.537e-05 | 1.00e-03 | [1.514e-05, 1.563e-05] |
| `erigon` | 231 | 0.8778 | 1.195e-05 | 1.00e-03 | [1.132e-05, 1.256e-05] |
| `ethrex` | 1562 | 0.8385 | 7.31e-06 | 1.00e-03 | [7.131e-06, 7.493e-06] |
| `geth` | 4092 | 0.831 | 1.029e-05 | 1.00e-03 | [1.014e-05, 1.046e-05] |
| `nethermind` | 1155 | 0.9259 | 1.109e-05 | 1.00e-03 | [1.091e-05, 1.128e-05] |
| `reth` | 99 | 0.8422 | 8.753e-06 | 1.00e-03 | [7.994e-06, 9.546e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.811
Model:                  NNLS                    Adj. R-squared:          0.811
No. Observations:       3652                              RMSE:          58.54
Df Residuals:           3650                               MAE:          48.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    105.2530      3.2482       0.001     98.6946    111.2062
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.878
Model:                  NNLS                    Adj. R-squared:          0.877
No. Observations:       231                               RMSE:          35.16
Df Residuals:           229                                MAE:          27.67
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.5224      7.8330       0.003      7.6607     38.1582
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.838
No. Observations:       1562                              RMSE:          25.30
Df Residuals:           1560                               MAE:          21.39
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     55.0181      2.5050       0.001     49.8847     59.8868
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.831
Model:                  NNLS                    Adj. R-squared:          0.831
No. Observations:       4092                              RMSE:          36.60
Df Residuals:           4090                               MAE:          30.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     78.8605      2.2117       0.001     74.3816     83.1446
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.926
Model:                  NNLS                    Adj. R-squared:          0.926
No. Observations:       1155                              RMSE:          24.75
Df Residuals:           1153                               MAE:          19.59
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     50.5899      2.4067       0.001     46.1960     55.2439
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.842
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       99                                RMSE:          29.87
Df Residuals:           97                                 MAE:          25.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     69.8202     10.8710       0.001     48.1953     90.9060
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_mod — combo `63`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8117 | 1.549e-05 | 1.00e-03 | [1.524e-05, 1.573e-05] |
| `erigon` | 231 | 0.8938 | 9.202e-06 | 1.00e-03 | [8.769e-06, 9.614e-06] |
| `ethrex` | 1562 | 0.8276 | 4.542e-06 | 1.00e-03 | [4.42e-06, 4.651e-06] |
| `geth` | 4092 | 0.8289 | 8.62e-06 | 1.00e-03 | [8.492e-06, 8.756e-06] |
| `nethermind` | 1155 | 0.9146 | 8.104e-06 | 1.00e-03 | [7.961e-06, 8.245e-06] |
| `reth` | 99 | 0.8655 | 6.348e-06 | 1.00e-03 | [5.832e-06, 6.881e-06] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.812
Model:                  NNLS                    Adj. R-squared:          0.812
No. Observations:       3652                              RMSE:          58.82
Df Residuals:           3650                               MAE:          48.33
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    114.5869      3.2754       0.001    108.3147    120.9429
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.894
Model:                  NNLS                    Adj. R-squared:          0.893
No. Observations:       231                               RMSE:          25.01
Df Residuals:           229                                MAE:          20.74
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     19.2036      5.3776       0.001      8.8490     29.9323
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.828
Model:                  NNLS                    Adj. R-squared:          0.827
No. Observations:       1562                              RMSE:          16.35
Df Residuals:           1560                               MAE:          13.67
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     37.5186      1.5748       0.001     34.5816     40.6265
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.829
Model:                  NNLS                    Adj. R-squared:          0.829
No. Observations:       4092                              RMSE:          30.88
Df Residuals:           4090                               MAE:          25.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     67.7025      1.8227       0.001     64.0458     71.2905
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.915
Model:                  NNLS                    Adj. R-squared:          0.915
No. Observations:       1155                              RMSE:          19.52
Df Residuals:           1153                               MAE:          14.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     35.4936      1.6629       0.001     32.2208     38.7607
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.866
Model:                  NNLS                    Adj. R-squared:          0.864
No. Observations:       99                                RMSE:          19.73
Df Residuals:           97                                 MAE:          16.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     51.7572      7.3986       0.001     37.5205     65.8323
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## ADDMOD

### test_mod_arithmetic — combo `191`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8315 | 2.338e-05 | 1.00e-03 | [2.307e-05, 2.371e-05] |
| `erigon` | 231 | 0.9041 | 1.823e-05 | 1.00e-03 | [1.752e-05, 1.893e-05] |
| `ethrex` | 1562 | 0.8367 | 1.361e-05 | 1.00e-03 | [1.327e-05, 1.394e-05] |
| `geth` | 4092 | 0.8376 | 1.65e-05 | 1.00e-03 | [1.626e-05, 1.674e-05] |
| `nethermind` | 1155 | 0.9297 | 1.328e-05 | 1.00e-03 | [1.308e-05, 1.348e-05] |
| `reth` | 99 | 0.8579 | 9.424e-06 | 1.00e-03 | [8.543e-06, 1.031e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.831
Model:                  NNLS                    Adj. R-squared:          0.831
No. Observations:       3652                              RMSE:          47.39
Df Residuals:           3650                               MAE:          38.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    107.4560      2.4447       0.001    102.3448    112.1026
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.904
Model:                  NNLS                    Adj. R-squared:          0.904
No. Observations:       231                               RMSE:          26.73
Df Residuals:           229                                MAE:          23.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     28.5952      5.7405       0.001     17.2735     39.1526
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.837
Model:                  NNLS                    Adj. R-squared:          0.837
No. Observations:       1562                              RMSE:          27.07
Df Residuals:           1560                               MAE:          22.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     61.2844      2.7019       0.001     55.8850     66.6120
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.838
No. Observations:       4092                              RMSE:          32.71
Df Residuals:           4090                               MAE:          27.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     70.9402      1.9049       0.001     67.0255     74.9205
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.930
Model:                  NNLS                    Adj. R-squared:          0.930
No. Observations:       1155                              RMSE:          16.44
Df Residuals:           1153                               MAE:          13.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     33.5232      1.3988       0.001     30.8839     36.2306
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.858
Model:                  NNLS                    Adj. R-squared:          0.856
No. Observations:       99                                RMSE:          17.27
Df Residuals:           97                                 MAE:          14.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     40.7360      6.8612       0.001     26.9693     54.2698
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## MULMOD

### test_mod_arithmetic — combo `191`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8484 | 3.576e-05 | 1.00e-03 | [3.528e-05, 3.625e-05] |
| `erigon` | 231 | 0.8873 | 2.615e-05 | 1.00e-03 | [2.481e-05, 2.722e-05] |
| `ethrex` | 1562 | 0.8258 | 2.265e-05 | 1.00e-03 | [2.212e-05, 2.319e-05] |
| `geth` | 4092 | 0.8357 | 2.385e-05 | 1.00e-03 | [2.35e-05, 2.42e-05] |
| `nethermind` | 1155 | 0.9081 | 3.349e-05 | 1.00e-03 | [3.286e-05, 3.411e-05] |
| `reth` | 99 | 0.8533 | 1.684e-05 | 1.00e-03 | [1.539e-05, 1.832e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.848
Model:                  NNLS                    Adj. R-squared:          0.848
No. Observations:       3652                              RMSE:          68.07
Df Residuals:           3650                               MAE:          57.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    154.8030      3.7485       0.001    147.5404    162.1317
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.887
Model:                  NNLS                    Adj. R-squared:          0.887
No. Observations:       231                               RMSE:          41.96
Df Residuals:           229                                MAE:          36.64
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     44.7394      9.6813       0.001     27.6897     65.4034
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.826
Model:                  NNLS                    Adj. R-squared:          0.826
No. Observations:       1562                              RMSE:          46.83
Df Residuals:           1560                               MAE:          39.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    102.4392      4.4549       0.001     93.6398    110.8514
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.836
Model:                  NNLS                    Adj. R-squared:          0.836
No. Observations:       4092                              RMSE:          47.60
Df Residuals:           4090                               MAE:          40.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    100.3542      2.7265       0.001     94.9464    105.4237
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.908
Model:                  NNLS                    Adj. R-squared:          0.908
No. Observations:       1155                              RMSE:          47.98
Df Residuals:           1153                               MAE:          37.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     84.1258      4.1922       0.001     75.7796     92.1472
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.853
Model:                  NNLS                    Adj. R-squared:          0.852
No. Observations:       99                                RMSE:          31.45
Df Residuals:           97                                 MAE:          25.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     89.1284     11.5187       0.001     66.1461    112.1967
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## KECCAK256

### test_keccak_diff_mem_msg_sizes — combo `0`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 14608 | 0.7664 | 9.826e-05 | 1.00e-03 | [9.736e-05, 9.917e-05] |
| `erigon` | 924 | 0.8081 | 7.638e-05 | 1.00e-03 | [7.385e-05, 7.867e-05] |
| `ethrex` | 6248 | 0.6558 | 1.303e-05 | 1.00e-03 | [1.131e-05, 1.468e-05] |
| `geth` | 16368 | 0.789 | 8.134e-05 | 1.00e-03 | [8.075e-05, 8.201e-05] |
| `nethermind` | 4620 | 0.6981 | 2.397e-05 | 1.00e-03 | [2.048e-05, 2.753e-05] |
| `reth` | 396 | 0.5592 | 1.586e-05 | 1.00e-03 | [7.961e-06, 2.429e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.766
Model:                  NNLS                    Adj. R-squared:          0.766
No. Observations:       14608                             RMSE:          85.33
Df Residuals:           14605                              MAE:          71.14
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    140.5054      2.3213       0.001    135.9759    144.9773
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.808
Model:                  NNLS                    Adj. R-squared:          0.808
No. Observations:       924                               RMSE:          64.05
Df Residuals:           921                                MAE:          49.88
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     38.6597      6.3445       0.001     26.6551     51.3674
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.656
Model:                  NNLS                    Adj. R-squared:          0.656
No. Observations:       6248                              RMSE:          91.87
Df Residuals:           6245                               MAE:          75.93
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     63.8305      3.3412       0.001     57.1098     70.1756
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.789
Model:                  NNLS                    Adj. R-squared:          0.789
No. Observations:       16368                             RMSE:          63.56
Df Residuals:           16365                              MAE:          51.65
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    101.8034      1.6000       0.001     98.4177    104.7050
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.698
Model:                  NNLS                    Adj. R-squared:          0.698
No. Observations:       4620                              RMSE:         158.87
Df Residuals:           4617                               MAE:         130.27
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     90.0434      6.9984       0.001     77.1524    103.8655
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.559
Model:                  NNLS                    Adj. R-squared:          0.557
No. Observations:       396                               RMSE:         106.66
Df Residuals:           393                                MAE:          85.96
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     61.0340     15.9476       0.001     28.4883     92.7944
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_keccak_diff_mem_msg_sizes — combo `1024`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 14608 | 0.7844 | 0.0001079 | 1.00e-03 | [0.0001071, 0.0001089] |
| `erigon` | 924 | 0.8265 | 7.606e-05 | 1.00e-03 | [7.33e-05, 7.866e-05] |
| `ethrex` | 6248 | 0.6561 | 1.316e-05 | 1.00e-03 | [1.136e-05, 1.483e-05] |
| `geth` | 16368 | 0.794 | 8.142e-05 | 1.00e-03 | [8.081e-05, 8.203e-05] |
| `nethermind` | 4620 | 0.7005 | 2.444e-05 | 1.00e-03 | [2.1e-05, 2.794e-05] |
| `reth` | 396 | 0.5698 | 1.625e-05 | 1.00e-03 | [7.498e-06, 2.462e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.784
Model:                  NNLS                    Adj. R-squared:          0.784
No. Observations:       14608                             RMSE:          86.51
Df Residuals:           14605                              MAE:          71.33
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.6644      2.3422       0.001    127.8051    137.1040
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.827
Model:                  NNLS                    Adj. R-squared:          0.826
No. Observations:       924                               RMSE:          59.88
Df Residuals:           921                                MAE:          48.35
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     39.4858      6.2113       0.001     28.0829     52.0117
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.656
Model:                  NNLS                    Adj. R-squared:          0.656
No. Observations:       6248                              RMSE:          92.02
Df Residuals:           6245                               MAE:          76.08
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     63.0297      3.4903       0.001     56.5041     69.8949
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.794
Model:                  NNLS                    Adj. R-squared:          0.794
No. Observations:       16368                             RMSE:          62.78
Df Residuals:           16365                              MAE:          51.24
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.3861      1.6552       0.001     95.0853    101.6429
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.701
Model:                  NNLS                    Adj. R-squared:          0.700
No. Observations:       4620                              RMSE:         158.37
Df Residuals:           4617                               MAE:         129.51
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     86.8001      6.8432       0.001     72.9895    100.1890
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.570
Model:                  NNLS                    Adj. R-squared:          0.568
No. Observations:       396                               RMSE:         106.37
Df Residuals:           393                                MAE:          85.33
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     58.1366     16.2160       0.001     25.6331     88.6644
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_keccak_diff_mem_msg_sizes — combo `256`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 14608 | 0.7805 | 0.0001103 | 1.00e-03 | [0.0001094, 0.0001112] |
| `erigon` | 924 | 0.8147 | 7.492e-05 | 1.00e-03 | [7.224e-05, 7.721e-05] |
| `ethrex` | 6248 | 0.6564 | 1.325e-05 | 1.00e-03 | [1.157e-05, 1.488e-05] |
| `geth` | 16368 | 0.7919 | 8.097e-05 | 1.00e-03 | [8.033e-05, 8.155e-05] |
| `nethermind` | 4620 | 0.6993 | 2.44e-05 | 1.00e-03 | [2.093e-05, 2.758e-05] |
| `reth` | 396 | 0.5606 | 1.602e-05 | 1.00e-03 | [7.885e-06, 2.455e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.780
Model:                  NNLS                    Adj. R-squared:          0.780
No. Observations:       14608                             RMSE:          88.97
Df Residuals:           14605                              MAE:          73.33
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    129.1090      2.3482       0.001    124.8571    133.7915
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.815
Model:                  NNLS                    Adj. R-squared:          0.814
No. Observations:       924                               RMSE:          61.55
Df Residuals:           921                                MAE:          49.34
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     45.0322      6.3195       0.001     32.6658     58.4800
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.656
Model:                  NNLS                    Adj. R-squared:          0.656
No. Observations:       6248                              RMSE:          91.89
Df Residuals:           6245                               MAE:          75.85
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     62.6232      3.2391       0.001     56.5885     69.0111
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.792
Model:                  NNLS                    Adj. R-squared:          0.792
No. Observations:       16368                             RMSE:          62.85
Df Residuals:           16365                              MAE:          50.96
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     99.7643      1.6299       0.001     96.6401    102.8870
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.699
Model:                  NNLS                    Adj. R-squared:          0.699
No. Observations:       4620                              RMSE:         158.40
Df Residuals:           4617                               MAE:         129.58
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     87.8619      6.5439       0.001     75.0825    100.8425
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.561
Model:                  NNLS                    Adj. R-squared:          0.558
No. Observations:       396                               RMSE:         106.64
Df Residuals:           393                                MAE:          85.88
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     59.8467     15.4798       0.001     27.8576     88.8289
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_keccak_diff_mem_msg_sizes — combo `32`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 14608 | 0.7611 | 0.0001022 | 1.00e-03 | [0.0001012, 0.0001031] |
| `erigon` | 924 | 0.8226 | 7.518e-05 | 1.00e-03 | [7.282e-05, 7.761e-05] |
| `ethrex` | 6248 | 0.6549 | 1.314e-05 | 1.00e-03 | [1.145e-05, 1.507e-05] |
| `geth` | 16368 | 0.7919 | 8.123e-05 | 1.00e-03 | [8.061e-05, 8.188e-05] |
| `nethermind` | 4620 | 0.6992 | 2.408e-05 | 1.00e-03 | [2.071e-05, 2.76e-05] |
| `reth` | 396 | 0.5645 | 1.527e-05 | 1.00e-03 | [7.06e-06, 2.302e-05] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.761
Model:                  NNLS                    Adj. R-squared:          0.761
No. Observations:       14608                             RMSE:          87.97
Df Residuals:           14605                              MAE:          73.55
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    152.3981      2.4343       0.001    147.6067    157.3849
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.823
Model:                  NNLS                    Adj. R-squared:          0.822
No. Observations:       924                               RMSE:          59.80
Df Residuals:           921                                MAE:          48.80
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     44.7774      6.0713       0.001     32.7908     55.8971
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.655
Model:                  NNLS                    Adj. R-squared:          0.655
No. Observations:       6248                              RMSE:          92.09
Df Residuals:           6245                               MAE:          76.07
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     63.4598      3.4548       0.001     56.4330     70.1921
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.792
Model:                  NNLS                    Adj. R-squared:          0.792
No. Observations:       16368                             RMSE:          63.06
Df Residuals:           16365                              MAE:          51.79
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.2611      1.6387       0.001     95.1424    101.4627
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.699
Model:                  NNLS                    Adj. R-squared:          0.699
No. Observations:       4620                              RMSE:         158.51
Df Residuals:           4617                               MAE:         130.02
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     89.4085      6.8927       0.001     74.9642    102.9367
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.565
Model:                  NNLS                    Adj. R-squared:          0.562
No. Observations:       396                               RMSE:         106.18
Df Residuals:           393                                MAE:          85.13
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     63.0521     15.0854       0.001     33.3584     93.2852
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
     msg_words      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## ECRECOVER

### test_ecrecover

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8849 | 0.0067 | 1.00e-03 | [0.006622, 0.006774] |
| `erigon` | 231 | 0.8262 | 0.008405 | 1.00e-03 | [0.007826, 0.008916] |
| `ethrex` | 1562 | 0.8209 | 0.006236 | 1.00e-03 | [0.006081, 0.006386] |
| `geth` | 4092 | 0.8809 | 0.007801 | 1.00e-03 | [0.007716, 0.007889] |
| `nethermind` | 1155 | 0.8773 | 0.006904 | 1.00e-03 | [0.006725, 0.007079] |
| `reth` | 99 | 0.8359 | 0.006548 | 1.00e-03 | [0.005918, 0.007205] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.885
Model:                  NNLS                    Adj. R-squared:          0.885
No. Observations:       3652                              RMSE:          48.76
Df Residuals:           3650                               MAE:          41.53
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    144.1879      2.7858       0.001    138.8795    149.7463
       opcount      0.0067      0.0000       0.001      0.0066      0.0068
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.826
Model:                  NNLS                    Adj. R-squared:          0.825
No. Observations:       231                               RMSE:          77.79
Df Residuals:           229                                MAE:          50.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     88.2901     22.6796       0.001     47.9486    132.7997
       opcount      0.0084      0.0003       0.001      0.0078      0.0089
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.821
Model:                  NNLS                    Adj. R-squared:          0.821
No. Observations:       1562                              RMSE:          58.76
Df Residuals:           1560                               MAE:          50.41
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    129.8668      5.6566       0.001    119.4284    141.5329
       opcount      0.0062      0.0001       0.001      0.0061      0.0064
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.881
Model:                  NNLS                    Adj. R-squared:          0.881
No. Observations:       4092                              RMSE:          57.88
Df Residuals:           4090                               MAE:          49.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    115.3869      3.1047       0.001    109.5404    121.2017
       opcount      0.0078      0.0000       0.001      0.0077      0.0079
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.877
Model:                  NNLS                    Adj. R-squared:          0.877
No. Observations:       1155                              RMSE:          52.09
Df Residuals:           1153                               MAE:          43.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    102.8759      5.9971       0.001     90.7031    114.2329
       opcount      0.0069      0.0001       0.001      0.0067      0.0071
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.836
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       99                                RMSE:          58.53
Df Residuals:           97                                 MAE:          48.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    121.0467     23.1192       0.001     76.5813    167.6927
       opcount      0.0065      0.0003       0.001      0.0059      0.0072
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## BLAKE2F

### test_blake2f_benchmark

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 14608 | 0.8693 | 0.0003378 | 1.00e-03 | [0.0003353, 0.0003401] |
| `erigon` | 924 | 0.9536 | 0.0005902 | 1.00e-03 | [0.0005812, 0.0006001] |
| `ethrex` | 6248 | 0.8723 | 4.498e-05 | 1.00e-03 | [4.425e-05, 4.578e-05] |
| `geth` | 16368 | 0.9304 | 0.000104 | 1.00e-03 | [0.0001034, 0.0001045] |
| `nethermind` | 4620 | 0.9519 | 0.000156 | 1.00e-03 | [0.0001549, 0.0001572] |
| `reth` | 396 | 0.9896 | 0.0003815 | 1.00e-03 | [0.0003779, 0.0003852] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.869
Model:                  NNLS                    Adj. R-squared:          0.869
No. Observations:       14608                             RMSE:          68.62
Df Residuals:           14605                              MAE:          58.14
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    164.7682      2.1811       0.001    160.6268    169.1850
       opcount      0.0003      0.0000       0.001      0.0003      0.0003
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.954
Model:                  NNLS                    Adj. R-squared:          0.954
No. Observations:       924                               RMSE:          65.82
Df Residuals:           921                                MAE:          47.74
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     18.3210      6.8763       0.006      4.8943     31.6851
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
    num_rounds      0.0000      0.0000       0.008      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.872
Model:                  NNLS                    Adj. R-squared:          0.872
No. Observations:       6248                              RMSE:          14.26
Df Residuals:           6245                               MAE:          11.57
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     28.2348      0.6540       0.001     26.8982     29.4346
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.930
Model:                  NNLS                    Adj. R-squared:          0.930
No. Observations:       16368                             RMSE:          17.30
Df Residuals:           16365                              MAE:          13.85
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     34.8823      0.4928       0.001     33.9108     35.8480
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.952
Model:                  NNLS                    Adj. R-squared:          0.952
No. Observations:       4620                              RMSE:          18.92
Df Residuals:           4617                               MAE:          15.48
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     28.8549      0.7941       0.001     27.1293     30.3438
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       396                               RMSE:          19.75
Df Residuals:           393                                MAE:          15.67
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     11.6857      3.0888       0.001      5.5188     17.8405
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
    num_rounds      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_blake2f_uncachable

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 14608 | 0.8528 | 0.0004011 | 1.00e-03 | [0.0003981, 0.0004041] |
| `erigon` | 924 | 0.9603 | 0.0009363 | 1.00e-03 | [0.0009227, 0.000948] |
| `ethrex` | 6248 | 0.8711 | 5.119e-05 | 1.00e-03 | [5.033e-05, 5.198e-05] |
| `geth` | 16368 | 0.9234 | 0.0001355 | 1.00e-03 | [0.0001348, 0.0001363] |
| `nethermind` | 4620 | 0.9323 | 0.000165 | 1.00e-03 | [0.0001637, 0.0001663] |
| `reth` | 396 | 0.9875 | 0.0003756 | 1.00e-03 | [0.0003718, 0.0003789] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.853
Model:                  NNLS                    Adj. R-squared:          0.853
No. Observations:       14608                             RMSE:          71.68
Df Residuals:           14605                              MAE:          60.58
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    156.0843      2.1709       0.001    151.6979    160.3488
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       924                               RMSE:          78.79
Df Residuals:           921                                MAE:          57.78
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     47.1798      8.3910       0.001     32.0294     64.6495
       opcount      0.0009      0.0000       0.001      0.0009      0.0009
    num_rounds      0.0000      0.0000       0.198      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.871
Model:                  NNLS                    Adj. R-squared:          0.871
No. Observations:       6248                              RMSE:          12.77
Df Residuals:           6245                               MAE:          10.39
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     23.9197      0.5441       0.001     22.9303     25.0477
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.923
Model:                  NNLS                    Adj. R-squared:          0.923
No. Observations:       16368                             RMSE:          18.47
Df Residuals:           16365                              MAE:          14.56
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     23.9269      0.5474       0.001     22.8235     24.9216
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.932
Model:                  NNLS                    Adj. R-squared:          0.932
No. Observations:       4620                              RMSE:          19.86
Df Residuals:           4617                               MAE:          14.32
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.5344      0.7865       0.001     24.9812     28.0668
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
    num_rounds      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.988
Model:                  NNLS                    Adj. R-squared:          0.987
No. Observations:       396                               RMSE:          17.44
Df Residuals:           393                                MAE:          14.04
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.4682      2.6589       0.001     11.4694     21.9744
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
    num_rounds      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## BLS12_G1ADD

### test_bls12_381

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8572 | 0.001742 | 1.00e-03 | [0.00172, 0.001767] |
| `erigon` | 231 | 0.8317 | 0.0009951 | 1.00e-03 | [0.0009579, 0.00103] |
| `ethrex` | 1562 | 0.05318 | 0.002351 | 1.00e-03 | [0.001864, 0.00278] |
| `geth` | 4092 | 0.9 | 0.000733 | 1.00e-03 | [0.0007246, 0.0007412] |
| `nethermind` | 1155 | 0.9388 | 0.0009701 | 1.00e-03 | [0.0009563, 0.0009841] |
| `reth` | 99 | 0.8538 | 0.0007585 | 1.00e-03 | [0.0006852, 0.000828] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.857
Model:                  NNLS                    Adj. R-squared:          0.857
No. Observations:       3652                              RMSE:          91.12
Df Residuals:           3650                               MAE:          72.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     99.2794      5.7564       0.001     87.7412    109.8290
       opcount      0.0017      0.0000       0.001      0.0017      0.0018
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.832
Model:                  NNLS                    Adj. R-squared:          0.831
No. Observations:       231                               RMSE:          57.34
Df Residuals:           229                                MAE:          37.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     45.8068      9.0191       0.001     28.7509     62.9708
       opcount      0.0010      0.0000       0.001      0.0010      0.0010
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.053
Model:                  NNLS                    Adj. R-squared:          0.053
No. Observations:       1562                              RMSE:        1270.62
Df Residuals:           1560                               MAE:        1146.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    291.7258     88.5341       0.001    130.9252    475.9325
       opcount      0.0024      0.0002       0.001      0.0019      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.900
Model:                  NNLS                    Adj. R-squared:          0.900
No. Observations:       4092                              RMSE:          31.30
Df Residuals:           4090                               MAE:          26.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     65.1685      1.9124       0.001     61.5192     68.8799
       opcount      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.939
Model:                  NNLS                    Adj. R-squared:          0.939
No. Observations:       1155                              RMSE:          31.72
Df Residuals:           1153                               MAE:          25.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     76.5374      2.8442       0.001     71.2104     81.9459
       opcount      0.0010      0.0000       0.001      0.0010      0.0010
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.854
Model:                  NNLS                    Adj. R-squared:          0.852
No. Observations:       99                                RMSE:          40.20
Df Residuals:           97                                 MAE:          34.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     90.0398     16.2699       0.001     58.7032    123.1038
       opcount      0.0008      0.0000       0.001      0.0007      0.0008
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## BLS12_G2ADD

### test_bls12_381

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8683 | 0.00212 | 1.00e-03 | [0.002092, 0.002147] |
| `erigon` | 231 | 0.7986 | 0.001273 | 1.00e-03 | [0.001218, 0.001331] |
| `ethrex` | 1562 | 0.06885 | 0.00277 | 1.00e-03 | [0.002287, 0.003269] |
| `geth` | 4092 | 0.8989 | 0.001048 | 1.00e-03 | [0.001036, 0.001059] |
| `nethermind` | 1155 | 0.9356 | 0.001486 | 1.00e-03 | [0.001462, 0.001508] |
| `reth` | 99 | 0.8454 | 0.001013 | 1.00e-03 | [0.0009255, 0.001108] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.868
Model:                  NNLS                    Adj. R-squared:          0.868
No. Observations:       3652                              RMSE:          72.58
Df Residuals:           3650                               MAE:          58.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     88.8408      4.3018       0.001     80.6795     97.4124
       opcount      0.0021      0.0000       0.001      0.0021      0.0021
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.799
Model:                  NNLS                    Adj. R-squared:          0.798
No. Observations:       231                               RMSE:          56.23
Df Residuals:           229                                MAE:          35.11
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     41.8842      7.7871       0.001     26.9727     57.5737
       opcount      0.0013      0.0000       0.001      0.0012      0.0013
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.069
Model:                  NNLS                    Adj. R-squared:          0.068
No. Observations:       1562                              RMSE:         895.80
Df Residuals:           1560                               MAE:         806.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    238.3055     63.7407       0.001    113.8707    359.9967
       opcount      0.0028      0.0003       0.001      0.0023      0.0033
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.899
Model:                  NNLS                    Adj. R-squared:          0.899
No. Observations:       4092                              RMSE:          30.91
Df Residuals:           4090                               MAE:          25.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     55.4126      1.7924       0.001     52.1050     59.1439
       opcount      0.0010      0.0000       0.001      0.0010      0.0011
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.936
Model:                  NNLS                    Adj. R-squared:          0.936
No. Observations:       1155                              RMSE:          34.27
Df Residuals:           1153                               MAE:          27.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     83.3407      3.1555       0.001     77.2736     89.9864
       opcount      0.0015      0.0000       0.001      0.0015      0.0015
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.845
Model:                  NNLS                    Adj. R-squared:          0.844
No. Observations:       99                                RMSE:          38.10
Df Residuals:           97                                 MAE:          31.07
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    100.4848     14.6671       0.001     72.5037    128.0705
       opcount      0.0010      0.0000       0.001      0.0009      0.0011
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## ECADD

### test_alt_bn128 — combo `add`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8856 | 0.0006195 | 1.00e-03 | [0.0006122, 0.000627] |
| `erigon` | 231 | 0.9289 | 0.0007158 | 1.00e-03 | [0.0006911, 0.0007383] |
| `ethrex` | 1562 | 0.826 | 0.000576 | 1.00e-03 | [0.0005615, 0.0005891] |
| `geth` | 4092 | 0.8805 | 0.0003886 | 1.00e-03 | [0.0003845, 0.000393] |
| `nethermind` | 1155 | 0.9168 | 0.0004388 | 1.00e-03 | [0.000431, 0.0004464] |
| `reth` | 99 | 0.867 | 0.0005895 | 1.00e-03 | [0.0005412, 0.0006379] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.886
Model:                  NNLS                    Adj. R-squared:          0.886
No. Observations:       3652                              RMSE:          52.48
Df Residuals:           3650                               MAE:          44.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    150.8838      3.0729       0.001    144.8091    156.7965
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.929
Model:                  NNLS                    Adj. R-squared:          0.929
No. Observations:       231                               RMSE:          46.66
Df Residuals:           229                                MAE:          39.69
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     42.2780      9.7649       0.001     24.3394     62.1269
       opcount      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.826
Model:                  NNLS                    Adj. R-squared:          0.826
No. Observations:       1562                              RMSE:          62.30
Df Residuals:           1560                               MAE:          53.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    135.5485      5.9133       0.001    124.4990    147.6392
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.880
Model:                  NNLS                    Adj. R-squared:          0.880
No. Observations:       4092                              RMSE:          33.75
Df Residuals:           4090                               MAE:          29.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     80.5519      1.8602       0.001     76.8046     84.2295
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.917
Model:                  NNLS                    Adj. R-squared:          0.917
No. Observations:       1155                              RMSE:          31.15
Df Residuals:           1153                               MAE:          24.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     77.1826      2.9073       0.001     71.7735     82.8734
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.867
Model:                  NNLS                    Adj. R-squared:          0.866
No. Observations:       99                                RMSE:          54.42
Df Residuals:           97                                 MAE:          45.80
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    133.0129     20.8191       0.001     93.7482    175.6213
       opcount      0.0006      0.0000       0.001      0.0005      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_alt_bn128 — combo `add_infinities`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8907 | 0.0003655 | 1.00e-03 | [0.0003611, 0.0003699] |
| `erigon` | 231 | 0.9221 | 0.0005737 | 1.00e-03 | [0.0005604, 0.0005881] |
| `ethrex` | 1562 | 0.8423 | 0.0001401 | 1.00e-03 | [0.0001367, 0.0001437] |
| `geth` | 4092 | 0.789 | 0.0001097 | 1.00e-03 | [0.000108, 0.0001114] |
| `nethermind` | 1155 | 0.918 | 0.0002005 | 1.00e-03 | [0.0001975, 0.0002034] |
| `reth` | 99 | 0.9867 | 0.0003772 | 1.00e-03 | [0.0003692, 0.0003854] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.891
Model:                  NNLS                    Adj. R-squared:          0.891
No. Observations:       3652                              RMSE:          30.17
Df Residuals:           3650                               MAE:          25.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     77.9570      1.7896       0.001     74.3824     81.5722
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.922
Model:                  NNLS                    Adj. R-squared:          0.922
No. Observations:       231                               RMSE:          39.29
Df Residuals:           229                                MAE:          22.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     21.8254      6.1519       0.001      9.9337     34.5979
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.842
Model:                  NNLS                    Adj. R-squared:          0.842
No. Observations:       1562                              RMSE:          14.29
Df Residuals:           1560                               MAE:          11.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.8071      1.3489       0.001     24.0496     29.4687
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.789
Model:                  NNLS                    Adj. R-squared:          0.789
No. Observations:       4092                              RMSE:          13.37
Df Residuals:           4090                               MAE:          10.61
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.6609      0.7561       0.001     11.1456     14.1698
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.918
Model:                  NNLS                    Adj. R-squared:          0.918
No. Observations:       1155                              RMSE:          14.13
Df Residuals:           1153                               MAE:           9.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.8542      1.0544       0.001     13.8584     18.0041
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.987
Model:                  NNLS                    Adj. R-squared:          0.987
No. Observations:       99                                RMSE:          10.31
Df Residuals:           97                                 MAE:           8.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.5468      3.4866       0.016      0.6702     14.2900
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_alt_bn128 — combo `add_negative`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8863 | 0.000384 | 1.00e-03 | [0.0003791, 0.0003888] |
| `erigon` | 231 | 0.8414 | 0.0005794 | 1.00e-03 | [0.0005571, 0.0005963] |
| `ethrex` | 1562 | 0.841 | 0.0002002 | 1.00e-03 | [0.0001954, 0.0002053] |
| `geth` | 4092 | 0.8739 | 0.0001692 | 1.00e-03 | [0.0001671, 0.0001712] |
| `nethermind` | 1155 | 0.9088 | 0.0002669 | 1.00e-03 | [0.0002618, 0.0002717] |
| `reth` | 99 | 0.9774 | 0.0003535 | 1.00e-03 | [0.0003448, 0.0003627] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.886
Model:                  NNLS                    Adj. R-squared:          0.886
No. Observations:       3652                              RMSE:          32.41
Df Residuals:           3650                               MAE:          27.39
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     83.2912      2.0447       0.001     79.3887     87.2641
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.841
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       231                               RMSE:          59.28
Df Residuals:           229                                MAE:          30.02
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     29.0079      8.9798       0.001     14.2142     49.6547
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.841
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       1562                              RMSE:          20.51
Df Residuals:           1560                               MAE:          17.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     46.6268      2.0144       0.001     42.5562     50.3677
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.874
Model:                  NNLS                    Adj. R-squared:          0.874
No. Observations:       4092                              RMSE:          15.14
Df Residuals:           4090                               MAE:          11.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     17.3043      0.9280       0.001     15.4778     19.1064
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.909
Model:                  NNLS                    Adj. R-squared:          0.909
No. Observations:       1155                              RMSE:          19.92
Df Residuals:           1153                               MAE:          13.17
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.2692      1.9039       0.001     23.6578     31.3559
       opcount      0.0003      0.0000       0.001      0.0003      0.0003
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       99                                RMSE:          12.67
Df Residuals:           97                                 MAE:          10.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     25.1619      3.7891       0.001     17.4157     33.0829
       opcount      0.0004      0.0000       0.001      0.0003      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_alt_bn128 — combo `double`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8824 | 0.0006555 | 1.00e-03 | [0.000647, 0.0006636] |
| `erigon` | 231 | 0.8542 | 0.0007104 | 1.00e-03 | [0.0006822, 0.0007357] |
| `ethrex` | 1562 | 0.8272 | 0.0005872 | 1.00e-03 | [0.0005732, 0.0006022] |
| `geth` | 4092 | 0.8792 | 0.0004045 | 1.00e-03 | [0.0003993, 0.0004093] |
| `nethermind` | 1155 | 0.9282 | 0.0004714 | 1.00e-03 | [0.0004634, 0.000479] |
| `reth` | 99 | 0.8591 | 0.0006084 | 1.00e-03 | [0.0005562, 0.0006598] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.882
Model:                  NNLS                    Adj. R-squared:          0.882
No. Observations:       3652                              RMSE:          56.38
Df Residuals:           3650                               MAE:          48.44
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    127.4271      3.6120       0.001    120.5506    134.6351
       opcount      0.0007      0.0000       0.001      0.0006      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.854
Model:                  NNLS                    Adj. R-squared:          0.854
No. Observations:       231                               RMSE:          69.17
Df Residuals:           229                                MAE:          47.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     55.4303     12.7229       0.001     32.2733     81.4497
       opcount      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.827
Model:                  NNLS                    Adj. R-squared:          0.827
No. Observations:       1562                              RMSE:          63.25
Df Residuals:           1560                               MAE:          54.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    133.9596      6.1786       0.001    121.4385    145.6927
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.879
Model:                  NNLS                    Adj. R-squared:          0.879
No. Observations:       4092                              RMSE:          35.33
Df Residuals:           4090                               MAE:          30.53
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     73.5763      2.1589       0.001     69.5622     77.9952
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.928
Model:                  NNLS                    Adj. R-squared:          0.928
No. Observations:       1155                              RMSE:          30.89
Df Residuals:           1153                               MAE:          23.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     48.6767      2.9087       0.001     43.4690     54.5675
       opcount      0.0005      0.0000       0.001      0.0005      0.0005
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.859
Model:                  NNLS                    Adj. R-squared:          0.858
No. Observations:       99                                RMSE:          58.07
Df Residuals:           97                                 MAE:          48.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    122.7038     22.3725       0.001     79.8058    165.7491
       opcount      0.0006      0.0000       0.001      0.0006      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_alt_bn128_uncachable

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8779 | 0.0008978 | 1.00e-03 | [0.0008866, 0.0009086] |
| `erigon` | 231 | 0.9355 | 0.001074 | 1.00e-03 | [0.001036, 0.001107] |
| `ethrex` | 1562 | 0.8156 | 0.0009039 | 1.00e-03 | [0.0008828, 0.0009273] |
| `geth` | 4092 | 0.8611 | 0.0006026 | 1.00e-03 | [0.0005952, 0.00061] |
| `nethermind` | 1155 | 0.944 | 0.0007578 | 1.00e-03 | [0.0007472, 0.0007689] |
| `reth` | 99 | 0.8362 | 0.0009582 | 1.00e-03 | [0.00087, 0.001044] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.878
Model:                  NNLS                    Adj. R-squared:          0.878
No. Observations:       3652                              RMSE:          71.68
Df Residuals:           3650                               MAE:          61.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    174.2594      4.4282       0.001    165.7715    183.1917
       opcount      0.0009      0.0000       0.001      0.0009      0.0009
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.935
Model:                  NNLS                    Adj. R-squared:          0.935
No. Observations:       231                               RMSE:          60.38
Df Residuals:           229                                MAE:          51.70
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     66.8205     13.5799       0.001     41.2421     94.5023
       opcount      0.0011      0.0000       0.001      0.0010      0.0011
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.816
Model:                  NNLS                    Adj. R-squared:          0.815
No. Observations:       1562                              RMSE:          92.02
Df Residuals:           1560                               MAE:          79.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    187.1750      8.7550       0.001    169.4688    203.0392
       opcount      0.0009      0.0000       0.001      0.0009      0.0009
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.861
Model:                  NNLS                    Adj. R-squared:          0.861
No. Observations:       4092                              RMSE:          51.82
Df Residuals:           4090                               MAE:          44.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    107.3041      2.8717       0.001    101.4869    112.8098
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.944
Model:                  NNLS                    Adj. R-squared:          0.944
No. Observations:       1155                              RMSE:          39.51
Df Residuals:           1153                               MAE:          31.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     69.6953      3.5700       0.001     62.6180     76.5260
       opcount      0.0008      0.0000       0.001      0.0007      0.0008
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.836
Model:                  NNLS                    Adj. R-squared:          0.835
No. Observations:       99                                RMSE:          90.79
Df Residuals:           97                                 MAE:          77.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    186.4975     34.3214       0.001    121.1542    255.6964
       opcount      0.0010      0.0000       0.001      0.0009      0.0010
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## ECPAIRING

### test_alt_bn128_benchmark

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 18260 | 0.8814 | 0.04592 | 1.00e-03 | [0.04558, 0.04627] |
| `erigon` | 1155 | 0.7776 | 0.05023 | 1.00e-03 | [0.0482, 0.05234] |
| `ethrex` | 7810 | 0.8117 | 0.04761 | 1.00e-03 | [0.04627, 0.04889] |
| `geth` | 20460 | 0.8178 | 0.0443 | 1.00e-03 | [0.04388, 0.04474] |
| `nethermind` | 5775 | 0.9343 | 0.0664 | 1.00e-03 | [0.06508, 0.06772] |
| `reth` | 495 | 0.8172 | 0.04688 | 1.00e-03 | [0.04257, 0.05164] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.881
Model:                  NNLS                    Adj. R-squared:          0.881
No. Observations:       18260                             RMSE:          20.24
Df Residuals:           18257                              MAE:          17.12
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     52.6567      0.5637       0.001     51.5698     53.6996
       opcount      0.0459      0.0002       0.001      0.0456      0.0463
     num_pairs      0.0262      0.0001       0.001      0.0261      0.0264
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.778
Model:                  NNLS                    Adj. R-squared:          0.777
No. Observations:       1155                              RMSE:          33.01
Df Residuals:           1152                               MAE:          18.84
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.8384      4.5749       0.001     19.0346     36.6277
       opcount      0.0502      0.0011       0.001      0.0482      0.0523
     num_pairs      0.0296      0.0007       0.001      0.0282      0.0310
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.812
Model:                  NNLS                    Adj. R-squared:          0.812
No. Observations:       7810                              RMSE:          53.66
Df Residuals:           7807                               MAE:          44.95
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    110.6409      2.2159       0.001    106.2160    115.0076
       opcount      0.0476      0.0007       0.001      0.0463      0.0489
     num_pairs      0.0589      0.0003       0.001      0.0582      0.0596
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.818
Model:                  NNLS                    Adj. R-squared:          0.818
No. Observations:       20460                             RMSE:          25.91
Df Residuals:           20457                              MAE:          21.70
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     52.7877      0.7042       0.001     51.4742     54.1403
       opcount      0.0443      0.0002       0.001      0.0439      0.0447
     num_pairs      0.0265      0.0001       0.001      0.0263      0.0267
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.934
Model:                  NNLS                    Adj. R-squared:          0.934
No. Observations:       5775                              RMSE:          51.37
Df Residuals:           5772                               MAE:          40.46
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     79.8147      2.0977       0.001     75.7109     83.9170
       opcount      0.0664      0.0007       0.001      0.0651      0.0677
     num_pairs      0.1023      0.0004       0.001      0.1015      0.1030
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.817
Model:                  NNLS                    Adj. R-squared:          0.817
No. Observations:       495                               RMSE:          51.84
Df Residuals:           492                                MAE:          43.05
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    112.0218      8.0009       0.001     96.5744    126.9719
       opcount      0.0469      0.0023       0.001      0.0426      0.0516
     num_pairs      0.0580      0.0013       0.001      0.0555      0.0605
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_ec_pairing

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 18260 | 0.9076 | 0.05105 | 1.00e-03 | [0.05067, 0.05141] |
| `erigon` | 1155 | 0.8897 | 0.04745 | 1.00e-03 | [0.04623, 0.04855] |
| `ethrex` | 7810 | 0.834 | 0.08182 | 1.00e-03 | [0.08061, 0.083] |
| `geth` | 20460 | 0.8667 | 0.04134 | 1.00e-03 | [0.04095, 0.0417] |
| `nethermind` | 5775 | 0.9466 | 0.05277 | 1.00e-03 | [0.05145, 0.05397] |
| `reth` | 495 | 0.8392 | 0.08247 | 1.00e-03 | [0.07785, 0.08735] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.908
Model:                  NNLS                    Adj. R-squared:          0.908
No. Observations:       18260                             RMSE:          19.20
Df Residuals:           18257                              MAE:          15.99
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     43.7129      0.5245       0.001     42.7546     44.8030
       opcount      0.0511      0.0002       0.001      0.0507      0.0514
     num_pairs      0.0331      0.0001       0.001      0.0329      0.0333
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.890
Model:                  NNLS                    Adj. R-squared:          0.889
No. Observations:       1155                              RMSE:          23.52
Df Residuals:           1152                               MAE:          15.58
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     24.6623      1.6627       0.001     21.4796     28.1117
       opcount      0.0475      0.0006       0.001      0.0462      0.0485
     num_pairs      0.0399      0.0003       0.001      0.0393      0.0404
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.834
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       7810                              RMSE:          47.43
Df Residuals:           7807                               MAE:          40.36
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    111.7478      2.0122       0.001    108.1361    115.7305
       opcount      0.0818      0.0006       0.001      0.0806      0.0830
     num_pairs      0.0616      0.0004       0.001      0.0609      0.0623
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.867
Model:                  NNLS                    Adj. R-squared:          0.867
No. Observations:       20460                             RMSE:          25.09
Df Residuals:           20457                              MAE:          20.83
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     50.4421      0.6339       0.001     49.2719     51.7259
       opcount      0.0413      0.0002       0.001      0.0409      0.0417
     num_pairs      0.0392      0.0001       0.001      0.0389      0.0394
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.947
Model:                  NNLS                    Adj. R-squared:          0.947
No. Observations:       5775                              RMSE:          43.15
Df Residuals:           5772                               MAE:          34.69
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     72.6568      1.7660       0.001     69.3939     76.1020
       opcount      0.0528      0.0006       0.001      0.0515      0.0540
     num_pairs      0.1171      0.0004       0.001      0.1164      0.1179
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.839
Model:                  NNLS                    Adj. R-squared:          0.839
No. Observations:       495                               RMSE:          46.22
Df Residuals:           492                                MAE:          38.57
Df Model:               2      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    105.5209      7.4806       0.001     91.2479    120.5613
       opcount      0.0825      0.0024       0.001      0.0778      0.0873
     num_pairs      0.0608      0.0013       0.001      0.0582      0.0634
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## POINT_EVALUATION

### test_point_evaluation

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8753 | 0.1731 | 1.00e-03 | [0.1706, 0.1758] |
| `erigon` | 231 | 0.8993 | 0.1785 | 1.00e-03 | [0.1711, 0.1852] |
| `ethrex` | 1562 | 0.8135 | 0.2363 | 1.00e-03 | [0.2308, 0.2426] |
| `geth` | 4092 | 0.829 | 0.1979 | 1.00e-03 | [0.1951, 0.2007] |
| `nethermind` | 1155 | 0.8769 | 0.2157 | 1.00e-03 | [0.2104, 0.2211] |
| `reth` | 99 | 0.8398 | 0.1978 | 1.00e-03 | [0.1799, 0.2152] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.875
Model:                  NNLS                    Adj. R-squared:          0.875
No. Observations:       3652                              RMSE:          82.74
Df Residuals:           3650                               MAE:          64.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    420.1928      6.0176       0.001    408.0318    430.9260
       opcount      0.1731      0.0014       0.001      0.1706      0.1758
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.899
Model:                  NNLS                    Adj. R-squared:          0.899
No. Observations:       231                               RMSE:          75.65
Df Residuals:           229                                MAE:          67.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     68.6243     15.9205       0.001     40.1323    100.4102
       opcount      0.1785      0.0036       0.001      0.1711      0.1852
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.813
Model:                  NNLS                    Adj. R-squared:          0.813
No. Observations:       1562                              RMSE:         143.32
Df Residuals:           1560                               MAE:         123.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    294.7115     13.6918       0.001    267.0669    319.7219
       opcount      0.2363      0.0030       0.001      0.2308      0.2426
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.829
Model:                  NNLS                    Adj. R-squared:          0.829
No. Observations:       4092                              RMSE:         113.88
Df Residuals:           4090                               MAE:          96.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    230.6663      6.5759       0.001    218.3207    243.6019
       opcount      0.1979      0.0015       0.001      0.1951      0.2007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.877
Model:                  NNLS                    Adj. R-squared:          0.877
No. Observations:       1155                              RMSE:         102.35
Df Residuals:           1153                               MAE:          84.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    199.3761     11.6006       0.001    177.2871    222.5617
       opcount      0.2157      0.0028       0.001      0.2104      0.2211
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.840
Model:                  NNLS                    Adj. R-squared:          0.838
No. Observations:       99                                RMSE:         109.44
Df Residuals:           97                                 MAE:          94.34
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    224.9285     41.7326       0.001    149.6991    313.9231
       opcount      0.1978      0.0093       0.001      0.1799      0.2152
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_point_evaluation_uncachable

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8758 | 0.2084 | 1.00e-03 | [0.2056, 0.2111] |
| `erigon` | 231 | 0.8947 | 0.1942 | 1.00e-03 | [0.1867, 0.2014] |
| `ethrex` | 1562 | 0.8149 | 0.2382 | 1.00e-03 | [0.2325, 0.244] |
| `geth` | 4092 | 0.8406 | 0.1922 | 1.00e-03 | [0.1895, 0.195] |
| `nethermind` | 1155 | 0.8628 | 0.234 | 1.00e-03 | [0.2277, 0.2399] |
| `reth` | 99 | 0.8355 | 0.1966 | 1.00e-03 | [0.178, 0.2139] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.876
Model:                  NNLS                    Adj. R-squared:          0.876
No. Observations:       3652                              RMSE:          92.88
Df Residuals:           3650                               MAE:          78.57
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    219.7217      5.7999       0.001    208.5187    230.9829
       opcount      0.2084      0.0014       0.001      0.2056      0.2111
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.895
Model:                  NNLS                    Adj. R-squared:          0.894
No. Observations:       231                               RMSE:          78.86
Df Residuals:           229                                MAE:          68.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     68.8348     15.9512       0.001     40.1171    100.2995
       opcount      0.1942      0.0038       0.001      0.1867      0.2014
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.815
Model:                  NNLS                    Adj. R-squared:          0.815
No. Observations:       1562                              RMSE:         134.41
Df Residuals:           1560                               MAE:         116.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    283.8455     12.4008       0.001    258.9834    306.7242
       opcount      0.2382      0.0029       0.001      0.2325      0.2440
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.841
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       4092                              RMSE:          99.10
Df Residuals:           4090                               MAE:          83.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    194.9613      5.7962       0.001    183.3327    206.3370
       opcount      0.1922      0.0014       0.001      0.1895      0.1950
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.863
Model:                  NNLS                    Adj. R-squared:          0.863
No. Observations:       1155                              RMSE:         110.45
Df Residuals:           1153                               MAE:          85.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    149.7763     11.4816       0.001    128.3096    172.7554
       opcount      0.2340      0.0032       0.001      0.2277      0.2399
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.835
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       99                                RMSE:         103.29
Df Residuals:           97                                 MAE:          86.35
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    225.5452     39.6374       0.001    152.3949    305.7742
       opcount      0.1966      0.0094       0.001      0.1780      0.2139
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## P256VERIFY

### test_p256verify

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.8684 | 0.008331 | 1.00e-03 | [0.008235, 0.008442] |
| `erigon` | 231 | 0.8362 | 0.01405 | 1.00e-03 | [0.01343, 0.01465] |
| `ethrex` | 1562 | 0.8106 | 0.03803 | 1.00e-03 | [0.03709, 0.03901] |
| `geth` | 4092 | 0.8268 | 0.01169 | 1.00e-03 | [0.01151, 0.01187] |
| `nethermind` | 1155 | 0.8816 | 0.008589 | 1.00e-03 | [0.008375, 0.008796] |
| `reth` | 99 | 0.8427 | 0.008424 | 1.00e-03 | [0.007627, 0.009186] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.868
Model:                  NNLS                    Adj. R-squared:          0.868
No. Observations:       3652                              RMSE:          29.21
Df Residuals:           3650                               MAE:          24.49
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     77.0097      1.7077       0.001     73.4044     80.1343
       opcount      0.0083      0.0001       0.001      0.0082      0.0084
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.836
Model:                  NNLS                    Adj. R-squared:          0.836
No. Observations:       231                               RMSE:          55.98
Df Residuals:           229                                MAE:          39.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     49.3381      9.8136       0.001     31.0747     68.6145
       opcount      0.0140      0.0003       0.001      0.0134      0.0146
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.811
Model:                  NNLS                    Adj. R-squared:          0.810
No. Observations:       1562                              RMSE:         165.56
Df Residuals:           1560                               MAE:         142.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    336.2904     16.1013       0.001    305.4215    366.6415
       opcount      0.0380      0.0005       0.001      0.0371      0.0390
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.827
Model:                  NNLS                    Adj. R-squared:          0.827
No. Observations:       4092                              RMSE:          48.18
Df Residuals:           4090                               MAE:          40.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     95.6695      2.8780       0.001     90.0300    101.2115
       opcount      0.0117      0.0001       0.001      0.0115      0.0119
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.882
Model:                  NNLS                    Adj. R-squared:          0.881
No. Observations:       1155                              RMSE:          28.35
Df Residuals:           1153                               MAE:          23.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     59.2739      3.1631       0.001     53.3594     65.6267
       opcount      0.0086      0.0001       0.001      0.0084      0.0088
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.843
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       99                                RMSE:          32.78
Df Residuals:           97                                 MAE:          27.80
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     63.0968     12.8506       0.001     38.1110     89.1053
       opcount      0.0084      0.0004       0.001      0.0076      0.0092
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_p256verify_uncachable

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 3652 | 0.9095 | 0.0109 | 1.00e-03 | [0.01079, 0.01101] |
| `erigon` | 231 | 0.8114 | 0.01411 | 1.00e-03 | [0.0131, 0.01497] |
| `ethrex` | 1562 | 0.8105 | 0.03814 | 1.00e-03 | [0.03715, 0.03908] |
| `geth` | 4092 | 0.8253 | 0.01183 | 1.00e-03 | [0.01166, 0.01201] |
| `nethermind` | 1155 | 0.8835 | 0.008746 | 1.00e-03 | [0.008526, 0.008972] |
| `reth` | 99 | 0.8658 | 0.008419 | 1.00e-03 | [0.007681, 0.00912] |

<details><summary>besu — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.910
Model:                  NNLS                    Adj. R-squared:          0.910
No. Observations:       3652                              RMSE:          30.74
Df Residuals:           3650                               MAE:          26.30
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     25.3016      1.7245       0.001     21.7949     28.6537
       opcount      0.0109      0.0001       0.001      0.0108      0.0110
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>erigon — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.811
Model:                  NNLS                    Adj. R-squared:          0.811
No. Observations:       231                               RMSE:          60.84
Df Residuals:           229                                MAE:          39.53
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     49.7319     14.6554       0.001     25.3822     81.0316
       opcount      0.0141      0.0005       0.001      0.0131      0.0150
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>ethrex — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.810
Model:                  NNLS                    Adj. R-squared:          0.810
No. Observations:       1562                              RMSE:         164.99
Df Residuals:           1560                               MAE:         142.15
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    332.7567     15.8105       0.001    302.9333    362.8966
       opcount      0.0381      0.0005       0.001      0.0372      0.0391
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>geth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.825
Model:                  NNLS                    Adj. R-squared:          0.825
No. Observations:       4092                              RMSE:          48.70
Df Residuals:           4090                               MAE:          40.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.7969      2.7667       0.001     87.4152     97.9833
       opcount      0.0118      0.0001       0.001      0.0117      0.0120
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>nethermind — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.884
Model:                  NNLS                    Adj. R-squared:          0.883
No. Observations:       1155                              RMSE:          28.40
Df Residuals:           1153                               MAE:          23.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     57.0388      3.2838       0.001     50.2955     63.5019
       opcount      0.0087      0.0001       0.001      0.0085      0.0090
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details><summary>reth — NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.866
Model:                  NNLS                    Adj. R-squared:          0.864
No. Observations:       99                                RMSE:          29.65
Df Residuals:           97                                 MAE:          24.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     69.2118     11.7461       0.001     47.1850     91.9381
       opcount      0.0084      0.0004       0.001      0.0077      0.0091
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>
