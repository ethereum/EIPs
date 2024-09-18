---
eip: <to be assigned>
title: Standard Test Addresses for Development Frameworks
description: A standard set of test addresses derived from a known mnemonic for use in Ethereum development frameworks
author: HarryR (@CedarMist)
discussions-to: https://ethereum-magicians.org/t/test-accounts-need-clear-warnings/20228
status: Draft
type: Informational
created: 2023-09-13
---

## Abstract

This EIP proposes a standardized set of Ethereum addresses and private keys derived from a specific mnemonic phrase for use in testing and development environments. These addresses are already widely used in popular development frameworks such as [Hardhat](https://github.com/NomicFoundation/hardhat) and [Foundry](https://github.com/foundry-rs/foundry).

## Motivation

Ethereum developers frequently need a set of known addresses and private keys for testing smart contracts and applications. While various development frameworks provide such addresses, there's no standardized set across all tools. This leads to inconsistencies and potential confusion when moving between different development environments.

Additionally there is no warning in wallets about when well-known keys are being used, this leads to accidents and confusion where people may sign-up or use services with a test account leading to loss of funds or KYC checks which are meaningless in practice.

By standardizing on a specific set of addresses derived from a known mnemonic, we can:

1. Enhance interoperability between different development tools and frameworks.
2. Reduce cognitive load on developers who switch between tools.
3. Facilitate easier sharing and reproduction of test scenarios across teams and projects.
4. Standardize warnings in wallets & related UI/UX areas to make users aware of 'test accounts'.

## Specification

The standard test addresses and private keys shall be derived from the following mnemonic phrase:

```
test test test test test test test test test test test junk
```

This mnemonic should be used with [BIP39](https://en.bitcoin.it/wiki/BIP_0039) (Mnemonic code for generating deterministic keys) to generate the seed, and then [BIP32](https://en.bitcoin.it/wiki/BIP_0032) (Hierarchical Deterministic Wallets) for key derivation. The derivation path follows the pattern:

```
m/44'/60'/0'/0/{account_index}
```

Where `{account_index}` starts at 0 and increments for each subsequent address. The first 20 derived addresses (0-19) shall be considered the standard test addresses.

### Test Addresses

Here are the first 10 addresses (0-9) derived from this mnemonic:

0. `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
1. `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
2. `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`
3. `0x90F79bf6EB2c4f870365E785982E1f101E93b906`
4. `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65`
5. `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc`
6. `0x976EA74026E726554dB657fA54763abd0C3a0aa9`
7. `0x14dC79964da2C08b23698B3D3cc7Ca32193d9955`
8. `0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f`
9. `0xa0Ee7A142d267C1f36714E4a8F75612F20a79720`

### Private Keys

Here are the corresponding private keys for the first 10 addresses:

0. `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
1. `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`
2. `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`
3. `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6`
4. `0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a`
5. `0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba`
6. `0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e`
7. `0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356`
8. `0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97`
9. `0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6`

(Note: The full list of 20 private keys and their corresponding addresses can be derived using the Python code in the appendix)

## Rationale

The chosen mnemonic `test test test test test test test test test test test junk` is already widely. By standardizing on this mnemonic, we leverage existing adoption while providing a clear specification for other tools to implement.

The derivation path `m/44'/60'/0'/0/{account_index}` follows the standard for Ethereum accounts as per [BIP44](https://en.bitcoin.it/wiki/BIP_0044) (Multi-Account Hierarchy for Deterministic Wallets), ensuring compatibility with existing wallet software and hardware.

Twenty addresses are specified to provide a sufficient number for most testing scenarios while keeping the list manageable.

## Backwards Compatibility

This EIP is fully backwards compatible as it does not introduce any changes to the Ethereum protocol. It merely standardizes a set of addresses already in use by many developers.

## Security Considerations

The private keys and addresses specified in this EIP should NEVER be used on any production network or to store real assets. They are intended for testing purposes only.

Developers and users should be aware that these addresses and private keys are publicly known and should treat them accordingly in their development and testing processes.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

----

## Appendix

### Key Derivation

Uses the following Python packages via `python -m pip install eth-account hdwallet`:

 * [eth-account](https://github.com/ethereum/eth-account/)
 * [hdwallet](https://github.com/meherett/python-hdwallet)

```python=
from hdwallet import BIP44HDWallet
from hdwallet.cryptocurrencies import EthereumMainnet
from hdwallet.derivations import BIP44Derivation
from eth_account import Account
MNEMONIC = "test test test test test test test test test test test junk"
w = BIP44HDWallet(cryptocurrency=EthereumMainnet)
w.from_mnemonic(mnemonic=MNEMONIC, language="english")
for i in range(20):
    w.clean_derivation()
    w.from_path(path=BIP44Derivation(
        cryptocurrency=EthereumMainnet, account=0, change=False, address=i
    ))
    account = Account.from_key(w.private_key())
    print(f"{i}. {account.address} 0x{w.private_key()}")
```
