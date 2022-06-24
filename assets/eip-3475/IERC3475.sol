// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


interface IERC3475 {

    // STRUCTURE 

    /**
     * @dev Values structure of the Metadata
     */
    struct Values{        
        string stringValue;
        uint uintValue;
        address addressValue;
        bool boolValue;
    }
    /**
     * @dev structure allows the transfer of any given number of bonds from an address to another.
     * @title": "defning the title information",
     * @type": "explaining the type of the title information added",
    * @description": "little description about the information stored in the bond",
     */
    struct Metadata {
        string title;
        string types;
        string description;
    }
    /**
     * @dev structure allows the transfer of any given number of bonds from an address to another.
     * @classId is the class id of bond.
     * @nonceId is the nonce id of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @_amount is the _amount of the bond, that will be transferred.
     */
    struct Transaction {
        uint256 classId;
        uint256 nonceId;
        uint256 _amount;
    }

    // WRITABLE
    /**
     * @dev allows the transfer of a bond from an address to another (either single or in batches).
     * @param _from argument is the address of the holder whose balance about to decrease.
     * @param _to argument is the address of the recipient whose balance is about to increased.
     */
    function transferFrom(address _from, address _to, Transaction[] calldata _transaction) external;
     /**
     * @dev allows the transfer of allowance from an address to another (either single or in batches).
     * @param _from argument is the address of the holder whose balance about to decrease.
     * @param _to argument is the address of the recipient whose balance is about to increased.
     */
    function transferAllowanceFrom(address _from, address _to, Transaction[] calldata _transaction) external;
   /**
     * @dev allows issuing of any number of bond types to an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _to is the address to which the bond will be issued.
     */
    function issue(address _to, Transaction[] calldata _transaction) external;
    /**
     * @dev allows redemption of any number of bond types from an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _from is the address _from which the bond will be redeemed.
     */
    function redeem(address _from, Transaction[] calldata _transaction) external;
    /**
     * @dev allows the transfer of any number of bond types from an address to another.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _from argument is the address of the holder whose balance about to decrees.
     */
    function burn(address _from, Transaction[] calldata _transaction) external;
    /**
     * @dev Allows _spender to withdraw from your account multiple times, up to the _amount.
     * @notice If this function is called again it overwrites the current allowance with _amount.
     * @param _spender is the address the caller approve for his bonds
     */
    function approve(address _spender, Transaction[] calldata _transaction) external;
    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved "True" if the operator is approved, "False" to revoke approval
     */
    function setApprovalFor(address _operator, bool _approved) external;

    // READABLES 
    /**
     * @dev Returns the total supply of the bond in question.
     */
    function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
     * @dev Returns the redeemed supply of the bond in question.
     */
    function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
     * @dev Returns the active supply of the bond in question.
     */
    function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
     * @dev Returns the burned supply of the bond in question.
     */
    function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
     * @dev Returns the balance of the giving bond classId and bond nonce.
     */
    function balanceOf(address _account, uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
     * @dev Returns the JSON metadata of the classes.
     * The metadata SHOULD follow a set of structure explained later in eip-3475.md
     */
    function classMetadata(uint256 metadataId) external view returns ( Metadata memory);
    /**
     * @dev Returns the JSON metadata of the nonces.
     * The metadata SHOULD follow a set of structure explained later in eip-3475.md
     */
    function nonceMetadata(uint256 classId, uint256 metadataId) external view returns ( Metadata memory);
    /**
     * @dev Returns the values of given classId.
     * the metadata SHOULD follow a set of structure explained in eip-3475.md
     */
    function classValues(uint256 classId, uint256 metadataId) external view returns ( Values memory);
    /**
     * @dev Returns the values of given nonceId.
     * The metadata SHOULD follow a set of structure explained in eip-3475.md
     */
    function nonceValues(uint256 classId, uint256 nonceId, uint256 metadataId) external view returns ( Values memory);
    /**
     * @dev Returns the informations about the progress needed to redeem the bond
     * @notice Every bond contract can have their own logic concerning the progress definition.
     */
    function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining);
    /**
     * @notice Returns the _amount which spender is still allowed to withdraw from _owner.
     */
    function allowance(address _owner, address _spender, uint256 classId, uint256 nonceId) external view returns (uint256);
    /**
    * @notice Queries the approval status of an operator for a given owner.
     * Returns "True" if the operator is approved, "False" if not
     */
    function isApprovedFor(address _owner, address _operator) external view returns (bool);


    // EVENTS
    /**
     * @notice MUST trigger when tokens are transferred, including zero value transfers.
     */
    event Transfer(address indexed _operator, address indexed _from, address indexed _to, Transaction[] _transaction);
    /**
     * @notice MUST trigger when tokens are issued
     */
    event Issue(address indexed _operator, address indexed _to, Transaction[] _transaction);
    /**
     * @notice MUST trigger when tokens are redeemed
     */
    event Redeem(address indexed _operator, address indexed _from, Transaction[] _transaction);
    /**
     * @notice MUST trigger when tokens are burned
     */
    event Burn(address indexed _operator, address indexed _from, Transaction[] _transaction);
    /**
     * @dev MUST emit when approval for a second party/operator address to manage all bonds from a classId given for an owner address is enabled or disabled (absence of an event assumes disabled).
     */
    event ApprovalFor(address indexed _owner, address indexed _operator, bool _approved);

}
