// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5851 {
    // STRUCTURE 
    /**
     * @dev metadata and Values structure of the Metadata, cited from ERC-3475.
     eg: 
     {
        "title":"jurisdiction-code",
        "_type":"string",
        "description":"ISO code defining the jusrisdiction"

     }
     */
    struct Metadata {
        string title;
        string _type;
        string description;
    }

    /**    
    * this stores the actual parameter on which the condition is described.
    * e.g  
    * string swissJurisdiction = IERC5851.Values("ch","0",address(0), false)
    */
    struct Values { 
        string stringValue;
        uint uintValue;
        address addressValue;
        bool boolValue;
    }
    /**
     * @dev structure that defines the parameters for specific issuance of bonds and amount which are to be transferred/issued/given allowance, etc.
     * @notice this structure is used for the verification process, it chontains the metadata, logic and expectation
     * @logic given here MUST be one of ("⊄", "⊂", "<", "<=", "==", "!=", ">=",">")
     */
    struct Requirement {
        Metadata metadata;
        string logic;
        Values expectation;
    }
    //getter functions 
    
    /**
    This function gets the status of whether the address `verifying` is holding the address SBTID.
    @param verifying is the address who wants to verify the holding of KYC-SBT of Id 'SBTID'.
    @param SBTID is the index number of the SBT issued by the KYC admin.
    @return returns true if the KYC is verified else false.
    */
    function ifVerified(address verifying, uint256 SBTID) external view returns (bool);

    /// @notice getter function to fetch the onchain identification logic for the given identity holder.
    /// @dev it MUST not be defined for address(0). 
    /// @param SBTID is the Id of the SBT that the user is the claimer.
    /// @return the struct array of all the descriptions of condition metadata that is defined by the administrator for the given KYC provider.

    function standardRequirement(uint256 SBTID) external view returns (Requirement[] memory);


    // writable functions 
    /// @notice function for setting the requirement logic (defined by Requirements metadata) details for the given identity token defined by SBTID.
    /// @dev it should only be called by the admin address.
    /// @param SBTID is the Id of the SBT-based identity certificate for which the admin wants to define the Requirements.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.


    function changeStandardRequirement(uint256 SBTID, Requirement[] calldata requirements) external returns (bool);
    
    
    /// @notice function which uses the ZKProof protocol to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBTID is the Id of the SBT-based identity certificate for which admin wants to define the Requirements.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.

    
    function certify(address certifying, uint256 SBTID) external returns (bool);



    /// @notice function which uses the ZKProof protocol to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBTID is the Id of the SBT-based identity certificate for which the admin wants to define the Requirements.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.

    function revoke(address certifying, uint256 SBTID) external returns (bool);


    //EVENTS

    event standardChanged(uint256 SBTID, Requirement[]);   
    event certified(address certifying, uint256 SBTID);
    event revoked(address certifying, uint256 SBTID);
}