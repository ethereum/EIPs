---
eip: <to be assigned>
title: Omniverse-DLT(O-DLT for short)
description: The Omniverse DLT is a new application-level token features built over multiple existing L1 public chains, enabling asset-related operations such as transfers and receptions running over different consensus spaces synchronously and equivalently.
author: Shawn Zheng(@xiyu1984), Jason Cheng(chengjingxx@gmail.com), George Huang(@virgil2019), Kay Lin(@kay404)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-01-17
requires (*optional): <EIP number(s)>
---

## Abstract

The **Omniverse DLT**(O-DLT for short) is a new application-level token features built **over** multiple existing L1 public chains, enabling asset-related operations such as transfers and receptions running over different consensus spaces **synchronously** and **equivalently**.  
The core meaning of Omniverse is that the ***legitimacy of all on-chain states and operations can be equivalently verified and recorded simultaneously over different consensus spaces, regardless of where they were initiated.***  
O-DLT works at an application level, which means everything related is processed in smart contracts or similar mechanisms, just as the ERC20/ERC721 did.  

## Motivation

For projects serving multiple chains, it is definitely useful that the token is able to be accessed anywhere.   
This idea came to us as we are building an infrastructure to help smart contracts deployed on different blockchains work together.  
When coming to the token part, however, we do not believe that the asset-bridge paradigm is enough.  
- We want our token to be treated as a whole instead of being divided into different parts on different public chains. O-DLT can get it.
- When one chain breaks down, we don't want users to lose assets along with it. Assets-bridge paradigm cannot provide a guarantee for this. O-DLT can provide this guarantee even if there's only one chain that works.  
- Not just for a concrete token, we think the Omniverse Token might be useful for other projects on Ethereum and other chains. O-DLT is actually a new kind of asset paradigm at the application level. 

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Omniverse Account
The Omniverse account is expressed as a public key created by the elliptic curve `secp256k1`, which has already been supported by Ethereum tech stacks. For those who don’t support secp256k1 or have a different address system, a mapping mechanism is needed.  

### Data Structure
The definations of omniverse transaction data is as follows:  
```solidity
/**
* @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
* @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
* @Member chainId: The chain where the o-transaction is initiated
* @Member initiator: The contract address from which the o-transaction is initiated
* @Member from: The Omniverse account which signs the o-transaction
* @Member op: The operation type. NOTE op: 0-31 are reserved values, 32-255 are custom values
*             op: 0 Transfers omniverse token `amount` from user `from` to user `data`, `from` MUST have at least `amount` token
*             op: 1 User `from` mints token `amount` to user `data`
*             op: 2 User `from` burns token `amount` from user `data`
* @Member data: The operation data. This sector could be empty and is determined by `op`
* @Member amount: The amount of token which is operated
* 
* @Member signature: The signature of the above informations. 
*                    Firstly, the above sectors are combined as 
*                    `bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.initiator, _data.from, _data.op, _data.data, uint128(_data.amount));`
*                    The it is hashed by `keccak256(rawData)`
*                    The signature is to the hashed value.
* 
*/
struct OmniverseTransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiateSC;
    bytes from;
    bytes payload;
    bytes signature;
}
```
- The member `nonce` is defined as `uint128` due to better compatibility for more tech stacks of blockchains.
- The member `payload` is a user-defined data related to the o-transaction, which is encoded to bytes. For example:  
    - For fungible tokens:  
        ```solidity
        struct FungibleToken {
            uint8 op;
            bytes exData;
            uint256 amount;
        }
        ```
        - The related raw data for `signature` in o-transaction is the concatenation of the raw bytes of op, ex_data, and amount.  
    - For non-fungible tokens:  
        ```solidity
        struct NonFungibleToken {
            uint8 op;
            bytes exData;
            uint256 tokenId;
        }
        ```
        - The related raw data for `signature` in o-transaction is the concatenation of the raw bytes of op, ex_data, and tokenId. 
- The member `signature` is created as follows:
    - Firstly, concat the above sectors as below: 
        ```solidity
        // calculate the raw data of member `payload` as mentioned above

        // generate raw data for hash
        bytes memory rawData = abi.encodePacked(.nonce, .chainId, .initiator, .from, .op, <raw data of payload>);
        ```
    - Secondly, generate the hash value of the `rawData` with `keccak256`
    - The signature is about the hash value.

### Smart Contract
- Omniverse Protocol  
    ```solidity

    ```
- Omniverse Fungible  
    ```solidity

    ```
- Omniverse Non-Fungible
    ```solidity

    ```

## Rationale
### Architecture
![image](https://user-images.githubusercontent.com/83746881/212859732-8dbc3e0c-57e3-4629-bb30-8c5d4d9a23de.png)
  
- The implementation of the Omniverse Account is not very hard, and we temporarily choose a common elliptic curve secp256k1 to make it out, which has already been supported by Ethereum tech stacks. For those who don’t support secp256k1 or have a different address system, we can adapt them with a simple mapping mechanism ([Flow for example](https://github.com/Omniverse-Web3-Labs/omniverse-flow)).  
- The Omniverse Transaction guarantees the ultimate consistency of omniverse transactions(o-transaction for short) across all chains. The related data structure is `OmniverseTransactionData` mentioned [above](#data-structure).
    - The `nonce` is very important, which is the key point to synchronize the states globally.
    - The `nonce` appears in two places, the one is `nonce in o-transaction` data as above, and the other is `account nonce` maintained by on-chain O-DLT smart contracts. The example codes about the `account nonce` can be found [here](https://github.com/Omniverse-Web3-Labs/omniverse-evm/blob/main/contracts/contracts/SkywalkerFungible.sol#L50) 
    - The `nonce in o-transaction` data will be verified according to the `account nonce` managed by on-chain O-DLT smart contracts. Some example codes can be found [here](https://github.com/Omniverse-Web3-Labs/omniverse-evm/blob/main/contracts/contracts/libraries/OmniverseProtocol.sol#L64).
- The Omniverse Token could be implemented with the [interfaces mentioned above](#smart-contract). It can also be used with the combination of ERC20/ERC721. The prototype of the code can be found [here](https://github.com/Omniverse-Web3-Labs/omniverse-evm/blob/main/contracts/contracts/interfaces/IOmniverseFungible.sol)  
    - The first thing is verifying the signature of the o-transaction data. 
    - Then the operation will be added to a pre-execution cache, and wait for a fixed time until is executed. The waiting time will be able to be settled by the deployer, for example, 5 minutes. 
    - The off-chain synchronizer will deliver the o-transaction data to other chains. If another o-transaction data with the same nonce and the same sender account is received within the waiting time, and if there's any content in `OmniverseTransactionData` difference, a malicious attack happens and the related sender account will be punished. 
    - The example code of `sendOmniverseTransaction` is [here](https://github.com/Omniverse-Web3-Labs/omniverse-evm/blob/main/contracts/contracts/SkywalkerFungible.sol#L103)
    - and the example code of executing is [here](https://github.com/Omniverse-Web3-Labs/omniverse-evm/blob/main/contracts/contracts/SkywalkerFungible.sol#L110). 
    - The implementation for Omniverse Non-Fungible Token is almost the same and the defination of the interface can be found [here](https://github.com/Omniverse-Web3-Labs/omniverse-evm/blob/main/contracts/contracts/interfaces/IOmniverseNonFungible.sol) 
- The Omniverse Verification is mainly about the verification of the signature implemented in different tech stacks according to the blockchain. As the signature is unfakeable and non-deniable, malicious attacks could be found determinedly.
- The bottom is the off-chain synchronizer. The synchronizer is a very simple off-chain procedure, and it just listens to the Omniverse events happening on-chain and makes the information synchronization. As everything in the Omniverse paradigm is along with a signature and is verified cryptographically, there's no need to worry about synchronizers doing malicious things, and I will explain it later. The off-chain part of O-DLT is indeed trust-free. Everyone can launch a synchronizer to get rewards by helping synchronize information.  

### Features
The O-DLT has the following features:
- The omniverse token(o-token for short) based on O-DLT deployed on different chains is not separated but as a whole. If someone has one o-token on Ethereum, he will have an equivalent one on other chains at the same time.
- The state of the tokens based on O-DLT is synchronous on different chains. If someone sends/receives one token on Ethereum, he will send/receive one token on other chains at the same time.

### Workflow
![image](https://user-images.githubusercontent.com/83746881/212859794-13a0ba68-f89f-45cf-8fb4-e5fd09970166.png)

- Suppose a common user `A` and the related operation `account nonce` is $k$.
- `A` initiate an omniverse transfer operation on Ethereum by calling `omniverse_transfer`. The current `account nonce` of `A` in the O-DLT smart contracts deployed on Ethereum is $k$ so the valid value of `nonce in o-transaction` needs to be $k+1$.  
- The O-DLT smart contracts on Ethereum verify the signature of the o-transaction data at an **application level**. If the verification for the signature and data succeeds, the o-transaction data will be published on the O-DLT smart contracts of the Ethereum side. The verification for the data includes:
    - whether the amount is valid
    - and whether the `nonce in o-transaction` is 1 larger than the `account nonce` maintained by the on-chain O-DLT
- Now, `A`'s newest submitted `nonce in o-transaction` on Ethereum is $k+1$, but still $k$ on other chains.
- The off-chain synchronizers find the newly published o-transaction, and they will find the `nonce in o-transaction` is larger than the related `account nonce` on other chains.
- These synchronizers will rush to deliver this message because whoever submits to the destination chain first will get a reward. There's no will for independent synchronizers to do evil because they just deliver `A`'s o-transaction data. (The reward is coming from the service fee or a mining mechanism according to the average number of o-transactions within a fixed time. The strategy of the reward may not be just for the first one but for the first three with a gradual decrease.) 
- Finally, the O-DLT smart contracts deployed on other chains will all receive the o-transaction data, verify the signature and execute it when the **waiting time is up**. After execution, the underlying `account nonce` will add 1. Now all the `account nonce` of account `A` will be $k+1$, and the state of the balances of the related account will be the same too.  

We have provided an intuitive but non-rigorous [proof for the **ultimate consistency**](https://github.com/Omniverse-Web3-Labs/o-amm/blob/main/docs/Proof-of-ultimate-consistency.md) for a better understanding of the **synchronization** mechanisms.

## Reference Implementation

- Omniverse Protocol  
    ```solidity

    ```
- Omniverse Fungible Token
    ```solidity

    ```

- The implememtation of Omniverse Non-Fungible Token is similiar with the Omniverse Fungible Token.  

## Security Considerations

### Attack Vector Analysis
According to the above, there are two roles:
**common users** who initiate a o-transaction (at the application level)
and **synchronizers** who just carry the o-transaction data if they find differences between different chains.  

The two roles might be where the attack happens:  
#### **Will the *synchronizers* cheat?**  
- Simply speaking, it's none of the **synchronizer**'s business as **they cannot create other users' signatures** unless some **common users** tell him, but at this point, we think it's a problem with the role **common user**.  
- The **synchronizer** has no will and cannot do evil because the transastion data that they deliver is verified by the related **signature** of others(a **common user**).  
- The **synchronizers** will be rewarded as long as they submit a valid o-transaction data, and *valid* only means that the signature and the amount are both valid even if the `nonce in o-transaction` is **invalid**. This will be detailed explained later when analyzing the role **common user**.  
- The **synchronizers** will do the delivery once they find differences between different chains:
    - If the current `account nonce` on one chain is smaller than a published `nonce in o-transaction` on another chain
    - If the transaction data related to a specific `nonce in o-transaction` on one chain is different from another published o-transaction data with the same `nonce in o-transaction` on another chain

- **Conclusion: The *synchronizers* won't cheat because there's no benifits and no way for them to do so.**

#### **Will the *common user* cheat?**
Simply speaking, **yes they will**, but fortunately, **they can't succeed**.  
- Suppose current `account nonce` of a **common user** `A` is $k$ on all chains.  
- Common user `A` initiates an o-transaction on a Parachain of Polkadot first, in which `A` transfer `10` o-tokens to an o-account of a **common user** `B`. The `nonce in o-transaction` needs to be $k+1$. After signature and data verification, the o-transaction data(`ot-P-ab` for short) will be published on Polkadot.
- At the same time, `A` initiates an o-transaction with the same nonce $k+1$ but different data(transfer `10` o-tokens to another o-account `C`) on Ethereum. This o-transaction(named as `ot-E-ac`) will pass the verification on Ethereum first, and be published.  
- At this point, it seems `A` finished a ***double spend attack*** and the O-DLT states on Polkadot and Ethereum are different.  
- **Response strategy**:
    - As we mentioned above, the synchronizers will deliver `ot-P-ab` to the O-DLT on Ethereum and deliver `ot-E-ac` to the O-DLT on Polkadot because they are different although with the same nonce. The synchronizer who submits the o-transaction first will be rewarded as the signature is valid.
    - Both the O-DLTs on Polkadot and Ethereum will find that `A` did cheating after they received `ot-E-ac` and `ot-P-ab` respectively as the signature of `A` is non-deniable.  
    - We mentioned above that the execution of an o-transaction will not be done immediately and instead there needs to be an fixed waiting time. So the `double spend attack` caused by `A` won't succeed.
    - There will be many synchronizers waiting for delivering o-transactions to get rewards. So although it's almost impossible that a **common user** can submit two o-transactions to two chains, none of the synchronizers deliver the o-transactions successfully because of a network problem or something else, we still provide a solution:  
        - The synchronizers will connect to several native nodes of every public chain to avoid the malicious native nodes.
        - If it indeed happened that all synchronizers' network break, the o-transaction will be synchronized when the network recovered. If the waiting time is up and the cheating o-transaction has been executed, we will revert it from where the cheating happens according to the `nonce in o-transaction` and `account nonce`.
- `A` will be punished(lock his account or something else, and this is about the user-defined tokenomics).  

- **Conclusion: The *common user* will cheat but won't succeed.**

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
