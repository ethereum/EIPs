---
eip: ????
title: Precompile for Falcon support
description: Proposal to add a precompiled contract that performs signature verifications using the Falcon signature scheme.
author: Renaud Dubois, Simon Masson, Antonio Sanso (@asanso), Marius Van Der Wijden, Kevaundray Wedderburn, Zhenfei Zhang
discussions-to: ...
status: Draft
type: Standards Track
category: Core
created: ????-??-??
---

# Falcon EIP

## 1. Abstract
This proposal creates a precompiled contract that performs signature verifications using the Falcon-512 signature scheme by given parameters of the message hash, signature, and public key. This allows any EVM chain—principally Ethereum rollups—to integrate this precompiled contract easily.
The signature scheme can be instantiated in two version:
* Falcon, the standard signature scheme, recommended by the NIST,
* An EVM-friendly version where the hash function is efficiently computed in the Ethereum Virtual Machine.

## 2. Motivation

Quantum computers pose a long-term risk to classical cryptographic algorithms. In particular, signature algorithms based on the hardness of the Elliptic Curve Discrete Logarithm Problem (ECDLP) such as secp256k1, are widely used in Ethereum and threaten by quantum algorithms. This exposes potentially on-chain assets and critical infrastructure to quantum adversaries.

Integrating post-quantum signature schemes is crucial to future-proof Ethereum and other EVM-based environments. We note that infrastructure for post-quantum signatures should be deployed *before* quantum adversaries are known to be practical because it takes on the order of years for existing applications to integrate.

Falcon, a lattice-based scheme standardized by NIST, offers high security against both classical and quantum adversaries. Its compact signature size (~666 bytes for Falcon-512) and its efficient verification algorithm make it well-suited for blockchain applications, where gas usage and transaction throughput are critical considerations.
<!-- When the public key is also stored together with the signature, it leads to 666 + 897 = 1563 bytes.
Using the recovery mode, it can be reduced to 1292 + 32 = 1324 bytes. -->
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

In the context of the Ethereum Virtual Machine, a precompile for Keccak256 hash function is already available, making Falcon verification much faster when instantiated with an extendable output function derived from Keccak than with SHAKE256, as specified in NIST submission. We propose in this EIP to split the signature verification into two algorithms: HashToPoint, that can be instantiated with SHAKE256 or Keccak-PRNG, and the core Falcon algorithm, that does not require any hash computation. Using this separation, it is possible to follow rigorously NIST specification, or slightly deviate in order to reduce the gas cost.

## 3. Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Falcon can be instantiated with polynomials of degree $512$ or $1024$, leading to a different security level. We focus on Falcon-512 in this EIP, leading to a security level equivalent to RSA2048.
This setting leads to the following size for signatures and keys:

| Parameter | Falcon |
| -------- | -------- | 
| **n** (lattice dimension)     | 512     |
| **q** (modulus)     | 12289     | 
| Padded signature size      | 666 bytes     | 
| Public Key size     | 897 bytes     |
| Private key size     | 1281 bytes     | 


From a high level, a signature verification can be decomposed in two steps:
- The **challenge computation**, that involves the message and the salt, and computes a challenge polynomial using a XOF,
- The **core algorithm**, that compute polynomial arithmetic (with the challenge, the public key and the signature), and finally verify the shortness of the full signature $(s_1,s_2)$.

The following pseudo-code highlights how these two algorithms are involved in a Falcon verification:
```python
def falcon512_verify(message: bytes, signature: Tuple[bytes, bytes], pubkey: bytes) -> bool:
    """
    Verify a Falcon Signature

    Args:
        message (bytes): The message to sign.
        signature (Tuple[bytes, bytes]): A tuple (r, s), where:
            - r (bytes): The salt.
            - s (bytes): The signature vector.
        pubkey (bytes): The Falcon public key.

    Returns:
        bool: True if the signature is valid, False otherwise.
    """
    
    # 1. Compute the Hash To Point Challenge (see 3.1.)
    challenge = hash_to_point_challenge(message, signature)
 
    # 2. Verify Falcon Core Algorithm (see 3.2.)
    return falcon_core(signature, pubkey, challenge)
```

### 3.1. Hash To Point Challenge

1. **Parse Input Data:** Check the byte sizes and then extract the message and the signature. We denote the parsed signature as a tuple of values $(r, s_2)$. $r$ is denoted as the salt and contains bytes, and $s_2$ is denoted as the signature vector, a vector of elements mod $q$.
2. **Verify Well-formedness:** Verify that the signature contains 40 bytes of salt for $r$.
<!-- See the `Required Checks in Verification` section for more details. -->
3. **Compute the challenge $c$:** the challenge is obtained from hash-to-point on the salt $r$ of the signature and the message. The output $c$ is a polynomial of degree 512, stored in 896 bytes.
The hash-to-point function computes eXtendable Output from a hash Function (XOF). This EIP provides two instantiations of a XOF:
    - SHAKE256 is the XOF provided in NIST submission, a sponge construction derived from SHA256,
    - Keccak-PRNG is a XOF that is build from a counter-mode PRNG based on Keccak256. Precompile of Keccak are available in the Ethereum Virtual Machine, making this XOF very efficient in the EVM.

The following pseudo-code illustrates the Hash To Point algorithm:
```python
def hash_to_point_challenge(message: bytes32, signature: Tuple[bytes, bytes]) -> bool:
    """
    Compute the Hash To Point Falcon Challenge.

    Args:
        message (bytes32): The original message (hash).
        signature (Tuple[bytes, bytes]): A tuple (r, s), where:
            - r (bytes): The salt.
            - s (bytes): The signature vector.

    Returns:
        c: The Hash To Point polynomial challenge as a vector.
    """
    
    # Constants
    q = 12289  # Falcon modulus
    
    # Step 1: Parse Input Data
    r, s2_compressed = signature  # Extract salt and compressed signature vector

    # Step 2: Verify Well-formedness
    if not is_valid_signature_format(s2_compressed, pubkey):
        return False

    # Step 3: Compute the challenge vector (HashToPoint)
    c = hash_to_point(r + message)  # c = HashToPoint(r || message)
    
    # return the challenge
    return c
```

### 3.2 Core algorithm

1. **Parse Input Data:** Check the byte sizes and then extract the public key, the Hash To Point Challenge and the signature.
    - We denote the parsed public key as $h$, viewed as a vector of elements mod $q$,
    - We denote the parsed signature as a tuple of values $(r, s_2)$. $r$ is denoted as the salt and $s_2$ is denoted as the signature vector, made of elements mod $q$.
2. **Verify Well-formedness:** Verify that the signature, Hash To Point Challenge and public key have the correct number of elements and is canonical.
<!-- See the `Required Checks in Verification` section for more details. -->
3. **Compute $s_1$ from $s_2$ and $h$.** $s_1 = c - h * s_2$ where:
    -  $c$ is the Hash To Point challenge,
    -  $h$ is the public key,
    -  $s_2$ is the signature vector.
    
    > Note: since $h$ and $s_2$ are polynomials, the operation $*$ is the polynomial multiplication and can be sped up using the Number Theoretic Transform (NTT).

4. **Check $L^2$ norm Bound:** Verify that the signature is _short_ by checking the following equation:
    $$ ||(s_1, s_2) ||_2^2 < \lfloor\beta^2\rfloor$$
    where $\beta^2$ is the acceptance bound. For Falcon-512, it is $\lfloor\beta^2\rfloor = 34034726$.

> Do we compute directly the pubkey in the NTT domain so that we reduce the verification cost by one NTT?

The following code illustrates Falcon core algorithm:
```python
def falcon_core(signature: Tuple[bytes, bytes], pubkey: bytes, challenge: bytes) -> bool:
    """
    Verify Falcon Core Algorithm

    Args:
        signature (Tuple[bytes, bytes]): A tuple (r, s), where:
            - r (bytes): The salt.
            - s (bytes): The signature vector.
        pubkey (bytes): The Falcon public key.
        challenge (bytes): The Falcon Hash To Point Challenge.

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

    # Step 3: Decompress Signature Vector
    s2 = decompress(s2_compressed)  # Convert compressed signature to full form
    if s2 is None: # Reject invalid encodings 
        return False

    # Step 4: Convert to Evaluation domain (NTT)
    s2_ntt = ntt(s2)
    pubkey_ntt = ntt(pubkey)

    # Step 5: Compute the Verification Equation
    tmp_ntt = hadamard_product(s2_ntt, pubkey_ntt)  # Element-wise product
    tmp = intt(tmp_ntt) # Convert back to coefficient form (INTT)
    s1 = challenge - tmp
    
    # Step 6: Normalize s1 coefficients to be in the range [-q/2, q/2]
    s1 = normalize_coefficients(s1, q)
    
    # Step 7: Compute Norm Bound Check
    s1_squared = square_each_element(s1)
    s2_squared = square_each_element(s2)

    total_norm = sum(s1_squared) + sum(s2_squared)

    # Step 8: Compare with Acceptance Bound
    # To ensure signature is short
    return total_norm < ACCEPTANCE_BOUND  # Falcon-512: β² = 34,034,726
```

### 3.3. Required Checks in Falcon Verification
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
it shall also be burned if an error happens during decompression (incorrect encodings).


## 4. Precompiled Contract Specification

### 4.1. Hash To Point precompiled contract
The precompiled contract HASH_TO_POINT is proposed with the following input and outputs, which are big-endian values:

- **Input data**
    - 32 bytes for the message
    - 666 bytes for Falcon-512 compressed signature
    <!-- - 897 bytes for Falcon-512 public key -->
- **Output data**:
    - the polynomial Hash To Point challenge as (14*512 = ) 897 bytes.

### 4.2. Falcon Core precompiled contract
The precompiled contract FALCON_CORE is proposed with the following input and outputs, which are big-endian values:

- **Input data**
    - 666 bytes for Falcon-512 compressed signature
    - 897 bytes for Falcon-512 public key
    - 897 bytes for the Hash To Point Challenge
- **Output data**:
    - If the core algorithm process succeeds, it returns 1 in 32 bytes format.
    - If the core algorithm process fails, it does not return any output data.

    > **Or return 0??**

### 4.3. Precompiled Contract Gas Usage

The cost of the **HASH_TO_POINT** contract highly depends on the XOF chosen for the computation:
    - SHAKE256 is not available in the Ethereum Virtual Machine, and HASH_TO_POINT requires in average 35 calls to the XOF. A rough estimation of the cost would be **???** Million gas.
    - Using another XOF can drastically decrease the cost of this algorithm. We suggest here to design a PRNG in counter mode based on Keccak256, a hash function whose precompiled contract is available in the Ethereum Virtual Machine. Using this construction, the 35 calls to the hash function become inexpensive, making the overall verification cheaper. However, this is not the XOF specified by the NIST standardization.
    
The cost of **FALCON_CORE** is dominated by performing 2 NTTs and 1 inverse NTT. One of these NTTs is for the public key and can be precomputed so that the contract requires to perform only 1 NTT and 1 inverse NTT. An estimation of the cost is given by **???** Million gas.

## 5. Rationale

The Falcon signature scheme was selected as a NIST-standardized post-quantum cryptographic algorithm due to its strong security guarantees and efficiency.

Falcon is a signature algorithm build from lattice-based cryptography. Specifically, its hardness relies on the Short Integer Solution (SIS) problem over NTRU lattices, which is believed to be hard for both classical and quantum computers. 

Falcon offers several advantages over traditional cryptographic signatures such as secp256k1 and secp256r1:

- **Efficiency**: Falcon is highly optimized for constrained environments, offering small signature sizes (666 bytes for Falcon-512) and fast verification time. This makes it well-suited for Ethereum, where gas costs and computational efficiency are critical factors.
- **NIST Standardization**: Falcon was selected as part of NIST Post-Quantum Cryptography Standardization process, ensuring that it meets rigorous security and performance criteria.
- **Enabling Future-Proof Smart Contracts**: With the integration of Falcon, Ethereum roll-ups and smart contract applications can start adopting quantum-secure schemes that remain secure even when we have quantum computers.
- **Compatibility with Existing EVM Designs**: While Falcon operates on fundamentally different cryptographic assumptions than elliptic curves, its verification process can be efficiently implemented as a precompiled contract with similar APIs to classical signature schemes like secp256r1.

Given the increasing urgency of transitioning to quantum-resistant cryptographic primitives or even having them ready in the event that research into quantum computers speeds up. 

The choice of a precompiled contract, rather than an opcode, aligns with existing approaches to signature verification, such as ecrecover for secp256k1 and P256VERIFY for secp256r1.


## 6. Backwards Compatibility
In order to make Falcon-512 compatible with EIP-7932, we provide the necessary parameters and structure for its integration. We assign ALG_TYPE = 0xFA to uniquely identify Falcon-512 transactions, set MAX_SIZE = 699 bytes to accommodate the fixed-length signature_info container (comprising a 1-byte version tag, a 666-byte Falcon signature, and a 32-byte public key hash), and recommend a GAS_PENALTY of approximately **???** gas subject to benchmarking. The verification function follows the EIP-7932 model, parsing the signature_info, recovering the corresponding Falcon public key, verifying the signature against the transaction payload hash, and deriving the signer’s Ethereum address as the last 20 bytes of keccak256(pubkey). This definition ensures that Falcon-512 can be cleanly adopted within the `AlgorithmicTransaction` container specified by EIP-7932.

```
signature_info = Container[
    version: uint8              # 0xFA for Falcon-512
    signature: ByteVector[666]  # Falcon-512 signature, padded if shorter
    pubkey_hash: ByteVector[32] # keccak256(pubkey)
]
```

In the format of EIP-7932, a verification is implemented as follows:
```python
verify(signature_info: bytes, payload_hash: Hash32) -> ExecutionAddress:
    assert len(signature_info) == 699
    version      = signature_info[0]
    signature    = signature_info[1:667]
    pubkey_hash  = signature_info[667:699]
    assert version == 0x01
    pubkey = lookup_pubkey(pubkey_hash)
    assert falcon512_verify(pubkey, signature, payload_hash)
    return ExecutionAddress(keccak256(pubkey)[12:])
```

## 7. Test Cases

TODO: We cannot use the official test vectors because they use shake256 in the hashToPoint implementation, whereas we are using keccak256. 


> Note: If this is made as a precompile, then we can use shake256. If implemented in solidity, then we would need to reimplement shake256 in solidity which will be more expensive than keccak256 by a significant amount.

## 8. Reference Implementation

**TODO REFER TO CONTRACTS ON TESTNETS?**

**TODO: We can modify geth to include falcon-512 as a reference. (Similar to secp256r1 signature verification)**

## 9. Security Considerations
?

## 10. Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
