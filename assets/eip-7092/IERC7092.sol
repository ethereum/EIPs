// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
* @title ERC-7092 Financial Bonds tandard
*/
interface IERC7092 {
    /**
    *  @notice Returns the bond isin
    */
    function isin() external view returns(string memory);

    /**
    * @notice Returns the bond name
    */
    function name() external view returns(string memory);

    /**
    * @notice Returns the bond symbol
    */
    function symbol() external view returns(string memory);

    /**
    * @notice Returns the number of decimals the bond uses - e.g `10`, means to divide the token amount by `10000000000`
    *
    * OPTIONAL
    */
    function decimals() external view returns(uint8);

    /**
    * @notice Returns the bond currency. This is the contract address of the token used to pay and return the bond principal
    */
    function currency() external view returns(address);

    /**
    * @notice Returns the copoun currency. This is the contract address of the token used to pay coupons. It can be same as the the one used for the principal
    */
    function currencyOfCoupon() external view returns(address);

    /**
    * @notice Returns the bond denominiation. This is the minimum amount in which the Bonds may be issued. It must be expressend in unit of the principal currency
    *         ex: If the denomination is equal to 1,000 and the currency is USDC, then the bond denomination is equal to 1,000 USDC
    */
    function denomination() external view returns(uint256);

    /**
    * @notice Returns the issue volume (total debt amount). It is RECOMMENDED to express the issue volume in denomination unit.
    *         ex: if denomination = $1,000, and the total debt is $5,000,000
    *         then, issueVolume() = $5,000, 000 / $1,000 = 5,000 bonds
    */
    function issueVolume() external view returns(uint256);

    /**
    * @notice Returns the bond interest rate. It is RECOMMENDED to express the interest rate in basis point unit.
    *         1 basis point = 0.01% = 0.0001
    *         ex: if interest rate = 5%, then coupon() => 500 basis points
    */
    function couponRate() external view returns(uint256);

    /**
    * @notice Returns the coupon type
    *         ex: 0: Zero coupon, 1: Fixed Rate, 2: Floating Rate, etc...
    */
    function couponType() external view returns(uint256);

    /**
    * @notice Returns the coupon frequency, i.e. the number of times coupons are paid in a year.
    */
    function couponFrequency() external view returns(uint256);

    /**
    * @notice Returns the date when bonds were issued to investors. This is a Unix Timestamp like the one returned by block.timestamp
    */
    function issueDate() external view returns(uint256);

    /**
    * @notice Returns the bond maturity date, i.e, the date when the pricipal is repaid. This is a Unix Timestamp like the one returned by block.timestamp
    *         The maturity date MUST be greater than the issue date
    */
    function maturityDate() external view returns(uint256);

    /**
    * @notice Returns the day count basis
    *         Ex: 0: actual/actual, 1: actual/360, etc...
    */
    function dayCountBasis() external view returns(uint256);

    /**
    * @notice Returns the principal of an account. It is RECOMMENDED to express the principal in denomination unit.
    *         Ex: if denomination = $1,000, and the user has invested $5,000
    *             then principalOf(_account) = 5,000/1,000 = 5
    * @param _account account address
    */
    function principalOf(address _account) external view returns(uint256);

    /**
    * @notice Returns the amount of tokens the `_spender` account has been authorized by the `_owner``
    *         acount to manage their bonds
    * @param _owner the bondholder address
    * @param _spender the address that has been authorized by the bondholder
    */
    function approval(address _owner, address _spender) external view returns(uint256);

    /**
    * @notice Authorizes `_spender` account to manage `_amount`of their bonds
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond to approve. _amount MUST be a multiple of denomination
    */
    function approve(address _spender, uint256 _amount) external;

    /**
    * @notice Authorizes the `_spender` account to manage all their bonds
    * @param _spender the address to be authorized by the bondholder
    */
    function approveAll(address _spender) external;

    /**
    * @notice Lowers the allowance of `_spender` by `_amount`
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond to remove approval; _amount MUST be a multiple of denomination
    */
    function decreaseAllowance(address _spender, uint256 _amount) external;

    /**
    * @notice Removes the allowance for `_spender`
    * @param _spender the address to remove the authorization by from
    */
    function decreaseAllowanceForAll(address _spender) external;

    /**
    * @notice Moves `_amount` bonds to address `_to`
    * @param _to the address to send the bonds to
    * @param _amount amount of bond to transfer. _amount MUST be a multiple of denomination
    * @param _data additional information provided by the token holder
    */
    function transfer(address _to, uint256 _amount, bytes calldata _data) external;

    /**
    * @notice Moves all bonds to address `_to`
    * @param _to the address to send the bonds to
    * @param _data additional information provided by the token holder
    */
    function transferAll(address _to, bytes calldata _data) external;

    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function
    * @param _from the bondholder address
    * @param _to the address to transfer bonds to
    * @param _amount amount of bond to transfer. _amount MUST be a multiple of denomination
    * @param _data additional information provided by the token holder
    */
    function transferFrom(address _from, address _to, uint256 _amount, bytes calldata _data) external;

    /**
    * @notice Moves all bonds from `_from` to `_to`. The caller must have been authorized through the approve function
    * @param _from the bondholder address
    * @param _to the address to transfer bonds to
    * @param _data additional information provided by the token holder
    */
    function transferAllFrom(address _from, address _to, bytes calldata _data) external;

    /**
    * @notice MUST be emitted when bonds are transferred
    * @param _from the account that owns bonds
    * @param _to the account that receives the bond
    * @param _amount the amount of bonds to be transferred
    * @param _data additional information provided by the token holder
    */
    event Transferred(address _from, address _to, uint256 _amount, bytes _data);

    /**
    * @notice MUST be emitted when an account is approved
    * @param _owner the bonds owner
    * @param _spender the account to be allowed to spend bonds
    * @param _amount the amount allowed by _owner to be spent by _spender.
    */
    event Approved(address _owner, address _spender, uint256 _amount);

    /**
    * @notice MUST be emmitted when the `_owner` decreases allowance from `_sepnder` by quantity `_amount`
    * @param _owner the bonds owner
    * @param _spender the account that has been allowed to spend bonds
    * @param _amount the amount of tokens to disapprove
    */
    event AllowanceDecreased(address _owner, address _spender, uint256 _amount);
}
