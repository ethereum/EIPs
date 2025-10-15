# Falcon in python

This repository implements the signature scheme Falcon (https://falcon-sign.info/).
Falcon stands for **FA**st Fourier **L**attice-based **CO**mpact signatures over **N**TRU

**Authors: Renaud Dubois and Simon Masson.**

<small>Acknowledgements: Thomas Prest for the originial code, Zhenfei Zhang for the possible optimizations.</small>

:warning: This is an experimental code, not the [reference code](https://falcon-sign.info/) of Falcon.. It is not considered secure or suitable for production. 

License: MIT.

## Interface

It is possible to generate a key pair, sign a message and verify a signature in one command-line.

###### Key generation


```
./sign_cli.py genkeys --version='falcon' # or 'ethfalcon'
```
It creates two files `private_key.pem` and `public_key.pem` storing the private and public keys.
It also prints the public key in Solidity format.

###### Signature
```
./sign_cli.py sign --data=deadbeef --privkey=private_key.pem
```
It create a signature file `sig` for the given  message and the private key.
The signature is stored in hexadecimal format.
It also prints the signature in Solidity format.

###### Verification
```
./sign_cli.py verify --data=deadbeef --pubkey=public_key.pem --signature='sig'
```
It outputs the validity of the signature with respect to a message and a public key given as input.
The signature needs to be provided as a (large) string.


<!-- ## Profiling

I included a makefile target to performing profiling on the code. If you type `make profile` on a Linux machine, you should obtain something along these lines:

![kcachegrind](https://tprest.github.io/images/kcachegrind_falcon.png)

Make sure you have `pyprof2calltree` and `kcachegrind` installed on your machine, or it will not work. -->

## Tests

Tests of key generation, signing and verification can be done in iterative and recursive NTT. The HashToPoint can be set with the SHAKE256, KeccaXOF (implemented in Tetration), or KeccakPRNG (a PRNG based on Keccak).
```
make test
```
This runs the original tests, and additional tests made in `test_xxx.py`.

## Benchmarks

:warning: This implementation is not optimized.

<table>
  <tr>
    <th rowspan="2">n</th>
    <th colspan="2">Key generation</th>
    <th colspan="2">Signature</th>
    <th colspan="4">Verification</th>
  </tr>
  <tr>
    <td>NTT iterative</td>
    <td>NTT recursive</td>
    <td>SHAKE256</td>
    <td>KeccaXOF</td>
    <td>NTT iterative</td>
    <td>NTT recursive</td>
    <td>SHAKE256</td>
    <td>KeccaXOF</td>
  </tr>
  <tr>
    <td>64</td>
    <td>180 ms</td>
    <td>96 ms</td>
    <td>2.4 ms</td>
    <td>2.4 ms</td>
    <td>0.3 ms</td>
    <td>0.6 ms</td>
    <td>0.3 ms</td>
    <td>0.4 ms</td>
  </tr>
  <tr>
    <td>128</td>
    <td>825 ms</td>
    <td>1033 ms</td>
    <td>4.7 ms</td>
    <td>4.7 ms</td>
    <td>0.6 ms</td>
    <td>1.4 ms</td>
    <td>0.6 ms</td>
    <td>0.7 ms</td>
  </tr>
  <tr>
    <td>256</td>
    <td>1051 ms</td>
    <td>1530 ms</td>
    <td>9.7 ms</td>
    <td>9.4 ms</td>
    <td>1.3 ms</td>
    <td>3.0 ms</td>
    <td>1.3 ms</td>
    <td>1.3 ms</td>
  </tr>
  <tr>
    <td>512</td>
    <td>2273 ms</td>
    <td>1755 ms</td>
    <td>19.2 ms</td>
    <td>19.0 ms</td>
    <td>3.0 ms</td>
    <td>6.6 ms</td>
    <td>3.0 ms</td>
    <td>3.0 ms</td>
  </tr>
  <tr>
    <td>1024</td>
    <td>10256 ms</td>
    <td>13652 ms</td>
    <td>39.3 ms</td>
    <td>39.2 ms</td>
    <td>6.4 ms</td>
    <td>14.2 ms</td>
    <td>6.4 ms</td>
    <td>6.2 ms</td>
  </tr>
</table>
