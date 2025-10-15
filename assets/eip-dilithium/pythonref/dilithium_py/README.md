[![License MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://github.com/GiacomoPope/dilithium-py/blob/main/LICENSE)
[![GitHub CI](https://github.com/GiacomoPope/dilithium-py/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/GiacomoPope/dilithium-py/actions/workflows/ci.yml)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)

# CRYSTALS-Dilithium Python Implementation

> [!CAUTION]
> :warning: **Under no circumstances should this be used for cryptographic
applications.** :warning:
> 
> This is an educational resource and has not been designed to be secure
> against any form of side-channel attack. The intended use of this project
> is for learning and experimenting with ML-DSA and Dilithium

This repository contains a pure python implementation of both:

1. **ML-DSA** the NIST Module-Lattice-Based Digital Signature Standard following
   the [FIPS 204](https://csrc.nist.gov/pubs/fips/204/final) based off the Dilithium
   submission to the NIST post-quantum project.
1. **CRYSTALS-Dilithium**: following (at the time of writing) the most recent
  [specification](https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf) (v3.1)

**Note**: This project has followed
[`kyber-py`](https://github.com/GiacomoPope/kyber-py) which is a pure-python
implementation of CRYSTALS-Kyber and ML-KEM and reuses a lot of code. 

## Disclaimer

I have written `dilithium-py` as a way to learn about the way protocol works,
and to try and create a clean, well commented implementation which people can
learn from.

This code is not constant time, or written to be performant. Rather, it was 
written so that reading though the pseudocode of the 
[specification](https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf)
closely matches the code which we use within `dilithium.py` and supporting files.

## History of this Repository

This work started by simply implementing Dilithium for fun, however after NIST
picked Dilithium to standardise as ML-DSA, the repository grew and now includes
both implementations of Dilithium and ML-DSA. I assume as this repository ages,
the Dilithium implementation will get less useful and the ML-DSA one will be the
focus, but for historical reasons we will include both. If only so that people
can study the differences which NIST introduced during the standardisation of
the protocol.

### KATs

This implementation passes all the KAT vectors for `dilithium` and `ml_dsa`. For more information see the unit tests in [`test_ml_dsa.py`](tests/test_ml_dsa.py) and [`test_dilithium.py`](tests/test_dilithium.py)

The KAT files were either downloaded or generated:

1. For **ML-DSA**, the KAT files were download from the GitHub repository
   [usnistgov/ACVP-Server/](https://github.com/usnistgov/ACVP-Server/releases/tag/v1.1.0.35) release 1.1.0.35, and are included in `assets/ML-DSA-*` directories.
2. For **Dilithium**, the KAT files were generated from the projects [GitHub
   repository](https://github.com/pq-crystals/dilithium/) and are included in
   `assets/PQCsignKAT_*.rsp`

### Generating KAT files for Dilithium

This implementation is based off the most recent specification (v3.1). 
There were 
[breaking changes](https://github.com/pq-crystals/dilithium/commit/e989e691ae3d3f5933d012ab074bdc413ebc6fad) 
to the KAT files submitted to NIST when Dilithium was updated to 3.1, so the
NIST KAT files will not match our code.

To deal with this, we generated our own KAT files from the 
[reference implementation](https://github.com/pq-crystals/dilithium/releases/tag/v3.1)
for version 3.1. These are the files inside [assets](assets/).

### Dependencies

Originally, as with `kyber-py`, this project was planned to have zero
dependencies, however like `kyber-py`, to pass the KATs, I need  a 
deterministic CSRNG. The reference implementation uses
AES256 CTR DRBG. I have implemented this in [`ase256_ctr_drbg.py`](src/dilithium_py/drbg/ase256_ctr_drbg.py). 
However, I have not implemented AES itself, instead I import this from `pycryptodome`.

To install dependencies, run `pip install -r requirements.txt`.

If you're happy to use system randomness (`os.urandom`) then you don't need
this dependency.

#### `xoflib`

There is an additional optional dependency of
[`xoflib`](https://github.com/GiacomoPope/xoflib) which is a python package with
bindings to many Rust implementations of eXtendable-Output Functions (XOFx). The
creation of this package was inspired by this repository as Dilithium needs a streaming API from the shake XOFs which `hashlib` doesn't support.

`xoflib` can be installed by running `pip install xoflib` or by installing from requirements as above.

If you do not wish to install this dependency, then we include a small
[`shake_wrapper`](src/dilithium_py/shake/shake_wrapper.py) to mimic `xoflib` but
with a much higher memory consumption due to the limitations of `hashlib`.

## Using dilithium-py

### ML DSA

There are three functions exposed on the `ML_DSA` class which are intended
for use:

- `ML_DSA.keygen()`: generate a bit-packed keypair `(pk, sk)`
- `ML_DSA.sign(sk, msg)`: generate a bit-packed signature `sig` 
from the message `msg` and bit-packed secret key `sk`.
- `ML_DSA.verify(pk, msg, sig)`: verify that the bit-packed `sig` is
valid for a given message `msg` and bit-packed public key `pk`.

To use `ML_DSA()`, it must be initialised with a dictionary of the 
protocol parameters. An example can be seen in `DEFAULT_PARAMETERS` in
the file [`ml_dsa.py`](src/dilithium_py/ml_dsa/default_parameters.py)

Additionally, the class has been initialised with these default parameters, 
so you can simply import the NIST level you want to play with:

#### Example

```python
>>> from dilithium_py.ml_dsa import ML_DSA_44
>>>
>>> # Example of signing
>>> pk, sk = ML_DSA_44.keygen()
>>> msg = b"Your message signed by ML_DSA"
>>> sig = ML_DSA_44.sign(sk, msg)
>>> assert ML_DSA_44.verify(pk, msg, sig)
>>>
>>> # Verification will fail with the wrong msg or pk
>>> assert not ML_DSA_44.verify(pk, b"", sig)
>>> pk_new, sk_new = ML_DSA_44.keygen()
>>> assert not ML_DSA_44.verify(pk_new, msg, sig)
```

The above example would also work with the other NIST levels
`ML_DSA_65` and `ML_DSA_87`.

### Benchmarks

Some very rough benchmarks to give an idea about performance:

|  1000 Iterations         | `ML_DSA_44`  | `ML_DSA_65`  | `ML_DSA_87`  |
|--------------------------|--------------|--------------|--------------|
| `KeyGen()` Median Time   |  6 ms        | 10 ms        | 14 ms        |
| `Sign()`   Median Time   |  29 ms       | 49 ms        | 59 ms        |
| `Sign()`   Average Time  |  36 ms       | 62 ms        | 75 ms        |
| `Verify()` Median Time   |  8 ms        | 11 ms        | 17 ms        |

All times recorded using a Intel Core i7-9750H CPU averaged over 1000 calls. 

### Dilithium

There are three functions exposed on the `Dilithium` class which are intended
for use:

- `Dilithium.keygen()`: generate a bit-packed keypair `(pk, sk)`
- `Dilithium.sign(sk, msg)`: generate a bit-packed signature `sig` 
from the message `msg` and bit-packed secret key `sk`.
- `Dilithium.verify(pk, msg, sig)`: verify that the bit-packed `sig` is
valid for a given message `msg` and bit-packed public key `pk`.

To use `Dilithium()`, it must be initialised with a dictionary of the 
protocol parameters. An example can be seen in `DEFAULT_PARAMETERS` in
the file [`dilithium.py`](src/dilithium_py/dilithium/default_parameters.py)

Additionally, the class has been initialised with these default parameters, 
so you can simply import the NIST level you want to play with:

#### Example

```python
>>> from dilithium_py.dilithium import Dilithium2
>>>
>>> # Example of signing
>>> pk, sk = Dilithium2.keygen()
>>> msg = b"Your message signed by Dilithium"
>>> sig = Dilithium2.sign(sk, msg)
>>> assert Dilithium2.verify(pk, msg, sig)
>>>
>>> # Verification will fail with the wrong msg or pk
>>> assert not Dilithium2.verify(pk, b"", sig)
>>> pk_new, sk_new = Dilithium2.keygen()
>>> assert not Dilithium2.verify(pk_new, msg, sig)
```

The above example would also work with the other NIST levels
`Dilithium3` and `Dilithium5`.

### Benchmarks

Some very rough benchmarks to give an idea about performance:

|  1000 Iterations         | `Dilithium2`  | `Dilithium3`  | `Dilithium5`  |
|--------------------------|---------------|--------------|--------------|
| `KeyGen()` Median Time   |  6 ms         |  9 ms        | 15 ms        |
| `Sign()`   Median Time   |  27 ms        | 46 ms        | 58 ms        |
| `Sign()`   Average Time  |  35 ms        | 58 ms        | 72 ms        |
| `Verify()` Median Time   |  7 ms         | 11 ms        | 18 ms        |

All times recorded using a Intel Core i7-9750H CPU averaged over 1000 calls.

## Discussion of Implementation

### Optimising decomposition and making hints

You may notice that ML DSA has marginally slower signing than the reported
Dilithium times included above. This is because the ML DSA implementation
follows the NIST spec while the Dilithium implementation includes an
optimisation of decomposition and hint generation. Details of this are given in
Section 5.1 of the [Dilithium
specification](https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf).
We discuss it informally below and would like to thank Keegan Ryan for helping
understand the differences between the two hint generation functions.

When it comes to implementing the optimisation, not only are slightly different
vectors used during the computation, but the generation of the hint $\mathbf{h}$
coefficients themselves is subtly different.

For the NIST specification the hint is generated by considering the vectors
$-c\mathbf{t}_0$ and $\mathbf{w} -c\mathbf{s}_1 + -c\mathbf{t}_0$ and each
coefficient of each polynomial within $\mathbf{h}$ is computed by checking if
the top bits will change when the coefficients `r` and `r + z` are added
together. This is computed using algorithm 39 from FIPS 204:

```py
def make_hint(z, r, a, q):
    """
    Check whether the top bit of z will change when r is added
    """
    r1 = high_bits(r, a, q)
    v1 = high_bits(r + z, a, q)
    return int(r1 != v1)
```

This function is used pairwise for every coefficient of every polynomial in the
two vectors: $-c\mathbf{t}_0$ and $\mathbf{w} -c\mathbf{s}_1 + -c\mathbf{t}_0$.

For the Dilithium optimisation, rather than computing only the high bits of
$\mathbf{w}$ as $\mathbf{w}_1$, for the same cost, one can compute both the high
and low bits denoted $\mathbf{w}_1$ and $\mathbf{w}_0$. Then, the hint can be
constructed from $\mathbf{w}_0$ (and a further call to low bits for
$\mathbf{r}_0$ in line 21 of Algorithm 7 of FIPS 204 can be avoided). Precisely, the hint is generated from the two vectors  $\mathbf{w}_0 -c\mathbf{s}_1 + -c\mathbf{t}_0$ and $\mathbf{w}_1$.

As the inputs to the hint generation are now used from the decomposition, where
top bits have already been removed, the `make_hint()` function has to check
whether high bits are set in the result of `low_bits(r) + z`, which is computed
using the following function:

```py
def make_hint_optimised(z, r, a, q):
    """
    Optimised version of the above used when the low bits w0 are extracted from
    `w = (A_hat @ y_hat).from_ntt()` during signing
    """
    gamma2 = a >> 1
    if z <= gamma2 or z > (q - gamma2) or (z == (q - gamma2) and r == 0):
        return 0
    return 1
```

In particular, when `z = q-1`, `make_hint()` will return `1`, while the `make_hint_optimised()` returns `0`. 

As this optimisation is present in most implementations, this has caused a
confusion about whether `make_hint()` is correct as the output is different to
`make_hint_optimised()`. 

It's important to realise the output of these make hints functions is different
with the same input vectors, but the hint vector will be identical in the cases that:

- `make_hint()` is used with $-c\mathbf{t}_0$ and $\mathbf{w} -c\mathbf{s}_1 + -c\mathbf{t}_0$
- `make_hint_optimised()` is used with $\mathbf{w}_0 -c\mathbf{s}_1 + -c\mathbf{t}_0$ and $\mathbf{w}_1$

This means that for an implementation one can pick either the NIST documented
algorithm or the optimisation in 5.1 of Dilithium and the resulting signatures
will be identical (indeed, you can use either method and have all KAT vectors
pass.)

### Polynomials

The file [`polynomials.py`](src/dilithium_py/polynomials/polynomials_generic.py) contains the classes 
`PolynomialRing` and 
`Polynomial`. This implements the univariate polynomial ring

$$
R_q = \mathbb{F}_q[X] /(X^n + 1) 
$$

The implementation is inspired by `SageMath` and you can create the
ring $R_{11} = \mathbb{F}_{11}[X] /(X^8 + 1)$ in the following way:

#### Example

```python
>>> R = PolynomialRing(11, 8)
>>> x = R.gen()
>>> f = 3*x**3 + 4*x**7
>>> g = R.random_element(); g
5 + x^2 + 5*x^3 + 4*x^4 + x^5 + 3*x^6 + 8*x^7
>>> f*g
8 + 9*x + 10*x^3 + 7*x^4 + 2*x^5 + 5*x^6 + 10*x^7
>>> f + f
6*x^3 + 8*x^7
>>> g - g
0
```

### Modules

The file [`modules.py`](src/dilithium_py/modules/modules_generic.py) contains the classes `Module` and `Matrix`.
A module is a generalisation of a vector space, where the field
of scalars is replaced with a ring. In the case of Dilithium, we 
need the module with the ring $R_q$ as described above. 

`Matrix` allows elements of the module to be of size $m \times n$
For Dilithium, we need vectors of length $k$ and $l$ and a matrix
of size $l \times k$. 

As an example of the operations we can perform with out `Module`
lets revisit the ring from the previous example:

#### Example

```python
>>> R = PolynomialRing(11, 8)
>>> x = R.gen()
>>>
>>> M = Module(R)
>>> # We create a matrix by feeding the coefficients to M
>>> A = M([[x + 3*x**2, 4 + 3*x**7], [3*x**3 + 9*x**7, x**4]])
>>> A
[    x + 3*x^2, 4 + 3*x^7]
[3*x^3 + 9*x^7,       x^4]
>>> # We can add and subtract matricies of the same size
>>> A + A
[  2*x + 6*x^2, 8 + 6*x^7]
[6*x^3 + 7*x^7,     2*x^4]
>>> A - A
[0, 0]
[0, 0]
>>> # A vector can be constructed by a list of coefficents
>>> v = M([3*x**5, x])
>>> v
[3*x^5, x]
>>> # We can compute the transpose
>>> v.transpose()
[3*x^5]
[    x]
>>> v + v
[6*x^5, 2*x]
>>> # We can also compute the transpose in place
>>> v.transpose_self()
[3*x^5]
[    x]
>>> v + v
[6*x^5]
[  2*x]
>>> # Matrix multiplication follows python standards and is denoted by @
>>> A @ v
[8 + 4*x + 3*x^6 + 9*x^7]
[        2 + 6*x^4 + x^5]
```

### Number Theoretic Transform

We can transform polynomials to NTT form and from NTT form
with `poly.to_ntt()` and `poly.from_ntt()`.

When we perform operations between polynomials, `(+, -, *)`
either both or neither must be in NTT form.

```py
>>> f = R.random_element()
>>> f == f.to_ntt().from_ntt()
True
>>> g = R.random_element()
>>> h = f*g
>>> h == (f.to_ntt() * g.to_ntt()).from_ntt()
True
```

While writing this README, performing multiplication of of polynomials
in NTT form is about 100x faster when working with the ring used by
Dilithium.

```py
>>> # Lets work in the ring we use for Dilithium
>>> R = Dilithium2.R
>>> # Generate some random elements
>>> f = R.random_element()
>>> g = R.random_element()
>>> # Takes about 10 seconds to perform 1000 multiplications
>>> timeit.timeit("f*g", globals=globals(), number=1000)
9.621509193995735
>>> # Now lets convert to NTT and try again
>>> f.to_ntt()
>>> g.to_ntt()
>>> # Now it only takes ~0.1s to perform 1000 multiplications!
>>> timeit.timeit("f*g", globals=globals(), number=1000)
0.12979038299818058
```

These functions extend to modules

```py
>>> M = Dilithium2.M
>>> R = Dilithium2.R
>>> v = M([R.random_element(), R.random_element()])
>>> u = M([R.random_element(), R.random_element()]).transpose()
>>> A = u @ v
>>> A == (u.to_ntt() @ v.to_ntt()).from_ntt()
True
```

As operations on the module are just operations between elements, 
we expect a similar 100x speed up when working in NTT form:

```py
>>> u = M([R.random_element(), R.random_element()]).transpose()
>>> v = M([R.random_element(), R.random_element()])
>>> timeit.timeit("u@v", globals=globals(), number=1000)
38.39359304799291
>>> u = u.to_ntt()
>>> v = v.to_ntt()
>>> timeit.timeit("u@v", globals=globals(), number=1000)
0.495470915993792
```
