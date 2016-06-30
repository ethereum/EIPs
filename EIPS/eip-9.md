### Title

      EIP: 9
      Title: Add precompiled contracts for blockchain interoperability
      Author: Tjaden Hess <tah83@cornell.edu>
      Status: Draft
      Type: Standard Track
      Layer: Consensus (hard-fork)
      Created 2016-06-30

### Abstract

This EIP introduces several new "precompiled contracts" designed to provide interoperability between the Ethereum network and various other blockchains by enabling the construction of efficient BTC Relay- like SPV clients on top of the EVM.  

### Specification

EVM implementations should support 2 new precompiled contracts at addresses 5 and 6, respectively. The contract at address 5 implements the Scrypt KDF with parameters

      N = 1024
      r = 1
      p = 1
      salt = input
      256 bit digest length

which are notably used in Litecoin and its derivatives. The contract at address 6 should implement the BLAKE2b hash function, a Password Hashing Competition finalist most notably used Proof of Work function for Zcash.
