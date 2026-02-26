# EIP-5725: Transferrable Vesting NFT - Reference Implementation

This repository serves as a reference implementation for **EIP-5725 Transferrable Vesting NFT Standard**. A Non-Fungible Token (NFT) standard used to vest ERC-20 tokens over a vesting release curve.

## Contents

- [EIP-5725 Specification](./contracts/IERC5725.sol): Interface and definitions for the EIP-5725 specification.
- [ERC-5725 Implementation (abstract)](./contracts/ERC5725.sol): ERC-5725 contract which can be extended to implement the specification.
- [VestingNFT Implementation](./contracts/reference/LinearVestingNFT.sol): Full ERC-5725 implementation using cliff vesting curve.
- [LinearVestingNFT Implementation](./contracts/reference/VestingNFT.sol): Full ERC-5725 implementation using linear vesting curve.
