// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


interface IERC3475 {

    // WRITE

    /**
     * @dev allows the transfer of a bond type from an address to another.
     * @param from argument is the address of the holder whose balance about to decrees.
     * @param to argument is the address of the recipient whose balance is about to increased.
     * @param classId is the classId of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that will be transferred from "_from" address to "_to" address.
     */
    function transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) external;


    /**
     * @dev  allows issuing any number of bond types to an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param to is the address to which the bond will be issued.
     * @param classId is the classId of the bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that "to" address will receive.
     */
    function issue(address to, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev  allows redemption of any number of bond types from an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param from is the address from which the bond will be redeemed.
     * @param classId is the class nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonce of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that "from" address will redeem.
     */
    function redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev  allows the transfer of any number of bond types from an address to another.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param from argument is the address of the holder whose balance about to decrees.
     * @param classId is the class nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonce of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that will be transferred from "_from"address to "_to" address.
     */
    function burn(address from, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev Allows spender to withdraw from your account multiple times, up to the amount.
     * @notice If this function is called again it overwrites the current allowance with amount.
     * @param spender is the address the caller approve for his bonds
     * @param classId is the classId nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond that the spender is approved for.
     */
    function approve(address spender, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
      * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
      * @dev MUST emit the ApprovalForAll event on success.
      * @param operator  Address to add to the set of authorized operators
      * @param classId is the classId nonce of bond, the first bond class created will be 0, and so on.
      * @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalFor(address operator, uint256 classId, bool approved) external;

    /**
     * @dev Allows spender to withdraw bonds from your account multiple times, up to the amount.
     * @notice If this function is called again it overwrites the current allowance with amount.
     * @param spender is the address the caller approve for his bonds.
     * @param classIds is the list of classIds of bond.
     * @param nonceIds is the list of nonceIds of the given bond class.
     * @param amounts is the list of amounts of the bond that the spender is approved for.
     */
    function batchApprove(address spender, uint256[] calldata classIds, uint256[] calldata nonceIds, uint256[] calldata amounts) external;


    // READ

    /**
     * @dev Returns the total supply of the bond in question
     */
    function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the redeemed supply of the bond in question
     */
    function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the active supply of the bond in question
     */
    function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the burned supply of the bond in question
     */
    function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the balance of the giving bond classId and bond nonce
     */
    function balanceOf(address account, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the symbol of the giving bond classId
     */
    function symbol(uint256 classId) external view returns (string memory);

    /**
     * @dev Returns the information for the class of given classId
     * @notice Every bond contract can have their own list of class information
     */
    function classInfos(uint256 classId) external view returns (uint256[] memory);

    /**
     * @dev Returns the information description for a given class info
     * @notice Every bond contract can have their own list of class information
     */
    function classInfoDescription(uint256 classInfo) external view returns (string memory);

    /**
     * @dev Returns the information description for a given nonce info
     * @notice Every bond contract can have their own list of nonce information
     */
    function nonceInfoDescription(uint256 nonceInfo) external view returns (string memory);

    /**
     * @dev Returns the information for the nonce of given classId and nonceId
     * @notice Every bond contract can have their own list. But the first uint256 in the list MUST be the UTC time code of the issuing time.
     */
    function nonceInfos(uint256 classId, uint256 nonceId) external view returns (uint256[] memory);

    /**
     * @dev  allows anyone to check if a bond is redeemable.
     * @notice the conditions of redemption can be specified with one or several internal functions.
     */
    function isRedeemable(uint256 classId, uint256 nonceId) external view returns (bool);

    /**
     * @notice  Returns the amount which spender is still allowed to withdraw from owner.
     */
    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
    * @notice Queries the approval status of an operator for a given owner.
    * @return True if the operator is approved, false if not
    */
    function isApprovedFor(address owner, address operator, uint256 classId) external view returns (bool);

    /**
    * @notice MUST trigger when tokens are transferred, including zero value transfers.
    */
    event Transfer(address indexed _operator, address indexed _from, address indexed _to, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are issued
    */
    event Issue(address indexed _operator, address indexed _to, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are redeemed
    */
    event Redeem(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are burned
    */
    event Burn(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @dev MUST emit when approval for a second party/operator address to manage all bonds from a classId given for an owner address is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalFor(address indexed _owner, address indexed _operator, uint256 classId, bool _approved);

}
