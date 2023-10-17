// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
//import "./IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

///
/// @dev Required interface of an ERC20 Charity compliant contract.
///
interface IERC20charity is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    ///type(IERC20charity).interfaceId.interfaceId == 0x557512b6
    /// bytes4 private constant _INTERFACE_ID_ERCcharity = 0x557512b6;
    /// _registerInterface(_INTERFACE_ID_ERCcharity);

    
    /**
     * @dev Emitted when `toAdd` charity address is added to `whitelistedRate`.
     */
    event AddedToWhitelist (address toAdd);

    /**
     * @dev Emitted when `toRemove` charity address is deleted from `whitelistedRate`.
     */
    event RemovedFromWhitelist (address toRemove);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr`.
     */
    event DonnationAddressChanged (address whitelistedAddr);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr` 
    * and _donation is set to `rate`.
     */
    event DonnationAddressAndRateChanged (address whitelistedAddr,uint256 rate);

    /**
     * @dev Emitted when `whitelistedRate` for `whitelistedAddr` is modified and set to `rate`.
     */
    event ModifiedCharityRate(address whitelistedAddr,uint256 rate);
    
    /**
    *@notice Called with the charity address to determine if the contract whitelisted the address
    *and if it is the rate assigned.
    *@param addr - the Charity address queried for donnation information.
    *@return whitelisted - true if the contract whitelisted the address to receive donnation
    *@return defaultRate - the rate defined by the contract owner by default , the minimum rate allowed different from 0
    */
    function charityInfo(
        address addr
    ) external view returns (
        bool whitelisted,
        uint256 defaultRate
    );

    /**
    *@notice Add address to whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toAdd` cannot be the zero address.
     *
     * @param toAdd The address to whitelist.
     */
    function addToWhitelist(address toAdd) external;

    /**
    *@notice Remove the address from the whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toRemove` cannot be the zero address.
     *
     * @param toRemove The address to remove from whitelist.
     */
    function deleteFromWhitelist(address toRemove) external;

    /**
    *@notice Get all registered charity addresses.
     */
    function getAllWhitelistedAddresses() external view returns (address[] memory) ;

    /**
    *@notice Display for a user the rate of the default charity address that will receive donation.
     */
    function getRate() external view returns (uint256);

    /**
    *@notice Set personlised rate for charity address in {whitelistedRate}.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     *
     * @param whitelistedAddr The address to set as default.
     */
    function setSpecificDefaultAddress(address whitelistedAddr) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The rate is specified by the user.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate 
     * or to the rate specified by the owner of this contract in {whitelistedRate}.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificDefaultAddressAndRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Display for a user the default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
     */
    function specificDefaultAddress() external view returns (
        address defaultAddress
    );

    /**
    *@notice Delete The Default Address and so deactivate donnations .
     */
    function deleteDefaultAddress() external;
}