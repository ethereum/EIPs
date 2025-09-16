---
rip: ????
title: Precompile for Falcon support
description: Proposal to add a precompiled contract that performs signature verifications using the Falcon signature scheme.
author: Renaud Dubois, Simon Masson, Antonio Sanso (@asanso), Marius Van Der Wijden, Kevaundray Wedderburn, Zhenfei Zhang
discussions-to: ...
status: Draft
type: Standards Track
category: Core
created: ????-??-??
---

# Falcon RIP 

## 1. Abstract
This proposal creates a precompiled contract that performs signature verifications using the Falcon-512 signature scheme by given parameters of the message hash, signature, and public key. This allows any EVM chain—principally Ethereum rollups—to integrate this precompiled contract easily.
The signature scheme can be instantiated in two version:
* Falcon, the standard signature scheme, recommended by the NIST,
* Falcon in recovery mode, a variant for reducing the overall size of signature and public key.

## 2. Motivation

Quantum computers poses a long-term risk to classical cryptographic algorithms. In particular those based on the hardness of the Elliptic Curve Discrete Logarithm Problem(ECDLP) such as secp256k1, that are widely used in Ethereum. This potentially exposes on-chain assets and critical infrastructure to quantum adversaries.

Integrating post-quantum signature schemes is crucial to future-proof Ethereum and other EVM-based environments. We note that infrastructure for post quantum signatures should be deployed *before* quantum adversaries are known to be practical because it takes on the order of years for existing applications to integrate.

Falcon, a lattice-based scheme standardized by NIST, offers quantum-resistant security against both classical and quantum adversaries. Its compact signature size (~666 bytes for Falcon-512) and efficient verification process make it well-suited for blockchain applications, where gas usage and transaction throughput are critical considerations.
When the public key is also stored together with the signature, it leads to 666 + 897 = 1563 bytes.
Using the recovery mode, it can be reduced to 1292 + 32 = 1324 bytes.
<!--
For Falcon,
    σ=666 (40 bytes of salt, ~626 bytes for s2)
    pk = 897,
    TOTAL=1563
For FalconRec,
    σ=1292 (40 bytes of salt, ~626 bytes for s1, ~626 bytes for s2),
    pk = 32,
    TOTAL=1324
-->


## 3. Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

##### Falcon-512 Information

| Parameter | Falcon | Falcon recovery mode | 
| -------- | -------- | -|
| **n** (lattice dimension)     | 512     | 512 |
| **q** (modulus)     | 12289     | 12289|
| Padded signature size      | _666_ bytes     | **1292** bytes |
| Public Key size     | _897_ bytes     | **32** bytes |
| Private key size     | 1281 bytes     | 1281 bytes|
| Security level     | ~128 bit security     | ~128 bit security|
| Gaussian standard deviation| 1.17 |1.17|

> **Remove security level and standard deviation??**

### 3.1. Falcon verification

##### 3.1.1. Verification steps (High level)

1. **Parse Input Data:** Check the byte sizes and then extract the public key, message and signature.
    - We denote the parsed public key as $h$. One should view it as a vector of elements in $\mathbb{Z}_q$
    - We denote the parsed signature as a tuple of values $(r, s_2)$. $r$ is denoted as the salt and $s_2$ is denoted as the signature vector. The signature vector is also a vector of elements in $\mathbb{Z}_q$, while $r$ is vector of bytes.
3. **Verify Well-formedness:** Verify that the signature and public key have the correct number of elements and canonical. See the `Required Checks in Verification` section for more details.
4. **Compute $s_1$ from $s_2$ and $h$.** $s_1 = c - h * s_2$ where:
    -  $c$ is the challenge obtained from hash-to-point on the salt of the signature and the message. $c$ is a polynomial/vector of size 512.
    -  $h$ is the public key.
    -  $s_2$ is the signature vector.
    
    > Note: since $h$ and $s_2$ are polynomials. The $*$ operation is the polynomial multiplication and can be sped up using the Number Theoretic Transform (NTT)

1. **Check $L^2$ norm Bound:** Verify that the signature was _short_ by checking the following equation:
$$ \|(s_1, s_2) \|_2^2 < \lfloor\beta^2\rfloor$$ where $\beta^2$ is the acceptance bound. For Falcon-512, it is $\lfloor\beta^2\rfloor = 34034726$.

##### 3.1.2. Falcon Verification Steps (pseudo code)

```python
def verify_falcon_signature(message: bytes32, signature: Tuple[bytes, bytes], pubkey: bytes) -> bool:
    """
    Verifies a Falcon signature.

    Args:
        message (bytes32): The original message (hash).
        signature (Tuple[bytes, bytes]): A tuple (r, s), where:
            - r (bytes): The salt.
            - s (bytes): The signature vector.
        pubkey (bytes): The Falcon public key.

    Returns:
        bool: True if the signature is valid, False otherwise.
    """
    
    # Constants
    q = 12289  # Falcon modulus
    ACCEPTANCE_BOUND = 34034726  # Falcon-512 acceptance bound
    
    # Step 1: Parse Input Data
    r, s2_compressed = signature  # Extract salt and compressed signature vector

    # Step 2: Verify Well-formedness
    if not is_valid_signature_format(s2_compressed, pubkey):
        return False

    # Step 3: Compute the challenge vector (HashToPoint)
    c = hash_to_point(r + message)  # c = HashToPoint(r || message)

    # Step 4: Decompress Signature Vector
    s2 = decompress(s2_compressed)  # Convert compressed signature to full form
    if s2 is None: # Reject invalid encodings 
        return False

    # Step 5: Convert to Evaluation domain (NTT)
    s2_ntt = ntt(s2)
    pubkey_ntt = ntt(pubkey)

    # Step 6: Compute the Verification Equation
    tmp_ntt = hadamard_product(s2_ntt, pubkey_ntt)  # Element-wise product
    tmp = intt(tmp_ntt) # Convert back to coefficient form (INTT)
    s1 = c - tmp
    
    # Step 7: Normalize s1 coefficients to be in the range [-q/2, q/2]
    s1 = normalize_coefficients(s1, q)
    
    # Step 8: Compute Norm Bound Check
    s1_squared = square_each_element(s1)
    s2_squared = square_each_element(s2)

    total_norm = sum(s1_squared) + sum(s2_squared)

    # Step 9: Compare with Acceptance Bound
    # To ensure signature is short
    return total_norm < ACCEPTANCE_BOUND  # Falcon-512: β² = 34,034,726
```

> Do we compute directly the pubkey in the NTT domain so that we reduce the verification cost by one NTT?

##### 3.1.3. Required Checks in Verification

The following requirements MUST be checked by the precompiled contract to verify signature components are valid:

**Raw Input data**
- Verify that the message is 32-bytes long,
- Verify that the public key is 897-bytes long,
- Verify that the signature is 666-bytes long.

**Parsed Input data**
- Verify that the public key consists of 512 elements, where each element is between $[0, q-1]$,
- Verify that the signature vector in the signature consists of 512 elements, where each element is between $[0, q-1]$,
- Verify that the salt in the signature is 40-bytes long.

**Gas burning on error**
if one of the above condition is not met then all the gas supplied along with a CALL or STATICCALL is burned.
it shall also be burned if an error happens during decompression (incorrect encodings)

### 3.2. Falcon Public Key Recovery

> **Explain somewhere that at the end, it means recovering pk and then check with a stored one (that is a 256bit size). Maybe not here.**

##### 3.2.1. Public Key Recovery steps (High level)

1. **Parse Input Data:** Check the byte sizes and then extract the message and the signature.
    - We denote the parsed signature as a tuple of values $(r, s_1,s_2)$. $r$ is denoted as the salt and $(s_1,s_2)$ is denoted as the signature vector. The signature vector corresponds to $2n$ elements of $\mathbb{Z}_q$, while $r$ is vector of bytes.
2. **Verify Well-formedness:** Verify that the signature has the correct number of elements and canonical. See the `Required Checks in Public Key Recovery` section for more details.
3. **Recover Public Key:** $$pk = H(s_2^{-1} (c - s_1))$$ where:
    - $c$ is the challenge and is the result of calling hash-to-point on the salt of the signature and the message. $c$ is a polynomial/vector of size 512.
    - $(s_1,s_2)$ is the signature vector.
    - $H$ is the Keccak256 hash function.
    > **THIS CAN BE CHANGED TO SHAKE (SEE LATER IN THE DOCUMENT)**

    > Note: since $s_2^{-1}$ and $(c-s_1)$ are vectors/polynomials, the $*$ operation is the polynomial multiplication and can be sped up using the Number Theoretic Transform (NTT)

1. **Check Norm Bound:** Verify that the signature was _short_ by checking the following equation:
$$ \|(s_1, s_2) \|_2^2 < \lfloor\beta^2\rfloor$$ where $\beta^2$ is the acceptance bound. For Falcon-512, it is $\lfloor\beta^2\rfloor = 34034726$.

##### 3.2.2 Falcon Public Key Recovery Steps (pseudo code)

```python
def recover_falcon_public_key(message: bytes32, signature: Tuple[bytes, bytes, bytes]) -> bytes:
    """
    Recover a Falcon public key.

    Args:
        message (bytes32): The original message (hash).
        signature (Tuple[bytes, bytes, bytes]): A tuple (r, s1,s2), where:
            - r (bytes): The salt.
            - s1 (bytes): The signature first vector.
            - s2 (bytes): The signature second vector.

    Returns:
        pubkey (bytes): The Falcon public key.
        OR A BOOLEAN IF SOMETHING GOES WRONG??
    """
    
    # Constants
    q = 12289  # Falcon modulus
    ACCEPTANCE_BOUND = 34034726  # Falcon-512 acceptance bound
    
    # Step 1: Parse Input Data
    r, s1_compressed, s2_compressed = signature  # Extract salt and compressed signature vector

    # Step 2: Verify Well-formedness
    if not is_valid_signature_format(s1_compressed, s2_compressed):
        return False

    # Step 3: Compute the challenge vector (HashToPoint)
    c = hash_to_point(r + message)  # c = HashToPoint(r || message)

    # Step 4: Decompress Signature Vector
    s1 = decompress(s1_compressed)
    s2 = decompress(s2_compressed) 
    if s1 is None or s2 is None : # Reject invalid encodings 
        return False

    # Step 5: Normalize s1 and s2 coefficients to be in the range [-q/2, q/2]
    s1 = normalize_coefficients(s1, q)
    s2 = normalize_coefficients(s2, q)

    # Step 6: Convert to Evaluation domain (NTT)
    s2_ntt_inverse = inverse(ntt(s2)) # Element-wise inverse

    # Step 7: Recover the public key
    tmp_ntt = ntt(c - s1)
    tmp_ntt_prod = hadamard_product(s2_ntt_inverse, tmp_ntt)  # Element-wise product
    input_hash = intt(tmp_ntt_prod) # Convert back to coefficient form (INTT)
    
    # Step 8: Compute Norm Bound Check
    s1_squared = square_each_element(s1)
    s2_squared = square_each_element(s2)

    total_norm = sum(s1_squared) + sum(s2_squared)

    # Step 9: Compare with Acceptance Bound
    # To ensure signature is short
    if total_norm < ACCEPTANCE_BOUND :  # Falcon-512: β² = 34,034,726
        return H(input_hash)
    else:
        return False
```

> **Do we need to normalize s1 and s2? Decompression makes it anyway? or no?**
> **The output is a public key, but if something goes wrong it returns False. I guess its not the right way to do it.**
> **Similarly to the Falcon verification case, we could compute pk in the NTT domain (H(ntt(h))) in order to save NTTs.**

##### 3.2.3. Required Checks in Public Key Recovery

The following requirements MUST be checked by the precompiled contract to verify signature components are valid:

**Raw Input data**
- Verify that the message is 32-bytes long,
- Verify that the signature is 1292-bytes long. <!-- 40 + (666-40)*2 -->

**Parsed Input data**
- Verify that the signature vector in the signature consists of 1024 elements, where each element is between $[0, q-1]$,
- Verify that the salt in the signature is 40-bytes length.

> **Is there a malleability problem when the attacker plays with s1 and s2? Not sure...**

## 4. Precompiled Contract Specification

### 4.1. Falcon verification

The FALCON512VERIFY precompiled contract is proposed with the following input and outputs, which are big-endian values:

- **Input data**
    - 32 bytes for the message
    - 666 bytes for Falcon-512 compressed signature
    - 897 bytes for Falcon-512 public key
- **Output data**:
- If the signature verification process succeeds, it returns 1 in 32 bytes format.
- If the signature verification process fails, it does not return any output data.

> **Or return 0??**

##### Precompiled Contract Gas Usage

The use of signature verification cost by FALCON512VERIFY is ~3.5Million gas (native solidity).
> **HOW DID YOU CHOOSE THIS VALUE**

The majority of the gas cost comes from performing 2 NTTs and 1 inverse NTT. One of these NTTs is for the public key, we can precompute this and then we only need to perform 1 NTT and 1 inverse NTT.

### 4.2. Falcon Public Key Recovery

The FALCON512RECOVER precompiled contract is proposed with the following input and outputs, which are big-endian values:

- **Input data**
    - 32 bytes for the message
    - 1292 bytes for Falcon-512 compressed signature
    - 32 bytes for Falcon-512 public key
- **Output data**:
- If the signature verification process succeeds, it returns the 32 bytes format public key.
- If the signature verification process fails, it does not return any output data.
> **DOES IT RETURN FALSE OR NOTHING?**

##### Precompiled Contract Gas Usage

The use of signature verification cost by FALCON512RECOVER is ~???Million gas (native solidity).
> **HOW TO CHOOSE THIS?**

The majority of the gas cost comes from performing 2 NTTs and 1 inverse NTT. One of these NTTs is for the public key, we can precompute this and then we only need to perform 1 NTT and 1 inverse NTT.

## Rationale

The Falcon signature scheme was selected as a NIST-standardized post-quantum cryptographic algorithm due to its strong security guarantees and efficiency.

Falcon is based on lattice-based cryptography, specifically its hardness relies on the Short Integer Solution (SIS) problem, which is believed to be resistant to attacks from both classical and quantum computers. 

Falcon offers several advantages over traditional cryptographic signatures such as secp256k1 and secp256r1:

- **Efficiency**: Falcon is highly optimized for constrained environments, offering small signature sizes (~666 bytes for Falcon-512) and fast verification times. This makes it well-suited for Ethereum, where gas costs and computational efficiency are critical factors.
- **NIST Standardization**: Falcon was selected as part of NIST’s Post-Quantum Cryptography Standardization process, ensuring that it meets rigorous security and performance criteria.
- **Enabling Future-Proof Smart Contracts**: With the integration of Falcon, Ethereum rollups and smart contract applications can start adopting quantum-secure schemes that remain secure even when we have post quantum computers.
- **Compatibility with Existing EVM Designs**: While Falcon operates on fundamentally different cryptographic assumptions than elliptic curves, its verification process can be efficiently implemented as a precompiled contract with similar APIs to classical signature schemes like secp256r1.
> **Say something about ZK and its efficiency in ZK?**

Given the increasing urgency of transitioning to quantum-resistant cryptographic primitives or even having them ready in the event that research into quantum computers speeds up. 

The choice of a precompiled contract, rather than an opcode, aligns with existing approaches to signature verification, such as ecrecover for secp256k1 and P256VERIFY for secp256r1.


## Backwards Compatibility

N/A 

## Test Cases

TODO: We cannot use the official test vectors because they use shake256 in the hashToPoint implementation, whereas we are using keccak256. 


> Note: If this is made as a precompile, then we can use shake256. If implemented in solidity, then we would need to reimplement shake256 in solidity which will be more expensive than keccak256 by a significant amount.

## Reference Implementation

TODO: We can modify geth to include falcon-512 as a reference. (Similar to secp256r1 signature verification)

## Security Considerations


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
