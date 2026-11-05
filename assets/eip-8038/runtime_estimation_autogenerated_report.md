# Runtime estimation report

> This is a snapshot of the latest archived evm-gasfit run. All numerical tables and regression summaries are retained. Plots are omitted. Runtime estimates do not depend on the gas anchor. See the [supporting report](gas-cost-report.md) for the source details and gas estimates at 75 Mgas/s.

This report fits `test_runtime_ms` against `opcount` using nonnegative least squares (NNLS). Each row covers one target opcode, test, model configuration, and client.

## Contents

- [SLOAD](#sload)
- [SSTORE](#sstore)
- [BALANCE](#balance)
- [CALL](#call)
- [CALLCODE](#callcode)
- [DELEGATECALL](#delegatecall)
- [EXTCODEHASH](#extcodehash)
- [EXTCODESIZE](#extcodesize)
- [STATICCALL](#staticcall)
- [EXTCODECOPY](#extcodecopy)

## SLOAD

### test_sload_bloated: combo `False`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.974 | 0.01016 | 1.00e-03 | [0.009943, 0.01038] |
| `erigon` | 231 | 0.9914 | 0.003528 | 1.00e-03 | [0.003484, 0.003576] |
| `ethrex` | 165 | 0.8544 | 0.001865 | 1.00e-03 | [0.001758, 0.001981] |
| `geth` | 286 | 0.9723 | 0.0217 | 1.00e-03 | [0.02126, 0.02217] |
| `nethermind` | 209 | 0.8464 | 0.002533 | 1.00e-03 | [0.002382, 0.002685] |
| `reth` | 209 | 0.9803 | 0.005326 | 1.00e-03 | [0.005223, 0.005439] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       220                               RMSE:          48.86
Df Residuals:           218                                MAE:          39.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    192.8576     10.1407       0.001    172.2782    212.6350
       opcount      0.0102      0.0001       0.001      0.0099      0.0104
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.991
Model:                  NNLS                    Adj. R-squared:          0.991
No. Observations:       231                               RMSE:           9.68
Df Residuals:           229                                MAE:           6.62
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.7396      1.9378       0.001      5.8426     13.2907
       opcount      0.0035      0.0000       0.001      0.0035      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.854
Model:                  NNLS                    Adj. R-squared:          0.853
No. Observations:       165                               RMSE:          22.67
Df Residuals:           163                                MAE:          18.39
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    160.5968      5.9996       0.001    149.1483    171.5477
       opcount      0.0019      0.0001       0.001      0.0018      0.0020
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.972
Model:                  NNLS                    Adj. R-squared:          0.972
No. Observations:       286                               RMSE:         107.91
Df Residuals:           284                                MAE:          87.91
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    569.6012     20.6284       0.001    529.1801    608.1148
       opcount      0.0217      0.0002       0.001      0.0213      0.0222
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.846
Model:                  NNLS                    Adj. R-squared:          0.846
No. Observations:       209                               RMSE:          31.77
Df Residuals:           207                                MAE:          26.20
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     68.2940      6.5472       0.001     55.8875     81.3843
       opcount      0.0025      0.0001       0.001      0.0024      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       209                               RMSE:          22.24
Df Residuals:           207                                MAE:          17.35
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    121.0869      4.6623       0.001    111.8756    130.3419
       opcount      0.0053      0.0001       0.001      0.0052      0.0054
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_sload_bloated: combo `True`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9791 | 0.0163 | 1.00e-03 | [0.01596, 0.01662] |
| `erigon` | 231 | 0.9952 | 0.00382 | 1.00e-03 | [0.003785, 0.003852] |
| `ethrex` | 165 | 0.9711 | 0.007433 | 1.00e-03 | [0.007241, 0.007642] |
| `geth` | 286 | 0.9736 | 0.0219 | 1.00e-03 | [0.02142, 0.02236] |
| `nethermind` | 209 | 0.9631 | 0.007617 | 1.00e-03 | [0.007413, 0.007819] |
| `reth` | 209 | 0.9808 | 0.005397 | 1.00e-03 | [0.005299, 0.005491] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.979
Model:                  NNLS                    Adj. R-squared:          0.979
No. Observations:       220                               RMSE:          70.04
Df Residuals:           218                                MAE:          56.80
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    527.2150     15.1789       0.001    498.1693    560.4275
       opcount      0.0163      0.0002       0.001      0.0160      0.0166
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.995
Model:                  NNLS                    Adj. R-squared:          0.995
No. Observations:       231                               RMSE:           7.80
Df Residuals:           229                                MAE:           5.61
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.4975      1.5903       0.001     12.4585     18.8637
       opcount      0.0038      0.0000       0.001      0.0038      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       165                               RMSE:          37.73
Df Residuals:           163                                MAE:          31.64
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    188.9535      9.7678       0.001    169.8363    207.6871
       opcount      0.0074      0.0001       0.001      0.0072      0.0076
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       286                               RMSE:         106.08
Df Residuals:           284                                MAE:          85.41
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    537.1295     20.9914       0.001    498.0687    577.1506
       opcount      0.0219      0.0002       0.001      0.0214      0.0224
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.963
Model:                  NNLS                    Adj. R-squared:          0.963
No. Observations:       209                               RMSE:          43.87
Df Residuals:           207                                MAE:          33.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    117.7130      9.1662       0.001    100.3695    135.3325
       opcount      0.0076      0.0001       0.001      0.0074      0.0078
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       209                               RMSE:          22.23
Df Residuals:           207                                MAE:          16.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    130.4682      4.5499       0.001    121.8800    139.2844
       opcount      0.0054      0.0000       0.001      0.0053      0.0055
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_sload_same_key_benchmark

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.2923 | 0.0002257 | 1.00e-03 | [0.00019, 0.0002645] |
| `erigon` | 462 | 0.1139 | 1.248e-05 | 1.00e-03 | [9.097e-06, 1.563e-05] |
| `ethrex` | 330 | 0.828 | 3.723e-05 | 1.00e-03 | [3.526e-05, 3.904e-05] |
| `geth` | 572 | 0.9063 | 6.716e-05 | 1.00e-03 | [6.547e-05, 6.892e-05] |
| `nethermind` | 418 | 0.4998 | 8.555e-05 | 1.00e-03 | [7.735e-05, 9.385e-05] |
| `reth` | 418 | 0.8022 | 1.15e-05 | 1.00e-03 | [1.096e-05, 1.203e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.292
Model:                  NNLS                    Adj. R-squared:          0.291
No. Observations:       440                               RMSE:         221.90
Df Residuals:           438                                MAE:         209.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    199.8512     32.6570       0.001    130.6942    263.3670
       opcount      0.0002      0.0000       0.001      0.0002      0.0003
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.114
Model:                  NNLS                    Adj. R-squared:          0.112
No. Observations:       462                               RMSE:          21.99
Df Residuals:           460                                MAE:          20.80
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     17.4879      2.9091       0.001     11.9885     23.5220
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.828
Model:                  NNLS                    Adj. R-squared:          0.827
No. Observations:       330                               RMSE:          10.72
Df Residuals:           328                                MAE:           8.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.1986      1.7645       0.001     13.0230     19.7824
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.906
Model:                  NNLS                    Adj. R-squared:          0.906
No. Observations:       572                               RMSE:          13.65
Df Residuals:           570                                MAE:          10.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.9686      1.7188       0.001     23.3663     30.3539
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.500
Model:                  NNLS                    Adj. R-squared:          0.499
No. Observations:       418                               RMSE:          54.07
Df Residuals:           416                                MAE:          41.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     40.2594      7.4111       0.001     26.2271     55.1666
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.802
Model:                  NNLS                    Adj. R-squared:          0.802
No. Observations:       418                               RMSE:           3.61
Df Residuals:           416                                MAE:           2.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.0896      0.5299       0.001      7.0802      9.0886
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## SSTORE

### test_sstore_bloated: combo `False`: `presets[cold_storage_sstore_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9681 | 0.01902 | 1.00e-03 | [0.01854, 0.01951] |
| `erigon` | 231 | 0.992 | 0.003485 | 1.00e-03 | [0.003436, 0.003523] |
| `ethrex` | 165 | 0.9256 | 0.001889 | 1.00e-03 | [0.001806, 0.001973] |
| `geth` | 286 | 0.9699 | 0.0215 | 1.00e-03 | [0.02103, 0.02195] |
| `nethermind` | 209 | 0.8542 | 0.002504 | 1.00e-03 | [0.002352, 0.002653] |
| `reth` | 209 | 0.9819 | 0.005329 | 1.00e-03 | [0.005226, 0.005423] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.968
Model:                  NNLS                    Adj. R-squared:          0.968
No. Observations:       220                               RMSE:         102.17
Df Residuals:           218                                MAE:          87.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    491.0841     22.1858       0.001    445.9863    534.6586
       opcount      0.0190      0.0002       0.001      0.0185      0.0195
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.992
Model:                  NNLS                    Adj. R-squared:          0.992
No. Observations:       231                               RMSE:           9.25
Df Residuals:           229                                MAE:           6.59
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.5965      2.0136       0.001      5.9969     13.8952
       opcount      0.0035      0.0000       0.001      0.0034      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.926
Model:                  NNLS                    Adj. R-squared:          0.925
No. Observations:       165                               RMSE:          15.84
Df Residuals:           163                                MAE:          12.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    154.8243      3.6977       0.001    147.3949    162.1697
       opcount      0.0019      0.0000       0.001      0.0018      0.0020
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.970
No. Observations:       286                               RMSE:         112.10
Df Residuals:           284                                MAE:          92.32
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    586.4551     21.5896       0.001    546.0509    630.8404
       opcount      0.0215      0.0002       0.001      0.0210      0.0220
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.854
Model:                  NNLS                    Adj. R-squared:          0.853
No. Observations:       209                               RMSE:          30.61
Df Residuals:           207                                MAE:          24.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     74.1325      6.4905       0.001     62.2391     86.4837
       opcount      0.0025      0.0001       0.001      0.0024      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.982
Model:                  NNLS                    Adj. R-squared:          0.982
No. Observations:       209                               RMSE:          21.42
Df Residuals:           207                                MAE:          16.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    119.2851      4.4968       0.001    110.4970    128.6628
       opcount      0.0053      0.0000       0.001      0.0052      0.0054
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_sstore_bloated: combo `True`: `presets[cold_storage_sstore_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9755 | 0.0244 | 1.00e-03 | [0.02387, 0.02496] |
| `erigon` | 231 | 0.9975 | 0.003851 | 1.00e-03 | [0.003827, 0.003873] |
| `ethrex` | 165 | 0.9858 | 0.007478 | 1.00e-03 | [0.007341, 0.007626] |
| `geth` | 286 | 0.9763 | 0.02199 | 1.00e-03 | [0.02149, 0.02239] |
| `nethermind` | 209 | 0.956 | 0.007784 | 1.00e-03 | [0.007534, 0.008017] |
| `reth` | 209 | 0.9806 | 0.005472 | 1.00e-03 | [0.005369, 0.005572] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.976
Model:                  NNLS                    Adj. R-squared:          0.975
No. Observations:       220                               RMSE:         114.36
Df Residuals:           218                                MAE:          95.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    679.7662     25.1594       0.001    628.1006    728.1234
       opcount      0.0244      0.0003       0.001      0.0239      0.0250
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.998
Model:                  NNLS                    Adj. R-squared:          0.998
No. Observations:       231                               RMSE:           5.69
Df Residuals:           229                                MAE:           4.35
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.8651      1.1446       0.001      7.6560     12.1860
       opcount      0.0039      0.0000       0.001      0.0038      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.986
Model:                  NNLS                    Adj. R-squared:          0.986
No. Observations:       165                               RMSE:          26.53
Df Residuals:           163                                MAE:          22.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    175.2746      6.4827       0.001    161.6532    187.6948
       opcount      0.0075      0.0001       0.001      0.0073      0.0076
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.976
Model:                  NNLS                    Adj. R-squared:          0.976
No. Observations:       286                               RMSE:         101.48
Df Residuals:           284                                MAE:          81.34
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    524.8916     19.5615       0.001    490.6055    566.4099
       opcount      0.0220      0.0002       0.001      0.0215      0.0224
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.956
Model:                  NNLS                    Adj. R-squared:          0.956
No. Observations:       209                               RMSE:          49.39
Df Residuals:           207                                MAE:          36.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    100.5868      9.5979       0.001     81.9654    120.0470
       opcount      0.0078      0.0001       0.001      0.0075      0.0080
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       209                               RMSE:          22.78
Df Residuals:           207                                MAE:          17.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    126.4415      4.5064       0.001    117.9899    135.3254
       opcount      0.0055      0.0001       0.001      0.0054      0.0056
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_sstore_bloated: combo `False`: `presets[cold_storage_sstore_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9034 | 0.1107 | 1.00e-03 | [0.1056, 0.1154] |
| `erigon` | 231 | 0.997 | 0.1674 | 1.00e-03 | [0.1661, 0.1686] |
| `ethrex` | 165 | 0 | 0 | 1.00e+00 | [0, 0] |
| `geth` | 286 | 0.9193 | 0.1529 | 1.00e-03 | [0.1478, 0.158] |
| `nethermind` | 209 | 0.6348 | 0.09007 | 1.00e-03 | [0.07989, 0.09886] |
| `reth` | 209 | 0.9832 | 0.1209 | 1.00e-03 | [0.1187, 0.123] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.903
Model:                  NNLS                    Adj. R-squared:          0.903
No. Observations:       220                               RMSE:          23.38
Df Residuals:           218                                MAE:          17.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.4186      5.3086       0.001    122.4416    143.4076
       opcount      0.1107      0.0025       0.001      0.1056      0.1154
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.997
Model:                  NNLS                    Adj. R-squared:          0.997
No. Observations:       231                               RMSE:           5.90
Df Residuals:           229                                MAE:           4.91
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    105.5243      1.3796       0.001    102.9042    108.4007
       opcount      0.1674      0.0006       0.001      0.1661      0.1686
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.000
Model:                  NNLS                    Adj. R-squared:         -0.006
No. Observations:       165                               RMSE:         501.05
Df Residuals:           163                                MAE:         484.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    946.7481     38.8619       0.001    872.3785   1020.6378
       opcount      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.919
Model:                  NNLS                    Adj. R-squared:          0.919
No. Observations:       286                               RMSE:          29.27
Df Residuals:           284                                MAE:          21.86
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     68.9117      5.2748       0.001     58.3914     79.8553
       opcount      0.1529      0.0026       0.001      0.1478      0.1580
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.635
Model:                  NNLS                    Adj. R-squared:          0.633
No. Observations:       209                               RMSE:          44.12
Df Residuals:           207                                MAE:          36.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     67.0142      8.8793       0.001     50.6918     85.5246
       opcount      0.0901      0.0048       0.001      0.0799      0.0989
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.983
Model:                  NNLS                    Adj. R-squared:          0.983
No. Observations:       209                               RMSE:          10.20
Df Residuals:           207                                MAE:           7.63
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     60.7876      1.9911       0.001     56.8936     64.6931
       opcount      0.1209      0.0011       0.001      0.1187      0.1230
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_sstore_bloated: combo `True`: `presets[cold_storage_sstore_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9601 | 0.08925 | 1.00e-03 | [0.08677, 0.09162] |
| `erigon` | 231 | 0.9989 | 0.1104 | 1.00e-03 | [0.1099, 0.1109] |
| `ethrex` | 165 | 0.7008 | 0.02241 | 1.00e-03 | [0.02031, 0.02417] |
| `geth` | 286 | 0.9887 | 0.1102 | 1.00e-03 | [0.1089, 0.1115] |
| `nethermind` | 209 | 0.6625 | 0.07888 | 1.00e-03 | [0.07023, 0.08645] |
| `reth` | 209 | 0.9391 | 0.08332 | 1.00e-03 | [0.08059, 0.0863] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       220                               RMSE:          94.70
Df Residuals:           218                                MAE:          77.63
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    385.6765     18.8714       0.001    348.4412    423.1744
       opcount      0.0893      0.0012       0.001      0.0868      0.0916
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.999
Model:                  NNLS                    Adj. R-squared:          0.999
No. Observations:       231                               RMSE:          18.71
Df Residuals:           229                                MAE:          13.61
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    398.4491      4.1186       0.001    390.5434    406.7400
       opcount      0.1104      0.0002       0.001      0.1099      0.1109
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.701
Model:                  NNLS                    Adj. R-squared:          0.699
No. Observations:       165                               RMSE:          76.19
Df Residuals:           163                                MAE:          60.74
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    671.4231     19.3066       0.001    636.9461    711.8754
       opcount      0.0224      0.0010       0.001      0.0203      0.0242
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.989
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       286                               RMSE:          61.26
Df Residuals:           284                                MAE:          46.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    373.5914     10.3771       0.001    353.2976    393.0977
       opcount      0.1102      0.0007       0.001      0.1089      0.1115
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.663
Model:                  NNLS                    Adj. R-squared:          0.661
No. Observations:       209                               RMSE:         292.88
Df Residuals:           207                                MAE:         217.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    246.6617     60.6940       0.001    130.9695    367.1790
       opcount      0.0789      0.0040       0.001      0.0702      0.0865
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.939
Model:                  NNLS                    Adj. R-squared:          0.939
No. Observations:       209                               RMSE:         110.40
Df Residuals:           207                                MAE:          90.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    273.2022     20.6356       0.001    233.5135    312.4730
       opcount      0.0833      0.0015       0.001      0.0806      0.0863
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## BALANCE

### test_ext_account_query_warm: combo `BALANCE`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.857 | 0.0001281 | 1.00e-03 | [0.0001212, 0.0001347] |
| `erigon` | 231 | 0.7315 | 1.908e-05 | 1.00e-03 | [1.761e-05, 2.054e-05] |
| `ethrex` | 165 | 0.7873 | 2.257e-05 | 1.00e-03 | [2.072e-05, 2.446e-05] |
| `geth` | 286 | 0.8207 | 4.097e-05 | 1.00e-03 | [3.874e-05, 4.347e-05] |
| `nethermind` | 209 | 0.7331 | 7.612e-05 | 1.00e-03 | [6.975e-05, 8.231e-05] |
| `reth` | 209 | 0.8524 | 1.731e-05 | 1.00e-03 | [1.636e-05, 1.831e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.857
Model:                  NNLS                    Adj. R-squared:          0.856
No. Observations:       220                               RMSE:          30.60
Df Residuals:           218                                MAE:          25.11
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    194.3702      6.6539       0.001    181.7343    207.9987
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.731
Model:                  NNLS                    Adj. R-squared:          0.730
No. Observations:       231                               RMSE:           6.76
Df Residuals:           229                                MAE:           5.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     18.9802      1.3559       0.001     16.3468     21.6636
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.787
Model:                  NNLS                    Adj. R-squared:          0.786
No. Observations:       165                               RMSE:           6.86
Df Residuals:           163                                MAE:           5.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.6343      1.6277       0.001      6.4918     12.9782
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.821
Model:                  NNLS                    Adj. R-squared:          0.820
No. Observations:       286                               RMSE:          11.20
Df Residuals:           284                                MAE:           8.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     21.5452      2.0900       0.001     16.9039     25.5046
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.733
Model:                  NNLS                    Adj. R-squared:          0.732
No. Observations:       209                               RMSE:          26.87
Df Residuals:           207                                MAE:          18.57
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     23.9121      5.6341       0.001     13.8334     35.3068
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.852
Model:                  NNLS                    Adj. R-squared:          0.852
No. Observations:       209                               RMSE:           4.21
Df Residuals:           207                                MAE:           3.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     10.9523      0.9463       0.001      9.1637     12.8478
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `BALANCE_AccountMode.EXISTING_EOA`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9722 | 0.01584 | 1.00e-03 | [0.0156, 0.01608] |
| `erigon` | 462 | 0.9899 | 0.003897 | 1.00e-03 | [0.003862, 0.003933] |
| `ethrex` | 330 | 0.4885 | 0.01817 | 1.00e-03 | [0.01627, 0.01948] |
| `geth` | 572 | 0.9773 | 0.0209 | 1.00e-03 | [0.02062, 0.02114] |
| `nethermind` | 418 | 0.8342 | 0.00349 | 1.00e-03 | [0.003338, 0.003656] |
| `reth` | 418 | 0.9679 | 0.004819 | 1.00e-03 | [0.004737, 0.004906] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.972
Model:                  NNLS                    Adj. R-squared:          0.972
No. Observations:       440                               RMSE:          55.29
Df Residuals:           438                                MAE:          45.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    301.6649      7.9685       0.001    285.9325    316.6907
       opcount      0.0158      0.0001       0.001      0.0156      0.0161
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       462                               RMSE:           8.13
Df Residuals:           460                                MAE:           6.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.7557      1.0802       0.001     25.6143     29.8476
       opcount      0.0039      0.0000       0.001      0.0039      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.488
Model:                  NNLS                    Adj. R-squared:          0.487
No. Observations:       330                               RMSE:         384.01
Df Residuals:           328                                MAE:         319.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     51.2810     48.3785       0.214      0.0000    160.4338
       opcount      0.0182      0.0009       0.001      0.0163      0.0195
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       572                               RMSE:          65.77
Df Residuals:           570                                MAE:          52.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    287.4098      8.5475       0.001    271.2405    304.4366
       opcount      0.0209      0.0001       0.001      0.0206      0.0211
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.834
Model:                  NNLS                    Adj. R-squared:          0.834
No. Observations:       418                               RMSE:          32.12
Df Residuals:           416                                MAE:          23.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    129.5521      4.5798       0.001    120.3596    138.5449
       opcount      0.0035      0.0001       0.001      0.0033      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.968
Model:                  NNLS                    Adj. R-squared:          0.968
No. Observations:       418                               RMSE:          18.13
Df Residuals:           416                                MAE:          14.02
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    104.8034      2.6393       0.001     99.5781    109.6692
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `BALANCE_AccountMode.NON_EXISTING_ACCOUNT`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9725 | 0.01521 | 1.00e-03 | [0.01496, 0.01544] |
| `erigon` | 462 | 0.9852 | 0.003516 | 1.00e-03 | [0.003469, 0.003559] |
| `ethrex` | 330 | 0.9406 | 0.00251 | 1.00e-03 | [0.002438, 0.002573] |
| `geth` | 572 | 0.9733 | 0.01991 | 1.00e-03 | [0.01966, 0.02017] |
| `nethermind` | 418 | 0.7999 | 0.003076 | 1.00e-03 | [0.002936, 0.003237] |
| `reth` | 418 | 0.97 | 0.004848 | 1.00e-03 | [0.004774, 0.004932] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.972
Model:                  NNLS                    Adj. R-squared:          0.972
No. Observations:       440                               RMSE:          52.83
Df Residuals:           438                                MAE:          43.16
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    145.5019      7.5384       0.001    131.1175    160.2500
       opcount      0.0152      0.0001       0.001      0.0150      0.0154
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.985
Model:                  NNLS                    Adj. R-squared:          0.985
No. Observations:       462                               RMSE:           8.88
Df Residuals:           460                                MAE:           6.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     21.0033      1.3660       0.001     18.4991     23.7702
       opcount      0.0035      0.0000       0.001      0.0035      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.941
Model:                  NNLS                    Adj. R-squared:          0.940
No. Observations:       330                               RMSE:          13.02
Df Residuals:           328                                MAE:          10.54
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.5781      2.0795       0.001     18.5187     26.7410
       opcount      0.0025      0.0000       0.001      0.0024      0.0026
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       572                               RMSE:          68.14
Df Residuals:           570                                MAE:          54.54
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    301.2828      8.4787       0.001    284.5874    318.5849
       opcount      0.0199      0.0001       0.001      0.0197      0.0202
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.800
Model:                  NNLS                    Adj. R-squared:          0.799
No. Observations:       418                               RMSE:          31.77
Df Residuals:           416                                MAE:          24.11
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     77.6395      4.6766       0.001     68.0605     86.2529
       opcount      0.0031      0.0001       0.001      0.0029      0.0032
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.970
No. Observations:       418                               RMSE:          17.62
Df Residuals:           416                                MAE:          13.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     99.1659      2.5864       0.001     94.2275    104.1695
       opcount      0.0048      0.0000       0.001      0.0048      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `BALANCE_AccountMode.EXISTING_CONTRACT_DIFF_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8545 | 0.02292 | 1.00e-03 | [0.02199, 0.02383] |
| `erigon` | 462 | 0.9574 | 0.004269 | 1.00e-03 | [0.004194, 0.004348] |
| `ethrex` | 330 | 0.6499 | 0.01027 | 1.00e-03 | [0.009433, 0.01111] |
| `geth` | 572 | 0.896 | 0.01737 | 1.00e-03 | [0.01675, 0.01799] |
| `nethermind` | 418 | 0.6028 | 0.003018 | 1.00e-03 | [0.002779, 0.003275] |
| `reth` | 418 | 0.9258 | 0.005009 | 1.00e-03 | [0.004869, 0.005149] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.855
Model:                  NNLS                    Adj. R-squared:          0.854
No. Observations:       440                               RMSE:         192.25
Df Residuals:           438                                MAE:         158.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    760.1962     29.7252       0.001    704.5879    818.8375
       opcount      0.0229      0.0005       0.001      0.0220      0.0238
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.957
Model:                  NNLS                    Adj. R-squared:          0.957
No. Observations:       462                               RMSE:          18.31
Df Residuals:           460                                MAE:          13.32
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    158.4946      2.7501       0.001    153.2169    163.5302
       opcount      0.0043      0.0000       0.001      0.0042      0.0043
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.650
Model:                  NNLS                    Adj. R-squared:          0.649
No. Observations:       330                               RMSE:         153.24
Df Residuals:           328                                MAE:         136.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    234.8451     23.5866       0.001    186.7050    281.0338
       opcount      0.0103      0.0004       0.001      0.0094      0.0111
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.896
Model:                  NNLS                    Adj. R-squared:          0.896
No. Observations:       572                               RMSE:         120.30
Df Residuals:           570                                MAE:          91.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    383.8543     17.7189       0.001    348.2970    420.9969
       opcount      0.0174      0.0003       0.001      0.0167      0.0180
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.603
Model:                  NNLS                    Adj. R-squared:          0.602
No. Observations:       418                               RMSE:          49.80
Df Residuals:           416                                MAE:          36.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    128.2560      6.9035       0.001    114.3340    141.7153
       opcount      0.0030      0.0001       0.001      0.0028      0.0033
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.926
Model:                  NNLS                    Adj. R-squared:          0.926
No. Observations:       418                               RMSE:          28.82
Df Residuals:           416                                MAE:          22.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    109.7604      4.5769       0.001    101.1498    119.7067
       opcount      0.0050      0.0001       0.001      0.0049      0.0051
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `BALANCE_AccountMode.EXISTING_CONTRACT_MINIMAL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9608 | 0.01242 | 1.00e-03 | [0.01219, 0.01265] |
| `erigon` | 462 | 0.9085 | 0.003537 | 1.00e-03 | [0.003433, 0.003641] |
| `ethrex` | 330 | 0.7885 | 0.002601 | 1.00e-03 | [0.002442, 0.002733] |
| `geth` | 572 | 0.9723 | 0.01999 | 1.00e-03 | [0.01971, 0.02027] |
| `nethermind` | 418 | 0.5749 | 0.002749 | 1.00e-03 | [0.002504, 0.002988] |
| `reth` | 418 | 0.9647 | 0.004652 | 1.00e-03 | [0.004568, 0.004734] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.961
Model:                  NNLS                    Adj. R-squared:          0.961
No. Observations:       440                               RMSE:          51.01
Df Residuals:           438                                MAE:          41.32
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    269.1706      7.0031       0.001    255.3677    283.0551
       opcount      0.0124      0.0001       0.001      0.0122      0.0126
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.908
Model:                  NNLS                    Adj. R-squared:          0.908
No. Observations:       462                               RMSE:          22.83
Df Residuals:           460                                MAE:          17.67
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    159.4972      3.5283       0.001    152.7364    166.8311
       opcount      0.0035      0.0001       0.001      0.0034      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.789
Model:                  NNLS                    Adj. R-squared:          0.788
No. Observations:       330                               RMSE:          27.39
Df Residuals:           328                                MAE:          21.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    106.8853      5.3561       0.001     97.5156    118.4386
       opcount      0.0026      0.0001       0.001      0.0024      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.972
Model:                  NNLS                    Adj. R-squared:          0.972
No. Observations:       572                               RMSE:          68.64
Df Residuals:           570                                MAE:          55.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    267.4351      8.6312       0.001    251.3250    284.8305
       opcount      0.0200      0.0001       0.001      0.0197      0.0203
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.575
Model:                  NNLS                    Adj. R-squared:          0.574
No. Observations:       418                               RMSE:          48.07
Df Residuals:           416                                MAE:          35.25
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    139.7422      7.0208       0.001    126.3551    153.9011
       opcount      0.0027      0.0001       0.001      0.0025      0.0030
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.965
Model:                  NNLS                    Adj. R-squared:          0.965
No. Observations:       418                               RMSE:          18.09
Df Residuals:           416                                MAE:          14.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     91.8047      2.6216       0.001     86.7758     97.1325
       opcount      0.0047      0.0000       0.001      0.0046      0.0047
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `BALANCE_AccountMode.EXISTING_CONTRACT_SAME_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9625 | 0.01271 | 1.00e-03 | [0.01245, 0.01296] |
| `erigon` | 462 | 0.8286 | 0.003903 | 1.00e-03 | [0.003729, 0.004072] |
| `ethrex` | 330 | 0.7831 | 0.002676 | 1.00e-03 | [0.002528, 0.002827] |
| `geth` | 572 | 0.9732 | 0.01968 | 1.00e-03 | [0.01942, 0.01996] |
| `nethermind` | 418 | 0.5991 | 0.00291 | 1.00e-03 | [0.002653, 0.003163] |
| `reth` | 418 | 0.9634 | 0.004633 | 1.00e-03 | [0.004546, 0.004737] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.963
Model:                  NNLS                    Adj. R-squared:          0.962
No. Observations:       440                               RMSE:          50.98
Df Residuals:           438                                MAE:          41.17
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    252.2517      7.5654       0.001    237.9532    267.6941
       opcount      0.0127      0.0001       0.001      0.0124      0.0130
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.829
Model:                  NNLS                    Adj. R-squared:          0.828
No. Observations:       462                               RMSE:          36.08
Df Residuals:           460                                MAE:          30.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    107.1801      5.6912       0.001     96.2873    118.2866
       opcount      0.0039      0.0001       0.001      0.0037      0.0041
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.783
Model:                  NNLS                    Adj. R-squared:          0.782
No. Observations:       330                               RMSE:          28.63
Df Residuals:           328                                MAE:          22.95
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    104.2464      5.2339       0.001     93.8205    114.2018
       opcount      0.0027      0.0001       0.001      0.0025      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       572                               RMSE:          66.35
Df Residuals:           570                                MAE:          51.33
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    283.3158      8.4580       0.001    266.5982    299.7972
       opcount      0.0197      0.0001       0.001      0.0194      0.0200
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.599
Model:                  NNLS                    Adj. R-squared:          0.598
No. Observations:       418                               RMSE:          48.40
Df Residuals:           416                                MAE:          35.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.4717      7.0582       0.001    119.2074    146.3470
       opcount      0.0029      0.0001       0.001      0.0027      0.0032
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.963
Model:                  NNLS                    Adj. R-squared:          0.963
No. Observations:       418                               RMSE:          18.36
Df Residuals:           416                                MAE:          14.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     95.1428      2.8382       0.001     89.3795    100.6948
       opcount      0.0046      0.0000       0.001      0.0045      0.0047
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## CALL

### test_ext_account_query_warm: combo `CALL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9267 | 0.0007088 | 1.00e-03 | [0.0006793, 0.0007359] |
| `erigon` | 231 | 0.7724 | 9.583e-05 | 1.00e-03 | [8.934e-05, 0.0001025] |
| `ethrex` | 165 | 0.9212 | 0.0001313 | 1.00e-03 | [0.0001258, 0.0001372] |
| `geth` | 286 | 0.922 | 0.0001857 | 1.00e-03 | [0.0001795, 0.000192] |
| `nethermind` | 209 | 0.5385 | 0.0002259 | 1.00e-03 | [0.0001996, 0.000256] |
| `reth` | 209 | 0.9549 | 7.936e-05 | 1.00e-03 | [7.695e-05, 8.169e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.927
Model:                  NNLS                    Adj. R-squared:          0.926
No. Observations:       220                               RMSE:         100.76
Df Residuals:           218                                MAE:          77.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    603.1789     22.3011       0.001    561.9603    648.5309
       opcount      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.772
Model:                  NNLS                    Adj. R-squared:          0.771
No. Observations:       231                               RMSE:          26.29
Df Residuals:           229                                MAE:          23.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     33.0276      4.7601       0.001     23.6501     41.8423
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.921
Model:                  NNLS                    Adj. R-squared:          0.921
No. Observations:       165                               RMSE:          19.41
Df Residuals:           163                                MAE:          16.49
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     29.0113      4.5035       0.001     20.4301     37.2148
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.922
Model:                  NNLS                    Adj. R-squared:          0.922
No. Observations:       286                               RMSE:          27.29
Df Residuals:           284                                MAE:          23.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     36.5652      4.9933       0.001     26.4883     46.1421
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.538
Model:                  NNLS                    Adj. R-squared:          0.536
No. Observations:       209                               RMSE:         105.71
Df Residuals:           207                                MAE:          87.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    146.3243     21.5238       0.001    102.8054    187.2641
       opcount      0.0002      0.0000       0.001      0.0002      0.0003
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.955
Model:                  NNLS                    Adj. R-squared:          0.955
No. Observations:       209                               RMSE:           8.71
Df Residuals:           207                                MAE:           7.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     24.8972      1.8839       0.001     21.2794     28.7923
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_EOA`: `presets[cold_account_nocode_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9693 | 0.01859 | 1.00e-03 | [0.01825, 0.01893] |
| `erigon` | 462 | 0.9883 | 0.004259 | 1.00e-03 | [0.004214, 0.004297] |
| `ethrex` | 330 | 0.492 | 0.01846 | 1.00e-03 | [0.0163, 0.0197] |
| `geth` | 572 | 0.9803 | 0.02118 | 1.00e-03 | [0.02096, 0.02141] |
| `nethermind` | 418 | 0.8222 | 0.003798 | 1.00e-03 | [0.003629, 0.003966] |
| `reth` | 418 | 0.9726 | 0.005283 | 1.00e-03 | [0.0052, 0.005365] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       440                               RMSE:          67.95
Df Residuals:           438                                MAE:          55.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    399.7802     10.0226       0.001    381.1756    419.7260
       opcount      0.0186      0.0002       0.001      0.0183      0.0189
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.988
Model:                  NNLS                    Adj. R-squared:          0.988
No. Observations:       462                               RMSE:           9.50
Df Residuals:           460                                MAE:           7.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     23.8601      1.3036       0.001     21.4310     26.5846
       opcount      0.0043      0.0000       0.001      0.0042      0.0043
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.492
Model:                  NNLS                    Adj. R-squared:          0.490
No. Observations:       330                               RMSE:         385.20
Df Residuals:           328                                MAE:         319.69
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     44.9753     48.4848       0.180      0.0000    165.3696
       opcount      0.0185      0.0009       0.001      0.0163      0.0197
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       572                               RMSE:          61.58
Df Residuals:           570                                MAE:          48.08
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    289.5571      7.9974       0.001    274.2908    304.5609
       opcount      0.0212      0.0001       0.001      0.0210      0.0214
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.822
Model:                  NNLS                    Adj. R-squared:          0.822
No. Observations:       418                               RMSE:          36.27
Df Residuals:           416                                MAE:          28.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    128.9802      5.0312       0.001    119.0257    139.1252
       opcount      0.0038      0.0001       0.001      0.0036      0.0040
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       418                               RMSE:          18.20
Df Residuals:           416                                MAE:          13.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    102.7476      2.6355       0.001     97.9147    107.8638
       opcount      0.0053      0.0000       0.001      0.0052      0.0054
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.NON_EXISTING_ACCOUNT`: `presets[cold_account_nocode_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9631 | 0.01884 | 1.00e-03 | [0.01849, 0.01918] |
| `erigon` | 462 | 0.9815 | 0.003656 | 1.00e-03 | [0.003611, 0.003699] |
| `ethrex` | 330 | 0.9549 | 0.002627 | 1.00e-03 | [0.002568, 0.002689] |
| `geth` | 572 | 0.9769 | 0.02074 | 1.00e-03 | [0.0205, 0.021] |
| `nethermind` | 418 | 0.8191 | 0.003382 | 1.00e-03 | [0.003233, 0.003541] |
| `reth` | 418 | 0.9728 | 0.004984 | 1.00e-03 | [0.004898, 0.005066] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.963
Model:                  NNLS                    Adj. R-squared:          0.963
No. Observations:       440                               RMSE:          75.73
Df Residuals:           438                                MAE:          62.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    352.6104     10.6612       0.001    332.2004    373.7348
       opcount      0.0188      0.0002       0.001      0.0185      0.0192
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       462                               RMSE:          10.32
Df Residuals:           460                                MAE:           7.92
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     19.6224      1.3846       0.001     16.8838     22.3009
       opcount      0.0037      0.0000       0.001      0.0036      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.955
Model:                  NNLS                    Adj. R-squared:          0.955
No. Observations:       330                               RMSE:          11.73
Df Residuals:           328                                MAE:           9.45
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.9150      1.9117       0.001     19.2709     26.6315
       opcount      0.0026      0.0000       0.001      0.0026      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       572                               RMSE:          65.47
Df Residuals:           570                                MAE:          52.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    274.1818      8.2226       0.001    256.6185    290.3613
       opcount      0.0207      0.0001       0.001      0.0205      0.0210
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.819
Model:                  NNLS                    Adj. R-squared:          0.819
No. Observations:       418                               RMSE:          32.63
Df Residuals:           416                                MAE:          25.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     73.3421      4.5954       0.001     64.4190     82.1190
       opcount      0.0034      0.0001       0.001      0.0032      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       418                               RMSE:          17.13
Df Residuals:           416                                MAE:          13.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.9339      2.5887       0.001     93.9460    104.2401
       opcount      0.0050      0.0000       0.001      0.0049      0.0051
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_EOA`: `presets[cold_account_nocode_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9552 | 0.09162 | 1.00e-03 | [0.08975, 0.09348] |
| `erigon` | 462 | 0.9971 | 0.06202 | 1.00e-03 | [0.06167, 0.06236] |
| `ethrex` | 330 | 0.9391 | 0.04057 | 1.00e-03 | [0.03975, 0.04094] |
| `geth` | 572 | 0.9898 | 0.1075 | 1.00e-03 | [0.1067, 0.1084] |
| `nethermind` | 418 | 0.5605 | 0.05265 | 1.00e-03 | [0.04832, 0.05691] |
| `reth` | 418 | 0.9804 | 0.09933 | 1.00e-03 | [0.098, 0.1007] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.955
Model:                  NNLS                    Adj. R-squared:          0.955
No. Observations:       440                               RMSE:          87.22
Df Residuals:           438                                MAE:          70.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    504.0334     13.0512       0.001    479.1140    530.1196
       opcount      0.0916      0.0010       0.001      0.0897      0.0935
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.997
Model:                  NNLS                    Adj. R-squared:          0.997
No. Observations:       462                               RMSE:          14.61
Df Residuals:           460                                MAE:          10.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    174.3324      2.2393       0.001    170.1822    178.7685
       opcount      0.0620      0.0002       0.001      0.0617      0.0624
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.939
Model:                  NNLS                    Adj. R-squared:          0.939
No. Observations:       330                               RMSE:          45.81
Df Residuals:           328                                MAE:          38.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      0.0000      2.3992       1.000      0.0000      9.1174
       opcount      0.0406      0.0003       0.001      0.0398      0.0409
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       572                               RMSE:          47.95
Df Residuals:           570                                MAE:          36.91
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.7682      6.1534       0.001    120.6597    144.9824
       opcount      0.1075      0.0005       0.001      0.1067      0.1084
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.561
Model:                  NNLS                    Adj. R-squared:          0.559
No. Observations:       418                               RMSE:         204.89
Df Residuals:           416                                MAE:         170.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    285.4152     28.3491       0.001    227.9835    342.3836
       opcount      0.0526      0.0022       0.001      0.0483      0.0569
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       418                               RMSE:          61.73
Df Residuals:           416                                MAE:          46.32
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    292.1170      8.5862       0.001    276.0554    308.6210
       opcount      0.0993      0.0007       0.001      0.0980      0.1007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.NON_EXISTING_ACCOUNT`: `presets[cold_account_nocode_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9137 | 0.1999 | 1.00e-03 | [0.1939, 0.2059] |
| `erigon` | 462 | 0.995 | 0.1933 | 1.00e-03 | [0.192, 0.1946] |
| `ethrex` | 330 | 0.6691 | 0.02946 | 1.00e-03 | [0.02727, 0.03153] |
| `geth` | 572 | 0.8554 | 0.121 | 1.00e-03 | [0.1171, 0.1252] |
| `nethermind` | 418 | 0.6811 | 0.1036 | 1.00e-03 | [0.09696, 0.11] |
| `reth` | 418 | 0.9784 | 0.1545 | 1.00e-03 | [0.1523, 0.1567] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.914
Model:                  NNLS                    Adj. R-squared:          0.914
No. Observations:       440                               RMSE:          21.16
Df Residuals:           438                                MAE:          16.71
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     82.7590      3.0554       0.001     76.8134     88.7385
       opcount      0.1999      0.0030       0.001      0.1939      0.2059
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.995
Model:                  NNLS                    Adj. R-squared:          0.995
No. Observations:       462                               RMSE:           4.73
Df Residuals:           460                                MAE:           3.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     67.9997      0.7172       0.001     66.5938     69.4314
       opcount      0.1933      0.0007       0.001      0.1920      0.1946
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.669
Model:                  NNLS                    Adj. R-squared:          0.668
No. Observations:       330                               RMSE:           7.14
Df Residuals:           328                                MAE:           6.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.3920      1.1163       0.001      7.3799     11.7229
       opcount      0.0295      0.0011       0.001      0.0273      0.0315
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.855
Model:                  NNLS                    Adj. R-squared:          0.855
No. Observations:       572                               RMSE:          17.14
Df Residuals:           570                                MAE:          12.50
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     29.1488      2.2356       0.001     24.7556     33.3924
       opcount      0.1210      0.0021       0.001      0.1171      0.1252
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.681
Model:                  NNLS                    Adj. R-squared:          0.680
No. Observations:       418                               RMSE:          24.42
Df Residuals:           416                                MAE:          21.20
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     30.8429      3.3670       0.001     24.3639     37.4274
       opcount      0.1036      0.0034       0.001      0.0970      0.1100
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.978
Model:                  NNLS                    Adj. R-squared:          0.978
No. Observations:       418                               RMSE:           7.92
Df Residuals:           416                                MAE:           6.15
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.2352      1.0821       0.001     24.0924     28.2731
       opcount      0.1545      0.0011       0.001      0.1523      0.1567
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_CONTRACT_DIFF_MAX`: `presets[cold_account_code_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8656 | 0.02817 | 1.00e-03 | [0.02705, 0.02918] |
| `erigon` | 462 | 0.5371 | 0.01534 | 1.00e-03 | [0.01398, 0.01658] |
| `ethrex` | 330 | 0.6415 | 0.01018 | 1.00e-03 | [0.009383, 0.01101] |
| `geth` | 572 | 0.7813 | 0.04589 | 1.00e-03 | [0.04393, 0.04793] |
| `nethermind` | 418 | 0.4636 | 0.02119 | 1.00e-03 | [0.01906, 0.02336] |
| `reth` | 418 | 0.4003 | 0.04179 | 1.00e-03 | [0.0366, 0.04549] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.866
Model:                  NNLS                    Adj. R-squared:          0.865
No. Observations:       440                               RMSE:         224.39
Df Residuals:           438                                MAE:         184.45
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    795.3012     33.5365       0.001    733.3787    863.2617
       opcount      0.0282      0.0005       0.001      0.0270      0.0292
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.537
Model:                  NNLS                    Adj. R-squared:          0.536
No. Observations:       462                               RMSE:         287.89
Df Residuals:           460                                MAE:         263.92
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    370.3540     37.4137       0.001    300.0278    444.8001
       opcount      0.0153      0.0007       0.001      0.0140      0.0166
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.641
Model:                  NNLS                    Adj. R-squared:          0.640
No. Observations:       330                               RMSE:         153.94
Df Residuals:           328                                MAE:         131.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    245.2347     24.2629       0.001    197.5963    292.9527
       opcount      0.0102      0.0004       0.001      0.0094      0.0110
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.781
Model:                  NNLS                    Adj. R-squared:          0.781
No. Observations:       572                               RMSE:         490.95
Df Residuals:           570                                MAE:         432.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const   1439.5324     70.3203       0.001   1291.8556   1570.9316
       opcount      0.0459      0.0010       0.001      0.0439      0.0479
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.464
Model:                  NNLS                    Adj. R-squared:          0.462
No. Observations:       418                               RMSE:         460.84
Df Residuals:           416                                MAE:         403.27
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    735.8755     69.8530       0.001    602.3160    864.0874
       opcount      0.0212      0.0011       0.001      0.0191      0.0234
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.400
Model:                  NNLS                    Adj. R-squared:          0.399
No. Observations:       418                               RMSE:        1034.23
Df Residuals:           416                                MAE:         982.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    160.9066    131.0486       0.142      0.0000    444.5238
       opcount      0.0418      0.0024       0.001      0.0366      0.0455
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_CONTRACT_MINIMAL`: `presets[cold_account_code_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9484 | 0.01348 | 1.00e-03 | [0.01321, 0.01381] |
| `erigon` | 462 | 0.9441 | 0.004231 | 1.00e-03 | [0.004136, 0.004324] |
| `ethrex` | 330 | 0.7949 | 0.002742 | 1.00e-03 | [0.002592, 0.002887] |
| `geth` | 572 | 0.9786 | 0.02057 | 1.00e-03 | [0.02033, 0.02082] |
| `nethermind` | 418 | 0.6282 | 0.003231 | 1.00e-03 | [0.002959, 0.003469] |
| `reth` | 418 | 0.9728 | 0.005187 | 1.00e-03 | [0.005108, 0.00527] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.948
Model:                  NNLS                    Adj. R-squared:          0.948
No. Observations:       440                               RMSE:          63.54
Df Residuals:           438                                MAE:          51.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    400.6219      9.7193       0.001    380.0488    418.7781
       opcount      0.0135      0.0002       0.001      0.0132      0.0138
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.944
Model:                  NNLS                    Adj. R-squared:          0.944
No. Observations:       462                               RMSE:          20.82
Df Residuals:           460                                MAE:          16.27
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    171.5333      3.1363       0.001    165.4267    177.5191
       opcount      0.0042      0.0000       0.001      0.0041      0.0043
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.795
Model:                  NNLS                    Adj. R-squared:          0.794
No. Observations:       330                               RMSE:          28.16
Df Residuals:           328                                MAE:          22.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    108.5237      5.4108       0.001     98.2239    119.0271
       opcount      0.0027      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.979
Model:                  NNLS                    Adj. R-squared:          0.979
No. Observations:       572                               RMSE:          61.45
Df Residuals:           570                                MAE:          47.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    268.5780      7.8683       0.001    253.5731    283.9563
       opcount      0.0206      0.0001       0.001      0.0203      0.0208
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.628
Model:                  NNLS                    Adj. R-squared:          0.627
No. Observations:       418                               RMSE:          50.26
Df Residuals:           416                                MAE:          38.34
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    155.2070      7.4582       0.001    142.1225    170.1170
       opcount      0.0032      0.0001       0.001      0.0030      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       418                               RMSE:          17.53
Df Residuals:           416                                MAE:          13.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.1293      2.4431       0.001     87.2723     96.7439
       opcount      0.0052      0.0000       0.001      0.0051      0.0053
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_CONTRACT_SAME_MAX`: `presets[cold_account_code_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9505 | 0.0135 | 1.00e-03 | [0.0132, 0.01381] |
| `erigon` | 462 | 0.8421 | 0.004562 | 1.00e-03 | [0.004384, 0.004761] |
| `ethrex` | 330 | 0.7958 | 0.002754 | 1.00e-03 | [0.002592, 0.002908] |
| `geth` | 572 | 0.976 | 0.02047 | 1.00e-03 | [0.0202, 0.02072] |
| `nethermind` | 418 | 0.6412 | 0.003174 | 1.00e-03 | [0.002929, 0.003413] |
| `reth` | 418 | 0.9696 | 0.005212 | 1.00e-03 | [0.005118, 0.005297] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.950
Model:                  NNLS                    Adj. R-squared:          0.950
No. Observations:       440                               RMSE:          62.31
Df Residuals:           438                                MAE:          51.46
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    398.9702      9.9092       0.001    380.9992    418.8128
       opcount      0.0135      0.0002       0.001      0.0132      0.0138
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.842
Model:                  NNLS                    Adj. R-squared:          0.842
No. Observations:       462                               RMSE:          39.95
Df Residuals:           460                                MAE:          34.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    122.5352      6.2504       0.001    109.7696    134.3744
       opcount      0.0046      0.0001       0.001      0.0044      0.0048
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.796
Model:                  NNLS                    Adj. R-squared:          0.795
No. Observations:       330                               RMSE:          28.21
Df Residuals:           328                                MAE:          22.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    107.4062      5.6630       0.001     96.2898    118.5655
       opcount      0.0028      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.976
Model:                  NNLS                    Adj. R-squared:          0.976
No. Observations:       572                               RMSE:          64.92
Df Residuals:           570                                MAE:          50.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    277.8302      7.9897       0.001    262.6587    294.0500
       opcount      0.0205      0.0001       0.001      0.0202      0.0207
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.641
Model:                  NNLS                    Adj. R-squared:          0.640
No. Observations:       418                               RMSE:          48.02
Df Residuals:           416                                MAE:          36.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    157.4161      6.9763       0.001    144.4364    171.9217
       opcount      0.0032      0.0001       0.001      0.0029      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       418                               RMSE:          18.67
Df Residuals:           416                                MAE:          14.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.9437      2.7030       0.001     87.9105     98.5049
       opcount      0.0052      0.0000       0.001      0.0051      0.0053
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_CONTRACT_DIFF_MAX`: `presets[cold_account_code_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9254 | 0.1043 | 1.00e-03 | [0.1012, 0.1072] |
| `erigon` | 462 | 0.9499 | 0.0757 | 1.00e-03 | [0.07409, 0.07724] |
| `ethrex` | 330 | 0.9112 | 0.03467 | 1.00e-03 | [0.03344, 0.03596] |
| `geth` | 572 | 0.907 | 0.1521 | 1.00e-03 | [0.1479, 0.1564] |
| `nethermind` | 418 | 0.6689 | 0.07954 | 1.00e-03 | [0.07449, 0.08476] |
| `reth` | 418 | 0.8719 | 0.1334 | 1.00e-03 | [0.1286, 0.1384] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.925
Model:                  NNLS                    Adj. R-squared:          0.925
No. Observations:       440                               RMSE:         129.68
Df Residuals:           438                                MAE:         105.33
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    432.5010     18.5901       0.001    396.4141    468.6442
       opcount      0.1043      0.0015       0.001      0.1012      0.1072
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.950
Model:                  NNLS                    Adj. R-squared:          0.950
No. Observations:       462                               RMSE:          76.17
Df Residuals:           460                                MAE:          62.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    304.8201     10.2320       0.001    285.6897    326.1120
       opcount      0.0757      0.0008       0.001      0.0741      0.0772
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.911
Model:                  NNLS                    Adj. R-squared:          0.911
No. Observations:       330                               RMSE:          47.42
Df Residuals:           328                                MAE:          36.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     62.2018      7.5403       0.001     46.9132     76.9203
       opcount      0.0347      0.0006       0.001      0.0334      0.0360
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.907
Model:                  NNLS                    Adj. R-squared:          0.907
No. Observations:       572                               RMSE:         213.28
Df Residuals:           570                                MAE:         197.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    261.7549     26.9316       0.001    206.7213    313.4300
       opcount      0.1521      0.0021       0.001      0.1479      0.1564
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.669
Model:                  NNLS                    Adj. R-squared:          0.668
No. Observations:       418                               RMSE:         245.16
Df Residuals:           416                                MAE:         198.09
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    271.1241     33.7857       0.001    206.8217    337.5854
       opcount      0.0795      0.0027       0.001      0.0745      0.0848
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.872
Model:                  NNLS                    Adj. R-squared:          0.872
No. Observations:       418                               RMSE:         223.93
Df Residuals:           416                                MAE:         203.30
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    352.5772     31.2452       0.001    291.8305    411.7448
       opcount      0.1334      0.0026       0.001      0.1286      0.1384
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_CONTRACT_MINIMAL`: `presets[cold_account_code_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.936 | 0.07655 | 1.00e-03 | [0.07474, 0.07836] |
| `erigon` | 462 | 0.973 | 0.05748 | 1.00e-03 | [0.05651, 0.05847] |
| `ethrex` | 330 | 0.9187 | 0.02543 | 1.00e-03 | [0.02467, 0.02571] |
| `geth` | 572 | 0.9886 | 0.1072 | 1.00e-03 | [0.1063, 0.1083] |
| `nethermind` | 418 | 0.556 | 0.05236 | 1.00e-03 | [0.04785, 0.05672] |
| `reth` | 418 | 0.9796 | 0.09928 | 1.00e-03 | [0.09788, 0.1008] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.936
Model:                  NNLS                    Adj. R-squared:          0.936
No. Observations:       440                               RMSE:          87.70
Df Residuals:           438                                MAE:          69.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    448.1901     12.7737       0.001    423.6259    472.5995
       opcount      0.0765      0.0010       0.001      0.0747      0.0784
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       462                               RMSE:          41.91
Df Residuals:           460                                MAE:          33.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    222.1575      6.1930       0.001    210.1527    234.8458
       opcount      0.0575      0.0005       0.001      0.0565      0.0585
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.919
Model:                  NNLS                    Adj. R-squared:          0.918
No. Observations:       330                               RMSE:          33.14
Df Residuals:           328                                MAE:          27.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      0.6693      3.0355       0.446      0.0000     10.5553
       opcount      0.0254      0.0003       0.001      0.0247      0.0257
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.989
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       572                               RMSE:          50.47
Df Residuals:           570                                MAE:          39.35
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    114.9825      6.5411       0.001    102.2859    127.6101
       opcount      0.1072      0.0005       0.001      0.1063      0.1083
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.556
Model:                  NNLS                    Adj. R-squared:          0.555
No. Observations:       418                               RMSE:         204.96
Df Residuals:           416                                MAE:         169.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    276.7032     29.1963       0.001    221.8225    330.1101
       opcount      0.0524      0.0023       0.001      0.0479      0.0567
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       418                               RMSE:          62.71
Df Residuals:           416                                MAE:          48.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    284.4788      9.2155       0.001    265.3435    301.8615
       opcount      0.0993      0.0007       0.001      0.0979      0.1008
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALL_AccountMode.EXISTING_CONTRACT_SAME_MAX`: `presets[cold_account_code_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9424 | 0.07569 | 1.00e-03 | [0.07393, 0.07749] |
| `erigon` | 462 | 0.6863 | 0.0666 | 1.00e-03 | [0.06246, 0.07076] |
| `ethrex` | 330 | 0.9149 | 0.0252 | 1.00e-03 | [0.02442, 0.02572] |
| `geth` | 572 | 0.9893 | 0.1075 | 1.00e-03 | [0.1066, 0.1085] |
| `nethermind` | 418 | 0.5601 | 0.05286 | 1.00e-03 | [0.04824, 0.05718] |
| `reth` | 418 | 0.9804 | 0.09977 | 1.00e-03 | [0.0984, 0.101] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.942
Model:                  NNLS                    Adj. R-squared:          0.942
No. Observations:       440                               RMSE:          81.95
Df Residuals:           438                                MAE:          66.15
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    442.2498     11.7159       0.001    419.8806    465.7366
       opcount      0.0757      0.0009       0.001      0.0739      0.0775
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.686
Model:                  NNLS                    Adj. R-squared:          0.686
No. Observations:       462                               RMSE:         197.24
Df Residuals:           460                                MAE:         189.69
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    275.6270     27.7764       0.001    222.4888    329.6449
       opcount      0.0666      0.0021       0.001      0.0625      0.0708
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.915
Model:                  NNLS                    Adj. R-squared:          0.915
No. Observations:       330                               RMSE:          33.67
Df Residuals:           328                                MAE:          28.19
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.5059      4.3043       0.206      0.0000     14.2562
       opcount      0.0252      0.0003       0.001      0.0244      0.0257
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.989
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       572                               RMSE:          48.97
Df Residuals:           570                                MAE:          38.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    111.7746      6.2140       0.001     99.5230    124.3181
       opcount      0.1075      0.0005       0.001      0.1066      0.1085
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.560
Model:                  NNLS                    Adj. R-squared:          0.559
No. Observations:       418                               RMSE:         205.19
Df Residuals:           416                                MAE:         168.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    275.2323     28.5280       0.001    219.9082    331.6944
       opcount      0.0529      0.0023       0.001      0.0482      0.0572
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       418                               RMSE:          61.84
Df Residuals:           416                                MAE:          47.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    282.1465      8.5776       0.001    266.1846    299.4461
       opcount      0.0998      0.0007       0.001      0.0984      0.1010
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## CALLCODE

### test_ext_account_query_warm: combo `CALLCODE`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9209 | 0.000627 | 1.00e-03 | [0.0006049, 0.0006495] |
| `erigon` | 231 | 0.7854 | 6.199e-05 | 1.00e-03 | [5.805e-05, 6.619e-05] |
| `ethrex` | 165 | 0.9144 | 0.0001291 | 1.00e-03 | [0.0001221, 0.0001354] |
| `geth` | 286 | 0.9336 | 0.0002304 | 1.00e-03 | [0.0002233, 0.0002379] |
| `nethermind` | 209 | 0.3616 | 0.0001378 | 1.00e-03 | [0.0001144, 0.0001619] |
| `reth` | 209 | 0.9657 | 7.897e-05 | 1.00e-03 | [7.708e-05, 8.085e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.921
Model:                  NNLS                    Adj. R-squared:          0.921
No. Observations:       220                               RMSE:          92.89
Df Residuals:           218                                MAE:          72.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    627.1910     17.6779       0.001    593.8502    661.7313
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.785
Model:                  NNLS                    Adj. R-squared:          0.784
No. Observations:       231                               RMSE:          16.38
Df Residuals:           229                                MAE:          14.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     28.9532      2.9643       0.001     22.8333     34.7989
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.914
Model:                  NNLS                    Adj. R-squared:          0.914
No. Observations:       165                               RMSE:          19.97
Df Residuals:           163                                MAE:          16.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.7074      5.1281       0.001     17.9531     37.8054
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.934
Model:                  NNLS                    Adj. R-squared:          0.933
No. Observations:       286                               RMSE:          31.06
Df Residuals:           284                                MAE:          25.70
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     53.8119      5.5305       0.001     42.4663     65.2220
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.362
Model:                  NNLS                    Adj. R-squared:          0.359
No. Observations:       209                               RMSE:          92.54
Df Residuals:           207                                MAE:          84.24
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     83.5980     18.7005       0.001     47.7897    119.6449
       opcount      0.0001      0.0000       0.001      0.0001      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.966
Model:                  NNLS                    Adj. R-squared:          0.966
No. Observations:       209                               RMSE:           7.52
Df Residuals:           207                                MAE:           5.78
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     24.6133      1.5122       0.001     21.6310     27.5744
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_EOA`: `presets[cold_account_nocode_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9736 | 0.01728 | 1.00e-03 | [0.01701, 0.01755] |
| `erigon` | 462 | 0.9893 | 0.003745 | 1.00e-03 | [0.003712, 0.003781] |
| `ethrex` | 330 | 0.4968 | 0.01854 | 1.00e-03 | [0.01642, 0.0197] |
| `geth` | 572 | 0.9801 | 0.02111 | 1.00e-03 | [0.02085, 0.02134] |
| `nethermind` | 418 | 0.8197 | 0.003617 | 1.00e-03 | [0.003443, 0.003783] |
| `reth` | 418 | 0.9708 | 0.004882 | 1.00e-03 | [0.004798, 0.004963] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       440                               RMSE:          58.38
Df Residuals:           438                                MAE:          47.49
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    368.5417      8.5404       0.001    351.8328    384.3804
       opcount      0.0173      0.0001       0.001      0.0170      0.0175
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.989
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       462                               RMSE:           8.00
Df Residuals:           460                                MAE:           6.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.6866      1.1254       0.001     20.5073     24.9866
       opcount      0.0037      0.0000       0.001      0.0037      0.0038
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.497
Model:                  NNLS                    Adj. R-squared:          0.495
No. Observations:       330                               RMSE:         383.12
Df Residuals:           328                                MAE:         318.23
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     36.9067     46.9300       0.296      0.0000    158.0680
       opcount      0.0185      0.0009       0.001      0.0164      0.0197
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       572                               RMSE:          61.78
Df Residuals:           570                                MAE:          47.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    298.9100      8.1503       0.001    283.4301    315.1360
       opcount      0.0211      0.0001       0.001      0.0209      0.0213
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.820
Model:                  NNLS                    Adj. R-squared:          0.819
No. Observations:       418                               RMSE:          34.84
Df Residuals:           416                                MAE:          26.27
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    129.8064      5.0056       0.001    120.3629    139.8764
       opcount      0.0036      0.0001       0.001      0.0034      0.0038
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       418                               RMSE:          17.38
Df Residuals:           416                                MAE:          13.99
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    102.6715      2.7699       0.001     97.2980    108.2030
       opcount      0.0049      0.0000       0.001      0.0048      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.NON_EXISTING_ACCOUNT`: `presets[cold_account_nocode_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9597 | 0.01537 | 1.00e-03 | [0.01508, 0.01566] |
| `erigon` | 462 | 0.9901 | 0.003461 | 1.00e-03 | [0.003433, 0.003488] |
| `ethrex` | 330 | 0.9587 | 0.00259 | 1.00e-03 | [0.00253, 0.002652] |
| `geth` | 572 | 0.9793 | 0.02111 | 1.00e-03 | [0.02088, 0.02136] |
| `nethermind` | 418 | 0.7946 | 0.00324 | 1.00e-03 | [0.003077, 0.003392] |
| `reth` | 418 | 0.9728 | 0.004911 | 1.00e-03 | [0.004835, 0.004983] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       440                               RMSE:          64.65
Df Residuals:           438                                MAE:          53.46
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    325.6603      9.7759       0.001    307.1552    343.9177
       opcount      0.0154      0.0002       0.001      0.0151      0.0157
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       462                               RMSE:           7.12
Df Residuals:           460                                MAE:           5.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.9811      0.8464       0.001     13.3902     16.6886
       opcount      0.0035      0.0000       0.001      0.0034      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.959
Model:                  NNLS                    Adj. R-squared:          0.959
No. Observations:       330                               RMSE:          11.04
Df Residuals:           328                                MAE:           8.95
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     24.8984      1.9055       0.001     21.1929     28.5769
       opcount      0.0026      0.0000       0.001      0.0025      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.979
Model:                  NNLS                    Adj. R-squared:          0.979
No. Observations:       572                               RMSE:          62.99
Df Residuals:           570                                MAE:          50.15
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    296.6283      8.2217       0.001    280.2511    311.8909
       opcount      0.0211      0.0001       0.001      0.0209      0.0214
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.795
Model:                  NNLS                    Adj. R-squared:          0.794
No. Observations:       418                               RMSE:          33.82
Df Residuals:           416                                MAE:          25.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     75.2720      4.6288       0.001     66.3321     84.9859
       opcount      0.0032      0.0001       0.001      0.0031      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       418                               RMSE:          16.86
Df Residuals:           416                                MAE:          13.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.4290      2.4011       0.001     94.1899    103.0981
       opcount      0.0049      0.0000       0.001      0.0048      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_EOA`: `presets[cold_account_nocode_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8637 | 0.02127 | 1.00e-03 | [0.02056, 0.02202] |
| `erigon` | 462 | 0.9585 | 0.003864 | 1.00e-03 | [0.00379, 0.003943] |
| `ethrex` | 330 | 0.5654 | 0.01729 | 1.00e-03 | [0.01522, 0.01908] |
| `geth` | 572 | 0.9407 | 0.02976 | 1.00e-03 | [0.02921, 0.03037] |
| `nethermind` | 418 | 0.8784 | 0.008059 | 1.00e-03 | [0.007757, 0.008351] |
| `reth` | 418 | 0.9501 | 0.00686 | 1.00e-03 | [0.006705, 0.007017] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.864
Model:                  NNLS                    Adj. R-squared:          0.863
No. Observations:       440                               RMSE:          37.13
Df Residuals:           438                                MAE:          30.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    246.3307      5.1515       0.001    236.6524    256.5171
       opcount      0.0213      0.0004       0.001      0.0206      0.0220
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.959
Model:                  NNLS                    Adj. R-squared:          0.958
No. Observations:       462                               RMSE:           3.53
Df Residuals:           460                                MAE:           2.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     18.9610      0.5657       0.001     17.8151     20.0887
       opcount      0.0039      0.0000       0.001      0.0038      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.565
Model:                  NNLS                    Adj. R-squared:          0.564
No. Observations:       330                               RMSE:          66.62
Df Residuals:           328                                MAE:          41.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     67.2901     10.6438       0.001     47.9751     89.7578
       opcount      0.0173      0.0010       0.001      0.0152      0.0191
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.941
Model:                  NNLS                    Adj. R-squared:          0.941
No. Observations:       572                               RMSE:          32.85
Df Residuals:           570                                MAE:          26.57
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     57.7493      3.8735       0.001     50.1635     64.7338
       opcount      0.0298      0.0003       0.001      0.0292      0.0304
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.878
Model:                  NNLS                    Adj. R-squared:          0.878
No. Observations:       418                               RMSE:          13.18
Df Residuals:           416                                MAE:          10.81
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     45.9303      2.1211       0.001     42.0193     50.1441
       opcount      0.0081      0.0002       0.001      0.0078      0.0084
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.950
Model:                  NNLS                    Adj. R-squared:          0.950
No. Observations:       418                               RMSE:           6.91
Df Residuals:           416                                MAE:           5.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     40.2185      1.0466       0.001     38.1589     42.2690
       opcount      0.0069      0.0001       0.001      0.0067      0.0070
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.NON_EXISTING_ACCOUNT`: `presets[cold_account_nocode_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8481 | 0.02166 | 1.00e-03 | [0.02081, 0.02252] |
| `erigon` | 462 | 0.9434 | 0.00337 | 1.00e-03 | [0.003294, 0.003449] |
| `ethrex` | 330 | 0.8745 | 0.003234 | 1.00e-03 | [0.003088, 0.003372] |
| `geth` | 572 | 0.9392 | 0.0297 | 1.00e-03 | [0.0291, 0.03034] |
| `nethermind` | 418 | 0.8375 | 0.005989 | 1.00e-03 | [0.005735, 0.006244] |
| `reth` | 418 | 0.9512 | 0.006831 | 1.00e-03 | [0.006687, 0.006988] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.848
Model:                  NNLS                    Adj. R-squared:          0.848
No. Observations:       440                               RMSE:          40.28
Df Residuals:           438                                MAE:          32.50
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    197.5454      5.6406       0.001    185.9625    209.2722
       opcount      0.0217      0.0004       0.001      0.0208      0.0225
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.943
Model:                  NNLS                    Adj. R-squared:          0.943
No. Observations:       462                               RMSE:           3.63
Df Residuals:           460                                MAE:           2.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     17.9244      0.5399       0.001     16.9176     19.0096
       opcount      0.0034      0.0000       0.001      0.0033      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.875
Model:                  NNLS                    Adj. R-squared:          0.874
No. Observations:       330                               RMSE:           5.38
Df Residuals:           328                                MAE:           4.16
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.2873      0.9574       0.001      2.4192      6.2700
       opcount      0.0032      0.0001       0.001      0.0031      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.939
Model:                  NNLS                    Adj. R-squared:          0.939
No. Observations:       572                               RMSE:          33.21
Df Residuals:           570                                MAE:          26.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     65.1487      4.1424       0.001     57.1295     73.1616
       opcount      0.0297      0.0003       0.001      0.0291      0.0303
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.837
No. Observations:       418                               RMSE:          11.59
Df Residuals:           416                                MAE:           9.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     33.2912      1.7694       0.001     29.6654     36.7174
       opcount      0.0060      0.0001       0.001      0.0057      0.0062
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.951
Model:                  NNLS                    Adj. R-squared:          0.951
No. Observations:       418                               RMSE:           6.80
Df Residuals:           416                                MAE:           5.45
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     39.5484      1.0687       0.001     37.4163     41.5146
       opcount      0.0068      0.0001       0.001      0.0067      0.0070
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_CONTRACT_DIFF_MAX`: `presets[cold_account_code_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8645 | 0.02697 | 1.00e-03 | [0.02589, 0.02801] |
| `erigon` | 462 | 0.5354 | 0.01486 | 1.00e-03 | [0.0136, 0.01616] |
| `ethrex` | 330 | 0.6358 | 0.01024 | 1.00e-03 | [0.009391, 0.01107] |
| `geth` | 572 | 0.7858 | 0.04579 | 1.00e-03 | [0.04383, 0.04768] |
| `nethermind` | 418 | 0.4749 | 0.02187 | 1.00e-03 | [0.01981, 0.02406] |
| `reth` | 418 | 0.3905 | 0.04071 | 1.00e-03 | [0.0354, 0.0445] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.864
Model:                  NNLS                    Adj. R-squared:          0.864
No. Observations:       440                               RMSE:         215.91
Df Residuals:           438                                MAE:         177.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    785.2184     34.4525       0.001    720.8395    855.9531
       opcount      0.0270      0.0005       0.001      0.0259      0.0280
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.535
Model:                  NNLS                    Adj. R-squared:          0.534
No. Observations:       462                               RMSE:         279.82
Df Residuals:           460                                MAE:         260.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    355.1924     37.8898       0.001    284.3346    427.0898
       opcount      0.0149      0.0007       0.001      0.0136      0.0162
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.636
Model:                  NNLS                    Adj. R-squared:          0.635
No. Observations:       330                               RMSE:         156.63
Df Residuals:           328                                MAE:         134.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    242.9907     24.0927       0.001    196.7577    290.1811
       opcount      0.0102      0.0004       0.001      0.0094      0.0111
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.786
Model:                  NNLS                    Adj. R-squared:          0.785
No. Observations:       572                               RMSE:         483.42
Df Residuals:           570                                MAE:         425.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const   1440.9143     69.7227       0.001   1309.7983   1583.9390
       opcount      0.0458      0.0010       0.001      0.0438      0.0477
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.475
Model:                  NNLS                    Adj. R-squared:          0.474
No. Observations:       418                               RMSE:         465.00
Df Residuals:           416                                MAE:         408.87
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    706.9559     70.0819       0.001    570.9478    840.1114
       opcount      0.0219      0.0011       0.001      0.0198      0.0241
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.391
Model:                  NNLS                    Adj. R-squared:          0.389
No. Observations:       418                               RMSE:        1028.38
Df Residuals:           416                                MAE:         977.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    165.0664    132.6081       0.136      0.0000    460.1887
       opcount      0.0407      0.0024       0.001      0.0354      0.0445
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_CONTRACT_MINIMAL`: `presets[cold_account_code_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9543 | 0.01306 | 1.00e-03 | [0.01278, 0.01334] |
| `erigon` | 462 | 0.9197 | 0.003825 | 1.00e-03 | [0.003731, 0.003923] |
| `ethrex` | 330 | 0.7955 | 0.002796 | 1.00e-03 | [0.002637, 0.002948] |
| `geth` | 572 | 0.9771 | 0.02045 | 1.00e-03 | [0.0202, 0.02069] |
| `nethermind` | 418 | 0.6247 | 0.0033 | 1.00e-03 | [0.003047, 0.003569] |
| `reth` | 418 | 0.966 | 0.004775 | 1.00e-03 | [0.004694, 0.004853] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.954
Model:                  NNLS                    Adj. R-squared:          0.954
No. Observations:       440                               RMSE:          57.80
Df Residuals:           438                                MAE:          46.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    374.0039      9.1517       0.001    355.6287    391.5901
       opcount      0.0131      0.0001       0.001      0.0128      0.0133
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.920
Model:                  NNLS                    Adj. R-squared:          0.920
No. Observations:       462                               RMSE:          22.86
Df Residuals:           460                                MAE:          19.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    160.0113      3.1471       0.001    153.8744    166.1488
       opcount      0.0038      0.0001       0.001      0.0037      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.796
Model:                  NNLS                    Adj. R-squared:          0.795
No. Observations:       330                               RMSE:          28.66
Df Residuals:           328                                MAE:          23.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    105.1415      5.4112       0.001     95.2113    116.3756
       opcount      0.0028      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       572                               RMSE:          63.26
Df Residuals:           570                                MAE:          50.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    266.4444      7.8864       0.001    251.5974    282.3471
       opcount      0.0205      0.0001       0.001      0.0202      0.0207
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.625
Model:                  NNLS                    Adj. R-squared:          0.624
No. Observations:       418                               RMSE:          51.73
Df Residuals:           416                                MAE:          39.27
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    153.5226      7.4848       0.001    138.3039    168.5645
       opcount      0.0033      0.0001       0.001      0.0030      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.966
Model:                  NNLS                    Adj. R-squared:          0.966
No. Observations:       418                               RMSE:          18.12
Df Residuals:           416                                MAE:          14.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     89.4621      2.4363       0.001     85.0626     94.0964
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_CONTRACT_SAME_MAX`: `presets[cold_account_code_access]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9551 | 0.01313 | 1.00e-03 | [0.01288, 0.01342] |
| `erigon` | 462 | 0.8216 | 0.004066 | 1.00e-03 | [0.003894, 0.004235] |
| `ethrex` | 330 | 0.8032 | 0.002879 | 1.00e-03 | [0.002718, 0.003038] |
| `geth` | 572 | 0.9775 | 0.02045 | 1.00e-03 | [0.02019, 0.02069] |
| `nethermind` | 418 | 0.6228 | 0.003161 | 1.00e-03 | [0.002945, 0.003406] |
| `reth` | 418 | 0.9621 | 0.004759 | 1.00e-03 | [0.004668, 0.004851] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.955
Model:                  NNLS                    Adj. R-squared:          0.955
No. Observations:       440                               RMSE:          57.56
Df Residuals:           438                                MAE:          47.56
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    372.1505      8.9626       0.001    354.3518    389.2936
       opcount      0.0131      0.0001       0.001      0.0129      0.0134
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.822
Model:                  NNLS                    Adj. R-squared:          0.821
No. Observations:       462                               RMSE:          38.30
Df Residuals:           460                                MAE:          32.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    115.8675      5.7788       0.001    104.7949    127.5010
       opcount      0.0041      0.0001       0.001      0.0039      0.0042
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.803
Model:                  NNLS                    Adj. R-squared:          0.803
No. Observations:       330                               RMSE:          28.82
Df Residuals:           328                                MAE:          23.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    100.3421      5.5449       0.001     89.5053    110.9011
       opcount      0.0029      0.0001       0.001      0.0027      0.0030
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       572                               RMSE:          62.75
Df Residuals:           570                                MAE:          50.09
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    275.4616      7.8388       0.001    261.0870    290.9290
       opcount      0.0204      0.0001       0.001      0.0202      0.0207
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.623
Model:                  NNLS                    Adj. R-squared:          0.622
No. Observations:       418                               RMSE:          49.74
Df Residuals:           416                                MAE:          38.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    161.9207      6.9775       0.001    147.9848    175.1996
       opcount      0.0032      0.0001       0.001      0.0029      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.962
Model:                  NNLS                    Adj. R-squared:          0.962
No. Observations:       418                               RMSE:          19.09
Df Residuals:           416                                MAE:          15.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.7422      2.7725       0.001     87.5459     98.2764
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_CONTRACT_DIFF_MAX`: `presets[cold_account_code_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8464 | 0.04158 | 1.00e-03 | [0.03988, 0.04343] |
| `erigon` | 462 | 0.801 | 0.02162 | 1.00e-03 | [0.02059, 0.02262] |
| `ethrex` | 330 | 0.6654 | 0.0151 | 1.00e-03 | [0.01392, 0.01632] |
| `geth` | 572 | 0.6861 | 0.07357 | 1.00e-03 | [0.06938, 0.07767] |
| `nethermind` | 418 | 0.6409 | 0.03647 | 1.00e-03 | [0.0339, 0.03899] |
| `reth` | 418 | 0.4115 | 0.04275 | 1.00e-03 | [0.03741, 0.04748] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.846
Model:                  NNLS                    Adj. R-squared:          0.846
No. Observations:       440                               RMSE:          77.61
Df Residuals:           438                                MAE:          64.63
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    247.4670     12.6635       0.001    222.7823    272.1073
       opcount      0.0416      0.0009       0.001      0.0399      0.0434
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.801
Model:                  NNLS                    Adj. R-squared:          0.801
No. Observations:       462                               RMSE:          47.20
Df Residuals:           460                                MAE:          41.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    177.1275      6.5452       0.001    164.7200    189.9443
       opcount      0.0216      0.0005       0.001      0.0206      0.0226
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.665
Model:                  NNLS                    Adj. R-squared:          0.664
No. Observations:       330                               RMSE:          46.89
Df Residuals:           328                                MAE:          35.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    155.2505      7.2743       0.001    141.5276    170.1197
       opcount      0.0151      0.0006       0.001      0.0139      0.0163
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.686
Model:                  NNLS                    Adj. R-squared:          0.686
No. Observations:       572                               RMSE:         218.00
Df Residuals:           570                                MAE:         201.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    238.1260     26.2608       0.001    187.3089    288.9627
       opcount      0.0736      0.0021       0.001      0.0694      0.0777
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.641
Model:                  NNLS                    Adj. R-squared:          0.640
No. Observations:       418                               RMSE:         119.58
Df Residuals:           416                                MAE:         102.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    117.4383     17.0007       0.001     85.6426    150.0605
       opcount      0.0365      0.0013       0.001      0.0339      0.0390
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.411
Model:                  NNLS                    Adj. R-squared:          0.410
No. Observations:       418                               RMSE:         223.96
Df Residuals:           416                                MAE:         212.45
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     90.7999     32.1637       0.001     30.9968    158.1345
       opcount      0.0428      0.0027       0.001      0.0374      0.0475
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_CONTRACT_MINIMAL`: `presets[cold_account_code_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8762 | 0.01856 | 1.00e-03 | [0.01795, 0.01924] |
| `erigon` | 462 | 0.8271 | 0.007625 | 1.00e-03 | [0.007304, 0.007946] |
| `ethrex` | 330 | 0.3361 | 0.003761 | 1.00e-03 | [0.003107, 0.004346] |
| `geth` | 572 | 0.9446 | 0.02767 | 1.00e-03 | [0.02714, 0.02821] |
| `nethermind` | 418 | 0.8378 | 0.008074 | 1.00e-03 | [0.007738, 0.008422] |
| `reth` | 418 | 0.9466 | 0.006568 | 1.00e-03 | [0.006418, 0.006721] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.876
Model:                  NNLS                    Adj. R-squared:          0.876
No. Observations:       440                               RMSE:          30.56
Df Residuals:           438                                MAE:          24.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    175.2380      4.7580       0.001    166.1153    184.3997
       opcount      0.0186      0.0003       0.001      0.0179      0.0192
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.827
Model:                  NNLS                    Adj. R-squared:          0.827
No. Observations:       462                               RMSE:          15.27
Df Residuals:           460                                MAE:          12.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     68.5479      2.2086       0.001     64.2878     72.8203
       opcount      0.0076      0.0002       0.001      0.0073      0.0079
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.336
Model:                  NNLS                    Adj. R-squared:          0.334
No. Observations:       330                               RMSE:          23.15
Df Residuals:           328                                MAE:          16.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     89.0334      3.8539       0.001     82.2602     96.6881
       opcount      0.0038      0.0003       0.001      0.0031      0.0043
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.945
Model:                  NNLS                    Adj. R-squared:          0.945
No. Observations:       572                               RMSE:          29.35
Df Residuals:           570                                MAE:          23.33
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     60.6074      3.6255       0.001     53.5516     67.5389
       opcount      0.0277      0.0003       0.001      0.0271      0.0282
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.837
No. Observations:       418                               RMSE:          15.56
Df Residuals:           416                                MAE:          12.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     54.9624      2.4029       0.001     50.4328     59.7221
       opcount      0.0081      0.0002       0.001      0.0077      0.0084
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.947
Model:                  NNLS                    Adj. R-squared:          0.946
No. Observations:       418                               RMSE:           6.84
Df Residuals:           416                                MAE:           5.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     33.5315      0.9745       0.001     31.6432     35.5723
       opcount      0.0066      0.0001       0.001      0.0064      0.0067
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `CALLCODE_AccountMode.EXISTING_CONTRACT_SAME_MAX`: `presets[cold_account_code_write]`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8803 | 0.01849 | 1.00e-03 | [0.01782, 0.01911] |
| `erigon` | 462 | 0.5144 | 0.006445 | 1.00e-03 | [0.005895, 0.007014] |
| `ethrex` | 330 | 0.3181 | 0.003569 | 1.00e-03 | [0.002999, 0.004221] |
| `geth` | 572 | 0.9467 | 0.02846 | 1.00e-03 | [0.02793, 0.02901] |
| `nethermind` | 418 | 0.8358 | 0.008121 | 1.00e-03 | [0.007739, 0.008497] |
| `reth` | 418 | 0.94 | 0.006614 | 1.00e-03 | [0.006444, 0.006776] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.880
Model:                  NNLS                    Adj. R-squared:          0.880
No. Observations:       440                               RMSE:          29.88
Df Residuals:           438                                MAE:          24.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    177.6349      4.5629       0.001    168.4267    186.5280
       opcount      0.0185      0.0003       0.001      0.0178      0.0191
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.514
Model:                  NNLS                    Adj. R-squared:          0.513
No. Observations:       462                               RMSE:          27.43
Df Residuals:           460                                MAE:          23.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     62.7134      3.5892       0.001     56.1639     69.5915
       opcount      0.0064      0.0003       0.001      0.0059      0.0070
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.318
Model:                  NNLS                    Adj. R-squared:          0.316
No. Observations:       330                               RMSE:          22.89
Df Residuals:           328                                MAE:          16.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.2120      3.7938       0.001     84.2075     98.9834
       opcount      0.0036      0.0003       0.001      0.0030      0.0042
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.947
Model:                  NNLS                    Adj. R-squared:          0.947
No. Observations:       572                               RMSE:          29.59
Df Residuals:           570                                MAE:          23.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     53.9756      3.6452       0.001     46.5268     60.7636
       opcount      0.0285      0.0003       0.001      0.0279      0.0290
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.836
Model:                  NNLS                    Adj. R-squared:          0.835
No. Observations:       418                               RMSE:          15.77
Df Residuals:           416                                MAE:          12.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     55.1986      2.5362       0.001     50.2093     60.5705
       opcount      0.0081      0.0002       0.001      0.0077      0.0085
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.940
Model:                  NNLS                    Adj. R-squared:          0.940
No. Observations:       418                               RMSE:           7.32
Df Residuals:           416                                MAE:           5.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     34.5131      1.1750       0.001     32.4178     36.9307
       opcount      0.0066      0.0001       0.001      0.0064      0.0068
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## DELEGATECALL

### test_ext_account_query_warm: combo `DELEGATECALL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9053 | 0.0005729 | 1.00e-03 | [0.0005495, 0.0005944] |
| `erigon` | 231 | 0.7643 | 5.765e-05 | 1.00e-03 | [5.345e-05, 6.212e-05] |
| `ethrex` | 165 | 0.9107 | 0.0001248 | 1.00e-03 | [0.0001186, 0.000131] |
| `geth` | 286 | 0.9304 | 0.000205 | 1.00e-03 | [0.0001985, 0.0002108] |
| `nethermind` | 209 | 0.5719 | 0.0004025 | 1.00e-03 | [0.0003509, 0.0004496] |
| `reth` | 209 | 0.9536 | 7.374e-05 | 1.00e-03 | [7.15e-05, 7.592e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.905
Model:                  NNLS                    Adj. R-squared:          0.905
No. Observations:       220                               RMSE:          95.98
Df Residuals:           218                                MAE:          75.17
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    612.6006     18.3155       0.001    578.5827    647.2691
       opcount      0.0006      0.0000       0.001      0.0005      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.764
Model:                  NNLS                    Adj. R-squared:          0.763
No. Observations:       231                               RMSE:          16.58
Df Residuals:           229                                MAE:          14.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     31.6421      3.1988       0.001     25.3986     37.7979
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.911
Model:                  NNLS                    Adj. R-squared:          0.910
No. Observations:       165                               RMSE:          20.23
Df Residuals:           163                                MAE:          17.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     32.8015      5.2116       0.001     22.8456     42.8559
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.930
Model:                  NNLS                    Adj. R-squared:          0.930
No. Observations:       286                               RMSE:          29.04
Df Residuals:           284                                MAE:          23.62
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     46.6518      5.1927       0.001     36.8316     56.8836
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.572
Model:                  NNLS                    Adj. R-squared:          0.570
No. Observations:       209                               RMSE:         180.32
Df Residuals:           207                                MAE:         155.30
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    147.8354     35.7771       0.001     80.9443    217.3353
       opcount      0.0004      0.0000       0.001      0.0004      0.0004
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.954
Model:                  NNLS                    Adj. R-squared:          0.953
No. Observations:       209                               RMSE:           8.42
Df Residuals:           207                                MAE:           6.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.1257      1.7183       0.001     22.9012     29.6332
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `DELEGATECALL_AccountMode.EXISTING_EOA`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9724 | 0.01729 | 1.00e-03 | [0.017, 0.01756] |
| `erigon` | 462 | 0.9918 | 0.003749 | 1.00e-03 | [0.003718, 0.003781] |
| `ethrex` | 330 | 0.4959 | 0.01854 | 1.00e-03 | [0.01631, 0.01966] |
| `geth` | 572 | 0.9809 | 0.02143 | 1.00e-03 | [0.0212, 0.02168] |
| `nethermind` | 418 | 0.8295 | 0.003905 | 1.00e-03 | [0.003735, 0.004074] |
| `reth` | 418 | 0.9727 | 0.004967 | 1.00e-03 | [0.004887, 0.005049] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.972
Model:                  NNLS                    Adj. R-squared:          0.972
No. Observations:       440                               RMSE:          59.90
Df Residuals:           438                                MAE:          49.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    360.7091      8.7874       0.001    343.9761    378.7367
       opcount      0.0173      0.0001       0.001      0.0170      0.0176
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.992
Model:                  NNLS                    Adj. R-squared:          0.992
No. Observations:       462                               RMSE:           7.00
Df Residuals:           460                                MAE:           5.61
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.9509      1.0074       0.001     20.9722     25.0032
       opcount      0.0037      0.0000       0.001      0.0037      0.0038
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.496
Model:                  NNLS                    Adj. R-squared:          0.494
No. Observations:       330                               RMSE:         384.22
Df Residuals:           328                                MAE:         318.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     36.8229     47.0682       0.265      0.0000    157.3161
       opcount      0.0185      0.0009       0.001      0.0163      0.0197
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       572                               RMSE:          61.54
Df Residuals:           570                                MAE:          47.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    268.9391      8.0262       0.001    253.6994    284.1314
       opcount      0.0214      0.0001       0.001      0.0212      0.0217
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.830
Model:                  NNLS                    Adj. R-squared:          0.829
No. Observations:       418                               RMSE:          36.39
Df Residuals:           416                                MAE:          28.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    127.6652      5.2578       0.001    117.4392    137.7064
       opcount      0.0039      0.0001       0.001      0.0037      0.0041
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       418                               RMSE:          17.09
Df Residuals:           416                                MAE:          13.44
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     97.6442      2.6546       0.001     92.6531    102.9705
       opcount      0.0050      0.0000       0.001      0.0049      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `DELEGATECALL_AccountMode.NON_EXISTING_ACCOUNT`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9609 | 0.01554 | 1.00e-03 | [0.01527, 0.01584] |
| `erigon` | 462 | 0.9895 | 0.00343 | 1.00e-03 | [0.003403, 0.003457] |
| `ethrex` | 330 | 0.9582 | 0.002598 | 1.00e-03 | [0.002538, 0.00266] |
| `geth` | 572 | 0.9812 | 0.02131 | 1.00e-03 | [0.02107, 0.02155] |
| `nethermind` | 418 | 0.8123 | 0.003603 | 1.00e-03 | [0.003448, 0.003774] |
| `reth` | 418 | 0.9736 | 0.005005 | 1.00e-03 | [0.00493, 0.005073] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.961
Model:                  NNLS                    Adj. R-squared:          0.961
No. Observations:       440                               RMSE:          64.43
Df Residuals:           438                                MAE:          53.24
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    308.2249      9.5261       0.001    289.8812    327.3010
       opcount      0.0155      0.0001       0.001      0.0153      0.0158
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.989
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       462                               RMSE:           7.26
Df Residuals:           460                                MAE:           5.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.8187      0.9121       0.001     15.0158     18.5922
       opcount      0.0034      0.0000       0.001      0.0034      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.958
Model:                  NNLS                    Adj. R-squared:          0.958
No. Observations:       330                               RMSE:          11.15
Df Residuals:           328                                MAE:           8.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     23.7567      1.9495       0.001     19.8657     27.6299
       opcount      0.0026      0.0000       0.001      0.0025      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       572                               RMSE:          60.62
Df Residuals:           570                                MAE:          49.19
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    284.2222      8.0702       0.001    268.8072    299.8064
       opcount      0.0213      0.0001       0.001      0.0211      0.0215
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.812
Model:                  NNLS                    Adj. R-squared:          0.812
No. Observations:       418                               RMSE:          35.59
Df Residuals:           416                                MAE:          27.69
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     70.9744      5.0827       0.001     60.9158     80.2318
       opcount      0.0036      0.0001       0.001      0.0034      0.0038
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       418                               RMSE:          16.96
Df Residuals:           416                                MAE:          13.02
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     91.8199      2.2246       0.001     87.7714     96.4963
       opcount      0.0050      0.0000       0.001      0.0049      0.0051
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `DELEGATECALL_AccountMode.EXISTING_CONTRACT_DIFF_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8631 | 0.02686 | 1.00e-03 | [0.02589, 0.02794] |
| `erigon` | 462 | 0.5404 | 0.01498 | 1.00e-03 | [0.0137, 0.0162] |
| `ethrex` | 330 | 0.6359 | 0.01022 | 1.00e-03 | [0.009325, 0.01114] |
| `geth` | 572 | 0.7821 | 0.04569 | 1.00e-03 | [0.04375, 0.04759] |
| `nethermind` | 418 | 0.4692 | 0.02149 | 1.00e-03 | [0.01942, 0.02376] |
| `reth` | 418 | 0.3884 | 0.04051 | 1.00e-03 | [0.03542, 0.04439] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.863
Model:                  NNLS                    Adj. R-squared:          0.863
No. Observations:       440                               RMSE:         216.55
Df Residuals:           438                                MAE:         176.49
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    780.5885     32.6950       0.001    712.9951    843.7626
       opcount      0.0269      0.0005       0.001      0.0259      0.0279
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.540
Model:                  NNLS                    Adj. R-squared:          0.539
No. Observations:       462                               RMSE:         279.66
Df Residuals:           460                                MAE:         258.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    350.3808     35.7921       0.001    287.1344    419.0851
       opcount      0.0150      0.0006       0.001      0.0137      0.0162
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.636
Model:                  NNLS                    Adj. R-squared:          0.635
No. Observations:       330                               RMSE:         156.53
Df Residuals:           328                                MAE:         134.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    243.5005     25.0182       0.001    197.3547    291.0833
       opcount      0.0102      0.0005       0.001      0.0093      0.0111
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.782
Model:                  NNLS                    Adj. R-squared:          0.782
No. Observations:       572                               RMSE:         488.17
Df Residuals:           570                                MAE:         432.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const   1442.9003     70.7622       0.001   1301.8018   1581.1036
       opcount      0.0457      0.0010       0.001      0.0437      0.0476
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.469
Model:                  NNLS                    Adj. R-squared:          0.468
No. Observations:       418                               RMSE:         462.63
Df Residuals:           416                                MAE:         403.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    721.4976     69.1922       0.001    583.3817    854.1887
       opcount      0.0215      0.0011       0.001      0.0194      0.0238
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.388
Model:                  NNLS                    Adj. R-squared:          0.387
No. Observations:       418                               RMSE:        1028.75
Df Residuals:           416                                MAE:         978.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    178.2125    128.5895       0.114      0.0000    462.9367
       opcount      0.0405      0.0024       0.001      0.0354      0.0444
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `DELEGATECALL_AccountMode.EXISTING_CONTRACT_MINIMAL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.959 | 0.0132 | 1.00e-03 | [0.0129, 0.01348] |
| `erigon` | 462 | 0.9199 | 0.003799 | 1.00e-03 | [0.003697, 0.003895] |
| `ethrex` | 330 | 0.8134 | 0.002719 | 1.00e-03 | [0.002573, 0.002861] |
| `geth` | 572 | 0.9784 | 0.02032 | 1.00e-03 | [0.0201, 0.02058] |
| `nethermind` | 418 | 0.6596 | 0.003258 | 1.00e-03 | [0.003026, 0.00351] |
| `reth` | 418 | 0.9655 | 0.004799 | 1.00e-03 | [0.00471, 0.004898] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.959
Model:                  NNLS                    Adj. R-squared:          0.959
No. Observations:       440                               RMSE:          55.25
Df Residuals:           438                                MAE:          44.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    358.3976      8.8527       0.001    341.6290    376.7656
       opcount      0.0132      0.0001       0.001      0.0129      0.0135
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.920
Model:                  NNLS                    Adj. R-squared:          0.920
No. Observations:       462                               RMSE:          22.69
Df Residuals:           460                                MAE:          18.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    160.8926      3.1739       0.001    154.7778    167.2175
       opcount      0.0038      0.0001       0.001      0.0037      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.813
Model:                  NNLS                    Adj. R-squared:          0.813
No. Observations:       330                               RMSE:          26.36
Df Residuals:           328                                MAE:          21.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    107.8017      5.2102       0.001     97.8915    117.6655
       opcount      0.0027      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.978
Model:                  NNLS                    Adj. R-squared:          0.978
No. Observations:       572                               RMSE:          61.07
Df Residuals:           570                                MAE:          47.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    277.7867      7.6405       0.001    261.5257    291.9908
       opcount      0.0203      0.0001       0.001      0.0201      0.0206
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.660
Model:                  NNLS                    Adj. R-squared:          0.659
No. Observations:       418                               RMSE:          47.37
Df Residuals:           416                                MAE:          36.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    156.2115      6.9216       0.001    142.3997    169.8832
       opcount      0.0033      0.0001       0.001      0.0030      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.966
Model:                  NNLS                    Adj. R-squared:          0.965
No. Observations:       418                               RMSE:          18.36
Df Residuals:           416                                MAE:          14.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     88.6845      2.8206       0.001     83.0049     93.8072
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `DELEGATECALL_AccountMode.EXISTING_CONTRACT_SAME_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9597 | 0.0132 | 1.00e-03 | [0.01296, 0.01344] |
| `erigon` | 462 | 0.833 | 0.004271 | 1.00e-03 | [0.00409, 0.00445] |
| `ethrex` | 330 | 0.787 | 0.002765 | 1.00e-03 | [0.002619, 0.002917] |
| `geth` | 572 | 0.9781 | 0.02043 | 1.00e-03 | [0.02016, 0.0207] |
| `nethermind` | 418 | 0.6355 | 0.003256 | 1.00e-03 | [0.002992, 0.003514] |
| `reth` | 418 | 0.9628 | 0.004707 | 1.00e-03 | [0.004618, 0.004795] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       440                               RMSE:          54.74
Df Residuals:           438                                MAE:          44.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    357.6440      7.9450       0.001    342.6066    372.6994
       opcount      0.0132      0.0001       0.001      0.0130      0.0134
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.833
Model:                  NNLS                    Adj. R-squared:          0.833
No. Observations:       462                               RMSE:          38.72
Df Residuals:           460                                MAE:          32.09
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    101.2140      6.0106       0.001     89.8165    113.4410
       opcount      0.0043      0.0001       0.001      0.0041      0.0045
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.787
Model:                  NNLS                    Adj. R-squared:          0.786
No. Observations:       330                               RMSE:          29.12
Df Residuals:           328                                MAE:          23.59
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    106.6569      5.5718       0.001     96.1738    117.5062
       opcount      0.0028      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.978
Model:                  NNLS                    Adj. R-squared:          0.978
No. Observations:       572                               RMSE:          61.83
Df Residuals:           570                                MAE:          49.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    269.7221      8.2506       0.001    253.7327    285.8648
       opcount      0.0204      0.0001       0.001      0.0202      0.0207
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.635
Model:                  NNLS                    Adj. R-squared:          0.635
No. Observations:       418                               RMSE:          49.91
Df Residuals:           416                                MAE:          37.53
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    156.1924      7.3780       0.001    142.1124    171.7480
       opcount      0.0033      0.0001       0.001      0.0030      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.963
Model:                  NNLS                    Adj. R-squared:          0.963
No. Observations:       418                               RMSE:          18.73
Df Residuals:           416                                MAE:          14.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     94.7426      2.7578       0.001     89.5465     99.8731
       opcount      0.0047      0.0000       0.001      0.0046      0.0048
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## EXTCODEHASH

### test_ext_account_query_warm: combo `EXTCODEHASH`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.8511 | 0.0001285 | 1.00e-03 | [0.0001207, 0.0001363] |
| `erigon` | 231 | 0.9042 | 3.216e-05 | 1.00e-03 | [3.076e-05, 3.356e-05] |
| `ethrex` | 165 | 0.772 | 2.35e-05 | 1.00e-03 | [2.156e-05, 2.548e-05] |
| `geth` | 286 | 0.8853 | 5.795e-05 | 1.00e-03 | [5.529e-05, 6.053e-05] |
| `nethermind` | 209 | 0.7753 | 0.0001387 | 1.00e-03 | [0.0001286, 0.0001499] |
| `reth` | 209 | 0.8827 | 2.018e-05 | 1.00e-03 | [1.919e-05, 2.123e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.851
Model:                  NNLS                    Adj. R-squared:          0.850
No. Observations:       220                               RMSE:          31.44
Df Residuals:           218                                MAE:          23.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    194.3957      6.8726       0.001    181.0801    207.6764
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.904
Model:                  NNLS                    Adj. R-squared:          0.904
No. Observations:       231                               RMSE:           6.12
Df Residuals:           229                                MAE:           5.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     21.7317      1.2781       0.001     19.3208     24.3908
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.772
Model:                  NNLS                    Adj. R-squared:          0.771
No. Observations:       165                               RMSE:           7.47
Df Residuals:           163                                MAE:           6.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.9390      1.6506       0.001      4.8069     11.2924
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.885
Model:                  NNLS                    Adj. R-squared:          0.885
No. Observations:       286                               RMSE:          12.20
Df Residuals:           284                                MAE:           9.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.4801      2.4375       0.001     17.8701     27.5196
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.775
Model:                  NNLS                    Adj. R-squared:          0.774
No. Observations:       209                               RMSE:          43.69
Df Residuals:           207                                MAE:          30.69
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    104.8471     10.2687       0.001     84.2741    123.9922
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.883
Model:                  NNLS                    Adj. R-squared:          0.882
No. Observations:       209                               RMSE:           4.30
Df Residuals:           207                                MAE:           3.39
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.0443      0.9558       0.001      7.2013     10.8600
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODEHASH_AccountMode.EXISTING_EOA`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.974 | 0.01631 | 1.00e-03 | [0.01605, 0.01655] |
| `erigon` | 462 | 0.9898 | 0.00409 | 1.00e-03 | [0.004056, 0.004128] |
| `ethrex` | 330 | 0.4919 | 0.0183 | 1.00e-03 | [0.01644, 0.01957] |
| `geth` | 572 | 0.981 | 0.02097 | 1.00e-03 | [0.02073, 0.02121] |
| `nethermind` | 418 | 0.8313 | 0.003565 | 1.00e-03 | [0.003422, 0.003726] |
| `reth` | 418 | 0.9688 | 0.004916 | 1.00e-03 | [0.00483, 0.005001] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       440                               RMSE:          55.05
Df Residuals:           438                                MAE:          44.80
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    274.7864      7.7654       0.001    260.0327    290.0402
       opcount      0.0163      0.0001       0.001      0.0160      0.0165
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       462                               RMSE:           8.57
Df Residuals:           460                                MAE:           6.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.6402      1.2524       0.001     24.1022     28.9598
       opcount      0.0041      0.0000       0.001      0.0041      0.0041
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.492
Model:                  NNLS                    Adj. R-squared:          0.490
No. Observations:       330                               RMSE:         384.06
Df Residuals:           328                                MAE:         319.34
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     45.6543     47.3431       0.242      0.0000    154.6231
       opcount      0.0183      0.0009       0.001      0.0164      0.0196
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       572                               RMSE:          60.21
Df Residuals:           570                                MAE:          47.00
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    278.1538      7.9787       0.001    262.9837    292.8499
       opcount      0.0210      0.0001       0.001      0.0207      0.0212
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.831
Model:                  NNLS                    Adj. R-squared:          0.831
No. Observations:       418                               RMSE:          33.16
Df Residuals:           416                                MAE:          24.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    129.9887      4.7538       0.001    120.2936    138.6996
       opcount      0.0036      0.0001       0.001      0.0034      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       418                               RMSE:          18.23
Df Residuals:           416                                MAE:          14.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.5478      2.8062       0.001     93.2160    104.0319
       opcount      0.0049      0.0000       0.001      0.0048      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODEHASH_AccountMode.NON_EXISTING_ACCOUNT`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9711 | 0.01525 | 1.00e-03 | [0.01501, 0.01549] |
| `erigon` | 462 | 0.9858 | 0.003348 | 1.00e-03 | [0.003316, 0.003383] |
| `ethrex` | 330 | 0.9513 | 0.002503 | 1.00e-03 | [0.00244, 0.002561] |
| `geth` | 572 | 0.9736 | 0.02023 | 1.00e-03 | [0.01996, 0.0205] |
| `nethermind` | 418 | 0.8222 | 0.00336 | 1.00e-03 | [0.003218, 0.003501] |
| `reth` | 418 | 0.9691 | 0.004795 | 1.00e-03 | [0.004716, 0.004872] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       440                               RMSE:          54.32
Df Residuals:           438                                MAE:          44.46
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    146.1401      7.6222       0.001    131.4082    160.8001
       opcount      0.0152      0.0001       0.001      0.0150      0.0155
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.986
Model:                  NNLS                    Adj. R-squared:          0.986
No. Observations:       462                               RMSE:           8.29
Df Residuals:           460                                MAE:           5.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.7155      1.0389       0.001     12.6010     16.6591
       opcount      0.0033      0.0000       0.001      0.0033      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.951
Model:                  NNLS                    Adj. R-squared:          0.951
No. Observations:       330                               RMSE:          11.70
Df Residuals:           328                                MAE:           9.62
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.7097      2.0439       0.001     19.0424     26.8102
       opcount      0.0025      0.0000       0.001      0.0024      0.0026
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       572                               RMSE:          68.82
Df Residuals:           570                                MAE:          53.23
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    271.5978      8.8343       0.001    254.8421    288.9485
       opcount      0.0202      0.0001       0.001      0.0200      0.0205
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.822
Model:                  NNLS                    Adj. R-squared:          0.822
No. Observations:       418                               RMSE:          32.26
Df Residuals:           416                                MAE:          24.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     66.6557      4.3859       0.001     58.3651     75.5864
       opcount      0.0034      0.0001       0.001      0.0032      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       418                               RMSE:          17.67
Df Residuals:           416                                MAE:          13.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    101.1960      2.4941       0.001     96.4415    106.1145
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODEHASH_AccountMode.EXISTING_CONTRACT_DIFF_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8561 | 0.02343 | 1.00e-03 | [0.02248, 0.02443] |
| `erigon` | 462 | 0.9601 | 0.004367 | 1.00e-03 | [0.004286, 0.004437] |
| `ethrex` | 330 | 0.6477 | 0.01017 | 1.00e-03 | [0.009292, 0.01096] |
| `geth` | 572 | 0.9029 | 0.01733 | 1.00e-03 | [0.01674, 0.01787] |
| `nethermind` | 418 | 0.5757 | 0.002804 | 1.00e-03 | [0.002556, 0.00305] |
| `reth` | 418 | 0.9235 | 0.004852 | 1.00e-03 | [0.004718, 0.004975] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.856
Model:                  NNLS                    Adj. R-squared:          0.856
No. Observations:       440                               RMSE:         195.30
Df Residuals:           438                                MAE:         157.59
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    723.5739     31.5731       0.001    660.0578    780.5321
       opcount      0.0234      0.0005       0.001      0.0225      0.0244
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       462                               RMSE:          18.11
Df Residuals:           460                                MAE:          14.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    170.5658      2.7859       0.001    165.3153    176.4182
       opcount      0.0044      0.0000       0.001      0.0043      0.0044
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.648
Model:                  NNLS                    Adj. R-squared:          0.647
No. Observations:       330                               RMSE:         152.52
Df Residuals:           328                                MAE:         135.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    241.7649     23.7848       0.001    196.4347    289.2357
       opcount      0.0102      0.0004       0.001      0.0093      0.0110
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.903
Model:                  NNLS                    Adj. R-squared:          0.903
No. Observations:       572                               RMSE:         115.55
Df Residuals:           570                                MAE:          88.09
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    402.5313     16.3733       0.001    373.2227    435.3415
       opcount      0.0173      0.0003       0.001      0.0167      0.0179
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.576
Model:                  NNLS                    Adj. R-squared:          0.575
No. Observations:       418                               RMSE:          48.93
Df Residuals:           416                                MAE:          36.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    138.5212      7.3804       0.001    123.5781    152.4426
       opcount      0.0028      0.0001       0.001      0.0026      0.0031
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.923
Model:                  NNLS                    Adj. R-squared:          0.923
No. Observations:       418                               RMSE:          28.40
Df Residuals:           416                                MAE:          22.16
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    119.0901      4.3536       0.001    110.7364    127.4794
       opcount      0.0049      0.0001       0.001      0.0047      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODEHASH_AccountMode.EXISTING_CONTRACT_MINIMAL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9621 | 0.01258 | 1.00e-03 | [0.01236, 0.01282] |
| `erigon` | 462 | 0.9258 | 0.003576 | 1.00e-03 | [0.003492, 0.003667] |
| `ethrex` | 330 | 0.7879 | 0.002686 | 1.00e-03 | [0.002539, 0.002824] |
| `geth` | 572 | 0.9732 | 0.01978 | 1.00e-03 | [0.01951, 0.02006] |
| `nethermind` | 418 | 0.6084 | 0.0028 | 1.00e-03 | [0.002564, 0.003017] |
| `reth` | 418 | 0.9647 | 0.004678 | 1.00e-03 | [0.004596, 0.004763] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.962
Model:                  NNLS                    Adj. R-squared:          0.962
No. Observations:       440                               RMSE:          50.78
Df Residuals:           438                                MAE:          40.64
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    260.6758      7.0738       0.001    246.9331    274.2704
       opcount      0.0126      0.0001       0.001      0.0124      0.0128
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.926
Model:                  NNLS                    Adj. R-squared:          0.926
No. Observations:       462                               RMSE:          20.57
Df Residuals:           460                                MAE:          15.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    173.3827      3.1104       0.001    167.1271    179.5586
       opcount      0.0036      0.0000       0.001      0.0035      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.788
Model:                  NNLS                    Adj. R-squared:          0.787
No. Observations:       330                               RMSE:          28.33
Df Residuals:           328                                MAE:          23.16
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    102.5472      5.2136       0.001     93.0837    113.1767
       opcount      0.0027      0.0001       0.001      0.0025      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.973
Model:                  NNLS                    Adj. R-squared:          0.973
No. Observations:       572                               RMSE:          66.75
Df Residuals:           570                                MAE:          52.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    278.7773      8.6461       0.001    261.8361    295.4235
       opcount      0.0198      0.0001       0.001      0.0195      0.0201
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.608
Model:                  NNLS                    Adj. R-squared:          0.607
No. Observations:       418                               RMSE:          45.67
Df Residuals:           416                                MAE:          34.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    139.9984      6.6011       0.001    127.1480    154.6333
       opcount      0.0028      0.0001       0.001      0.0026      0.0030
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.965
Model:                  NNLS                    Adj. R-squared:          0.965
No. Observations:       418                               RMSE:          18.19
Df Residuals:           416                                MAE:          14.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     89.8902      2.5773       0.001     84.7579     94.7738
       opcount      0.0047      0.0000       0.001      0.0046      0.0048
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODEHASH_AccountMode.EXISTING_CONTRACT_SAME_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9605 | 0.01252 | 1.00e-03 | [0.01227, 0.01277] |
| `erigon` | 462 | 0.8184 | 0.004026 | 1.00e-03 | [0.003855, 0.00419] |
| `ethrex` | 330 | 0.7709 | 0.00262 | 1.00e-03 | [0.002473, 0.002786] |
| `geth` | 572 | 0.9736 | 0.02003 | 1.00e-03 | [0.01974, 0.02033] |
| `nethermind` | 418 | 0.6106 | 0.002799 | 1.00e-03 | [0.002592, 0.003025] |
| `reth` | 418 | 0.9639 | 0.004679 | 1.00e-03 | [0.004591, 0.004766] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       440                               RMSE:          51.65
Df Residuals:           438                                MAE:          40.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    261.0389      7.4270       0.001    246.7476    276.0298
       opcount      0.0125      0.0001       0.001      0.0123      0.0128
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.818
Model:                  NNLS                    Adj. R-squared:          0.818
No. Observations:       462                               RMSE:          38.55
Df Residuals:           460                                MAE:          32.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    119.3966      6.1556       0.001    107.2996    131.2626
       opcount      0.0040      0.0001       0.001      0.0039      0.0042
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.771
Model:                  NNLS                    Adj. R-squared:          0.770
No. Observations:       330                               RMSE:          29.04
Df Residuals:           328                                MAE:          23.67
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    107.6396      5.5902       0.001     96.9244    117.8005
       opcount      0.0026      0.0001       0.001      0.0025      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       572                               RMSE:          67.11
Df Residuals:           570                                MAE:          53.49
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    267.1650      9.1017       0.001    249.7590    285.9491
       opcount      0.0200      0.0001       0.001      0.0197      0.0203
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.611
Model:                  NNLS                    Adj. R-squared:          0.610
No. Observations:       418                               RMSE:          45.44
Df Residuals:           416                                MAE:          33.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    137.2550      5.9647       0.001    125.7076    148.3134
       opcount      0.0028      0.0001       0.001      0.0026      0.0030
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.964
Model:                  NNLS                    Adj. R-squared:          0.964
No. Observations:       418                               RMSE:          18.40
Df Residuals:           416                                MAE:          14.30
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     91.0228      2.7758       0.001     85.4540     96.6002
       opcount      0.0047      0.0000       0.001      0.0046      0.0048
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## EXTCODESIZE

### test_ext_account_query_warm: combo `EXTCODESIZE`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.8439 | 0.0001894 | 1.00e-03 | [0.0001778, 0.0002004] |
| `erigon` | 231 | 0.6408 | 1.794e-05 | 1.00e-03 | [1.616e-05, 1.962e-05] |
| `ethrex` | 165 | 0.7163 | 2.522e-05 | 1.00e-03 | [2.277e-05, 2.75e-05] |
| `geth` | 286 | 0.6971 | 4.296e-05 | 1.00e-03 | [3.999e-05, 4.599e-05] |
| `nethermind` | 209 | 0.755 | 0.000118 | 1.00e-03 | [0.0001086, 0.0001282] |
| `reth` | 209 | 0.7693 | 1.586e-05 | 1.00e-03 | [1.478e-05, 1.697e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.844
Model:                  NNLS                    Adj. R-squared:          0.843
No. Observations:       220                               RMSE:          24.74
Df Residuals:           218                                MAE:          19.32
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    125.1065      5.7348       0.001    113.8886    136.7279
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.641
Model:                  NNLS                    Adj. R-squared:          0.639
No. Observations:       231                               RMSE:           4.08
Df Residuals:           229                                MAE:           3.47
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.4137      0.8041       0.001     12.9440     16.0032
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.716
Model:                  NNLS                    Adj. R-squared:          0.715
No. Observations:       165                               RMSE:           4.82
Df Residuals:           163                                MAE:           4.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.4975      1.1324       0.001      5.4048      9.8291
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.697
Model:                  NNLS                    Adj. R-squared:          0.696
No. Observations:       286                               RMSE:           8.60
Df Residuals:           284                                MAE:           5.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     17.2277      1.6868       0.001     14.0325     20.5489
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.755
Model:                  NNLS                    Adj. R-squared:          0.754
No. Observations:       209                               RMSE:          20.43
Df Residuals:           207                                MAE:          14.75
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.0871      4.2654       0.001      7.4519     24.5479
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.769
Model:                  NNLS                    Adj. R-squared:          0.768
No. Observations:       209                               RMSE:           2.64
Df Residuals:           207                                MAE:           2.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      5.7685      0.4957       0.001      4.7369      6.7392
       opcount      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODESIZE_AccountMode.EXISTING_EOA`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9758 | 0.01643 | 1.00e-03 | [0.01617, 0.01667] |
| `erigon` | 462 | 0.9891 | 0.003663 | 1.00e-03 | [0.003627, 0.003705] |
| `ethrex` | 330 | 0.4837 | 0.01808 | 1.00e-03 | [0.01593, 0.01959] |
| `geth` | 572 | 0.9784 | 0.02118 | 1.00e-03 | [0.02093, 0.02145] |
| `nethermind` | 418 | 0.8384 | 0.003584 | 1.00e-03 | [0.00344, 0.003731] |
| `reth` | 418 | 0.9673 | 0.004959 | 1.00e-03 | [0.004864, 0.00505] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.976
Model:                  NNLS                    Adj. R-squared:          0.976
No. Observations:       440                               RMSE:          51.76
Df Residuals:           438                                MAE:          42.11
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    267.7389      7.6431       0.001    252.8884    282.9968
       opcount      0.0164      0.0001       0.001      0.0162      0.0167
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.989
Model:                  NNLS                    Adj. R-squared:          0.989
No. Observations:       462                               RMSE:           7.68
Df Residuals:           460                                MAE:           5.54
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.4688      1.1138       0.001     14.0173     18.5376
       opcount      0.0037      0.0000       0.001      0.0036      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.484
Model:                  NNLS                    Adj. R-squared:          0.482
No. Observations:       330                               RMSE:         373.54
Df Residuals:           328                                MAE:         312.37
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     61.9643     53.1722       0.163      0.0000    179.8895
       opcount      0.0181      0.0010       0.001      0.0159      0.0196
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.978
Model:                  NNLS                    Adj. R-squared:          0.978
No. Observations:       572                               RMSE:          62.99
Df Residuals:           570                                MAE:          49.91
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    263.5669      8.3799       0.001    246.6943    280.6929
       opcount      0.0212      0.0001       0.001      0.0209      0.0214
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.838
No. Observations:       418                               RMSE:          31.46
Df Residuals:           416                                MAE:          24.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    127.1797      4.2853       0.001    118.7956    135.5866
       opcount      0.0036      0.0001       0.001      0.0034      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.967
Model:                  NNLS                    Adj. R-squared:          0.967
No. Observations:       418                               RMSE:          18.22
Df Residuals:           416                                MAE:          14.34
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     93.5835      2.8294       0.001     88.2550     99.5244
       opcount      0.0050      0.0000       0.001      0.0049      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODESIZE_AccountMode.NON_EXISTING_ACCOUNT`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9706 | 0.01524 | 1.00e-03 | [0.015, 0.01549] |
| `erigon` | 462 | 0.9905 | 0.003299 | 1.00e-03 | [0.003271, 0.003325] |
| `ethrex` | 330 | 0.9498 | 0.002534 | 1.00e-03 | [0.002476, 0.002594] |
| `geth` | 572 | 0.9743 | 0.02027 | 1.00e-03 | [0.02, 0.02053] |
| `nethermind` | 418 | 0.816 | 0.003187 | 1.00e-03 | [0.003034, 0.003346] |
| `reth` | 418 | 0.9741 | 0.00493 | 1.00e-03 | [0.004851, 0.005012] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       440                               RMSE:          53.04
Df Residuals:           438                                MAE:          43.39
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    140.7940      7.6116       0.001    125.6895    154.7267
       opcount      0.0152      0.0001       0.001      0.0150      0.0155
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.991
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       462                               RMSE:           6.46
Df Residuals:           460                                MAE:           4.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.1784      0.8234       0.001     13.6162     16.8044
       opcount      0.0033      0.0000       0.001      0.0033      0.0033
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.950
Model:                  NNLS                    Adj. R-squared:          0.950
No. Observations:       330                               RMSE:          11.65
Df Residuals:           328                                MAE:           9.23
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     21.5003      1.8600       0.001     17.8260     24.9415
       opcount      0.0025      0.0000       0.001      0.0025      0.0026
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       572                               RMSE:          65.78
Df Residuals:           570                                MAE:          53.02
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    273.5467      8.3746       0.001    257.4562    290.8120
       opcount      0.0203      0.0001       0.001      0.0200      0.0205
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.816
Model:                  NNLS                    Adj. R-squared:          0.816
No. Observations:       418                               RMSE:          30.26
Df Residuals:           416                                MAE:          21.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     72.0730      4.4618       0.001     63.4524     81.0912
       opcount      0.0032      0.0001       0.001      0.0030      0.0033
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       418                               RMSE:          16.08
Df Residuals:           416                                MAE:          12.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     93.9410      2.3443       0.001     89.1259     98.6581
       opcount      0.0049      0.0000       0.001      0.0049      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODESIZE_AccountMode.EXISTING_CONTRACT_DIFF_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8597 | 0.02336 | 1.00e-03 | [0.0224, 0.02431] |
| `erigon` | 462 | 0.9099 | 0.005836 | 1.00e-03 | [0.005687, 0.005981] |
| `ethrex` | 330 | 0.6688 | 0.01044 | 1.00e-03 | [0.009586, 0.01128] |
| `geth` | 572 | 0.7747 | 0.04658 | 1.00e-03 | [0.0446, 0.04858] |
| `nethermind` | 418 | 0.4722 | 0.02096 | 1.00e-03 | [0.01878, 0.02293] |
| `reth` | 418 | 0.3862 | 0.04041 | 1.00e-03 | [0.03524, 0.04447] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.860
Model:                  NNLS                    Adj. R-squared:          0.859
No. Observations:       440                               RMSE:         185.85
Df Residuals:           438                                MAE:         149.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    720.5326     30.0000       0.001    663.4737    781.3791
       opcount      0.0234      0.0005       0.001      0.0224      0.0243
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.910
Model:                  NNLS                    Adj. R-squared:          0.910
No. Observations:       462                               RMSE:          36.17
Df Residuals:           460                                MAE:          29.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    385.8708      5.1623       0.001    375.8458    396.0348
       opcount      0.0058      0.0001       0.001      0.0057      0.0060
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.669
Model:                  NNLS                    Adj. R-squared:          0.668
No. Observations:       330                               RMSE:         144.71
Df Residuals:           328                                MAE:         128.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    267.8748     23.3946       0.001    221.2326    313.3078
       opcount      0.0104      0.0004       0.001      0.0096      0.0113
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.775
Model:                  NNLS                    Adj. R-squared:          0.774
No. Observations:       572                               RMSE:         494.77
Df Residuals:           570                                MAE:         439.86
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const   1336.3481     69.3800       0.001   1205.1623   1468.7251
       opcount      0.0466      0.0011       0.001      0.0446      0.0486
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.472
Model:                  NNLS                    Adj. R-squared:          0.471
No. Observations:       418                               RMSE:         436.56
Df Residuals:           416                                MAE:         387.70
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    623.1554     64.8152       0.001    496.6354    752.6791
       opcount      0.0210      0.0011       0.001      0.0188      0.0229
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.386
Model:                  NNLS                    Adj. R-squared:          0.385
No. Observations:       418                               RMSE:        1003.53
Df Residuals:           416                                MAE:         954.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    174.1298    124.5351       0.095      0.0000    440.4161
       opcount      0.0404      0.0023       0.001      0.0352      0.0445
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODESIZE_AccountMode.EXISTING_CONTRACT_MINIMAL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9604 | 0.01261 | 1.00e-03 | [0.01237, 0.01287] |
| `erigon` | 462 | 0.9251 | 0.003504 | 1.00e-03 | [0.003427, 0.003581] |
| `ethrex` | 330 | 0.7902 | 0.002692 | 1.00e-03 | [0.002555, 0.002842] |
| `geth` | 572 | 0.9764 | 0.02 | 1.00e-03 | [0.01975, 0.02025] |
| `nethermind` | 418 | 0.6271 | 0.002713 | 1.00e-03 | [0.002513, 0.00294] |
| `reth` | 418 | 0.967 | 0.00478 | 1.00e-03 | [0.004695, 0.004872] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       440                               RMSE:          50.42
Df Residuals:           438                                MAE:          40.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    257.8284      7.4434       0.001    243.2532    272.9052
       opcount      0.0126      0.0001       0.001      0.0124      0.0129
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.925
Model:                  NNLS                    Adj. R-squared:          0.925
No. Observations:       462                               RMSE:          19.64
Df Residuals:           460                                MAE:          15.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    158.4391      2.7790       0.001    152.9743    163.6142
       opcount      0.0035      0.0000       0.001      0.0034      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.790
Model:                  NNLS                    Adj. R-squared:          0.790
No. Observations:       330                               RMSE:          27.33
Df Residuals:           328                                MAE:          21.91
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    101.7647      4.9705       0.001     91.3372    111.2395
       opcount      0.0027      0.0001       0.001      0.0026      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.976
Model:                  NNLS                    Adj. R-squared:          0.976
No. Observations:       572                               RMSE:          61.28
Df Residuals:           570                                MAE:          49.12
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    270.5553      8.0299       0.001    255.4286    286.0227
       opcount      0.0200      0.0001       0.001      0.0198      0.0203
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.627
Model:                  NNLS                    Adj. R-squared:          0.626
No. Observations:       418                               RMSE:          41.21
Df Residuals:           416                                MAE:          29.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    143.1166      6.2908       0.001    130.8457    155.1949
       opcount      0.0027      0.0001       0.001      0.0025      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.967
Model:                  NNLS                    Adj. R-squared:          0.967
No. Observations:       418                               RMSE:          17.39
Df Residuals:           416                                MAE:          13.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     83.2884      2.4918       0.001     78.4542     88.3054
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODESIZE_AccountMode.EXISTING_CONTRACT_SAME_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9615 | 0.01253 | 1.00e-03 | [0.01226, 0.01276] |
| `erigon` | 462 | 0.8302 | 0.003829 | 1.00e-03 | [0.003662, 0.003988] |
| `ethrex` | 330 | 0.7945 | 0.002762 | 1.00e-03 | [0.002603, 0.002917] |
| `geth` | 572 | 0.9754 | 0.02002 | 1.00e-03 | [0.01977, 0.02027] |
| `nethermind` | 418 | 0.6444 | 0.002964 | 1.00e-03 | [0.002755, 0.003206] |
| `reth` | 418 | 0.9617 | 0.004735 | 1.00e-03 | [0.004647, 0.004827] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.962
Model:                  NNLS                    Adj. R-squared:          0.961
No. Observations:       440                               RMSE:          49.38
Df Residuals:           438                                MAE:          39.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    263.9092      7.3664       0.001    250.5057    279.0117
       opcount      0.0125      0.0001       0.001      0.0123      0.0128
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.830
Model:                  NNLS                    Adj. R-squared:          0.830
No. Observations:       462                               RMSE:          34.11
Df Residuals:           460                                MAE:          29.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    106.8643      5.3313       0.001     96.5723    117.7704
       opcount      0.0038      0.0001       0.001      0.0037      0.0040
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.794
Model:                  NNLS                    Adj. R-squared:          0.794
No. Observations:       330                               RMSE:          27.67
Df Residuals:           328                                MAE:          22.64
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.2647      5.3973       0.001     87.4601    108.4783
       opcount      0.0028      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.975
Model:                  NNLS                    Adj. R-squared:          0.975
No. Observations:       572                               RMSE:          62.59
Df Residuals:           570                                MAE:          50.20
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    268.4104      7.8133       0.001    253.1039    283.5007
       opcount      0.0200      0.0001       0.001      0.0198      0.0203
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.644
Model:                  NNLS                    Adj. R-squared:          0.644
No. Observations:       418                               RMSE:          43.36
Df Residuals:           416                                MAE:          31.00
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    131.1863      6.4663       0.001    117.8075    143.1470
       opcount      0.0030      0.0001       0.001      0.0028      0.0032
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.962
Model:                  NNLS                    Adj. R-squared:          0.962
No. Observations:       418                               RMSE:          18.61
Df Residuals:           416                                MAE:          14.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     88.6430      2.6478       0.001     83.7906     93.9727
       opcount      0.0047      0.0000       0.001      0.0046      0.0048
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## STATICCALL

### test_ext_account_query_warm: combo `STATICCALL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 220 | 0.9144 | 0.0005886 | 1.00e-03 | [0.000565, 0.0006126] |
| `erigon` | 231 | 0.875 | 7.494e-05 | 1.00e-03 | [7.127e-05, 7.889e-05] |
| `ethrex` | 165 | 0.904 | 0.0001261 | 1.00e-03 | [0.0001192, 0.0001329] |
| `geth` | 286 | 0.9352 | 0.0002371 | 1.00e-03 | [0.0002296, 0.0002438] |
| `nethermind` | 209 | 0.5078 | 0.0002206 | 1.00e-03 | [0.0001929, 0.0002517] |
| `reth` | 209 | 0.9567 | 7.632e-05 | 1.00e-03 | [7.397e-05, 7.862e-05] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.914
Model:                  NNLS                    Adj. R-squared:          0.914
No. Observations:       220                               RMSE:          93.27
Df Residuals:           218                                MAE:          74.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    598.8605     20.0705       0.001    558.9127    638.2501
       opcount      0.0006      0.0000       0.001      0.0006      0.0006
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.875
Model:                  NNLS                    Adj. R-squared:          0.874
No. Observations:       231                               RMSE:          14.67
Df Residuals:           229                                MAE:          13.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     25.1862      2.7997       0.001     19.3270     30.4682
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.904
Model:                  NNLS                    Adj. R-squared:          0.903
No. Observations:       165                               RMSE:          21.28
Df Residuals:           163                                MAE:          17.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     30.8760      5.2254       0.001     20.6664     40.9330
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.935
Model:                  NNLS                    Adj. R-squared:          0.935
No. Observations:       286                               RMSE:          32.31
Df Residuals:           284                                MAE:          26.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     61.3000      5.3640       0.001     51.7173     72.1612
       opcount      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.508
Model:                  NNLS                    Adj. R-squared:          0.505
No. Observations:       209                               RMSE:         112.46
Df Residuals:           207                                MAE:          92.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    147.9461     23.0500       0.001    102.2882    189.0964
       opcount      0.0002      0.0000       0.001      0.0002      0.0003
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.957
Model:                  NNLS                    Adj. R-squared:          0.957
No. Observations:       209                               RMSE:           8.41
Df Residuals:           207                                MAE:           6.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     29.5289      1.8851       0.001     25.8994     33.2737
       opcount      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `STATICCALL_AccountMode.EXISTING_EOA`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9713 | 0.01831 | 1.00e-03 | [0.01801, 0.0186] |
| `erigon` | 462 | 0.9902 | 0.004209 | 1.00e-03 | [0.004173, 0.004244] |
| `ethrex` | 330 | 0.4901 | 0.01839 | 1.00e-03 | [0.01639, 0.01973] |
| `geth` | 572 | 0.9804 | 0.02135 | 1.00e-03 | [0.0211, 0.02161] |
| `nethermind` | 418 | 0.8379 | 0.003702 | 1.00e-03 | [0.003543, 0.003854] |
| `reth` | 418 | 0.9702 | 0.005317 | 1.00e-03 | [0.005226, 0.005411] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       440                               RMSE:          64.69
Df Residuals:           438                                MAE:          51.98
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    404.6261      9.2592       0.001    387.3545    422.1610
       opcount      0.0183      0.0002       0.001      0.0180      0.0186
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       462                               RMSE:           8.62
Df Residuals:           460                                MAE:           6.45
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     24.9208      1.1805       0.001     22.6771     27.2406
       opcount      0.0042      0.0000       0.001      0.0042      0.0042
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.490
Model:                  NNLS                    Adj. R-squared:          0.489
No. Observations:       330                               RMSE:         385.64
Df Residuals:           328                                MAE:         320.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     50.4954     50.6703       0.234      0.0000    160.8665
       opcount      0.0184      0.0009       0.001      0.0164      0.0197
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       572                               RMSE:          62.08
Df Residuals:           570                                MAE:          47.41
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    276.8771      8.2980       0.001    260.3310    292.9112
       opcount      0.0214      0.0001       0.001      0.0211      0.0216
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.838
Model:                  NNLS                    Adj. R-squared:          0.838
No. Observations:       418                               RMSE:          33.47
Df Residuals:           416                                MAE:          25.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.5728      4.8721       0.001    123.7634    142.0139
       opcount      0.0037      0.0001       0.001      0.0035      0.0039
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.970
No. Observations:       418                               RMSE:          19.16
Df Residuals:           416                                MAE:          14.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.3573      2.8457       0.001     92.8533    103.9081
       opcount      0.0053      0.0000       0.001      0.0052      0.0054
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `STATICCALL_AccountMode.NON_EXISTING_ACCOUNT`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9677 | 0.0187 | 1.00e-03 | [0.01838, 0.01901] |
| `erigon` | 462 | 0.9884 | 0.004179 | 1.00e-03 | [0.004137, 0.004218] |
| `ethrex` | 330 | 0.959 | 0.002614 | 1.00e-03 | [0.002552, 0.00267] |
| `geth` | 572 | 0.9819 | 0.02164 | 1.00e-03 | [0.02142, 0.02186] |
| `nethermind` | 418 | 0.8006 | 0.003367 | 1.00e-03 | [0.003207, 0.003547] |
| `reth` | 418 | 0.9722 | 0.004975 | 1.00e-03 | [0.004892, 0.005054] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.968
Model:                  NNLS                    Adj. R-squared:          0.968
No. Observations:       440                               RMSE:          70.26
Df Residuals:           438                                MAE:          57.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    352.4776      9.5866       0.001    333.3426    370.3938
       opcount      0.0187      0.0002       0.001      0.0184      0.0190
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.988
Model:                  NNLS                    Adj. R-squared:          0.988
No. Observations:       462                               RMSE:           9.29
Df Residuals:           460                                MAE:           7.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     25.0895      1.3095       0.001     22.5209     27.6113
       opcount      0.0042      0.0000       0.001      0.0041      0.0042
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.959
Model:                  NNLS                    Adj. R-squared:          0.959
No. Observations:       330                               RMSE:          11.12
Df Residuals:           328                                MAE:           9.06
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.4294      1.8178       0.001     18.8647     26.1502
       opcount      0.0026      0.0000       0.001      0.0026      0.0027
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.982
Model:                  NNLS                    Adj. R-squared:          0.982
No. Observations:       572                               RMSE:          60.30
Df Residuals:           570                                MAE:          46.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    276.6309      7.3204       0.001    262.2440    290.0066
       opcount      0.0216      0.0001       0.001      0.0214      0.0219
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.801
Model:                  NNLS                    Adj. R-squared:          0.800
No. Observations:       418                               RMSE:          34.54
Df Residuals:           416                                MAE:          26.71
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     74.6352      5.0752       0.001     64.2738     84.0944
       opcount      0.0034      0.0001       0.001      0.0032      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.972
Model:                  NNLS                    Adj. R-squared:          0.972
No. Observations:       418                               RMSE:          17.31
Df Residuals:           416                                MAE:          13.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     98.4068      2.5801       0.001     93.8817    103.6828
       opcount      0.0050      0.0000       0.001      0.0049      0.0051
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `STATICCALL_AccountMode.EXISTING_CONTRACT_DIFF_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8696 | 0.02792 | 1.00e-03 | [0.02686, 0.02892] |
| `erigon` | 462 | 0.5374 | 0.01533 | 1.00e-03 | [0.01404, 0.01654] |
| `ethrex` | 330 | 0.6389 | 0.01026 | 1.00e-03 | [0.009454, 0.01119] |
| `geth` | 572 | 0.7791 | 0.04556 | 1.00e-03 | [0.04362, 0.04757] |
| `nethermind` | 418 | 0.4815 | 0.02194 | 1.00e-03 | [0.0198, 0.02423] |
| `reth` | 418 | 0.4016 | 0.04191 | 1.00e-03 | [0.03679, 0.04571] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.870
Model:                  NNLS                    Adj. R-squared:          0.869
No. Observations:       440                               RMSE:         218.80
Df Residuals:           438                                MAE:         178.33
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    791.0377     32.4397       0.001    733.2364    856.7839
       opcount      0.0279      0.0005       0.001      0.0269      0.0289
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.537
Model:                  NNLS                    Adj. R-squared:          0.536
No. Observations:       462                               RMSE:         287.93
Df Residuals:           460                                MAE:         262.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    365.9736     35.1301       0.001    299.6393    436.6470
       opcount      0.0153      0.0006       0.001      0.0140      0.0165
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.639
Model:                  NNLS                    Adj. R-squared:          0.638
No. Observations:       330                               RMSE:         156.15
Df Residuals:           328                                MAE:         133.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    240.6000     25.3827       0.001    191.3222    288.8030
       opcount      0.0103      0.0005       0.001      0.0095      0.0112
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.779
Model:                  NNLS                    Adj. R-squared:          0.779
No. Observations:       572                               RMSE:         491.05
Df Residuals:           570                                MAE:         433.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const   1448.8191     70.8532       0.001   1305.5569   1585.4470
       opcount      0.0456      0.0010       0.001      0.0436      0.0476
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.481
Model:                  NNLS                    Adj. R-squared:          0.480
No. Observations:       418                               RMSE:         460.74
Df Residuals:           416                                MAE:         405.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    698.1286     70.9792       0.001    553.4103    833.2782
       opcount      0.0219      0.0011       0.001      0.0198      0.0242
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.402
Model:                  NNLS                    Adj. R-squared:          0.400
No. Observations:       418                               RMSE:        1035.62
Df Residuals:           416                                MAE:         984.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    153.9713    126.2823       0.164      0.0000    436.1604
       opcount      0.0419      0.0023       0.001      0.0368      0.0457
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `STATICCALL_AccountMode.EXISTING_CONTRACT_MINIMAL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9565 | 0.01348 | 1.00e-03 | [0.01321, 0.01376] |
| `erigon` | 462 | 0.9515 | 0.004118 | 1.00e-03 | [0.004036, 0.004194] |
| `ethrex` | 330 | 0.7935 | 0.002762 | 1.00e-03 | [0.00261, 0.00292] |
| `geth` | 572 | 0.9759 | 0.02031 | 1.00e-03 | [0.02006, 0.02056] |
| `nethermind` | 418 | 0.613 | 0.003096 | 1.00e-03 | [0.002824, 0.003343] |
| `reth` | 418 | 0.9689 | 0.005192 | 1.00e-03 | [0.005106, 0.005283] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.956
Model:                  NNLS                    Adj. R-squared:          0.956
No. Observations:       440                               RMSE:          58.20
Df Residuals:           438                                MAE:          47.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    386.9079      9.0658       0.001    369.1919    404.8480
       opcount      0.0135      0.0001       0.001      0.0132      0.0138
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.951
Model:                  NNLS                    Adj. R-squared:          0.951
No. Observations:       462                               RMSE:          18.82
Df Residuals:           460                                MAE:          14.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    174.9080      2.6050       0.001    169.9799    180.2348
       opcount      0.0041      0.0000       0.001      0.0040      0.0042
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.794
Model:                  NNLS                    Adj. R-squared:          0.793
No. Observations:       330                               RMSE:          28.51
Df Residuals:           328                                MAE:          22.86
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    106.4865      5.6137       0.001     95.5765    117.1108
       opcount      0.0028      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.976
Model:                  NNLS                    Adj. R-squared:          0.976
No. Observations:       572                               RMSE:          64.61
Df Residuals:           570                                MAE:          49.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    277.0536      7.8915       0.001    261.6147    292.7438
       opcount      0.0203      0.0001       0.001      0.0201      0.0206
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.613
Model:                  NNLS                    Adj. R-squared:          0.612
No. Observations:       418                               RMSE:          49.78
Df Residuals:           416                                MAE:          37.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    165.2922      7.4360       0.001    151.6971    181.1135
       opcount      0.0031      0.0001       0.001      0.0028      0.0033
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       418                               RMSE:          18.83
Df Residuals:           416                                MAE:          14.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.2049      2.7862       0.001     86.7121     97.6317
       opcount      0.0052      0.0000       0.001      0.0051      0.0053
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `STATICCALL_AccountMode.EXISTING_CONTRACT_SAME_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9508 | 0.01339 | 1.00e-03 | [0.0131, 0.01368] |
| `erigon` | 462 | 0.8501 | 0.004567 | 1.00e-03 | [0.004393, 0.004735] |
| `ethrex` | 330 | 0.7847 | 0.002765 | 1.00e-03 | [0.002609, 0.002934] |
| `geth` | 572 | 0.9773 | 0.0203 | 1.00e-03 | [0.02006, 0.02053] |
| `nethermind` | 418 | 0.6208 | 0.003282 | 1.00e-03 | [0.003032, 0.003556] |
| `reth` | 418 | 0.9643 | 0.005215 | 1.00e-03 | [0.005117, 0.005313] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.951
Model:                  NNLS                    Adj. R-squared:          0.951
No. Observations:       440                               RMSE:          61.64
Df Residuals:           438                                MAE:          50.99
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    392.3994      9.4879       0.001    374.3044    410.8712
       opcount      0.0134      0.0002       0.001      0.0131      0.0137
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.850
Model:                  NNLS                    Adj. R-squared:          0.850
No. Observations:       462                               RMSE:          38.81
Df Residuals:           460                                MAE:          33.45
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    116.8022      5.9846       0.001    105.3236    128.3490
       opcount      0.0046      0.0001       0.001      0.0044      0.0047
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.785
Model:                  NNLS                    Adj. R-squared:          0.784
No. Observations:       330                               RMSE:          29.31
Df Residuals:           328                                MAE:          24.21
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    106.7796      5.6250       0.001     95.4962    117.8850
       opcount      0.0028      0.0001       0.001      0.0026      0.0029
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       572                               RMSE:          62.60
Df Residuals:           570                                MAE:          49.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    278.7641      7.6777       0.001    263.5291    294.0613
       opcount      0.0203      0.0001       0.001      0.0201      0.0205
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.621
Model:                  NNLS                    Adj. R-squared:          0.620
No. Observations:       418                               RMSE:          51.91
Df Residuals:           416                                MAE:          39.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    151.0690      7.7081       0.001    135.4717    165.9803
       opcount      0.0033      0.0001       0.001      0.0030      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.964
Model:                  NNLS                    Adj. R-squared:          0.964
No. Observations:       418                               RMSE:          20.31
Df Residuals:           416                                MAE:          15.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     92.4673      2.8698       0.001     87.1883     98.1757
       opcount      0.0052      0.0000       0.001      0.0051      0.0053
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## EXTCODECOPY

### test_account_access: combo `EXTCODECOPY_AccountMode.EXISTING_EOA`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.974 | 0.01645 | 1.00e-03 | [0.01621, 0.01671] |
| `erigon` | 462 | 0.9904 | 0.003592 | 1.00e-03 | [0.003563, 0.003621] |
| `ethrex` | 330 | 0.491 | 0.01847 | 1.00e-03 | [0.01645, 0.01968] |
| `geth` | 572 | 0.9787 | 0.02156 | 1.00e-03 | [0.0213, 0.02182] |
| `nethermind` | 418 | 0.8446 | 0.003581 | 1.00e-03 | [0.003427, 0.003731] |
| `reth` | 418 | 0.9689 | 0.004999 | 1.00e-03 | [0.00492, 0.005088] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       440                               RMSE:          52.01
Df Residuals:           438                                MAE:          42.59
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    269.8657      7.1473       0.001    255.9148    284.4734
       opcount      0.0165      0.0001       0.001      0.0162      0.0167
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.990
Model:                  NNLS                    Adj. R-squared:          0.990
No. Observations:       462                               RMSE:           6.86
Df Residuals:           460                                MAE:           5.41
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     22.7242      0.9194       0.001     20.9691     24.5093
       opcount      0.0036      0.0000       0.001      0.0036      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.491
Model:                  NNLS                    Adj. R-squared:          0.489
No. Observations:       330                               RMSE:         364.22
Df Residuals:           328                                MAE:         302.61
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     39.8975     44.1204       0.251      0.0000    144.8905
       opcount      0.0185      0.0009       0.001      0.0164      0.0197
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.979
Model:                  NNLS                    Adj. R-squared:          0.979
No. Observations:       572                               RMSE:          61.61
Df Residuals:           570                                MAE:          49.28
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    263.6800      8.3110       0.001    247.6237    279.6874
       opcount      0.0216      0.0001       0.001      0.0213      0.0218
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.845
Model:                  NNLS                    Adj. R-squared:          0.844
No. Observations:       418                               RMSE:          29.75
Df Residuals:           416                                MAE:          22.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    132.2643      4.2832       0.001    124.1066    140.5328
       opcount      0.0036      0.0001       0.001      0.0034      0.0037
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       418                               RMSE:          17.34
Df Residuals:           416                                MAE:          13.65
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     93.8614      2.5681       0.001     88.8587     98.5432
       opcount      0.0050      0.0000       0.001      0.0049      0.0051
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODECOPY_AccountMode.NON_EXISTING_ACCOUNT`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9715 | 0.01538 | 1.00e-03 | [0.01515, 0.01562] |
| `erigon` | 462 | 0.991 | 0.003357 | 1.00e-03 | [0.003324, 0.00339] |
| `ethrex` | 330 | 0.9532 | 0.002529 | 1.00e-03 | [0.00247, 0.002585] |
| `geth` | 572 | 0.9739 | 0.02049 | 1.00e-03 | [0.02024, 0.02076] |
| `nethermind` | 418 | 0.8212 | 0.003348 | 1.00e-03 | [0.003206, 0.003502] |
| `reth` | 418 | 0.9641 | 0.004901 | 1.00e-03 | [0.004811, 0.00499] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       440                               RMSE:          51.05
Df Residuals:           438                                MAE:          42.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    140.5260      7.0799       0.001    127.0215    154.5852
       opcount      0.0154      0.0001       0.001      0.0152      0.0156
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.991
Model:                  NNLS                    Adj. R-squared:          0.991
No. Observations:       462                               RMSE:           6.21
Df Residuals:           460                                MAE:           4.50
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     11.9682      0.9285       0.001      9.9914     13.8005
       opcount      0.0034      0.0000       0.001      0.0033      0.0034
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.953
Model:                  NNLS                    Adj. R-squared:          0.953
No. Observations:       330                               RMSE:          10.85
Df Residuals:           328                                MAE:           8.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     21.1851      1.7625       0.001     17.8879     24.5447
       opcount      0.0025      0.0000       0.001      0.0025      0.0026
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       572                               RMSE:          64.97
Df Residuals:           570                                MAE:          52.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    283.9854      8.1729       0.001    267.9496    300.0064
       opcount      0.0205      0.0001       0.001      0.0202      0.0208
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.821
Model:                  NNLS                    Adj. R-squared:          0.821
No. Observations:       418                               RMSE:          30.25
Df Residuals:           416                                MAE:          22.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     71.0033      4.2075       0.001     63.0133     78.9794
       opcount      0.0033      0.0001       0.001      0.0032      0.0035
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.964
Model:                  NNLS                    Adj. R-squared:          0.964
No. Observations:       418                               RMSE:          18.31
Df Residuals:           416                                MAE:          13.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     95.2387      2.6174       0.001     90.1245    100.4564
       opcount      0.0049      0.0000       0.001      0.0048      0.0050
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODECOPY_AccountMode.EXISTING_CONTRACT_DIFF_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.8583 | 0.0239 | 1.00e-03 | [0.0229, 0.0249] |
| `erigon` | 462 | 0.533 | 0.01463 | 1.00e-03 | [0.0135, 0.01587] |
| `ethrex` | 330 | 0.6335 | 0.01015 | 1.00e-03 | [0.009332, 0.01102] |
| `geth` | 572 | 0.7657 | 0.0465 | 1.00e-03 | [0.04448, 0.04845] |
| `nethermind` | 418 | 0.4772 | 0.02111 | 1.00e-03 | [0.01918, 0.0231] |
| `reth` | 418 | 0.3865 | 0.04043 | 1.00e-03 | [0.03547, 0.04435] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.858
Model:                  NNLS                    Adj. R-squared:          0.858
No. Observations:       440                               RMSE:         185.33
Df Residuals:           438                                MAE:         152.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    703.4240     29.3542       0.001    648.0677    762.6638
       opcount      0.0239      0.0005       0.001      0.0229      0.0249
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.533
Model:                  NNLS                    Adj. R-squared:          0.532
No. Observations:       462                               RMSE:         261.42
Df Residuals:           460                                MAE:         241.06
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    345.1788     32.1962       0.001    280.5012    402.4086
       opcount      0.0146      0.0006       0.001      0.0135      0.0159
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.633
Model:                  NNLS                    Adj. R-squared:          0.632
No. Observations:       330                               RMSE:         147.36
Df Residuals:           328                                MAE:         124.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    239.1725     23.0532       0.001    193.7617    283.9903
       opcount      0.0102      0.0004       0.001      0.0093      0.0110
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.766
Model:                  NNLS                    Adj. R-squared:          0.765
No. Observations:       572                               RMSE:         490.89
Df Residuals:           570                                MAE:         437.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const   1344.4379     66.8444       0.001   1220.8201   1471.7317
       opcount      0.0465      0.0010       0.001      0.0445      0.0484
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.477
Model:                  NNLS                    Adj. R-squared:          0.476
No. Observations:       418                               RMSE:         421.57
Df Residuals:           416                                MAE:         373.39
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    620.5413     59.6540       0.001    499.6691    733.7915
       opcount      0.0211      0.0010       0.001      0.0192      0.0231
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.386
Model:                  NNLS                    Adj. R-squared:          0.385
No. Observations:       418                               RMSE:         972.02
Df Residuals:           416                                MAE:         923.87
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    175.5144    122.7194       0.081      0.0000    445.5476
       opcount      0.0404      0.0024       0.001      0.0355      0.0444
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODECOPY_AccountMode.EXISTING_CONTRACT_MINIMAL`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9599 | 0.01261 | 1.00e-03 | [0.01236, 0.01285] |
| `erigon` | 462 | 0.9377 | 0.003557 | 1.00e-03 | [0.003481, 0.003641] |
| `ethrex` | 330 | 0.7768 | 0.002668 | 1.00e-03 | [0.002489, 0.002827] |
| `geth` | 572 | 0.9738 | 0.02065 | 1.00e-03 | [0.02038, 0.02093] |
| `nethermind` | 418 | 0.6326 | 0.002969 | 1.00e-03 | [0.002745, 0.003194] |
| `reth` | 418 | 0.96 | 0.00477 | 1.00e-03 | [0.004679, 0.004858] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       440                               RMSE:          49.18
Df Residuals:           438                                MAE:          40.38
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    262.5006      7.4308       0.001    247.7519    276.6436
       opcount      0.0126      0.0001       0.001      0.0124      0.0128
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.938
Model:                  NNLS                    Adj. R-squared:          0.938
No. Observations:       462                               RMSE:          17.49
Df Residuals:           460                                MAE:          12.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    156.2364      2.5095       0.001    151.3902    161.0616
       opcount      0.0036      0.0000       0.001      0.0035      0.0036
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.777
Model:                  NNLS                    Adj. R-squared:          0.776
No. Observations:       330                               RMSE:          27.30
Df Residuals:           328                                MAE:          22.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    103.9488      5.5944       0.001     92.9994    115.1967
       opcount      0.0027      0.0001       0.001      0.0025      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.974
Model:                  NNLS                    Adj. R-squared:          0.974
No. Observations:       572                               RMSE:          64.59
Df Residuals:           570                                MAE:          51.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    251.7739      8.1318       0.001    235.7951    266.9840
       opcount      0.0206      0.0001       0.001      0.0204      0.0209
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.633
Model:                  NNLS                    Adj. R-squared:          0.632
No. Observations:       418                               RMSE:          43.17
Df Residuals:           416                                MAE:          31.27
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    133.9914      6.1182       0.001    122.2932    146.3381
       opcount      0.0030      0.0001       0.001      0.0027      0.0032
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       418                               RMSE:          18.57
Df Residuals:           416                                MAE:          14.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     86.5658      2.5292       0.001     81.6436     91.5020
       opcount      0.0048      0.0000       0.001      0.0047      0.0049
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### test_account_access: combo `EXTCODECOPY_AccountMode.EXISTING_CONTRACT_SAME_MAX`

| client | nobs | R² | target_coef (ms) | p-value | 95% CI |
| --- | --- | --- | --- | --- | --- |
| `besu` | 440 | 0.9637 | 0.01286 | 1.00e-03 | [0.01261, 0.0131] |
| `erigon` | 462 | 0.7948 | 0.003642 | 1.00e-03 | [0.003471, 0.003804] |
| `ethrex` | 330 | 0.7597 | 0.002652 | 1.00e-03 | [0.002493, 0.002818] |
| `geth` | 572 | 0.9702 | 0.02031 | 1.00e-03 | [0.02003, 0.0206] |
| `nethermind` | 418 | 0.6032 | 0.002921 | 1.00e-03 | [0.00268, 0.003167] |
| `reth` | 418 | 0.965 | 0.004739 | 1.00e-03 | [0.004658, 0.00482] |

<details markdown="1"><summary>besu: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.964
Model:                  NNLS                    Adj. R-squared:          0.964
No. Observations:       440                               RMSE:          47.65
Df Residuals:           438                                MAE:          37.60
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    257.1361      7.0494       0.001    244.3465    271.9967
       opcount      0.0129      0.0001       0.001      0.0126      0.0131
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>erigon: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.795
Model:                  NNLS                    Adj. R-squared:          0.794
No. Observations:       462                               RMSE:          35.31
Df Residuals:           460                                MAE:          31.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    120.9809      5.5731       0.001    110.3442    132.1812
       opcount      0.0036      0.0001       0.001      0.0035      0.0038
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>ethrex: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.760
Model:                  NNLS                    Adj. R-squared:          0.759
No. Observations:       330                               RMSE:          28.47
Df Residuals:           328                                MAE:          23.29
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    106.2053      5.6399       0.001     95.4736    116.3605
       opcount      0.0027      0.0001       0.001      0.0025      0.0028
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>geth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.970
No. Observations:       572                               RMSE:          67.98
Df Residuals:           570                                MAE:          54.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    252.7277      8.9831       0.001    235.5490    269.8873
       opcount      0.0203      0.0002       0.001      0.0200      0.0206
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>nethermind: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.603
Model:                  NNLS                    Adj. R-squared:          0.602
No. Observations:       418                               RMSE:          45.21
Df Residuals:           416                                MAE:          33.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    142.0538      6.4499       0.001    129.4384    154.8038
       opcount      0.0029      0.0001       0.001      0.0027      0.0032
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary>reth: NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.965
Model:                  NNLS                    Adj. R-squared:          0.965
No. Observations:       418                               RMSE:          17.21
Df Residuals:           416                                MAE:          13.23
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     87.6374      2.4144       0.001     83.0649     92.4033
       opcount      0.0047      0.0000       0.001      0.0047      0.0048
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>
