# Nft Roles

[![Coverage Status](https://coveralls.io/repos/github/OriumNetwork/nft-roles/badge.svg?branch=master)](https://coveralls.io/github/OriumNetwork/nft-roles?branch=master)
![Github Badge](https://github.com/OriumNetwork/nft-roles/actions/workflows/all.yml/badge.svg)
[![solidity - v0.8.9](https://img.shields.io/static/v1?label=solidity&message=v0.8.9&color=2ea44f&logo=solidity)](https://github.com/OriumNetwork)
[![License: CC0 v1](https://img.shields.io/badge/License-CC0v1-blue.svg)](https://creativecommons.org/publicdomain/zero/1.0/legalcode)
[![Discord](https://img.shields.io/discord/1009147970832322632?label=discord&logo=discord&logoColor=white)](https://discord.gg/NaNTgPK5rx)
[![Twitter Follow](https://img.shields.io/twitter/follow/oriumnetwork?label=Follow&style=social)](https://twitter.com/OriumNetwork)

This repository contains a minimal implementation of ERC-7432 (Non-Fungible Token Roles).
ERC-7432 introduces role management for NFTs. Each role assignment is associated with a single NFT and expires automatically at a given timestamp. 

ERC-7432 can be deeply integrated with dApps to create a utility-sharing mechanism. A good example is in digital real estate. A user can create a digital property NFT and grant a `keccak256("PROPERTY_MANAGER")` role to another user, allowing them to delegate specific utility without compromising ownership. The same user could also grant multiple  `keccak256("PROPERTY_TENANT")` roles, allowing the grantees to access and interact with the digital property.

You can find the full specification [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7432.md).

# Build

```bash
npm install
npm run build
```

# Test

```bash
npm run test
```