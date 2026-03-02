# NTT
Generic implementation of the Number Theoretic Transform in the context of cryptography applications.

We provide tests for various NTT-friendly rings, including Falcon's ring with `q = 12*1024+1` and the defining polynomial `x¹⁰²⁴+1`.

The implementation requires the file `ntt_constants.py`, generated using `python generate_constants.py`.

## Install
```
make install
```

## Tests
For running all tests:
```
make test
```
For running a specific test, use:
```
make test TEST=test_ntt_recursive.TestNTTRecursive.test_ntt_intt
```

## Benchmarks
For running the benchmarks:
```
make bench
```
Note that the field arithmetic is not optimized. For example, Montgomery multiplication is not implemented here.