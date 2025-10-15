# ETHDILITHIUM

ETHDILITHIUM gathers experiments around DILITHIUM adaptations for the ETHEREUM ecosystem. DILITHIUM signature scheme is a post-quantum digital signature algorithm.


## SPECIFICATION
The repo implements two version of DILITHIUM: one follows the NIST released implementation, and another is tunned for Ethereum Virtual Machine constraints. 
TODO write specifications (help with #Issue7).

## INSTALLATION
**This is an experimental work, not audited: DO NOT USE IN PRODUCTION, LOSS OF FUND WILL OCCUR**

The repo contains a solidity verifier and a python signer.

* **Installation:**
    ```bash
    make install
    ```
    (or `make install_signer` or `make install_verifier`)
* **Generation of test vectors:**
    ```bash
    make gen_test_vectors
    ```
    Generate the test vectors of `test/ZKNOX_dilithium.t.sol` and `test/ZKNOX_ethdilithium.t.sol`.
* **Tests:**
    ```bash
    make test
    ```
     (or `make test_signer` or `make test_verifier`)

## BENCHMARKS

|Signature verification | Gas cost|Status|
|-|-|-|
|Dilithium|13.5M|OK (NIST KAT pass)|
|ETHDilithium|6.6M|OK|

Dilithium is an implementation of the NIST standardized signature scheme, where the public key is expanded in order to save computations.
ETHDilithium is an alternative version with a cheaper hash function and precomputations in the public key and signer in order to accelerate the verification. 

## EXAMPLE 
An example of key generation, signature and verification in python is provided in [this file](python-ref/example.py), for Dilithium and ETHDilithium.
A signature verification can be computed in Solidity, as illustrated in [this file](test/ZKNOX_dilithiumKATS.t.sol) with a KAT vector from the NIST submission.


## CONCLUSION
This repo provides an optimized version of DILITHIUM. Order of magnitudes were gained compared to other implementations. Despite those efforts, it is not feasible to reach the same cost as [Falcon](https://github.com/ZKNoxHQ/ETHFALCON) post-quantum signature. The implementation takes advantage of the NTT implementation of [this repository](https://github.com/ZKNoxHQ/NTT). The main reason for adopting Dilithium for Ethereum is the simplicity and efficiency of the signer algorithm for hardware wallet. 

----

_Acknowledgements._ Giacomo Pope for the [original](https://github.com/GiacomoPope/dilithium-py/) python implementation.
