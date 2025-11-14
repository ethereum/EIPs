# KAT vectors
We provide Known Answer Test vectors from the NIST submission of MLDSA, and also vectors for the EVM-friendly version with the same format (but changing the hash function). In order to keep it as close as possible to the NIST submission, we do not provide the public key in the NTT domain in `KAT/`.

# Solidity contract
We provide an implementation of the verification for both contracts:
* A test for the 1-st KAT vector is provided for the NIST version,
* A test for the 15-th KAT vector is provided for the EVM version.

Note that the public key is formatted in expanded version, required by the Solidity contract implementation.
For the EVM-friendly version, the public key is provided in the NTT domain, as defined in the specification of the EIP.