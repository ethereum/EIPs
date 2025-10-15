# Solidity contract implementation

This directory implements the contracts for ML-DSA FIPS-204 and the alternative version with KeccakPRNG as a hash function, called here ETHDilithium.

In order to install the required dependencies:
```bash
make install
```

For running the tests located in `./tests/`:
```bash
make test
```

For having the optimized gas costs (this can take few seconds):
```bash
make test_slow
```

This should lead to:
```solidity
Ran 1 test for test/ZKNOX_ethdilithium.t.sol:ETHDilithiumTest
[PASS] testVerify() (gas: 8920414)
Logs:
  Gas used: 8803665

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 21.14ms (17.85ms CPU time)

Ran 1 test for test/ZKNOX_dilithium.t.sol:DilithiumTest
[PASS] testVerify() (gas: 15562254)
Logs:
  Gas used: 15445505
```

The gas cost is summarized in the following table:
|Version|Gas cost|
|-|-|
|FIPS-204| 15.45 M|
|DilithiumETH|8.80 M|