---
title: Domain-contracts two-way binding
description: A standward way to enable a two-way binding between domain and its official contracts to prevent DNS attacks
author: Venkat Kunisetty (@VenkatTeja)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-03-08
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->
This EIP proposes a standard way for dapps to maintain their official domains and contracts that are linked through an on-chain and off-chain two-way binding mechanism. 

## Motivation

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->
Web3 users sometimes get attacked due to vulnerebilities in web2 systems. For example, in Nov 2022, Curve.fi suffered a DNS attack. This attack would have been prevented if there was a standard way to allow dapp developers to disclose their official contracts. If this was possible, wallets could have easily detected un-official contracts and warned users. 
  
An added advantage to this approach is to predictably find the the official contract addresses of a dapp. Most dapp's docs are non-standard and it is difficult to find the official contract addresses.

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Terms
  1. `Two-way` binding: Being able to verify what official contracts of a domain are offchain and onchain
  2. `Dapp Registry contract (DRC)`: This is a contract that is to be deployed by dapp developer that validates if a contract address is official
  3. `Registry contract`: This is a contract that maintains the mapping between domain and its DRC.
  4. `DApp Developer (DAD)`: The one who is developing the decentralised application
  
### Implementation
  The DAD must create a custom file on their domain at `/contracts.json` route. The file must return the information about the official contracts in the following structure:
  ```
    // Returns the array of this structure
    {
      contractAddress: "0x...abc",
      name: "Your contract name",
      description?: "your contract description",
      code?: "Link to sol file of this contract"
    }[]
  ```
  
  Further, DAD must deploy deploy a DRC that has the following structure:
  ```
    interface IDAppRegistry {
      
      function isMyContract(address _address) external view returns (bool);
    }
  ```
  
  We define the Registry contract as:
  ```
    contract DomainContractRegistry {
      struct RegistryInfo {
        address dappRegistry;
        address admin;
      }
      
      mapping(string => RegistryInfo) public registryMap;
  
      function setDappRegistry(string memory _domain, address _dappRegistry) external {
        // check if a domain already has a dapp registry mapped
        // if yes, check if owner is same. if so, allow the change
        // if no, revert
        
        IDappRegistry dappRegistry = IDappRegistry(_dappRegistry);
        // Use chainlink to the call `{{domain}}/contracts.json`. 
        // Check for each contract listed in contracts.json by calling 
        // dappRegistry.isMyContract(_address)
        
        // If all addresses match, update registryMap
      }
    }
  ```
  DAD must register their domain in this registry to validate domain ownership. 

## Rationale
 
<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

  Wallets need official contract addresses of a domain to warn users if the domain is sending transaction to a different address. This could have been solved by allowing DADs to provide a standard url (e.g. /contracts.json) to wallets. However, in the event of a DNS attack, even this information can be tampered. By deploying a registry contract on chain, the DAD is able to have a second source of their official contracts that they can set when they have full control of their domain. If registry's information gets tampered, wallets can always use standard url to cross-check. This system ensures the attackers has to get access to both admin private keys and domain control to do the attack which is highly difficult relatively. This is analogous to 2FA. 
  
  More details - TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
