---
eip: 5163
title: Rich Site-Proposed Contract Metadata
description: A protocol for dapps to suggest metadata to wallets related to relevant contracts.
author: Dan Finlay <@danfinlay>
discussions-to: https://ethereum-magicians.org/t/eip-rich-site-proposed-contract-metadata/9635
status: Draft
type: Standards
category: Interface
created: 2022-06-15
---

## Abstract

Many types of phishing attack today rely on users not knowing what contract they're interacting with, even when it's a contract the user has interacted with before. To facilitate in recognizing these interactions in a way that requires no central registry or additioanl services, we propose that wallet methods that may interact with an address should also accept proposed metadata from the site suggesting the transaction, which can be used to enhance the display of future interactions with those contracts.

## Motivation

We've got a lot of ways we try to gather the information for confirmations, but it ranges between very complicated, unreliable, centralized, and incomplete, and is not getting the job done.
1. Contract names
  - Local address book
    - Requires user interaction, which adds UX burden, and most users skip.
  - Centralized registries
    - Are perpetually incomplete, and favor the established, not the upstart.
   - reverse-resolved ENS names
     - Attackers can choose familiar-looking names, so these are not a reliable basis of secure review of what you're looking at unless you entered it yourself.
2. Method information
  - Registry lookups (4byte directory, the Parity on-chain registry)
    - Can be prone to collisions (like At Inversebrah, with trolling increasing)
    - Returns ABIs
      - Has no parameter names, leaving most of the transaction illegible.
  - Trusting the contract for its own metadata (EIP-719, EIP-4430)
    - Requires an active connection to the blockchain.
    - Is not widespread (no backwards compatibility)
  - Transaction Insights
    - Requires an additional fairly heavy-weight process
    - Is largely centralized today
    - Only works for verified contracts on etherscan (although designed for eventual Sourcify support).

Additionally, this method serves to help populate the wallet with trustworthy information about what it holds. It reduces the need to rely on any central services for indexing (enhancing performance and privacy), and eliminates dangers that come from index-based automatic asset detection, like receiving harrassment, or Airdrop scams.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

Wallets may integrate the ability to propose names for contracts, methods, and parameters into any method that touches an address, so the wallet can be expanded with this metadata at runtime. These methods include `eth_sendTransaction`, and `eth_signTypedData` (and its variants).

Benefits
  - No need for any central server
  - No registry with collisions
  - Works on all chains
  - Includes parameter names as well as method and contract names.
  - Could be easily added to any existing dapp
  - If every dapp a user touches uses this, then no phishing site could get the user to give up one of those assets without seeing a legible confirmation.
  - Can even be implemented on a cold/offline or hardware wallet.

### Reference Implementation
Any method that involves an address MAY include a new OPTIONAL parameter `proposedContracts`, which will include an additional prompt to the user as part of the confirmation flow, asking if they'd like to trust the site for this information.

`contractId` would be some kind of cross chain address format, likely [CAIP-10](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md).
`ContractData` would be some kind of type that is enough to render transaction names for methods called.
  - Today TX Insight uses a full Truffle Decoder output to render this, which includes lots of compiler info that we would not need here.
```typescript
type TxOptionsEnhancement = {
  proposedContracts: {
    [contractId: CrossChainAddress]: {
      proposedName: string,
      abi?: Abi,
      contractData?: ContractData
    }
  }
}
```
Wallets MUST store the recommending site & time along with this data for forensic purposes.
The user SHOULD be able to adjust the proposed names in the confirmation, to avoid collisions, and help personalize their local context.
Any subsequent confirmations that are displaying the proposed contracts' names SHOULD show the proposed names.
  - A mouse hover may provide the metadata about when this name was proposed.
Any subsequent transaction confirmations that are displaying transactions to the proposed contracts SHOULD use the proposed data to render those transactions as readably as possible.
Additional optional parameters MAY be added to the `proposedContracts` options object to allow new kinds of enhancement in the future.

## Rationale
- We need a solution that can address two aspects of transaction interaction
  - What you're interacting with
  - How you're interacting with it
- We want something we can get into production ASAP
- We want a solution that is as complete as possible
  - If used correctly, it should be able to totally eliminate the un-readability problems of transactions.
- If this were adopted widespread, it could also reduce the need to rely on centralized indexes of on-chain assets in general, since users would have more complete local views of their own assets.

## Backwards Compatibility
Since this EIP involves a new optional parameter whose name is not used in any method, it should not have any issues with backwards compatibility.

## Security Considerations
This proposal's security depends on a user's first interaction with a contract being from a trustworthy site. If we assume that most of the time that a user is being phished, they are being robbed of an asset they previously acquired, then it should be safe to assume that there was a prior opportunity for the user to be introduced to reliable metadata from the source that they originally acquired the asset (the metadata is as trustworthy as the asset they have is authentic).

Achieving that initial safety would require a widespread push for adoption, but since it's just about adding a new optional parameter and it keeps a site's users more resistant to phishing, I think this effort could be effective.

Some users would not be protected by this: Users who acquired their assets previously, and do not have the relevant metadata for the assets they are holding. Those users would be at no greater risk than they are at today. One of these users being phished to a malicious site could be either presented with a malicious transaction or malicious metadata, but for a scammer the current behavior (transfer the asset) is simply fewer steps to success, so it seems unlikely this would be a desireable attack for phishers.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
