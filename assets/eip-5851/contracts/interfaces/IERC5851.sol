// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5851{
    
    /** Metadata
    * 
    * @param title defines the name of the claim field
    * @param kind is the nature of the data (bool,string,address,bytes,..)
    * @param description additional information about claim details.
    */
    struct Metadata {
        string title;
        string kind;
        string description;
    }
    
    /** Values
    * 
    * @dev Values here can be read and wrote by smartcontract and front-end, cited from [EIP-3475](./eip-3475.md) 
    */   
    struct Values { 
        string stringValue;
        uint uintValue;
        address addressValue;
        bool boolValue;
    }

    /** Claim
    * 
    * Claims structure consist of the conditions and value that holder claims to associate and verifier has to validate them.
    * @notice the below given parameters are for reference purposes only, developers can optimize the fields that are needed to be represented on-chain by using schemes like TLV, encoding into base64 etc.
    * @dev structure that DeFines the parameters for specific claims of the SBT certificate
    * @notice this structure is used for the verification process, it contains the metadata, logic and expectation
    * @logic given here MUST be one of ("⊄", "⊂", "<", "<=", "==", "!=", ">=",">")
    */
    struct Claim {
        Metadata metadata;
        string logic;
        Values expectation;   
    }

    //Verifier
    /// @notice getter function to validate if the address `claimer` is the holder of the claim Defined by the tokenId `SBTID`
    /// @dev it MUST be Defining the logic to fetch the result of the ZK verification (either from).
    /// @dev logic given here MUST be one of ("⊄", "⊂", "<", "<=", "==", "!=", ">=", ">")
    /// @param claimer is the EOA address that wants to validate the SBT issued to it by the KYC. 
    /// @param SBTID is the Id of the SBT that user is the claimer.
    /// @return true if the assertion is valid, else false
    /**
    example ifVerified(0xfoo, 1) => true will mean that 0xfoo is the holder of the SBT identity token DeFined by tokenId of the given collection. 
    */
    function ifVerified(address claimer, uint256 SBTID) external view returns (bool);

    //Issuer
    /// @notice getter function to fetch the on-chain identification logic for the given identity holder.
    /// @dev it MUST not be defined for address(0). 
    /// @param SBTID is the Id of the SBT that the user is the claimer.
    /// @return the struct array of all the descriptions of condition metadata that is defined by the administrator for the given KYC provider.
    /**
    ex: standardClaim(1) --> {
    { "title":"age",
        "kind": "uint",
        "description": "age of the person based on the birth date on the legal document",
        },
       "logic": ">=",
    "value":"18"  
    }
    Defines the condition encoded for the identity index 1, DeFining the identity condition that holder must be equal or more than 18 years old.
    **/
    function standardClaim(uint256 SBTID) external view returns (Claim[] memory);

    /// @notice function for setting the claim requirement logic (defined by Claims metadata) details for the given identity token defined by SBTID.
    /// @dev it should only be called by the admin address.
    /// @param SBTID is the Id of the SBT-based identity certificate for which the admin wants to define the Claims.
    /// @param `claims` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.
    /**
    example: changeStandardClaim(1, { "title":"age",
            "kind": "uint",
            "description": "age of the person based on the birth date on the legal document",
            },
        "logic": ">=",
        "value":"18"  
    }); 
    will correspond to the functionality that admin needs to adjust the standard claim for the identification SBT with tokenId = 1, based on the conditions described in the Claims array struct details.
    **/
    function changeStandardClaim(uint256 SBTID, Claim[] memory _claims) external returns (bool);

    /// @notice function which uses the ZKProof protocol to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBTID is the Id of the SBT-based identity certificate for which admin wants to define the Claims.
    /// @param claimer is the address that needs to be proven as the owner of the SBT defined by the tokenID.
    /**
    example: certify(0xA....., 10) means that admin assigns the DID badge with id 10 to the address defined by the `0xA....` wallet.
    */
    function certify(address claimer, uint256 SBTID) external returns (bool);

    /// @notice function which uses the ZKProof protocol to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBTID is the Id of the SBT-based identity certificate for which the admin wants to define the Claims.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.
    // eg: revoke(0xfoo,1): means that KYC admin revokes the SBT certificate number 1 for the address '0xfoo'.
    function revoke(address certifying, uint256 SBTID) external returns (bool);


// Events
    /** 
    * standardChanged
    * @notice standardChanged MUST be triggered when claims are changed by the admin. 
    * @dev standardChanged MUST also be triggered for the creation of a new SBTID.
    e.g : emit StandardChanged(1, Claims(Metadata('age', 'uint', 'age of the person based on the birth date on the legal document'), ">=", "18");
    is emitted when the Claim condition is changed which allows the certificate holder to call the functions with the modifier, claims that the holder must be equal or more than 18 years old.
    */
    event StandardChanged(uint256 SBTID, Claim[] _claims);
    
    /** 
    * certified
    * @notice certified MUST be triggered when the SBT certificate is given to the certifying address. 
    * eg: Certified(0xfoo,2); means that wallet holder address 0xfoo is certified to hold a certificate issued with id 2, and thus can satisfy all the conditions defined by the required interface.
    */
    event Certified(address claimer, uint256 SBTID);
    
    /** 
    * revoked
    * @notice revoked MUST be triggered when the SBT certificate is revoked. 
    * eg: Revoked( 0xfoo,1); means that entity user 0xfoo has been revoked to all the function access defined by the SBT ID 1.
    */
    event Revoked(address claimer, uint256 SBTID);
}
