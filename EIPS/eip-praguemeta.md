---
eip: XXXX
title: Hardfork Meta - Prague/Electra
description: EIPs included in the Prague/Electra Ethereum network upgrade.
author: Tim Beiko (@timbeiko)
discussions-to: TBA
status: Review
type: Meta
created: 2024-01-18
requires: 2537, 6110, 7002, 7569

## Abstract

This Meta EIP lists the EIPs formally considered for and included in the Prague/Electra network upgrade. 

## Specification

### Included EIPs 

### Considered for Inclusion

* [EIP-2537](./eip-2537.md): Precompile for BLS12-381 curve operations
* [EIP-6110](./eip-6110.md): Supply validator deposits on chain
* [EIP-7002](./eip-7002.md): Execution layer triggerable exits

### Full Specifications 

#### Consensus Layer

EIPs 6110 and 7002 require changes to Ethereum's consensus layer. While the EIPs present an overview of these changes, the full specifications can be found in the `_features` directory of the `ethereum/consensus-specs` repository. 

#### Execution Layer

EIPs 2537, 6110 and 7002 require changes to Ethereum's execution layer. The EIPs fully specify those changes. 

### Activation 

| Network Name     | Activation Epoch | Activation Timestamp |
|------------------|------------------|----------------------|
| Goerli           |                  |                      |
| Sepolia          |                  |                      |
| Holešky          |                  |                      |
| Mainnet          |                  |                      |

**Note**: rows in the table above will be filled as activation times are decided by client teams. 

## Rationale

This Meta EIP provides a global view of all changes included in the Prague/Electra network upgrade, as well as links to full specification. 

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
