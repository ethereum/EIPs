## Preamble

    EIP: 
    Title: Precompiled contracts for ring signature verification on the elliptic curve alt_bn128.
    Author: Jack Lu <jack@wanchain.org>, Demmon Guo <demmon@wanchain.org> and Shi Liu <shi@wanchain.org>
    Type: Standard Track
    Category (*only required for Standard Track): Core 
    Status: Draft
    Created: 2017-08-21
    


## Simple Summary
Use precompiled contracts for ring signature verification.

## Abstract
This EIP suggests adding precompiled contracts for ring signature verification on alt_bn128. This can in turn be combined with EIP #196 to verify ring signature in Ethereum smart contracts. The general benefit of this implementation is that it will offer another solution for privacy protection on Ethereum.

## Motivation
Currently, ether transactions on Ethereum are transparent, which makes them unsuitable for some use-cases where users’ privacy is of concern. EIP #196 and EIP #197 suggest adding precompiled contracts for addition and scalar multiplication on a specific pairing-friendly elliptic curve to verify zkSNARKs in Ethereum smart contract. But that implemtation has high computation complexity. Monero solves this problem by using Cryptonote under UTXO model. However, this technology cannot be directly used in Ethereum under account model. Considering all of the above, this EIP forgoes zero knowledge proof and proposes to implement precompiled contracts for ring signature verification.

## Specification
**Common parameters:**  

*q*:  a prime number;  
*E*: an elliptic curve equation;  
*G*: a base point;  
*Hs*: a cryptographic hash function which maps string of {0,1} to element of *F_q*;  
*Hp*: a hash function which creates a mapping between elements of *E(F_q)*;  
+: point addition on elliptic curve;  
*: scalar multiplication on elliptic curve.  

**Ring signature verification**  

Signature σ consists of a set of public keys, two arrays of random numbers selected by signer and a point I called key image.   
   
    σ=((P_1,P_2,…,P_n ),(c_1,c_2,…,c_n ),(r_1,r_2,…,r_n ),I)
   
Leaving the generation of ring signature behind, we implement the verification in this precompiled contract defined below, where m is the text to be signed: 
 
	Input: σ, m  
	Output: If the structure of the input is incorrect, the call fails.  
            Return true if equation below holds:  
				Hs(m,L_0,L_1,…,L_n,R_0,R_1,…,R_n )=c_0+c_1+⋯+c_n  
				L_i=c_i*p_i+r_i*G, R_i=r_i Hp(P_i )+c_i I, i=0,1…n  
            Otherwise, return false.  

**Key image check**

Ring signatures used here are linkable to prevent double spending. When signature σ is verified as valid, key image I is permanently stored in a key image set by smart contract. Thus, a signature σ that carries a key image with a second occurrence will be rejected. The linkable ring signature ensures that the withdrawal transaction cannot be linked to the deposit, but if someone attempts to withdraw twice then those two signatures can be linked and the second one will be rejected.   

**Gas costs**  

To be determined.
 

## Rationale
Choosing a precompiled contract for ring signature verification to provide privacy is a trade off between efficiency and computation cost. We forgoes the zero knowledge proof because of its high computation complexity (a transaction can be verified via a precompiled contract, but it is much harder to generate). Besides, accessibility is also an important consideration when designing a privacy protection scheme. After adding this precompiled contract, we can deploy a smart contract to provide privacy protection for ether transactions without modifying any existing mechanism.

## Backwards Compatibility
As with the introduction of any precompiled contract, contracts that already use the given addresses will change their semantics. Because of that, the addresses are taken from the "reserved range" below 256.

## Test Cases
To be written.

## Implementation
To be written.

## Copyright
License:   
Copyright and related rights waived via CC0.

