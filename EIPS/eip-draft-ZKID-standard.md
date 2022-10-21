---
eip: <to be assigned>
title:  ZK based KYC verifier standard. 
description: Standard Interface for validating identities using Zero knowledge proofs
author: Yu Liu (@yuliu-debond)
discussions-to: TBD
status: Draft
type: Standards Track
category (*only required for Standards Track):  ERC
created: 2022-10-18
requires (*optional): 721, 5114.
---

This is the suggested template for new EIPs.

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category. 

## Abstract

- This EIP Provides defined interface for KYC verification with abstract onchain conditions.

- This EIP defines the necessary interface functions to verify the identity of the wallet, based on the conditions descrivbed by the user onchain.

## Motivation
Onchain verification is becoming indispensable across DeFI as well as other web3 protocols (DAO, governance) as needed by the government, but also by different DeFI protocols to whitelist the users which fullfill the certain criteria. this created the necessity of building onchain verification of the addresses for token transfers (like stablecoin providers check for the blacklisted entities for the destination address, limited utility tokens for a DAO community , etc). 


current standards in the space, like [ERC-3643](./eip-3643.md) are insufficient to handle the complex usecases where: 

    -  The validation logic needs to be more complex than verification of the user identity wrt the blacklisted address that is defined offchain, and is very gas inefficient. 

    - also privacy enhanced/anonymous verification is important need by the crypto users in order to insure censorship/trustless networks. ZK based verification schemes are currently the only way to validate the assertion of the identity by the user, while keeping certain aspects of the providers identity completely private.

thus in order to address the two above major challanges: there needs to be creation of the identity verifier standard that will be validating the 

## Specification: 
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

**Definition**

SBT: Soulbound tokens, these are non-fungible and non transferrable tokens that is used for defining the identity of the users. they are defined by standard [eip-5192](./eip-5192.md).



**Functions**

```solidity
pragma solidity ^0.8.0;
    // getter function 
    /// @notice getter function to validate if the address `verifying` is the holder of the SBT defined by the tokenId `SBTID`
    /// @dev it MUST be defining the logic corresponding to all the current possible requirements definition.
    /// @param verifying is the  EOA address that wants to validate the SBT issued to it by the KYC. 
    /// @param SBTID is the Id of the SBT that user is the claimer.
    /// @return true if the assertion is valid, else false
    /**
    example ifVerified(0xfoo, 1) --> true will mean that 0xfoo is the holder of the SBF identity token defined by tokenId of the given collection. 
    */
    function ifVerified(address verifying, uint256 SBFID) external view returns (bool);

    /// @notice getter function to fetch the onchain identification logic for the given identity holder.
    /// @dev it MUST not be defined for address(0). 
    /// @param SBTID is the Id of the SBT that user is the claimer.
    /// @return the struct array of all the descriptions of condition metadata that is defined by the administrator.
    /**
    ex: standardRequirement(1) --> {
    { "title":"DepositRequirement",
        "type": "number",
        "description": "defines the minimum deposit in USDC for the investor along with the credit score",
        },
       "logic": "and",
    "values":{"30000", "5"}    
}
Defines the condition encoded for the identity index 1, defining the identity condition that holder must have 30000 USDC along with credit score of  atleast 5.
    */
    function standardRequirement(uint256 SBFID) external view returns (Requirement[] memory);

    // setter functions
    /// @notice function for setting the requirement logic (defined by Requirements metadata) details for the given identity token defined by SBTID.
    /// @dev it should only be called by the admin address.
    /// @param SBFID is the Id of the SBT based identity certificate for which admin wants to define the Requirements.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.

/**

example: changeStandardRequirement(1, { "title":"DepositRequirement",
        "type": "number",
        "description": "defines the minimum deposit in USDC for the investor along with the credit score",
        },
       "logic": "and",
    "values":{"30000", "5"}    
}); 

will correspond to the the functionality that admin needs to adjust the standard requirement for the identification SBT with tokenId = 1, based on the conditions described in the Requirements array struct details.
*/

    function changeStandardRequirement(uint256 SBFID, Requirement[] memory requirements) external returns (bool);
    
    /// @notice function which uses the ZKProof protocol in order to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBFID is the Id of the SBT based identity certificate for which admin wants to define the Requirements.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.
    function certify(address certifying, uint256 SBFID) external returns (bool);

    /// @notice function which uses the ZKProof protocol in order to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBFID is the Id of the SBT based identity certificate for which admin wants to define the Requirements.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.



    function revoke(address certifying, uint256 SBFID) external returns (bool);
```

**Events**

```solidity
pragma solidity ^0.8.0;

    

    event standardChanged(uint256 SBFID, Requirement[]);   
    event certified(address certifying, uint256 SBFID);
    event revoked(address certifying, uint256 SBFID);
```

**Metadata**:
here metadata







## Rationale
currently the 
## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).