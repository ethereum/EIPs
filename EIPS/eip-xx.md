---
eip: 4780
title: smart contracts in java
author: jeremy akatsa (@jeyakatsa)
description: java smart contract creation
discussions-to: https://ethresear.ch/t/a-new-erc-token-proposal/11540
status: draft
type: standards track
category: erc
created: 2022-02-04
---

## Abstract
Converting Solidity Keywords into Java Dependencies in order for a library of Smart-Contract implementations to be built in the Java programming language.

## Motivation
Currently, there are ***200,000 Solidity/Ethereum Developers (Worldwide*** *(source: [TrustNodes](https://www.trustnodes.com/2018/07/22/ethereums-ecosystem-estimated-200000-developers-truffle-seeing-80000-downloads-month))* ***)*** and ***7.1million Java Developers (Worldwide*** *(source: [Daxx](https://www.daxx.com/blog/development-trends/number-software-developers-world#:~:text=According%20to%20SlashData%2C%20the%20number,%2C6%20million%20(source)))* ***)*** respectfully.

What if all those Java developers (currently in the millions), could be onboarded into the Ethereum Ecosystem?

![](https://github.com/jeyakatsa/EIPs/blob/master/assets/eip-xx/Java-Abstraction-Visualization-display.jpg)

## Specification

##### Smart-Contract Storage example in *Solidity*:
```solidity
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}
```

##### Smart-Contract Storage example in *Java*:
```java
public class SimpleStorage {
    private Uint256 storedData;

    public void setStoredData (Uint256 storedData) {
        this.storedData = storedData;
    }

    public Uint256 getStoredData () {
        return storedData;
    }
}
```

## Rationale

### Solidity Keywords to Java Dependency conversion process:
The `uint` keyword in Solidity essentially represents a pre-packaged library containing a 256 bit byte. In Java, a dependency is created to suplement for the Solidity keyword as follows:

##### `Uint256` Java Dependency (in place of `uint` Solidity Keyword) example:
```java
public interface Uint256 {

    static byte[] ivBytes = new byte[256];
    static int iterations = 65536;
    static int keySize = 256;
    static byte[] uint = new byte[256];

    public default void Uint256() throws Exception {
        decrypt();
    }

    public static void decrypt() throws Exception {

        char[] placeholderText = new char[0];

        SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        PBEKeySpec spec = new PBEKeySpec(placeholderText, Uint256.uint, iterations, keySize);
        SecretKey secretkey = skf.generateSecret(spec);
        SecretKeySpec secretSpec = new SecretKeySpec(secretkey.getEncoded(), "AES");

        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.DECRYPT_MODE, secretSpec, new IvParameterSpec(ivBytes));

        byte[] decryptedTextBytes = null;

        try {
            decryptedTextBytes = cipher.doFinal();
        }   catch (IllegalBlockSizeException e) {
            e.printStackTrace();
        }   catch (BadPaddingException e) {
            e.printStackTrace();
        }

        decryptedTextBytes.toString();
    }
}
```

## Backwards Compatibility
These Smart-Contract Java abstractions are meant to be compatible with the overall Ethereum Execution and Consensus layers respectfully.

## Security Considerations
A 51% attack of these contracts seems to be the biggest security implication concerning these new abstractions. But as stated once by Vitalik, it seems implausible for a validator to get away with a 51% attack of any token (or smart-contract) running on Ethereum safely.

The second security concern is the expanding base of smart-contracts from Solidity into Java. Solidity is currently not as widely known by developers as Java thus making it a "blessing in disguise" in regards to how secure the contracts running on Ethereum are. Expanding the creation of these smart-contracts from Solidity into Java will blossom the development of the ecosystem, while also attracting maliciousness (hence the larger an ecosystem grows, the more "criminals" it attracts).

#### References
- [Java Smart Contract Abstraction for Ethereum R&D](https://github.com/jeyakatsa/Ethereum-Smart-Contract-Java-Abstraction/blob/main/R%26D.md)
- [Java Smart Contract Abstraction for Ethereum](https://github.com/jeyakatsa/Ethereum-Smart-Contract-Java-Abstraction)
- [New-ERC Token Proposal](https://ethresear.ch/t/a-new-erc-token-proposal/11540)
- [Light-Client Token Creation Proposal](https://ethresear.ch/t/light-client-custom-token-creation-proposal/11433)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
