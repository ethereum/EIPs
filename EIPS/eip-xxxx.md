# EIP: [Number TBD] - Remove Initcode Size Limit

## Abstract
This EIP proposes the removal of the initcode size limit of 49152 bytes introduced in [EIP-3860](https://eips.ethereum.org/EIPS/eip-3860). The restriction complicates deploying multiple contracts addressing the [EIP-170](https://eips.ethereum.org/EIPS/eip-170) limit (24576 bytes) within a single transaction, while the existing gas metering for initcode, including JUMPDEST analysis, already ensures fair cost attribution.

## Motivation

[EIP-3860](https://eips.ethereum.org/EIPS/eip-3860) limits initcode size to 49152 bytes to cap JUMPDEST analysis costs during contract deployment. However, this restriction hinders deploying multiple contracts in one transaction, a pattern for working around [EIP-170](https://eips.ethereum.org/EIPS/eip-170)'s 24576-byte deployed code limit. The initcode gas metering already accounts for JUMPDEST analysis, making the size cap redundant and overly restrictive.

## Specification
Revert the initcode size limit introduced in [EIP-3860](https://eips.ethereum.org/EIPS/eip-3860). Specifically:
- Remove the 49152-byte cap on initcode size during contract creation.
- Retain existing gas costs for initcode execution, including the 2 gas per byte for JUMPDEST analysis, as defined in [EIP-3860](https://eips.ethereum.org/EIPS/eip-3860).

No changes to deployed contract size limits ([EIP-170](https://eips.ethereum.org/EIPS/eip-170)) or gas schedules beyond removing the size restriction are proposed.

## Rationale
The initcode size limit imposes an unnecessary constraint on deployment patterns, particularly for factory contracts creating multiple sub-contracts in a single transaction. Gas metering sufficiently covers the computational cost of JUMPDEST analysis, scaling linearly with initcode size. Removing the cap simplifies development without compromising network security or cost fairness.

## Backwards Compatibility
This change is fully backwards compatible. Existing contracts and transactions remain unaffected, as the proposal only lifts a restriction without altering execution semantics or gas costs.

## Test Cases
1. Deploy a transaction with initcode exceeding 49152 bytes, verifying successful execution.
2. Confirm gas consumption matches existing metering (e.g., 2 gas per byte for JUMPDEST analysis) without additional penalties.

## Security Considerations
No new security risks are introduced. The gas schedule already mitigates denial-of-service concerns by charging for initcode processing.

## Copyright
Copyright and related rights waived via CC0.
