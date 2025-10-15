# Dilithium Python


Implementation based on [this repository](https://github.com/GiacomoPope/dilithium-py/). We use the NTT implemented by ZKNOX [here](https://github.com/zkNoxHQ/ntt) and the first task is to replace SHAKE by Keccak_prng.

:warning: This is a work in progress. Do not use in production.

## Install
```bash
make install
```

## Test
```bash
make test
```

## Example

We provide an example of keygen/signature/verification in [this file](dilithium_py/example.py):
```python
from .dilithium import ETHDilithium2

msg = b"We are ZKNox."
pk, sk = ETHDilithium2.keygen()
sig = ETHDilithium2.sign(sk, msg)
assert ETHDilithium2.verify(pk, msg, sig)
```
This can be run using
```bask
make example
``` 