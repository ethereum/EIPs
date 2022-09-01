# Multi-Fractional Non-Fungible Token
Solidity Implementation of Multi-Fractional Non-Fungible Token.

## Problem Trying to solve
Before, ERC20 Token contract should be deployed every time when fractionalizing a specific NFT.

To solve this problem, this standard proposes a token standard to cover multiple fractionalized nft in a contract without having to deploy each time.

Issue : https://github.com/ethereum/EIPs/issues/4674

PR : https://github.com/ethereum/EIPs/pull/4675

## How to use
```
contracts/
        helper/
        interface/
        math/
        MFNFT.sol
        NFT.sol
        ERC20Token.sol
```

### Contracts
``MFNFT.sol`` : Multi-Fractional Non-Fungible Token Contract

``NFT.sol`` : Non-Fungible Token Contract

``ERC20Token.sol`` : Sample ERC-20 Token Contract

``helper/Verifier.sol`` : Contract that verifies the ownership of NFT before fractionalization

``math/SafeMath.sol`` : Openzeppelin SafeMath Library

``interface/IERC20.sol`` : ERC-20 Token Interface

``interface/IERC721.sol`` : ERC-721 Token Interface

``interface/IMFNFT`` : MFNFT Token Interface

### Install & Test

Installation
```
npm install
```

Test
```
npx hardhat test
```

Coverage
```
npx hardhat coverage
```
