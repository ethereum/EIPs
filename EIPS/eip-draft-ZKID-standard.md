---
eip: <to be assigned>
title:  ZK based KYC verifier standard. 
description: Interface for assigning/validating identities using Zero Knowledge Proofs
author: Yu Liu (@yuliu-debond)
discussions-to: TBD
status: Draft
type: Standards Track
category (*only required for Standards Track):  ERC
created: 2022-10-18
requires (*optional): 721, 1155, 5114, 3643.
---


## Abstract

- This EIP Provides defined interface for KYC verification with abstract onchain conditions.

- This EIP defines the necessary interface for orchestrator to assign identity certificates (as Soulbound tokens) to the wallets, which can be verified by ZK schemes.

## Motivation

Onchain verification is becoming indispensable across DeFI as well as other web3 protocols (DAO, governance) as its needed not only by the government for regulatory purposes, but also by different DeFI protocols to whitelist the users which fullfill the certain criterias.

This created the necessity of building onchain verification of the addresses for token transfers (like stablecoin providers check for the blacklisted entities for the destination address, limited utility tokens for a DAO community , etc). Along with the concern that current whitelisting process of the proposals  are based on the addition of the whitelisted addresses (via onchain/offchain signatures) and thus its not trustless for truly decentralised protocols. 


Also Current standards in the space, like [ERC-3643](./eip-3643.md) are insufficient to handle the complex usecases where: 

    -  The validation logic needs to be more complex than verification of the user identity wrt the blacklisted address that is defined offchain, and is very gas inefficient. 

    - also privacy enhanced/anonymous verification is important need by the crypto users in order to insure censorship/trustless networks. ZK based verification schemes are currently the only way to validate the assertion of the identity by the user, while keeping certain aspects of the providers identity completely private.

thus in order to address the above major challenges: there is need of standard that defines the interface of contract which can issue an immutable identity for the identifier (except by the user) along with verifying the identity of the user based on the ownership of the given identity token.


## Specification: 
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

**Definition**

- SBT: Soulbound tokens, these are non-fungible and non transferrable tokens that is used for defining the identity of the users. they are defined by standard [eip-5192](./eip-5192.md).

- SBT Certificates: SBT that represent the  ownerships of ID signatures corresponding to the requirements defined in `function standardRequirement()`.

- KYC standard: Know your customer standard are the set of minimum viable conditions that financial services providers (banks, investment providers and other intermediate financial intermediateries) have to satisfy in order to access the services. this in web3 consideration concerns not about the details about the user itself, but about its status (onchain usage, total balance by the anon wallet, etc) that can be used for whitelisting.

**diagram**

[](../assets/eip-zkID/architecture-diagram.png)


example workflow using preimage verification: 

- here the KYC contract is an oracle that assigns the user identity with the SBT certificate.
- During issuance stage, the process to generate the offchain compute of the merkle root from the  various primairly details are calculated and then assigned onchain to the given wallet address with the identity (as SBT type of smart contract certificate).
- on the other hand, the verifier is shared part of the nodes and the merkle root, in order to verify the merkle leaf information.
- thus during the verification stage, the verifier will be provided with the preimage 


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
/** 
    * standardChanged
    * @notice standardChanged MUST be triggered when requirements are changed by the admin. 
    * @dev standardChanged MUST also be triggered for the creation of a new SBTID.
    */
    event standardChanged(uint256 SBTID, Requirement[]);   
    
    /** 
    * certified
    * @notice certified MUST be triggered when SBT certificate is given to the certifiying address. 
    */
    event certified(address certifying, uint256 SBTID);
    
    /** 
    * revoked
    * @notice revoked MUST be triggered when SBT certificate is revoked. 
    */
    event revoked(address certifying, uint256 SBTID);
```
## Rationale
We follow the structure of onchain metadata storage similar to that of [eip-3475](./eip-3475.md), except the fact that whole KYC requirement description is defined like the class from the eip-3475 standard but with only single condition. 

following are the descriptions of the structures: 

**1.Metadata structure**: 

```solidity
    /**
     * @dev metadata that describes the Values structure on the given requirement, cited from [EIP-3475](./eip-3475.md) 
    example: 
    {    "title": "jurisdiction",
        "_type": "string",
        "description": "two word code defining legal jurisdiction"
        }
    * @notice it can be further optimise by using efficient encoding schemes (like TLV etc) and there can be tradeoff in the gas costs of storing large strings vs encoding/decoding costs while describing the standard.
     */     
    struct Metadata {
        string title;
        string _type;
        string description;
    }
    
    /**
     * @dev Values here can be read and wrote by smartcontract and front-end, cited from [EIP-3475](./eip-3475.md).
     example : 
{
string jurisdiction = IERC6595.Values.StringValue("CH");
}
     */   
    struct Values { 
        string stringValue;
        uint uintValue;
        address addressValue;
        bool boolValue;
    }
```

**2.Requirement structure**:

this will be stored in each of the SBT certificate that will define the conditions that needs to be satisfied by the arbitrary address calling the `verify()` function, in order to be be validated as owner of the given certificate(ie following the regulations), this will be defined for each onchain Values separately. 


```solidity

    /**
     * @dev structure that DeFines the parameters for specific requirement of the SBT certificate
     * @notice this structure is used for the verification process, it contains the metadata, logic and expectation
     * @logic given here MUST be one of ("⊄", "⊂", "<", "<=", "==", "!=", ">=",">")
     ex: standardRequirement => {
    { "title":"adult",
        "type": "uint",
        "description": "client holders age to be gt 18 yrs.",
        },
       "logic": ">=",
    "value":"18"  
	}
	Defines the condition encoded for the identity index 1, DeFining the identity condition that holder must be more than 18 years old.
    */
	
    struct Requirement {
        Metadata metadata;
        string logic;
        Values expectation;
    }

```
 

**example implementation:** 
An example for the KYC of the investment grade bonds: 
```json
{
"Issuer": "ABC LLC",
"Issuer location": "US",
"Issuer url":"abc.ai",
"Issuer address": "0xfoo",
"Issuer contact information": "+1 234 565787",
"lssuer logo url": "./ABC.svg",
"pitch-deck url": "bit.ly/pitch-deck.pptx",
"Type": "Non-callable",
"Industry": "RWA",
"ISIN code":"XS0356705219",
"Registered authority":"SEC",
"Registered code": "",
"Date Position": "",
"Manager name": "",
"Manager’s code": "",
"Custodian Name": "",
"Custodian’s Code": "",
"Share Value": "",
"Total balance": "",
"Amounts Payable": "",
"Collateral":[],
"Callable": "",
"Zero-coupon": "",
"Fixed rate":"",
"Maturity period":"",
"Maturity calculation rule":"",
"Interest period":"",
"Interest calculation rule": " ",
"Accept Asset":[],
"Interest Payment Asset":[],
"Repayment Asset":[],
"ANBID code":"",
"Fund Type": "",
"Risk level":"",
"Risk level rated by": "",
"Preferred creditor":"",
"Liquidation rule": "",
"Qualified investor requirement":"",
"Interest rate":"",
"The amount": "",
"PL of the Fund": "",
"Asset Value":"",
"Amounts Receivable": "",
"Amounts Payable":"",
"Quotas to Issue":"",
"Quotas to be Redeemed": "",
"Number of Shareholders": "",

}
```

and their description of the requirements metadata will be as follows:

```json
{
 {
    { "title":"issuer",
        "type": "string",
        "description": "defines the issuer entity for given cat of bonds",
        },
    "value.stringValue":"ABC-LLC"  
	},

 {
    { "title":"Location",
        "type": "string",
        "description": "defines the jurisdiction of the issuance.",
        },
    "value":"USA"  
	},

{  
    { "title":"URL",
        "type": "string",
        "description": "URL of the website",
        },
    "value": "www.ABC-LLC.com"
},
{
    { "title":"address",
        "type": "string",
        "description": "EOA address of the owner of the SBT certificate of the bonds",
        },
    "value": "0xfoo..."
},

{
    { "title":"Contact information",
        "type": "string",
        "description": "Phone number/email of the responsible for the handling of bonds management (can be modified on behalf of issuing entity)",
        },
    "value": ""
},

{
    { "title":"Issuer Contact information",
        "type": "string",
        "description": "Phone number/email of the responsible for the handling of bonds management (can be modified on behalf of issuing entity)",
        },
    "value": "+1 234 567 9876"
},

{
    { "title":"issuer logo url",
        "type": "string",
        "description": "URI address of the logo of the issuing entity/ company handling the bonds",
        },
    "value": "ipfs://fooEOPIPOSIPO123/ABC_logo.png"
},


{
    { "title":"pitch deck URL",
        "type": "string",
        "description": "URI storage of pitch deck describing the bonds",
        },
    "value": "ipfs://fooEOPIPOSIPO123/ABC_Bond_description.pdf"
},


{
    { "title":"type",
        "type": "string",
        "description": "Defines the category of the bond",
        },
    "value": "Callable"
},



{
    { "title":"Industry",
        "type": "string",
        "description": "Defines the type of industry(agriculture, real-estate, etc)",
        },
    "value": "Callable"
},



{
    { "title":"Industry",
        "type": "string",
        "description": "Defines the type of industry(agriculture, real-estate, etc)",
        },
    "value": "RWA"
},

{
    { "title":"ISIN code",
        "type": "string",
        "description": "Hexadecimal code identifying the bond instrument",
        },
    "value": "XS0356705219..",
},

{
    { "title":"ISIN code",
        "type": "string",
        "description": "Hexadecimal code identifying the bond instrument",
        },
    "value": "XS0356705219..",
}



{
    { "title":"Registering authority",
        "type": "string",
        "description": "registeration financial authorities, based on the jurisdiction",
        },
    "value": "SEC",
}

{
    { "title":"Registering authority",
        "type": "string",
        "description": "registeration financial authorities, based on the jurisdiction",
        },
    "logic": "==",
    "value": "SEC",
}


{
    { "title":"Date position",
        "type": "string",
        "description": "Date for which issuer listed the proposition (ISO standard, UTC time)",
        },
    "value": "10:10:2010::7:05",
}

{
    { "title":"Manager-name",
        "type": "string",
        "description": "Person responsible for the management of the admin wallet for bonds, can be adapted only by main team",
        },
    "value": "Mr Joe",
},

{
    { "title":"Custodian name",
        "type": "string",
        "description": "Name of Entity that is managing the custody of the underlying collateral",
        },
    "value": "Joe Law firm",
}

//TBD
// "Custodian Name": "",
// "Custodian’s Code": "",
// "Share Value": "",
// "Total balance": "",
// "Amounts Payable": "",
// "Collateral":[],
// "Callable": "",
// "Zero-coupon": "",
// "Fixed rate":"",
// "Maturity period":"",

}

```


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