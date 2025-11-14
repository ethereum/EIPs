# falcon.py

This folder contains some files that are helpful to implement Falcon, test it and understand where parameters/constants come from.

## Content

This repository contains the following files:

1. [`generate_constants.sage`](generate_constants.sage) can be used in SageMath to generate the FFT and NTT constants.
1. [`parameters.py`](parameters.py) is a script that generates parameters used in the Round 3 specification as well as the C implementation.
1. [`saga.py`](saga.py) contains the SAGA test suite to test Gaussian samplers. It is used in [`../test.py`](../test.py).
1. [`samplerz_KAT512.py`](samplerz_KAT512.py) and [`samplerz_KAT1024.py`](samplerz_KAT1024.py) contain test vectors for the sampler over the integers. They are used in [`../test.py`](../test.py).
1. [`sign_KAT.py`](sign_KAT.py) contains test vectors for the signing procedure. It is used in [`../test.py`](../test.py).

## License

MIT
