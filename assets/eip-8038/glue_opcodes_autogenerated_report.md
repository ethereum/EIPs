# Glue opcodes report

> This is a snapshot of the latest archived evm-gasfit run. All numerical tables and regression summaries are retained. Plots are omitted. Runtime estimates do not depend on the gas anchor. See the [supporting report](gas-cost-report.md) for the source details and gas estimates at 75 Mgas/s.

This report uses nonnegative least squares (NNLS) to estimate auxiliary opcode runtimes for each client. Cycle tier opcodes share one joint regression per client. Pure tier and mixed tier opcodes each use a fit with one feature.

Mixed tier fits first subtract the estimated time spent on upstream partner opcodes. For `mixed_a`, these partners come from the pure and cycle tiers. For `mixed_b`, they also include the `mixed_a` tier.

**Contents:** [besu](#besu), [erigon](#erigon), [ethrex](#ethrex), [geth](#geth), [nethermind](#nethermind), [reth](#reth)

## besu

| glue_opcode | nobs | glue_runtime_ms | p_value | rsquared |
| --- | --- | --- | --- | --- |
| `ISZERO` | 1067 | 6.097e-06 | 1.00e-03 | 0.9869 |
| `JUMPDEST` | 1067 | 1.205e-06 | 1.00e-03 | 0.8849 |
| `SWAP` | 17072 | 3.562e-06 | 1.00e-03 | 0.9695 |
| `CALLDATASIZE` | 63173 | 5.045e-06 | 1.00e-03 | 0.9875 |
| `DUP` | 63173 | 2.342e-06 | 1.00e-03 | 0.9875 |
| `GAS` | 63173 | 4.155e-06 | 1.00e-03 | 0.9875 |
| `MLOAD` | 63173 | 1.328e-05 | 1.00e-03 | 0.9875 |
| `PUSH` | 63173 | 3.123e-06 | 1.00e-03 | 0.9875 |
| `PUSH0` | 63173 | 2.242e-06 | 1.00e-03 | 0.9875 |
| `STATICCALL` | 63173 | 0.0008686 | 1.00e-03 | 0.9875 |
| `ADD` | 1067 | 1.629e-05 | 1.00e-03 | 0.9788 |
| `AND` | 1067 | 1.05e-05 | 1.00e-03 | 0.9462 |
| `CALLDATACOPY` | 25608 | 2.36e-05 | 1.00e-03 | 0.7204 |
| `CALLDATALOAD` | 4268 | 3.431e-05 | 1.00e-03 | 0.03926 |
| `DIV` | 1067 | 2.324e-05 | 1.00e-03 | 0.981 |
| `EXP` | 1067 | 0.00229 | 1.00e-03 | 0.9693 |
| `GT` | 1067 | 4.46e-05 | 1.00e-03 | 0.9835 |
| `JUMPI` | 1067 | 9.852e-06 | 1.00e-03 | 0.9715 |
| `LT` | 1067 | 3.649e-05 | 1.00e-03 | 0.3061 |
| `MSTORE` | 5335 | 2.707e-05 | 1.00e-03 | 0.9774 |
| `MSTORE8` | 5335 | 1.553e-05 | 1.00e-03 | 0.9703 |
| `MUL` | 1067 | 1.39e-05 | 1.00e-03 | 0.8203 |
| `PC` | 1067 | 5.074e-06 | 1.00e-03 | 0.9801 |
| `RETURNDATASIZE` | 4268 | 7.389e-06 | 1.00e-03 | 0.9842 |
| `SELFBALANCE` | 1067 | 2.344e-05 | 1.00e-03 | 0.9871 |
| `SUB` | 1067 | 1.727e-05 | 1.00e-03 | 0.9882 |
| `JUMP` | 1067 | 3.687e-05 | 1.00e-03 | 0.987 |
| `KECCAK256` | 17072 | 4.594e-05 | 1.00e-03 | 0.1016 |

### Cycle glue: joint fit, besu

<details markdown="1"><summary>Joint NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.987
Model:                  NNLS                    Adj. R-squared:          0.987
No. Observations:       63173                             RMSE:          17.11
Df Residuals:           63165                              MAE:           9.86
Df Model:               7      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     34.9023      0.2429       0.001     34.4202     35.3485
  CALLDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
           DUP      0.0000      0.0000       0.001      0.0000      0.0000
           GAS      0.0000      0.0000       0.001      0.0000      0.0000
         MLOAD      0.0000      0.0000       0.001      0.0000      0.0000
          PUSH      0.0000      0.0000       0.001      0.0000      0.0000
         PUSH0      0.0000      0.0000       0.001      0.0000      0.0000
    STATICCALL      0.0009      0.0000       0.001      0.0009      0.0009
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```

</details>

<details markdown="1"><summary><code>CALLDATASIZE</code>, nobs=63173, runtime_ms=5.045e-06, p=1.00e-03, R²=0.9875</summary>




</details>

<details markdown="1"><summary><code>DUP</code>, nobs=63173, runtime_ms=2.342e-06, p=1.00e-03, R²=0.9875</summary>




</details>

<details markdown="1"><summary><code>GAS</code>, nobs=63173, runtime_ms=4.155e-06, p=1.00e-03, R²=0.9875</summary>




</details>

<details markdown="1"><summary><code>MLOAD</code>, nobs=63173, runtime_ms=1.328e-05, p=1.00e-03, R²=0.9875</summary>




</details>

<details markdown="1"><summary><code>PUSH</code>, nobs=63173, runtime_ms=3.123e-06, p=1.00e-03, R²=0.9875</summary>




</details>

<details markdown="1"><summary><code>PUSH0</code>, nobs=63173, runtime_ms=2.242e-06, p=1.00e-03, R²=0.9875</summary>




</details>

<details markdown="1"><summary><code>STATICCALL</code>, nobs=63173, runtime_ms=0.0008686, p=1.00e-03, R²=0.9875</summary>




</details>

### Pure glue, besu

<details markdown="1"><summary><code>ISZERO</code>, nobs=1067, runtime_ms=6.097e-06, p=1.00e-03, R²=0.9869</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.987
Model:                  NNLS                    Adj. R-squared:          0.987
No. Observations:       1067                              RMSE:          14.79
Df Residuals:           1065                               MAE:          10.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     34.2684      1.5632       0.001     31.1505     37.3538
        ISZERO      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPDEST</code>, nobs=1067, runtime_ms=1.205e-06, p=1.00e-03, R²=0.8849</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.885
Model:                  NNLS                    Adj. R-squared:          0.885
No. Observations:       1067                              RMSE:          27.45
Df Residuals:           1065                               MAE:          13.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.5062      2.5349       0.001     22.5978     32.4065
      JUMPDEST      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SWAP</code>, nobs=17072, runtime_ms=3.562e-06, p=1.00e-03, R²=0.9695</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       17072                             RMSE:          13.32
Df Residuals:           17070                              MAE:           9.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     31.5310      0.3124       0.001     30.9261     32.1369
          SWAP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier A), besu

<details markdown="1"><summary><code>ADD</code>, nobs=1067, runtime_ms=1.629e-05, p=1.00e-03, R²=0.9788</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.979
Model:                  NNLS                    Adj. R-squared:          0.979
No. Observations:       1067                              RMSE:          25.24
Df Residuals:           1065                               MAE:          20.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     74.6889      2.8580       0.001     69.0477     80.0287
           ADD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>AND</code>, nobs=1067, runtime_ms=1.05e-05, p=1.00e-03, R²=0.9462</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.946
Model:                  NNLS                    Adj. R-squared:          0.946
No. Observations:       1067                              RMSE:          26.37
Df Residuals:           1065                               MAE:          11.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     39.8178      2.3094       0.001     35.1187     43.8601
           AND      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATACOPY</code>, nobs=25608, runtime_ms=2.36e-05, p=1.00e-03, R²=0.7204</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.720
Model:                  NNLS                    Adj. R-squared:          0.720
No. Observations:       25608                             RMSE:         110.60
Df Residuals:           25606                              MAE:          85.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    138.2697      0.7261       0.001    136.8788    139.7283
  CALLDATACOPY      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATALOAD</code>, nobs=4268, runtime_ms=3.431e-05, p=1.00e-03, R²=0.03926</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.039
Model:                  NNLS                    Adj. R-squared:          0.039
No. Observations:       4268                              RMSE:           0.65
Df Residuals:           4266                               MAE:           0.42
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      2.9211      0.0383       0.001      2.8448      2.9950
  CALLDATALOAD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>DIV</code>, nobs=1067, runtime_ms=2.324e-05, p=1.00e-03, R²=0.981</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       1067                              RMSE:          25.51
Df Residuals:           1065                               MAE:          18.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     89.1046      2.1357       0.001     84.4769     93.0821
           DIV      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>EXP</code>, nobs=1067, runtime_ms=0.00229, p=1.00e-03, R²=0.9693</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.969
Model:                  NNLS                    Adj. R-squared:          0.969
No. Observations:       1067                              RMSE:          15.96
Df Residuals:           1065                               MAE:          11.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     66.7214      2.3857       0.001     62.0108     71.4222
           EXP      0.0023      0.0000       0.001      0.0023      0.0023
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>GT</code>, nobs=1067, runtime_ms=4.46e-05, p=1.00e-03, R²=0.9835</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.983
Model:                  NNLS                    Adj. R-squared:          0.983
No. Observations:       1067                              RMSE:          60.84
Df Residuals:           1065                               MAE:          48.72
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    118.1598      6.8655       0.001    105.0555    131.8340
            GT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPI</code>, nobs=1067, runtime_ms=9.852e-06, p=1.00e-03, R²=0.9715</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.971
Model:                  NNLS                    Adj. R-squared:          0.971
No. Observations:       1067                              RMSE:           7.62
Df Residuals:           1065                               MAE:           5.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     19.6079      0.7037       0.001     18.1048     20.9084
         JUMPI      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>LT</code>, nobs=1067, runtime_ms=3.649e-05, p=1.00e-03, R²=0.3061</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.306
Model:                  NNLS                    Adj. R-squared:          0.305
No. Observations:       1067                              RMSE:         578.52
Df Residuals:           1065                               MAE:         537.00
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    109.1524     50.0815       0.017      8.0092    208.2890
            LT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE</code>, nobs=5335, runtime_ms=2.707e-05, p=1.00e-03, R²=0.9774</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       5335                              RMSE:          28.90
Df Residuals:           5333                               MAE:          23.20
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     48.1290      1.2876       0.001     45.7086     50.5695
        MSTORE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE8</code>, nobs=5335, runtime_ms=1.553e-05, p=1.00e-03, R²=0.9703</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.970
No. Observations:       5335                              RMSE:          19.06
Df Residuals:           5333                               MAE:          13.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     25.3590      0.7848       0.001     23.8614     26.8685
       MSTORE8      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MUL</code>, nobs=1067, runtime_ms=1.39e-05, p=1.00e-03, R²=0.8203</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.820
Model:                  NNLS                    Adj. R-squared:          0.820
No. Observations:       1067                              RMSE:          51.39
Df Residuals:           1065                               MAE:          32.91
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     47.1055      4.5740       0.001     37.9001     55.9982
           MUL      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>PC</code>, nobs=1067, runtime_ms=5.074e-06, p=1.00e-03, R²=0.9801</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       1067                              RMSE:          21.61
Df Residuals:           1065                               MAE:          16.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.9476      2.1954       0.001     23.4155     32.2691
            PC      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>RETURNDATASIZE</code>, nobs=4268, runtime_ms=7.389e-06, p=1.00e-03, R²=0.9842</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.984
Model:                  NNLS                    Adj. R-squared:          0.984
No. Observations:       4268                              RMSE:          14.80
Df Residuals:           4266                               MAE:          10.18
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     36.7557      0.7639       0.001     35.3253     38.2218
RETURNDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SELFBALANCE</code>, nobs=1067, runtime_ms=2.344e-05, p=1.00e-03, R²=0.9871</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.987
Model:                  NNLS                    Adj. R-squared:          0.987
No. Observations:       1067                              RMSE:          33.09
Df Residuals:           1065                               MAE:          25.94
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     49.0053      3.7973       0.001     41.7580     57.0884
   SELFBALANCE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SUB</code>, nobs=1067, runtime_ms=1.727e-05, p=1.00e-03, R²=0.9882</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.988
Model:                  NNLS                    Adj. R-squared:          0.988
No. Observations:       1067                              RMSE:          19.91
Df Residuals:           1065                               MAE:          13.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     47.5521      1.7805       0.001     43.8725     50.9199
           SUB      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier B), besu

<details markdown="1"><summary><code>JUMP</code>, nobs=1067, runtime_ms=3.687e-05, p=1.00e-03, R²=0.987</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.987
Model:                  NNLS                    Adj. R-squared:          0.987
No. Observations:       1067                              RMSE:          15.74
Df Residuals:           1065                               MAE:          11.54
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     43.3092      1.6103       0.001     40.2416     46.4411
          JUMP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>KECCAK256</code>, nobs=17072, runtime_ms=4.594e-05, p=1.00e-03, R²=0.1016</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.102
Model:                  NNLS                    Adj. R-squared:          0.102
No. Observations:       17072                             RMSE:         271.61
Df Residuals:           17070                              MAE:         217.92
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    763.2790      4.5617       0.001    754.6101    771.9629
     KECCAK256      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## erigon

| glue_opcode | nobs | glue_runtime_ms | p_value | rsquared |
| --- | --- | --- | --- | --- |
| `ISZERO` | 1089 | 1.575e-06 | 1.00e-03 | 0.5326 |
| `JUMPDEST` | 1089 | 1.207e-06 | 1.00e-03 | 0.4256 |
| `SWAP` | 17424 | 1.937e-06 | 1.00e-03 | 0.8104 |
| `CALLDATASIZE` | 64482 | 1.63e-06 | 1.00e-03 | 0.7937 |
| `DUP` | 64482 | 1.901e-06 | 1.00e-03 | 0.7937 |
| `GAS` | 64482 | 1.655e-06 | 1.00e-03 | 0.7937 |
| `MLOAD` | 64482 | 4.443e-06 | 1.00e-03 | 0.7937 |
| `PUSH` | 64482 | 2.966e-06 | 1.00e-03 | 0.7937 |
| `PUSH0` | 64482 | 1.633e-06 | 1.00e-03 | 0.7937 |
| `STATICCALL` | 64482 | 5.864e-05 | 1.00e-03 | 0.7937 |
| `ADD` | 1089 | 3.378e-06 | 1.00e-03 | 0.4558 |
| `AND` | 1089 | 3.398e-06 | 1.00e-03 | 0.4912 |
| `CALLDATACOPY` | 26136 | 1.032e-05 | 1.00e-03 | 0.9594 |
| `CALLDATALOAD` | 4356 | 5.138e-05 | 1.00e-03 | 0.1927 |
| `DIV` | 1089 | 1.413e-05 | 1.00e-03 | 0.9243 |
| `EXP` | 1089 | 0.0006888 | 1.00e-03 | 0.981 |
| `GT` | 1089 | 3.455e-06 | 1.00e-03 | 0.505 |
| `JUMPI` | 1089 | 4.681e-06 | 1.00e-03 | 0.8555 |
| `LT` | 1089 | 3.465e-06 | 1.00e-03 | 0.5108 |
| `MSTORE` | 5445 | 6.85e-06 | 1.00e-03 | 0.4373 |
| `MSTORE8` | 5445 | 7.129e-06 | 1.00e-03 | 0.7473 |
| `MUL` | 1089 | 5.275e-06 | 1.00e-03 | 0.5413 |
| `PC` | 1089 | 1.751e-06 | 1.00e-03 | 0.9798 |
| `RETURNDATASIZE` | 4356 | 2.9e-06 | 1.00e-03 | 0.8139 |
| `SELFBALANCE` | 1089 | 1.928e-06 | 1.00e-03 | 0.9613 |
| `SUB` | 1089 | 3.417e-06 | 1.00e-03 | 0.4848 |
| `JUMP` | 1089 | 8.02e-06 | 1.00e-03 | 0.5586 |
| `KECCAK256` | 17424 | 5.972e-06 | 1.00e-03 | 0.002552 |

### Cycle glue: joint fit, erigon

<details markdown="1"><summary>Joint NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.794
Model:                  NNLS                    Adj. R-squared:          0.794
No. Observations:       64482                             RMSE:          31.55
Df Residuals:           64474                              MAE:          18.87
Df Model:               7      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.8406      0.3474       0.001     16.1746     17.5400
  CALLDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
           DUP      0.0000      0.0000       0.001      0.0000      0.0000
           GAS      0.0000      0.0000       0.001      0.0000      0.0000
         MLOAD      0.0000      0.0000       0.001      0.0000      0.0000
          PUSH      0.0000      0.0000       0.001      0.0000      0.0000
         PUSH0      0.0000      0.0000       0.001      0.0000      0.0000
    STATICCALL      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```

</details>

<details markdown="1"><summary><code>CALLDATASIZE</code>, nobs=64482, runtime_ms=1.63e-06, p=1.00e-03, R²=0.7937</summary>




</details>

<details markdown="1"><summary><code>DUP</code>, nobs=64482, runtime_ms=1.901e-06, p=1.00e-03, R²=0.7937</summary>




</details>

<details markdown="1"><summary><code>GAS</code>, nobs=64482, runtime_ms=1.655e-06, p=1.00e-03, R²=0.7937</summary>




</details>

<details markdown="1"><summary><code>MLOAD</code>, nobs=64482, runtime_ms=4.443e-06, p=1.00e-03, R²=0.7937</summary>




</details>

<details markdown="1"><summary><code>PUSH</code>, nobs=64482, runtime_ms=2.966e-06, p=1.00e-03, R²=0.7937</summary>




</details>

<details markdown="1"><summary><code>PUSH0</code>, nobs=64482, runtime_ms=1.633e-06, p=1.00e-03, R²=0.7937</summary>




</details>

<details markdown="1"><summary><code>STATICCALL</code>, nobs=64482, runtime_ms=5.864e-05, p=1.00e-03, R²=0.7937</summary>




</details>

### Pure glue, erigon

<details markdown="1"><summary><code>ISZERO</code>, nobs=1089, runtime_ms=1.575e-06, p=1.00e-03, R²=0.5326</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.533
Model:                  NNLS                    Adj. R-squared:          0.532
No. Observations:       1089                              RMSE:          31.08
Df Residuals:           1087                               MAE:          24.57
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.8921      2.7546       0.001      3.4568     14.1441
        ISZERO      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPDEST</code>, nobs=1089, runtime_ms=1.207e-06, p=1.00e-03, R²=0.4256</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.426
Model:                  NNLS                    Adj. R-squared:          0.425
No. Observations:       1089                              RMSE:          88.58
Df Residuals:           1087                               MAE:          70.79
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.6525      7.7588       0.037      0.0000     30.1437
      JUMPDEST      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SWAP</code>, nobs=17424, runtime_ms=1.937e-06, p=1.00e-03, R²=0.8104</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.810
Model:                  NNLS                    Adj. R-squared:          0.810
No. Observations:       17424                             RMSE:          19.73
Df Residuals:           17422                              MAE:          10.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     17.2551      0.4865       0.001     16.2337     18.1739
          SWAP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier A), erigon

<details markdown="1"><summary><code>ADD</code>, nobs=1089, runtime_ms=3.378e-06, p=1.00e-03, R²=0.4558</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.456
Model:                  NNLS                    Adj. R-squared:          0.455
No. Observations:       1089                              RMSE:          38.87
Df Residuals:           1087                               MAE:          30.52
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.2725      3.5162       0.001      7.2908     21.0937
           ADD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>AND</code>, nobs=1089, runtime_ms=3.398e-06, p=1.00e-03, R²=0.4912</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.491
Model:                  NNLS                    Adj. R-squared:          0.491
No. Observations:       1089                              RMSE:          36.41
Df Residuals:           1087                               MAE:          28.73
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.1921      3.2759       0.001      6.0315     19.1270
           AND      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATACOPY</code>, nobs=26136, runtime_ms=1.032e-05, p=1.00e-03, R²=0.9594</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.959
Model:                  NNLS                    Adj. R-squared:          0.959
No. Observations:       26136                             RMSE:          15.97
Df Residuals:           26134                              MAE:          10.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.3940      0.1183       0.001     14.1707     14.6302
  CALLDATACOPY      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATALOAD</code>, nobs=4356, runtime_ms=5.138e-05, p=1.00e-03, R²=0.1927</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.193
Model:                  NNLS                    Adj. R-squared:          0.192
No. Observations:       4356                              RMSE:           0.40
Df Residuals:           4354                               MAE:           0.19
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.2291      0.0173       0.001      4.1945      4.2631
  CALLDATALOAD      0.0001      0.0000       0.001      0.0000      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>DIV</code>, nobs=1089, runtime_ms=1.413e-05, p=1.00e-03, R²=0.9243</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.924
Model:                  NNLS                    Adj. R-squared:          0.924
No. Observations:       1089                              RMSE:          31.94
Df Residuals:           1087                               MAE:          25.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     29.8056      3.1696       0.001     23.5041     35.7120
           DIV      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>EXP</code>, nobs=1089, runtime_ms=0.0006888, p=1.00e-03, R²=0.981</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.981
Model:                  NNLS                    Adj. R-squared:          0.981
No. Observations:       1089                              RMSE:           3.76
Df Residuals:           1087                               MAE:           2.99
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.2110      0.4431       0.001      8.3873     10.0979
           EXP      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>GT</code>, nobs=1089, runtime_ms=3.455e-06, p=1.00e-03, R²=0.505</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.505
Model:                  NNLS                    Adj. R-squared:          0.505
No. Observations:       1089                              RMSE:          36.02
Df Residuals:           1087                               MAE:          27.64
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.3184      3.4392       0.001      6.5011     20.0403
            GT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPI</code>, nobs=1089, runtime_ms=4.681e-06, p=1.00e-03, R²=0.8555</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.855
Model:                  NNLS                    Adj. R-squared:          0.855
No. Observations:       1089                              RMSE:           8.68
Df Residuals:           1087                               MAE:           6.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.6278      0.8484       0.001      8.0301     11.3332
         JUMPI      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>LT</code>, nobs=1089, runtime_ms=3.465e-06, p=1.00e-03, R²=0.5108</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.511
Model:                  NNLS                    Adj. R-squared:          0.510
No. Observations:       1089                              RMSE:          35.71
Df Residuals:           1087                               MAE:          27.53
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.5595      3.2161       0.001      6.8622     19.8708
            LT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE</code>, nobs=5445, runtime_ms=6.85e-06, p=1.00e-03, R²=0.4373</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.437
Model:                  NNLS                    Adj. R-squared:          0.437
No. Observations:       5445                              RMSE:          54.55
Df Residuals:           5443                               MAE:          43.54
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.9383      2.0440       0.001     11.7785     20.2300
        MSTORE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE8</code>, nobs=5445, runtime_ms=7.129e-06, p=1.00e-03, R²=0.7473</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.747
Model:                  NNLS                    Adj. R-squared:          0.747
No. Observations:       5445                              RMSE:          29.10
Df Residuals:           5443                               MAE:          22.81
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.5302      1.1195       0.001     13.4172     17.7377
       MSTORE8      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MUL</code>, nobs=1089, runtime_ms=5.275e-06, p=1.00e-03, R²=0.5413</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.541
Model:                  NNLS                    Adj. R-squared:          0.541
No. Observations:       1089                              RMSE:          38.35
Df Residuals:           1087                               MAE:          29.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.0172      3.2450       0.003      1.6978     14.6537
           MUL      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>PC</code>, nobs=1089, runtime_ms=1.751e-06, p=1.00e-03, R²=0.9798</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.980
Model:                  NNLS                    Adj. R-squared:          0.980
No. Observations:       1089                              RMSE:           7.52
Df Residuals:           1087                               MAE:           6.23
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.9412      0.8754       0.001     11.2925     14.7194
            PC      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>RETURNDATASIZE</code>, nobs=4356, runtime_ms=2.9e-06, p=1.00e-03, R²=0.8139</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.814
Model:                  NNLS                    Adj. R-squared:          0.814
No. Observations:       4356                              RMSE:          21.91
Df Residuals:           4354                               MAE:          16.24
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.1639      0.9718       0.001     10.2260     14.0062
RETURNDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SELFBALANCE</code>, nobs=1089, runtime_ms=1.928e-06, p=1.00e-03, R²=0.9613</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.961
Model:                  NNLS                    Adj. R-squared:          0.961
No. Observations:       1089                              RMSE:           4.78
Df Residuals:           1087                               MAE:           3.76
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.3918      0.4488       0.001      6.4887      8.2413
   SELFBALANCE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SUB</code>, nobs=1089, runtime_ms=3.417e-06, p=1.00e-03, R²=0.4848</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.485
Model:                  NNLS                    Adj. R-squared:          0.484
No. Observations:       1089                              RMSE:          37.09
Df Residuals:           1087                               MAE:          29.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.2945      3.4508       0.001      6.9475     20.1371
           SUB      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier B), erigon

<details markdown="1"><summary><code>JUMP</code>, nobs=1089, runtime_ms=8.02e-06, p=1.00e-03, R²=0.5586</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.559
Model:                  NNLS                    Adj. R-squared:          0.558
No. Observations:       1089                              RMSE:          26.50
Df Residuals:           1087                               MAE:          20.87
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     10.2817      2.4346       0.001      5.6044     14.8511
          JUMP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>KECCAK256</code>, nobs=17424, runtime_ms=5.972e-06, p=1.00e-03, R²=0.002552</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.003
Model:                  NNLS                    Adj. R-squared:          0.002
No. Observations:       17424                             RMSE:         234.72
Df Residuals:           17422                              MAE:         186.56
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    573.2789      3.3761       0.001    566.5371    579.8039
     KECCAK256      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## ethrex

| glue_opcode | nobs | glue_runtime_ms | p_value | rsquared |
| --- | --- | --- | --- | --- |
| `ISZERO` | 110 | 7.251e-07 | 1.00e-03 | 0.8973 |
| `JUMPDEST` | 110 | 5.06e-07 | 1.00e-03 | 0.8625 |
| `SWAP` | 1760 | 8.804e-07 | 1.00e-03 | 0.8673 |
| `CALLDATASIZE` | 6655 | 6.443e-07 | 1.00e-03 | 0.9571 |
| `DUP` | 6655 | 6.648e-07 | 1.00e-03 | 0.9571 |
| `GAS` | 6655 | 6.681e-07 | 1.00e-03 | 0.9571 |
| `MLOAD` | 6655 | 1.705e-06 | 1.00e-03 | 0.9571 |
| `PUSH` | 6655 | 8.316e-07 | 1.00e-03 | 0.9571 |
| `PUSH0` | 6655 | 5.945e-07 | 1.00e-03 | 0.9571 |
| `STATICCALL` | 6655 | 0.000132 | 1.00e-03 | 0.9571 |
| `ADD` | 110 | 1.734e-06 | 1.00e-03 | 0.931 |
| `AND` | 110 | 1.297e-06 | 1.00e-03 | 0.9075 |
| `CALLDATACOPY` | 2640 | 3.997e-06 | 1.00e-03 | 0.9228 |
| `CALLDATALOAD` | 440 | 2.655e-05 | 1.00e-03 | 0.1755 |
| `DIV` | 110 | 1.365e-05 | 1.00e-03 | 0.9453 |
| `EXP` | 110 | 0.001842 | 1.00e-03 | 0.963 |
| `GT` | 110 | 1.75e-06 | 1.00e-03 | 0.9602 |
| `JUMPI` | 110 | 2.236e-06 | 1.00e-03 | 0.8041 |
| `LT` | 110 | 1.722e-06 | 1.00e-03 | 0.9513 |
| `MSTORE` | 550 | 2.483e-06 | 1.00e-03 | 0.9367 |
| `MSTORE8` | 550 | 2.556e-06 | 1.00e-03 | 0.9476 |
| `MUL` | 110 | 3.245e-06 | 1.00e-03 | 0.6291 |
| `PC` | 110 | 7.961e-07 | 1.00e-03 | 0.9233 |
| `RETURNDATASIZE` | 440 | 1.2e-06 | 1.00e-03 | 0.864 |
| `SELFBALANCE` | 110 | 1.032e-05 | 1.00e-03 | 0.9602 |
| `SUB` | 110 | 1.697e-06 | 1.00e-03 | 0.9043 |
| `JUMP` | 110 | 4.197e-06 | 1.00e-03 | 0.945 |
| `KECCAK256` | 1760 | 0 | 1.00e+00 | 0 |

### Cycle glue: joint fit, ethrex

<details markdown="1"><summary>Joint NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.957
Model:                  NNLS                    Adj. R-squared:          0.957
No. Observations:       6655                              RMSE:           7.32
Df Residuals:           6647                               MAE:           5.35
Df Model:               7      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.4778      0.2809       0.001      7.9347      9.0178
  CALLDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
           DUP      0.0000      0.0000       0.001      0.0000      0.0000
           GAS      0.0000      0.0000       0.001      0.0000      0.0000
         MLOAD      0.0000      0.0000       0.001      0.0000      0.0000
          PUSH      0.0000      0.0000       0.001      0.0000      0.0000
         PUSH0      0.0000      0.0000       0.001      0.0000      0.0000
    STATICCALL      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```

</details>

<details markdown="1"><summary><code>CALLDATASIZE</code>, nobs=6655, runtime_ms=6.443e-07, p=1.00e-03, R²=0.9571</summary>




</details>

<details markdown="1"><summary><code>DUP</code>, nobs=6655, runtime_ms=6.648e-07, p=1.00e-03, R²=0.9571</summary>




</details>

<details markdown="1"><summary><code>GAS</code>, nobs=6655, runtime_ms=6.681e-07, p=1.00e-03, R²=0.9571</summary>




</details>

<details markdown="1"><summary><code>MLOAD</code>, nobs=6655, runtime_ms=1.705e-06, p=1.00e-03, R²=0.9571</summary>




</details>

<details markdown="1"><summary><code>PUSH</code>, nobs=6655, runtime_ms=8.316e-07, p=1.00e-03, R²=0.9571</summary>




</details>

<details markdown="1"><summary><code>PUSH0</code>, nobs=6655, runtime_ms=5.945e-07, p=1.00e-03, R²=0.9571</summary>




</details>

<details markdown="1"><summary><code>STATICCALL</code>, nobs=6655, runtime_ms=0.000132, p=1.00e-03, R²=0.9571</summary>




</details>

### Pure glue, ethrex

<details markdown="1"><summary><code>ISZERO</code>, nobs=110, runtime_ms=7.251e-07, p=1.00e-03, R²=0.8973</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.897
Model:                  NNLS                    Adj. R-squared:          0.896
No. Observations:       110                               RMSE:           5.17
Df Residuals:           108                                MAE:           4.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.1731      1.4782       0.001      5.2025     10.9581
        ISZERO      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPDEST</code>, nobs=110, runtime_ms=5.06e-07, p=1.00e-03, R²=0.8625</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.863
Model:                  NNLS                    Adj. R-squared:          0.861
No. Observations:       110                               RMSE:          12.76
Df Residuals:           108                                MAE:           9.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.1752      3.6465       0.001      6.1061     20.3064
      JUMPDEST      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SWAP</code>, nobs=1760, runtime_ms=8.804e-07, p=1.00e-03, R²=0.8673</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.867
Model:                  NNLS                    Adj. R-squared:          0.867
No. Observations:       1760                              RMSE:           7.25
Df Residuals:           1758                               MAE:           5.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     10.5845      0.5006       0.001      9.6258     11.5920
          SWAP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier A), ethrex

<details markdown="1"><summary><code>ADD</code>, nobs=110, runtime_ms=1.734e-06, p=1.00e-03, R²=0.931</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.931
Model:                  NNLS                    Adj. R-squared:          0.930
No. Observations:       110                               RMSE:           4.97
Df Residuals:           108                                MAE:           3.85
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.4616      1.6100       0.001      5.2198     11.3837
           ADD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>AND</code>, nobs=110, runtime_ms=1.297e-06, p=1.00e-03, R²=0.9075</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.907
Model:                  NNLS                    Adj. R-squared:          0.907
No. Observations:       110                               RMSE:           4.36
Df Residuals:           108                                MAE:           3.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.8059      1.4072       0.001      6.0058     11.6268
           AND      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATACOPY</code>, nobs=2640, runtime_ms=3.997e-06, p=1.00e-03, R²=0.9228</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.923
Model:                  NNLS                    Adj. R-squared:          0.923
No. Observations:       2640                              RMSE:           8.70
Df Residuals:           2638                               MAE:           6.44
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.4017      0.2012       0.001     13.0123     13.8145
  CALLDATACOPY      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATALOAD</code>, nobs=440, runtime_ms=2.655e-05, p=1.00e-03, R²=0.1755</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.175
Model:                  NNLS                    Adj. R-squared:          0.174
No. Observations:       440                               RMSE:           0.22
Df Residuals:           438                                MAE:           0.17
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      2.3635      0.0361       0.001      2.2962      2.4320
  CALLDATALOAD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>DIV</code>, nobs=110, runtime_ms=1.365e-05, p=1.00e-03, R²=0.9453</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.945
Model:                  NNLS                    Adj. R-squared:          0.945
No. Observations:       110                               RMSE:          25.93
Df Residuals:           108                                MAE:          19.53
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     47.3308      8.6819       0.001     30.3407     63.6586
           DIV      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>EXP</code>, nobs=110, runtime_ms=0.001842, p=1.00e-03, R²=0.963</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.963
Model:                  NNLS                    Adj. R-squared:          0.963
No. Observations:       110                               RMSE:          14.15
Df Residuals:           108                                MAE:          11.50
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     18.2296      4.4047       0.001      9.1229     26.1515
           EXP      0.0018      0.0000       0.001      0.0018      0.0019
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>GT</code>, nobs=110, runtime_ms=1.75e-06, p=1.00e-03, R²=0.9602</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       110                               RMSE:           3.75
Df Residuals:           108                                MAE:           3.03
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.8371      1.2548       0.001      4.1737      9.2638
            GT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPI</code>, nobs=110, runtime_ms=2.236e-06, p=1.00e-03, R²=0.8041</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.804
Model:                  NNLS                    Adj. R-squared:          0.802
No. Observations:       110                               RMSE:           4.98
Df Residuals:           108                                MAE:           3.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.6657      1.4722       0.004      1.6392      7.4188
         JUMPI      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>LT</code>, nobs=110, runtime_ms=1.722e-06, p=1.00e-03, R²=0.9513</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.951
Model:                  NNLS                    Adj. R-squared:          0.951
No. Observations:       110                               RMSE:           4.10
Df Residuals:           108                                MAE:           3.13
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.8851      1.5648       0.001      5.9922     12.0822
            LT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE</code>, nobs=550, runtime_ms=2.483e-06, p=1.00e-03, R²=0.9367</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.937
Model:                  NNLS                    Adj. R-squared:          0.937
No. Observations:       550                               RMSE:           4.53
Df Residuals:           548                                MAE:           3.54
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.0189      0.6129       0.001      6.8584      9.1575
        MSTORE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE8</code>, nobs=550, runtime_ms=2.556e-06, p=1.00e-03, R²=0.9476</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.948
Model:                  NNLS                    Adj. R-squared:          0.948
No. Observations:       550                               RMSE:           4.22
Df Residuals:           548                                MAE:           3.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.6734      0.6258       0.001      6.4355      8.8800
       MSTORE8      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MUL</code>, nobs=110, runtime_ms=3.245e-06, p=1.00e-03, R²=0.6291</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.629
Model:                  NNLS                    Adj. R-squared:          0.626
No. Observations:       110                               RMSE:          19.68
Df Residuals:           108                                MAE:          15.74
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     27.5993      5.9692       0.001     15.9174     39.3799
           MUL      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>PC</code>, nobs=110, runtime_ms=7.961e-07, p=1.00e-03, R²=0.9233</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.923
Model:                  NNLS                    Adj. R-squared:          0.923
No. Observations:       110                               RMSE:           6.86
Df Residuals:           108                                MAE:           5.23
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.0822      2.0363       0.001      9.0777     17.1945
            PC      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>RETURNDATASIZE</code>, nobs=440, runtime_ms=1.2e-06, p=1.00e-03, R²=0.864</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.864
Model:                  NNLS                    Adj. R-squared:          0.864
No. Observations:       440                               RMSE:           7.52
Df Residuals:           438                                MAE:           5.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.5133      1.0621       0.001      7.4689     11.6429
RETURNDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SELFBALANCE</code>, nobs=110, runtime_ms=1.032e-05, p=1.00e-03, R²=0.9602</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       110                               RMSE:          25.96
Df Residuals:           108                                MAE:          19.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     33.6183      8.4528       0.001     15.9669     49.8346
   SELFBALANCE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SUB</code>, nobs=110, runtime_ms=1.697e-06, p=1.00e-03, R²=0.9043</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.904
Model:                  NNLS                    Adj. R-squared:          0.903
No. Observations:       110                               RMSE:           5.81
Df Residuals:           108                                MAE:           4.55
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.1569      1.8988       0.001      5.2369     12.8686
           SUB      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier B), ethrex

<details markdown="1"><summary><code>JUMP</code>, nobs=110, runtime_ms=4.197e-06, p=1.00e-03, R²=0.945</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.945
Model:                  NNLS                    Adj. R-squared:          0.945
No. Observations:       110                               RMSE:           3.76
Df Residuals:           108                                MAE:           2.92
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.1731      1.1693       0.001      6.9337     11.4902
          JUMP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>KECCAK256</code>, nobs=1760, runtime_ms=0, p=1.00e+00, R²=0</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.000
Model:                  NNLS                    Adj. R-squared:         -0.001
No. Observations:       1760                              RMSE:         271.45
Df Residuals:           1758                               MAE:         225.92
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    406.9619      6.2290       0.001    394.1295    418.3335
     KECCAK256      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## geth

| glue_opcode | nobs | glue_runtime_ms | p_value | rsquared |
| --- | --- | --- | --- | --- |
| `ISZERO` | 1595 | 1.887e-06 | 1.00e-03 | 0.9354 |
| `JUMPDEST` | 1595 | 1.292e-06 | 1.00e-03 | 0.8414 |
| `SWAP` | 25520 | 2.268e-06 | 1.00e-03 | 0.9496 |
| `CALLDATASIZE` | 94391 | 1.796e-06 | 1.00e-03 | 0.9151 |
| `DUP` | 94391 | 1.997e-06 | 1.00e-03 | 0.9151 |
| `GAS` | 94391 | 1.784e-06 | 1.00e-03 | 0.9151 |
| `MLOAD` | 94391 | 5.65e-06 | 1.00e-03 | 0.9151 |
| `PUSH` | 94391 | 3.155e-06 | 1.00e-03 | 0.9151 |
| `PUSH0` | 94391 | 1.669e-06 | 1.00e-03 | 0.9151 |
| `STATICCALL` | 94391 | 0.0002389 | 1.00e-03 | 0.9151 |
| `ADD` | 1595 | 4.503e-06 | 1.00e-03 | 0.9124 |
| `AND` | 1595 | 4.417e-06 | 1.00e-03 | 0.9084 |
| `CALLDATACOPY` | 38280 | 1.153e-05 | 1.00e-03 | 0.977 |
| `CALLDATALOAD` | 6380 | 2.461e-05 | 1.00e-03 | 0.07049 |
| `DIV` | 1595 | 1.439e-05 | 1.00e-03 | 0.9789 |
| `EXP` | 1595 | 0.0007158 | 1.00e-03 | 0.9822 |
| `GT` | 1595 | 3.969e-06 | 1.00e-03 | 0.8474 |
| `JUMPI` | 1595 | 5.576e-06 | 1.00e-03 | 0.837 |
| `LT` | 1595 | 4.358e-06 | 1.00e-03 | 0.9362 |
| `MSTORE` | 7975 | 8.479e-06 | 1.00e-03 | 0.9406 |
| `MSTORE8` | 7975 | 7.851e-06 | 1.00e-03 | 0.9251 |
| `MUL` | 1595 | 5.359e-06 | 1.00e-03 | 0.9461 |
| `PC` | 1595 | 1.98e-06 | 1.00e-03 | 0.9472 |
| `RETURNDATASIZE` | 6380 | 5.368e-06 | 1.00e-03 | 0.8652 |
| `SELFBALANCE` | 1595 | 1.233e-05 | 1.00e-03 | 0.9702 |
| `SUB` | 1595 | 4.347e-06 | 1.00e-03 | 0.9147 |
| `JUMP` | 1595 | 9.644e-06 | 1.00e-03 | 0.8032 |
| `KECCAK256` | 25520 | 3.778e-05 | 1.00e-03 | 0.1168 |

### Cycle glue: joint fit, geth

<details markdown="1"><summary>Joint NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.915
Model:                  NNLS                    Adj. R-squared:          0.915
No. Observations:       94391                             RMSE:          21.61
Df Residuals:           94383                              MAE:          13.24
Df Model:               7      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.1525      0.2117       0.001     15.7469     16.5535
  CALLDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
           DUP      0.0000      0.0000       0.001      0.0000      0.0000
           GAS      0.0000      0.0000       0.001      0.0000      0.0000
         MLOAD      0.0000      0.0000       0.001      0.0000      0.0000
          PUSH      0.0000      0.0000       0.001      0.0000      0.0000
         PUSH0      0.0000      0.0000       0.001      0.0000      0.0000
    STATICCALL      0.0002      0.0000       0.001      0.0002      0.0002
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```

</details>

<details markdown="1"><summary><code>CALLDATASIZE</code>, nobs=94391, runtime_ms=1.796e-06, p=1.00e-03, R²=0.9151</summary>




</details>

<details markdown="1"><summary><code>DUP</code>, nobs=94391, runtime_ms=1.997e-06, p=1.00e-03, R²=0.9151</summary>




</details>

<details markdown="1"><summary><code>GAS</code>, nobs=94391, runtime_ms=1.784e-06, p=1.00e-03, R²=0.9151</summary>




</details>

<details markdown="1"><summary><code>MLOAD</code>, nobs=94391, runtime_ms=5.65e-06, p=1.00e-03, R²=0.9151</summary>




</details>

<details markdown="1"><summary><code>PUSH</code>, nobs=94391, runtime_ms=3.155e-06, p=1.00e-03, R²=0.9151</summary>




</details>

<details markdown="1"><summary><code>PUSH0</code>, nobs=94391, runtime_ms=1.669e-06, p=1.00e-03, R²=0.9151</summary>




</details>

<details markdown="1"><summary><code>STATICCALL</code>, nobs=94391, runtime_ms=0.0002389, p=1.00e-03, R²=0.9151</summary>




</details>

### Pure glue, geth

<details markdown="1"><summary><code>ISZERO</code>, nobs=1595, runtime_ms=1.887e-06, p=1.00e-03, R²=0.9354</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.935
Model:                  NNLS                    Adj. R-squared:          0.935
No. Observations:       1595                              RMSE:          10.45
Df Residuals:           1593                               MAE:           5.62
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.7116      1.0064       0.001      6.8767     10.8339
        ISZERO      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPDEST</code>, nobs=1595, runtime_ms=1.292e-06, p=1.00e-03, R²=0.8414</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.841
Model:                  NNLS                    Adj. R-squared:          0.841
No. Observations:       1595                              RMSE:          35.45
Df Residuals:           1593                               MAE:          13.63
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     18.8843      2.4901       0.001     14.1043     23.6523
      JUMPDEST      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SWAP</code>, nobs=25520, runtime_ms=2.268e-06, p=1.00e-03, R²=0.9496</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.950
Model:                  NNLS                    Adj. R-squared:          0.950
No. Observations:       25520                             RMSE:          11.01
Df Residuals:           25518                              MAE:           6.77
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.4632      0.2431       0.001     11.9832     12.9303
          SWAP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier A), geth

<details markdown="1"><summary><code>ADD</code>, nobs=1595, runtime_ms=4.503e-06, p=1.00e-03, R²=0.9124</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.912
Model:                  NNLS                    Adj. R-squared:          0.912
No. Observations:       1595                              RMSE:          14.69
Df Residuals:           1593                               MAE:           7.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.5262      1.1394       0.001      2.2816      6.6021
           ADD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>AND</code>, nobs=1595, runtime_ms=4.417e-06, p=1.00e-03, R²=0.9084</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.908
Model:                  NNLS                    Adj. R-squared:          0.908
No. Observations:       1595                              RMSE:          14.77
Df Residuals:           1593                               MAE:           8.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.4078      1.1454       0.001      4.0359      8.5204
           AND      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATACOPY</code>, nobs=38280, runtime_ms=1.153e-05, p=1.00e-03, R²=0.977</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.977
Model:                  NNLS                    Adj. R-squared:          0.977
No. Observations:       38280                             RMSE:          13.30
Df Residuals:           38278                              MAE:           8.49
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.7332      0.0847       0.001     13.5668     13.9037
  CALLDATACOPY      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATALOAD</code>, nobs=6380, runtime_ms=2.461e-05, p=1.00e-03, R²=0.07049</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.070
Model:                  NNLS                    Adj. R-squared:          0.070
No. Observations:       6380                              RMSE:           0.34
Df Residuals:           6378                               MAE:           0.15
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      1.7837      0.0152       0.001      1.7555      1.8147
  CALLDATALOAD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>DIV</code>, nobs=1595, runtime_ms=1.439e-05, p=1.00e-03, R²=0.9789</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.979
Model:                  NNLS                    Adj. R-squared:          0.979
No. Observations:       1595                              RMSE:          16.67
Df Residuals:           1593                               MAE:          13.40
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     26.4239      1.4395       0.001     23.4731     29.3463
           DIV      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>EXP</code>, nobs=1595, runtime_ms=0.0007158, p=1.00e-03, R²=0.9822</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.982
Model:                  NNLS                    Adj. R-squared:          0.982
No. Observations:       1595                              RMSE:           3.78
Df Residuals:           1593                               MAE:           3.06
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      3.2335      0.2853       0.001      2.7018      3.8147
           EXP      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>GT</code>, nobs=1595, runtime_ms=3.969e-06, p=1.00e-03, R²=0.8474</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.847
Model:                  NNLS                    Adj. R-squared:          0.847
No. Observations:       1595                              RMSE:          17.74
Df Residuals:           1593                               MAE:          11.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     24.9365      1.9617       0.001     21.2616     28.7457
            GT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPI</code>, nobs=1595, runtime_ms=5.576e-06, p=1.00e-03, R²=0.837</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.837
Model:                  NNLS                    Adj. R-squared:          0.837
No. Observations:       1595                              RMSE:          11.11
Df Residuals:           1593                               MAE:           5.61
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.8169      0.9486       0.001      2.9980      6.8364
         JUMPI      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>LT</code>, nobs=1595, runtime_ms=4.358e-06, p=1.00e-03, R²=0.9362</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.936
Model:                  NNLS                    Adj. R-squared:          0.936
No. Observations:       1595                              RMSE:          11.98
Df Residuals:           1593                               MAE:           7.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.2216      1.0629       0.001      5.2012      9.3340
            LT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE</code>, nobs=7975, runtime_ms=8.479e-06, p=1.00e-03, R²=0.9406</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.941
Model:                  NNLS                    Adj. R-squared:          0.941
No. Observations:       7975                              RMSE:          14.96
Df Residuals:           7973                               MAE:           9.24
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     13.1446      0.5511       0.001     12.0517     14.1743
        MSTORE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE8</code>, nobs=7975, runtime_ms=7.851e-06, p=1.00e-03, R²=0.9251</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.925
Model:                  NNLS                    Adj. R-squared:          0.925
No. Observations:       7975                              RMSE:          15.69
Df Residuals:           7973                               MAE:           9.31
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.8031      0.5920       0.001     13.6721     15.9935
       MSTORE8      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MUL</code>, nobs=1595, runtime_ms=5.359e-06, p=1.00e-03, R²=0.9461</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.946
Model:                  NNLS                    Adj. R-squared:          0.946
No. Observations:       1595                              RMSE:          10.11
Df Residuals:           1593                               MAE:           6.36
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     10.1673      0.8118       0.001      8.5899     11.6815
           MUL      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>PC</code>, nobs=1595, runtime_ms=1.98e-06, p=1.00e-03, R²=0.9472</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.947
Model:                  NNLS                    Adj. R-squared:          0.947
No. Observations:       1595                              RMSE:          13.98
Df Residuals:           1593                               MAE:           9.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     14.2903      1.2269       0.001     12.0160     16.6217
            PC      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>RETURNDATASIZE</code>, nobs=6380, runtime_ms=5.368e-06, p=1.00e-03, R²=0.8652</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.865
Model:                  NNLS                    Adj. R-squared:          0.865
No. Observations:       6380                              RMSE:          33.46
Df Residuals:           6378                               MAE:          25.81
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     57.4778      1.5006       0.001     54.6717     60.4306
RETURNDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SELFBALANCE</code>, nobs=1595, runtime_ms=1.233e-05, p=1.00e-03, R²=0.9702</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.970
Model:                  NNLS                    Adj. R-squared:          0.970
No. Observations:       1595                              RMSE:          26.70
Df Residuals:           1593                               MAE:          21.90
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     48.1645      2.5311       0.001     43.2829     53.4037
   SELFBALANCE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SUB</code>, nobs=1595, runtime_ms=4.347e-06, p=1.00e-03, R²=0.9147</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.915
Model:                  NNLS                    Adj. R-squared:          0.915
No. Observations:       1595                              RMSE:          13.98
Df Residuals:           1593                               MAE:           7.33
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.9023      1.1188       0.001      6.8541     11.0750
           SUB      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier B), geth

<details markdown="1"><summary><code>JUMP</code>, nobs=1595, runtime_ms=9.644e-06, p=1.00e-03, R²=0.8032</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.803
Model:                  NNLS                    Adj. R-squared:          0.803
No. Observations:       1595                              RMSE:          17.74
Df Residuals:           1593                               MAE:           9.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     18.7051      2.0850       0.001     14.8379     22.9761
          JUMP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>KECCAK256</code>, nobs=25520, runtime_ms=3.778e-05, p=1.00e-03, R²=0.1168</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.117
Model:                  NNLS                    Adj. R-squared:          0.117
No. Observations:       25520                             RMSE:         206.57
Df Residuals:           25518                              MAE:         166.27
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    567.3920      2.7701       0.001    561.9039    572.7694
     KECCAK256      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## nethermind

| glue_opcode | nobs | glue_runtime_ms | p_value | rsquared |
| --- | --- | --- | --- | --- |
| `ISZERO` | 1661 | 5.57e-07 | 1.00e-03 | 0.4845 |
| `JUMPDEST` | 1661 | 3.782e-07 | 1.00e-03 | 0.7618 |
| `SWAP` | 26576 | 6.042e-07 | 1.00e-03 | 0.6358 |
| `CALLDATASIZE` | 98208 | 4.521e-07 | 1.00e-03 | 0.8723 |
| `DUP` | 98208 | 3.413e-07 | 1.00e-03 | 0.8723 |
| `GAS` | 98208 | 3.689e-07 | 1.00e-03 | 0.8723 |
| `MLOAD` | 98208 | 1.923e-06 | 1.00e-03 | 0.8723 |
| `PUSH` | 98208 | 5.851e-07 | 1.00e-03 | 0.8723 |
| `PUSH0` | 98208 | 2.964e-07 | 1.00e-03 | 0.8723 |
| `STATICCALL` | 98208 | 0.0002937 | 1.00e-03 | 0.8723 |
| `ADD` | 1661 | 1.462e-06 | 1.00e-03 | 0.8833 |
| `AND` | 1661 | 1.192e-06 | 1.00e-03 | 0.8966 |
| `CALLDATACOPY` | 39864 | 4.034e-06 | 1.00e-03 | 0.7819 |
| `CALLDATALOAD` | 6644 | 1.757e-05 | 1.00e-03 | 0.09259 |
| `DIV` | 1661 | 5.535e-06 | 1.00e-03 | 0.5437 |
| `EXP` | 1661 | 0 | 1.00e+00 | 0 |
| `GT` | 1661 | 1.467e-06 | 1.00e-03 | 0.9421 |
| `JUMPI` | 1661 | 2.292e-06 | 1.00e-03 | 0.8969 |
| `LT` | 1661 | 1.437e-06 | 1.00e-03 | 0.9415 |
| `MSTORE` | 8305 | 2.749e-06 | 1.00e-03 | 0.9276 |
| `MSTORE8` | 8305 | 2.757e-06 | 1.00e-03 | 0.9166 |
| `MUL` | 1661 | 4.259e-06 | 1.00e-03 | 0.9519 |
| `PC` | 1661 | 6.116e-07 | 1.00e-03 | 0.8791 |
| `RETURNDATASIZE` | 6644 | 9.423e-07 | 1.00e-03 | 0.8028 |
| `SELFBALANCE` | 1661 | 3.767e-06 | 1.00e-03 | 0.9394 |
| `SUB` | 1661 | 2.023e-06 | 1.00e-03 | 0.8617 |
| `JUMP` | 1661 | 2.931e-06 | 1.00e-03 | 0.7711 |
| `KECCAK256` | 26576 | 0 | 1.00e+00 | 0 |

### Cycle glue: joint fit, nethermind

<details markdown="1"><summary>Joint NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.872
Model:                  NNLS                    Adj. R-squared:          0.872
No. Observations:       98208                             RMSE:          10.90
Df Residuals:           98200                              MAE:           7.45
Df Model:               7      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.7698      0.1030       0.001      6.5626      6.9623
  CALLDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
           DUP      0.0000      0.0000       0.001      0.0000      0.0000
           GAS      0.0000      0.0000       0.001      0.0000      0.0000
         MLOAD      0.0000      0.0000       0.001      0.0000      0.0000
          PUSH      0.0000      0.0000       0.001      0.0000      0.0000
         PUSH0      0.0000      0.0000       0.001      0.0000      0.0000
    STATICCALL      0.0003      0.0000       0.001      0.0003      0.0003
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```

</details>

<details markdown="1"><summary><code>CALLDATASIZE</code>, nobs=98208, runtime_ms=4.521e-07, p=1.00e-03, R²=0.8723</summary>




</details>

<details markdown="1"><summary><code>DUP</code>, nobs=98208, runtime_ms=3.413e-07, p=1.00e-03, R²=0.8723</summary>




</details>

<details markdown="1"><summary><code>GAS</code>, nobs=98208, runtime_ms=3.689e-07, p=1.00e-03, R²=0.8723</summary>




</details>

<details markdown="1"><summary><code>MLOAD</code>, nobs=98208, runtime_ms=1.923e-06, p=1.00e-03, R²=0.8723</summary>




</details>

<details markdown="1"><summary><code>PUSH</code>, nobs=98208, runtime_ms=5.851e-07, p=1.00e-03, R²=0.8723</summary>




</details>

<details markdown="1"><summary><code>PUSH0</code>, nobs=98208, runtime_ms=2.964e-07, p=1.00e-03, R²=0.8723</summary>




</details>

<details markdown="1"><summary><code>STATICCALL</code>, nobs=98208, runtime_ms=0.0002937, p=1.00e-03, R²=0.8723</summary>




</details>

### Pure glue, nethermind

<details markdown="1"><summary><code>ISZERO</code>, nobs=1661, runtime_ms=5.57e-07, p=1.00e-03, R²=0.4845</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.484
Model:                  NNLS                    Adj. R-squared:          0.484
No. Observations:       1661                              RMSE:          12.10
Df Residuals:           1659                               MAE:           4.97
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.5041      1.0807       0.001      4.7022      8.9889
        ISZERO      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPDEST</code>, nobs=1661, runtime_ms=3.782e-07, p=1.00e-03, R²=0.7618</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.762
Model:                  NNLS                    Adj. R-squared:          0.762
No. Observations:       1661                              RMSE:          13.36
Df Residuals:           1659                               MAE:          10.20
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.5646      0.9430       0.001      5.7334      9.2993
      JUMPDEST      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SWAP</code>, nobs=26576, runtime_ms=6.042e-07, p=1.00e-03, R²=0.6358</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.636
Model:                  NNLS                    Adj. R-squared:          0.636
No. Observations:       26576                             RMSE:           9.63
Df Residuals:           26574                              MAE:           5.48
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.1578      0.1992       0.001     11.7938     12.5554
          SWAP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier A), nethermind

<details markdown="1"><summary><code>ADD</code>, nobs=1661, runtime_ms=1.462e-06, p=1.00e-03, R²=0.8833</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.883
Model:                  NNLS                    Adj. R-squared:          0.883
No. Observations:       1661                              RMSE:           5.60
Df Residuals:           1659                               MAE:           4.20
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.0229      0.4134       0.001      6.1935      7.8324
           ADD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>AND</code>, nobs=1661, runtime_ms=1.192e-06, p=1.00e-03, R²=0.8966</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.897
Model:                  NNLS                    Adj. R-squared:          0.896
No. Observations:       1661                              RMSE:           4.26
Df Residuals:           1659                               MAE:           3.15
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      5.3164      0.3130       0.001      4.6903      5.9278
           AND      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATACOPY</code>, nobs=39864, runtime_ms=4.034e-06, p=1.00e-03, R²=0.7819</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.782
Model:                  NNLS                    Adj. R-squared:          0.782
No. Observations:       39864                             RMSE:          16.03
Df Residuals:           39862                              MAE:          12.58
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     20.4063      0.0841       0.001     20.2474     20.5684
  CALLDATACOPY      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATALOAD</code>, nobs=6644, runtime_ms=1.757e-05, p=1.00e-03, R²=0.09259</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.093
Model:                  NNLS                    Adj. R-squared:          0.092
No. Observations:       6644                              RMSE:           0.21
Df Residuals:           6642                               MAE:           0.14
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      1.7934      0.0087       0.001      1.7748      1.8095
  CALLDATALOAD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>DIV</code>, nobs=1661, runtime_ms=5.535e-06, p=1.00e-03, R²=0.5437</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.544
Model:                  NNLS                    Adj. R-squared:          0.543
No. Observations:       1661                              RMSE:          40.04
Df Residuals:           1659                               MAE:          29.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    113.4877      5.0126       0.001    103.7268    123.0339
           DIV      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>EXP</code>, nobs=1661, runtime_ms=0, p=1.00e+00, R²=0</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.000
Model:                  NNLS                    Adj. R-squared:         -0.001
No. Observations:       1661                              RMSE:           1.19
Df Residuals:           1659                               MAE:           0.87
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      3.3793      0.0286       0.001      3.3266      3.4388
           EXP      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>GT</code>, nobs=1661, runtime_ms=1.467e-06, p=1.00e-03, R²=0.9421</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.942
Model:                  NNLS                    Adj. R-squared:          0.942
No. Observations:       1661                              RMSE:           3.83
Df Residuals:           1659                               MAE:           2.82
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.7215      0.3203       0.001      6.1109      7.3437
            GT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPI</code>, nobs=1661, runtime_ms=2.292e-06, p=1.00e-03, R²=0.8969</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.897
Model:                  NNLS                    Adj. R-squared:          0.897
No. Observations:       1661                              RMSE:           3.51
Df Residuals:           1659                               MAE:           1.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.7335      0.3051       0.001      4.1499      5.3825
         JUMPI      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>LT</code>, nobs=1661, runtime_ms=1.437e-06, p=1.00e-03, R²=0.9415</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.941
Model:                  NNLS                    Adj. R-squared:          0.941
No. Observations:       1661                              RMSE:           3.77
Df Residuals:           1659                               MAE:           2.84
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.6964      0.3319       0.001      7.0960      8.3617
            LT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE</code>, nobs=8305, runtime_ms=2.749e-06, p=1.00e-03, R²=0.9276</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.928
Model:                  NNLS                    Adj. R-squared:          0.928
No. Observations:       8305                              RMSE:           5.39
Df Residuals:           8303                               MAE:           3.69
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.4334      0.1758       0.001      7.0911      7.7852
        MSTORE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE8</code>, nobs=8305, runtime_ms=2.757e-06, p=1.00e-03, R²=0.9166</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.917
Model:                  NNLS                    Adj. R-squared:          0.917
No. Observations:       8305                              RMSE:           5.84
Df Residuals:           8303                               MAE:           3.95
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.9334      0.2147       0.001      6.5251      7.3527
       MSTORE8      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MUL</code>, nobs=1661, runtime_ms=4.259e-06, p=1.00e-03, R²=0.9519</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.952
Model:                  NNLS                    Adj. R-squared:          0.952
No. Observations:       1661                              RMSE:           7.56
Df Residuals:           1659                               MAE:           5.67
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     11.5409      0.5140       0.001     10.5155     12.5107
           MUL      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>PC</code>, nobs=1661, runtime_ms=6.116e-07, p=1.00e-03, R²=0.8791</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.879
Model:                  NNLS                    Adj. R-squared:          0.879
No. Observations:       1661                              RMSE:           6.78
Df Residuals:           1659                               MAE:           5.35
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.9987      0.4947       0.001      6.0606      7.9056
            PC      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>RETURNDATASIZE</code>, nobs=6644, runtime_ms=9.423e-07, p=1.00e-03, R²=0.8028</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.803
Model:                  NNLS                    Adj. R-squared:          0.803
No. Observations:       6644                              RMSE:           7.38
Df Residuals:           6642                               MAE:           3.83
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.2613      0.3241       0.001      5.6662      6.9088
RETURNDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SELFBALANCE</code>, nobs=1661, runtime_ms=3.767e-06, p=1.00e-03, R²=0.9394</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.939
Model:                  NNLS                    Adj. R-squared:          0.939
No. Observations:       1661                              RMSE:          11.83
Df Residuals:           1659                               MAE:           8.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     16.5843      0.9829       0.001     14.7251     18.5877
   SELFBALANCE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SUB</code>, nobs=1661, runtime_ms=2.023e-06, p=1.00e-03, R²=0.8617</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.862
Model:                  NNLS                    Adj. R-squared:          0.862
No. Observations:       1661                              RMSE:           8.53
Df Residuals:           1659                               MAE:           5.87
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.8375      0.5875       0.001      5.6454      7.9713
           SUB      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier B), nethermind

<details markdown="1"><summary><code>JUMP</code>, nobs=1661, runtime_ms=2.931e-06, p=1.00e-03, R²=0.7711</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.771
Model:                  NNLS                    Adj. R-squared:          0.771
No. Observations:       1661                              RMSE:           5.94
Df Residuals:           1659                               MAE:           3.07
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.2891      0.5737       0.001      6.2512      8.4384
          JUMP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>KECCAK256</code>, nobs=26576, runtime_ms=0, p=1.00e+00, R²=0</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.000
Model:                  NNLS                    Adj. R-squared:         -0.000
No. Observations:       26576                             RMSE:         216.15
Df Residuals:           26574                              MAE:         177.96
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    316.4548      1.2984       0.001    313.9681    319.1505
     KECCAK256      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

## reth

| glue_opcode | nobs | glue_runtime_ms | p_value | rsquared |
| --- | --- | --- | --- | --- |
| `ISZERO` | 946 | 1.733e-06 | 1.00e-03 | 0.9283 |
| `JUMPDEST` | 946 | 5.286e-07 | 1.00e-03 | 0.9638 |
| `SWAP` | 15136 | 6.168e-07 | 1.00e-03 | 0.6087 |
| `CALLDATASIZE` | 56023 | 8.685e-07 | 1.00e-03 | 0.7803 |
| `DUP` | 56023 | 5.92e-07 | 1.00e-03 | 0.7803 |
| `GAS` | 56023 | 7.167e-07 | 1.00e-03 | 0.7803 |
| `MLOAD` | 56023 | 2.045e-06 | 1.00e-03 | 0.7803 |
| `PUSH` | 56023 | 6.92e-07 | 1.00e-03 | 0.7803 |
| `PUSH0` | 56023 | 5.795e-07 | 1.00e-03 | 0.7803 |
| `STATICCALL` | 56023 | 8.121e-05 | 1.00e-03 | 0.7803 |
| `ADD` | 946 | 1.476e-06 | 1.00e-03 | 0.9394 |
| `AND` | 946 | 1.415e-06 | 1.00e-03 | 0.9245 |
| `CALLDATACOPY` | 22704 | 4.241e-06 | 1.00e-03 | 0.9118 |
| `CALLDATALOAD` | 3784 | 0 | 1.00e+00 | 1.11e-16 |
| `DIV` | 946 | 1.067e-05 | 1.00e-03 | 0.9476 |
| `EXP` | 946 | 0.0006835 | 1.00e-03 | 0.9599 |
| `GT` | 946 | 1.557e-06 | 1.00e-03 | 0.9486 |
| `JUMPI` | 946 | 2.255e-06 | 1.00e-03 | 0.9359 |
| `LT` | 946 | 3.08e-06 | 1.00e-03 | 0.6899 |
| `MSTORE` | 4730 | 3.655e-06 | 1.00e-03 | 0.3993 |
| `MSTORE8` | 4730 | 2.186e-06 | 1.00e-03 | 0.9256 |
| `MUL` | 946 | 2.269e-06 | 1.00e-03 | 0.9441 |
| `PC` | 946 | 9.372e-07 | 1.00e-03 | 0.6985 |
| `RETURNDATASIZE` | 3784 | 1.398e-06 | 1.00e-03 | 0.9506 |
| `SELFBALANCE` | 946 | 8.157e-06 | 1.00e-03 | 0.9606 |
| `SUB` | 946 | 1.577e-06 | 1.00e-03 | 0.9326 |
| `JUMP` | 946 | 4.242e-06 | 1.00e-03 | 0.9527 |
| `KECCAK256` | 15136 | 0 | 1.00e+00 | 0 |

### Cycle glue: joint fit, reth

<details markdown="1"><summary>Joint NNLS regression summary</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.780
Model:                  NNLS                    Adj. R-squared:          0.780
No. Observations:       56023                             RMSE:          11.59
Df Residuals:           56015                              MAE:           5.08
Df Model:               7      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.5101      0.1636       0.001      9.1948      9.8325
  CALLDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
           DUP      0.0000      0.0000       0.001      0.0000      0.0000
           GAS      0.0000      0.0000       0.001      0.0000      0.0000
         MLOAD      0.0000      0.0000       0.001      0.0000      0.0000
          PUSH      0.0000      0.0000       0.001      0.0000      0.0000
         PUSH0      0.0000      0.0000       0.001      0.0000      0.0000
    STATICCALL      0.0001      0.0000       0.001      0.0001      0.0001
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```

</details>

<details markdown="1"><summary><code>CALLDATASIZE</code>, nobs=56023, runtime_ms=8.685e-07, p=1.00e-03, R²=0.7803</summary>




</details>

<details markdown="1"><summary><code>DUP</code>, nobs=56023, runtime_ms=5.92e-07, p=1.00e-03, R²=0.7803</summary>




</details>

<details markdown="1"><summary><code>GAS</code>, nobs=56023, runtime_ms=7.167e-07, p=1.00e-03, R²=0.7803</summary>




</details>

<details markdown="1"><summary><code>MLOAD</code>, nobs=56023, runtime_ms=2.045e-06, p=1.00e-03, R²=0.7803</summary>




</details>

<details markdown="1"><summary><code>PUSH</code>, nobs=56023, runtime_ms=6.92e-07, p=1.00e-03, R²=0.7803</summary>




</details>

<details markdown="1"><summary><code>PUSH0</code>, nobs=56023, runtime_ms=5.795e-07, p=1.00e-03, R²=0.7803</summary>




</details>

<details markdown="1"><summary><code>STATICCALL</code>, nobs=56023, runtime_ms=8.121e-05, p=1.00e-03, R²=0.7803</summary>




</details>

### Pure glue, reth

<details markdown="1"><summary><code>ISZERO</code>, nobs=946, runtime_ms=1.733e-06, p=1.00e-03, R²=0.9283</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.928
Model:                  NNLS                    Adj. R-squared:          0.928
No. Observations:       946                               RMSE:          10.15
Df Residuals:           944                                MAE:           7.93
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     17.6447      0.8059       0.001     16.0742     19.3751
        ISZERO      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPDEST</code>, nobs=946, runtime_ms=5.286e-07, p=1.00e-03, R²=0.9638</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.964
Model:                  NNLS                    Adj. R-squared:          0.964
No. Observations:       946                               RMSE:           6.47
Df Residuals:           944                                MAE:           5.04
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      5.0375      0.6148       0.001      3.8493      6.3263
      JUMPDEST      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SWAP</code>, nobs=15136, runtime_ms=6.168e-07, p=1.00e-03, R²=0.6087</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.609
Model:                  NNLS                    Adj. R-squared:          0.609
No. Observations:       15136                             RMSE:          10.42
Df Residuals:           15134                              MAE:           3.66
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      9.6704      0.3018       0.001      9.0407     10.2491
          SWAP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier A), reth

<details markdown="1"><summary><code>ADD</code>, nobs=946, runtime_ms=1.476e-06, p=1.00e-03, R²=0.9394</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.939
Model:                  NNLS                    Adj. R-squared:          0.939
No. Observations:       946                               RMSE:           3.95
Df Residuals:           944                                MAE:           3.01
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.6471      0.3467       0.001      6.9845      8.3680
           ADD      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>AND</code>, nobs=946, runtime_ms=1.415e-06, p=1.00e-03, R²=0.9245</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.925
Model:                  NNLS                    Adj. R-squared:          0.924
No. Observations:       946                               RMSE:           4.26
Df Residuals:           944                                MAE:           3.19
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.3728      0.3879       0.001      5.5896      7.0971
           AND      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATACOPY</code>, nobs=22704, runtime_ms=4.241e-06, p=1.00e-03, R²=0.9118</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.912
Model:                  NNLS                    Adj. R-squared:          0.912
No. Observations:       22704                             RMSE:           9.93
Df Residuals:           22702                              MAE:           7.57
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.3806      0.0750       0.001     15.2350     15.5306
  CALLDATACOPY      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>CALLDATALOAD</code>, nobs=3784, runtime_ms=0, p=1.00e+00, R²=1.11e-16</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.000
Model:                  NNLS                    Adj. R-squared:         -0.000
No. Observations:       3784                              RMSE:           2.89
Df Residuals:           3782                               MAE:           2.71
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      4.6479      0.0546       0.001      4.5365      4.7421
  CALLDATALOAD      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>DIV</code>, nobs=946, runtime_ms=1.067e-05, p=1.00e-03, R²=0.9476</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.948
Model:                  NNLS                    Adj. R-squared:          0.948
No. Observations:       946                               RMSE:          19.82
Df Residuals:           944                                MAE:          15.26
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     32.8339      1.9656       0.001     29.0536     36.6122
           DIV      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>EXP</code>, nobs=946, runtime_ms=0.0006835, p=1.00e-03, R²=0.9599</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.960
Model:                  NNLS                    Adj. R-squared:          0.960
No. Observations:       946                               RMSE:           5.47
Df Residuals:           944                                MAE:           4.10
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.3537      0.5200       0.001      6.2666      8.3683
           EXP      0.0007      0.0000       0.001      0.0007      0.0007
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>GT</code>, nobs=946, runtime_ms=1.557e-06, p=1.00e-03, R²=0.9486</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.949
Model:                  NNLS                    Adj. R-squared:          0.949
No. Observations:       946                               RMSE:           3.82
Df Residuals:           944                                MAE:           2.89
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.3410      0.3790       0.001      7.5555      9.0444
            GT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>JUMPI</code>, nobs=946, runtime_ms=2.255e-06, p=1.00e-03, R²=0.9359</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.936
Model:                  NNLS                    Adj. R-squared:          0.936
No. Observations:       946                               RMSE:           2.66
Df Residuals:           944                                MAE:           2.05
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      6.3590      0.2753       0.001      5.8228      6.9040
         JUMPI      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>LT</code>, nobs=946, runtime_ms=3.08e-06, p=1.00e-03, R²=0.6899</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.690
Model:                  NNLS                    Adj. R-squared:          0.690
No. Observations:       946                               RMSE:          22.41
Df Residuals:           944                                MAE:          18.51
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      0.0000      0.3208       1.000      0.0000      1.0370
            LT      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE</code>, nobs=4730, runtime_ms=3.655e-06, p=1.00e-03, R²=0.3993</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.399
Model:                  NNLS                    Adj. R-squared:          0.399
No. Observations:       4730                              RMSE:          31.47
Df Residuals:           4728                               MAE:          28.88
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     15.2515      1.3197       0.001     12.7658     17.9468
        MSTORE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MSTORE8</code>, nobs=4730, runtime_ms=2.186e-06, p=1.00e-03, R²=0.9256</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.926
Model:                  NNLS                    Adj. R-squared:          0.926
No. Observations:       4730                              RMSE:           4.35
Df Residuals:           4728                               MAE:           2.43
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      8.1771      0.2186       0.001      7.7749      8.6256
       MSTORE8      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>MUL</code>, nobs=946, runtime_ms=2.269e-06, p=1.00e-03, R²=0.9441</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.944
Model:                  NNLS                    Adj. R-squared:          0.944
No. Observations:       946                               RMSE:           4.36
Df Residuals:           944                                MAE:           3.22
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.9356      0.4341       0.001      7.1101      8.7794
           MUL      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>PC</code>, nobs=946, runtime_ms=9.372e-07, p=1.00e-03, R²=0.6985</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.698
Model:                  NNLS                    Adj. R-squared:          0.698
No. Observations:       946                               RMSE:          18.42
Df Residuals:           944                                MAE:           6.44
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     12.6705      2.1697       0.001      8.9241     17.4679
            PC      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>RETURNDATASIZE</code>, nobs=3784, runtime_ms=1.398e-06, p=1.00e-03, R²=0.9506</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.951
Model:                  NNLS                    Adj. R-squared:          0.951
No. Observations:       3784                              RMSE:           5.03
Df Residuals:           3782                               MAE:           3.87
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.2148      0.2424       0.001      6.7305      7.7088
RETURNDATASIZE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SELFBALANCE</code>, nobs=946, runtime_ms=8.157e-06, p=1.00e-03, R²=0.9606</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.961
Model:                  NNLS                    Adj. R-squared:          0.961
No. Observations:       946                               RMSE:          20.42
Df Residuals:           944                                MAE:          14.68
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const     25.5432      2.0561       0.001     21.5949     29.6617
   SELFBALANCE      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>SUB</code>, nobs=946, runtime_ms=1.577e-06, p=1.00e-03, R²=0.9326</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.933
Model:                  NNLS                    Adj. R-squared:          0.932
No. Observations:       946                               RMSE:           4.47
Df Residuals:           944                                MAE:           3.30
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.5872      0.4474       0.001      6.7499      8.4413
           SUB      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

### Mixed glue (tier B), reth

<details markdown="1"><summary><code>JUMP</code>, nobs=946, runtime_ms=4.242e-06, p=1.00e-03, R²=0.9527</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.953
Model:                  NNLS                    Adj. R-squared:          0.953
No. Observations:       946                               RMSE:           3.51
Df Residuals:           944                                MAE:           2.67
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const      7.6319      0.3450       0.001      6.9064      8.2729
          JUMP      0.0000      0.0000       0.001      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>

<details markdown="1"><summary><code>KECCAK256</code>, nobs=15136, runtime_ms=0, p=1.00e+00, R²=0</summary>

```
==============================================================================
                           NNLS Regression Results                            
==============================================================================
Dep. Variable:          test_runtime_ms              R-squared:          0.000
Model:                  NNLS                    Adj. R-squared:         -0.000
No. Observations:       15136                             RMSE:         297.58
Df Residuals:           15134                              MAE:         246.59
Df Model:               1      
==============================================================================
                      coef     std err     P-value      [0.025      0.975]
------------------------------------------------------------------------------
         const    437.3304      2.3390       0.001    432.7476    441.9862
     KECCAK256      0.0000      0.0000       1.000      0.0000      0.0000
==============================================================================
Notes: Non-negative least squares with bootstrap inference (1000 iterations)
==============================================================================
```




</details>
