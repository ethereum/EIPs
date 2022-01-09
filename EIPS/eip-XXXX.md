---
Eip: XXXX *Number to be determined by Editor*
Title: ERC Token in Multiple Languages
Author: Jeremy Akatsa (@jeyakatsa)
Status: Draft
Type: Standards Track
Category: ERC
Created: 1/8/2022
---

## Simple Summary
An ERC token/currency capable of being created in multiple languages (Java, Rust, Python, Go, etc).

## Abstract
While building the *[Light Client Infrastructure for the Teku Client (for Ethereum 2)](https://github.com/jeyakatsa/teku/tree/master/light-client),* a discovery was made; clients serve as arbiters or "bridges" to the Ethereum main chain.
| ETH2 Client   | Language     | Team                |
|:--------------|:------------ |:------------------- |
| Teku          | Java         | Consensys           |
| Lighthouse    | Rust         | Sigma Prime         |
| Trinity       | Python       | Ethereum Foundation |
| Prysm         | Go           | Prysmatic Labs      |

Such clients offer differing languages that connect with the transactions offered on Ethereum, thus concluding if said clients can offer a base layer capable of inferring transactions from Ethereum's base layer, can tokens created in said languages also offer the same results?

## Motivation
Today, millions of websites are created every week in many languages. What if the Ethereum ecosystem could also do the same, but with currencies and tokens?

## Specification
>The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

#### Starting Point:
Creating a library of implementing smart-contracts in these languages: Java, Rust, Python & Go, beginning with Java. The first agenda being creating a simple smart-contract out of Java by using Solidity as the base layer.

##### Smart-Contract Storage Example in *Solidity*:
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

##### Smart-Contract Storage Example in *Java*:
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

##### Architecture Example:
![](https://imgur.com/hs8WlUw.jpg)

## Rationale

### Minting
Overall scope/goal for this proposal is for these tokens to be minted as easy as NFTs. This could be accomplished simply from a "button" within a dApp/App that mints a new token, *other simpler possibilities open to discussion*. The Total & Circulating Supply of these tokens are to be minted by dApps/Apps integrated within the logic-base implemented by the developer.

### Exchanging
These New-ERC Tokens are meant to act as ***"Personal Currencies"*** so in order for them to be successfully exchanged, they will need the consent of both parties *(like trading one NFT for another OR specifically speaking, trading 1 Yuan for 1 Dollar, or 50 Yuans for 1 Dollar, etc)*.

#### Token-to-Token Exchange Mechanics/Prices:
**Scenario 1:** *Party A agrees to exchange 1 of their Tokens for 1 Token from Party B.*

> ***Before Exchange***
> 
> | Party A with ERC Token       | Party B with ERC Token     |
> | --------------------------   | -------------------------- |
> | Market Cap = 2kUSD           | Market Cap = 1kUSD         |
> | Total Supply = 1k            | Total Supply = 1k          |
> | Circulating Supply = 100     | Circulating Supply = 50 |
> | 1 Token = 2USD               | 1 Token = 1USD             |
> 
> ***After Exchange***
> 
> | Party A with ERC Token       | Party B with ERC Token     |
> | --------------------------   | -------------------------- |
> | Market Cap = 1.998kUSD       | Market Cap = 1.002kUSD     |
> | Total Supply = 1k            | Total Supply = 1k          |
> | Circulating Supply = 100     | Circulating Supply = 50    |
> | 1 Token = 1.998USD           | 1 Token = 1.002USD         |

**Scenario 2:** *Party A agrees to exchange 50 of their Tokens for 1 Token from Party B.*

> ***Before Exchange***
> 
> | Party A with ERC Token       | Party B with ERC Token     |
> | --------------------------   | -------------------------- |
> | Market Cap = 2kUSD           | Market Cap = 1kUSD         |
> | Total Supply = 1k            | Total Supply = 1k          |
> | Circulating Supply = 100     | Circulating Supply = 50    |
> | 1 Token = 2USD               | 1 Token = 1USD             |
> 
> ***After Exchange***
> 
> | Party A with ERC Token        | Party B with ERC Token         |
> | ----------------------------- | ------------------------------ |
> | Market Cap = 1.9kUSD          | Market Cap = 1.1kUSD           |
> | Total Supply = 951            | Total Supply = 1.049k          |
> | Circulating Supply = 51       | Circulating Supply = 99        |
> | 1 Token = 1.997USD            | 1 Token = 1.048USD             |

### Burning
Burning of these new tokens are meant to occur only once exchanged from ERC into Fiat currencies thus, maintaining value of overall market cap of through what is called an *Exchange-Burn*.

#### Token-to-USD Exchange-Burn Mechanics/Prices:

*Circulating Supply is non-existant in below scenarios due to irrelevance within Exchange-Burn Mechanics.*

**Scenario 1:** *Party A agrees to exchange 1 of their Tokens for equivalent USD from Party B.*

> ***Before Exchange-Burn***
> 
> | Party A with ERC Token     | Party B with USD           |
> | -------------------------- | -------------------------- |
> | Market Cap = 2kUSD         | Total USD = 1kUSD          |
> | Total Supply(ERC) = 1k     | Total Supply(USD) = 1k     |
> | 1 Token = 2USD             | 1USD = 1USD                |
> | Total USD = 0              |
> 
> ***After Exchange-Burn***
> 
> | Party A with ERC Token        | Party B with USD             |
> | --------------------------    | --------------------------   |
> | Market Cap = 2kUSD            | Total USD = 998USD           |
> | Total Supply(ERC) = 999       | Total Supply(USD) = 998      |
> | 1 Token = 2.002USD            | 1USD = 1USD                  |
> | Total USD = 2                 |

**Scenario 2:** *Party A agrees to exchange 10 of their Tokens for equivalent USD from Party B.*

> ***Before Exchange-Burn***
> 
> | Party A with ERC Token     | Party B with USD           |
> | -------------------------- | -------------------------- |
> | Market Cap = 3kUSD         | Total USD = 1kUSD          |
> | Total Supply(ERC) = 1k     | Total Supply(USD) = 1k     |
> | 1 Token = 3USD             | 1USD = 1USD                |
> | Total USD = 0              |
> 
> ***After Exchange-Burn***
> 
> | Party A with ERC Token        | Party B with USD             |
> | --------------------------    | --------------------------   |
> | Market Cap = 3kUSD            | Total USD = 970USD           |
> | Total Supply(ERC) = 990       | Total Supply(USD) = 970      |
> | 1 Token = 3.03USD             | 1USD = 1USD                  |
> | Total USD = 30                |

## Backwards Compatibility
These new ERC tokens proposed by EIP-XXXX are meant to be compatible with ERC-20 tokens (or FTs[Fungible-Tokens]) and their kin only for exchange purposes. ERC-721 tokens (or NFTs[Non-Fungible-Tokens]) already serve and expand the genesis of creating millions of tokens on Ethereum. The premise for EIP-XXXX is to provide a funnel to create fungible tokens on Ethereum with the ease and capacity NFTs are created.

## Security Considerations
A 51% attack of the tokens seems to be the biggest security implication concerning these new ERC tokens which will run on Ethereum 2's PoS consensus. But as stated once by Vitalik, it seems implausible for a validator to get away with a 51% attack of any token running on Ethereum 2 safely.

The second security concern is the expanding base of languages these new ERC tokens can be created in. Solidity is currently not as widely known by developers as Java, Rust and other popular languages thus making it a "blessing in disguise" in regards to how secure the tokens and currencies running on Ethereum are. Expanding the creation of these currencies and tokens from Solidity into Java, Rust, Go, etc will blossom the development of the ecosystem, while also attracting maliciousness (hence the larger an ecosystem grows, the more "criminals" it attracts).

#### References
- [New ERC Token (EIP-XXXX) Research & Development](https://github.com/jeyakatsa/New-ERC-Token/blob/main/R&D.md)
- [New-ERC Token Proposal](https://ethresear.ch/t/a-new-erc-token-proposal/11540)
- [Light-Client Token Creation Proposal](https://ethresear.ch/t/light-client-custom-token-creation-proposal/11433)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
