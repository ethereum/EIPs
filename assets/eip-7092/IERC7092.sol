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
    *         It is RECOMMENDED to represent the symbol as a combination of the issuer Issuer'shorter name and the maturity date
    *         Ex: If a company named Green Energy issues bonds that will mature on october 25, 2030, the bond symbol could be `GE30` or `GE2030` or `GE102530`
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
    */
    function symbol() external view returns(string memory);

    /**
    * @notice Returns the number of decimals the bond uses - e.g `10`, means to divide the token amount by `10000000000`
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
    */
    function decimals() external view returns(uint8);

    /**
    * @notice Returns the bond currency. This is the contract address of the token used to pay and return the bond principal
    */
    function currency() external view returns(address);

    /**
    * @notice Returns the copoun currency. This is the contract address of the token used to pay coupons. It can be same as the the one used for the principal
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
    */
    function currencyOfCoupon() external view returns(address);

    /**
    * @notice Returns the bond denominiation. This is the minimum amount in which the Bonds may be issued. It must be expressend in unit of the principal currency
    *         ex: If the denomination is equal to 1,000 and the currency is USDC, then the bond denomination is equal to 1,000 USDC
    */
    function denomination() external view returns(uint256);

    /**
    * @notice Returns the issue volume (total debt amount). It is RECOMMENDED to express the issue volume in denomination unit.
    */
    function issueVolume() external view returns(uint256);

    /**
    * @notice Returns the total token supply
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used in case a bond needs to be represented as en ERC20 token.
    *            If not implemented, the total supply is equal to the ratio => issueVolume / denomination.
    */
    function totalSupply() external view returns(uint256);

    /**
    * @notice Returns the bond interest rate. It is RECOMMENDED to express the interest rate in basis point unit.
    *         1 basis point = 0.01% = 0.0001
    *         ex: if interest rate = 5%, then coupon() => 500 basis points
    */
    function couponRate() external view returns(uint256);

    /**
    * @notice Returns the coupon type
    *         An example could be => 0: Zero coupon, 1: Fixed Rate, 2: Floating Rate, etc...
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
    */
    function couponType() external view returns(uint256);

    /**
    * @notice Returns the coupon frequency, i.e. the number of times coupons are paid in a year.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
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
    *         An example could be => 0: actual/actual, 1: actual/360, etc...
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
    */
    function dayCountBasis() external view returns(uint256);

    /**
    * @notice Returns the principal of an account. It is RECOMMENDED to express the principal in the bond currency unit (USDC, DAI, etc...)
    * @param _account account address
    */
    function principalOf(address _account) external view returns(uint256);

    /**
    * @notice returns the balance of `_account`
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used in case a bond needs to be represented as en ERC20 token.
    *            If not implemented, the balance of an account is equal to the ratio => principalOf(account) / denomination.
    */
    function balanceOf(address _account) external view returns(uint256);

    /**
    * @notice Returns the amount of tokens the `_spender` account has been authorized by the `_owner``
    *         acount to manage their bonds
    * @param _owner the bondholder address
    * @param _spender the address that has been authorized by the bondholder
    */
    function allowance(address _owner, address _spender) external view returns(uint256);

    /**
    * @notice Authorizes `_spender` account to manage `_amount`of their bond tokens
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond tokens to approve
    */
    function approve(address _spender, uint256 _amount) external returns(bool);

    /**
    * @notice Authorizes `_spender` account to manage `_amount`of their bond tokens in the destination Chain
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond tokens to approve
    * @param _destinationChainID The unique ID that identifies the destination Chain.
    * @param _destinationContract The smart contract to interact with in the destination Chain in order to Deposit or Mint tokens that are transferred.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to approve tokens cross-chain.
    */
    function crossChainApprove(address _spender, uint256 _amount, uint64 _destinationChainID, address _destinationContract) external returns(bool);

    /**
    * @notice Authorizes several spenders account to manage `_amount`of their bond tokens
    * @param _spender array of addresses to be authorized by the bondholder
    * @param _amount array of amount of bond tokens to approve
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect these values to be present. The method is used to improve usability.
    */
    function batchApprove(address[] calldata _spender, uint256[] calldata _amount) external returns(bool);

    /**
    * @notice Authorizes several spender accounts to manage `_amount`of their bond tokens in the destination Chain
    * @param _spender array of addresses to be authorized by the bondholder
    * @param _amount array of amount of bond tokens to approve
    * @param _destinationChainID array of unique IDs that identifies the destination Chain.
    * @param _destinationContract array of smart contracts to interact with in the destination Chain in order to Deposit or Mint tokens that are transferred.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to approve tokens cross-chain.
    */
    function batchCrossChainApprove(address[] calldata _spender, uint256[] calldata _amount, uint64[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool);

    /**
    * @notice Lowers the allowance of `_spender` by `_amount`
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond tokens to remove from allowance
    */
    function decreaseAllowance(address _spender, uint256 _amount) external;

    /**
    * @notice Lowers the allowance of `_spender` by `_amount` in the destination Chain
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond tokens to remove from allowance
    * @param _destinationChainID The unique ID that identifies the destination Chain.
    * @param _destinationContract The smart contract to interact with in the destination Chain in order to Deposit or Mint tokens that are transferred.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to decrease the token allowance cross-chain.
    */
    function crossChainDecreaseAllowance(address _spender, uint256 _amount, uint64 _destinationChainID, address _destinationContract) external;

    /**
    * @notice Lowers the allowance of several spenders by corresponding amount in `_amount`
    * @param _spender array of addresses to be authorized by the bondholder
    * @param _amount array of amount of bond tokens to remove from allowance
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to decrease token allowance.
    */
    function batchDecreaseAllowance(address[] calldata _spender, uint256[] calldata _amount) external;

    /**
    * @notice Lowers the allowance of `_spender` by `_amount` in the destination Chain
    * @param _spender array of addresses to be authorized by the bondholder
    * @param _amount array of amount of bond tokens to remove from allowance
    * @param _destinationChainID array of unique IDs that identifies the destination Chain.
    * @param _destinationContract array of smart contracts to interact with in the destination Chain in order to Deposit or Mint tokens that are transferred.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to decrease the token allowance cross-chain.
    */
    function batchCrossChainDecreaseAllowance(address[] calldata _spender, uint256[] calldata _amount, uint64[] calldata _destinationChainID, address[] calldata _destinationContract) external;

    /**
    * @notice Moves `_amount` bonds to address `_to`
    * @param _to the address to send the bonds to
    * @param _amount amount of bond tokens to transfer
    */
    function transfer(address _to, uint256 _amount) external returns(bool);

    /**
    * @notice Moves `_amount` bonds to address `_to`. This methods also allows to attach data to the token that is being transferred
    * @param _to the address to send the bonds to
    * @param _amount amount of bond tokens to transfer
    * @param _data additional information provided by the token holder
    */
    function transfer(address _to, uint256 _amount, bytes calldata _data) external returns(bool);
   
    /**
    * @notice Moves `_amount` bonds to address `_to` from the current Chain to another Chain (Ex: move tokens from Ethereum to Polygon).
    *         This methods also allows to attach data to the token that is being transferred
    * @param _to the address to send the bonds to
    * @param _amount amount of bond tokens to transfer
    * @param _data additional information provided by the token holder
    * @param _destinationChainID The unique ID that identifies the destination Chain.
    * @param _destinationContract The smart contract to interact with in the destination Chain in order to Deposit or Mint bond tokens that are transferred.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to transfer tokens cross-chain.
    */
    function crossChainTransfer(address _to, uint256 _amount, bytes calldata _data, uint64 _destinationChainID, address _destinationContract) external returns(bool);

    /**
    * @notice Moves `_amount` bonds to address `_to`. This methods also allows to attach data to the token that is being transferred
    * @param _to array of addresses to send the bonds to
    * @param _amount array of amount of bond tokens to transfer
    * @param _data array of additional information provided by the token holder
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to decrease the token allowance cross-chain.
    */
    function batchTransfer(address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data) external returns(bool);

    /**
    * @notice Moves `_amount` bonds to address `_to` from the current Chain to another Chain (Ex: move tokens from Ethereum to Polygon).
    *         This methods also allows to attach data to the token that is being transferred
    * @param _to array of addresses to send the bonds to
    * @param _amount array of amounts of bond tokens to transfer
    * @param _data array of additional information provided by the token holder
    * @param _destinationChainID array of unique IDs that identify the destination Chains.
    * @param _destinationContract array of smart contracts to interact with in the destination Chains in order to Deposit or Mint bond tokens that are transferred.
    *
    * OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to transfer tokens cross-chain.
    */
    function batchCrossChainTransfer(address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data, uint64[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool);

    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function
    * @param _from the bondholder address
    * @param _to the address to transfer bonds to
    * @param _amount amount of bond tokens to transfer
    */
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);

    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function
    *         This methods also allows to attach data to the token that is being transferred
    * @param _from the bondholder address
    * @param _to the address to transfer bonds to
    * @param _amount amount of bond tokens to transfer.
    * @param _data additional information provided by the token holder
    */
    function transferFrom(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(bool);
    
    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function, from the current Chain to another Chain (Ex: move tokens from Ethereum to Polygon)
    *         This methods also allows to attach data to the token that is being transferred
    * @param _from the bondholder address
    * @param _to the address to transfer bonds to
    * @param _amount amount of bond tokens to transfer
    * @param _data additional information provided by the token holder
    * @param _destinationChainID The unique ID that identifies the destination Chain.
    * @param _destinationContract The smart contract to interact with in the destination Chain in order to Deposit or Mint tokens that are transferred.
    *
    ** OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to transfer tokens cross-chain.
    */
    function crossChainTransferFrom(address _from, address _to, uint256 _amount, bytes calldata _data, uint64 _destinationChainID, address _destinationContract) external returns(bool);

    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function
    *         This methods also allows to attach data to the token that is being transferred
    * @param _from array of bondholder addresses
    * @param _to array of addresses to transfer bond tokens to
    * @param _amount array of amount of bond tokens to transfer.
    * @param _data array of additional information provided by the token holder
    *
    ** OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to transfer tokens cross-chain.
    */
    function batchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data) external returns(bool);

    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function, from the current Chain to another Chain (Ex: move tokens from Ethereum to Polygon)
    *         This methods also allows to attach data to the token that is being transferred
    * @param _from array of bondholder addresses
    * @param _to array of addresses to transfer bonds to
    * @param _amount array of amount of bond tokens to transfer
    * @param _data array of additional information provided by the token holder
    * @param _destinationChainID array of unique IDs that identifies the destination Chain.
    * @param _destinationContract array of smart contracts to interact with in the destination Chain in order to Deposit or Mint tokens that are transferred.
    *
    ** OPTIONAL - interfaces and other contracts MUST NOT expect this function to be present. The method is used to transfer tokens cross-chain.
    */
    function batchCrossChainTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data, uint64[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool);

    /**
    * @notice MUST be emitted when bond tokens are transferred, issued or redeemed, except during contract creation
    * @param _from the account that owns bonds
    * @param _to the account that receives the bond
    * @param _amount amount of bond tokens to be transferred
    */
    event Transfer(address _from, address _to, uint256 _amount);

    /**
    * @notice MUST be emitted when a batch of bond tokens are transferred, issued or redeemed, except during contract creation
    * @param _from bond token's owner
    * @param _to array of accounts that receives the bond
    * @param _amount array of amount of bond tokens to be transferred
    */
    event TransferBatch(address _from, address[] _to, uint256[] _amount);

    /**
    * @notice MUST be emitted when bond tokens are transferred or redeemed cross-chain
    * @param _from the account that owns bonds
    * @param _to the account that receives the bond
    * @param _amount amount of bond tokens to be transferred
    * @param _destinationChainID The unique ID that identifies the destination Chain
    */
    event CrossChainTransfer(address _from, address _to, uint256 _amount, uint64 _destinationChainID);

    /**
    * @notice MUST be emitted when a batch of bond tokens are transferred or redeemed cross-chain
    * @param _from the bond token's owner
    * @param _to array of accounts that receive the bond
    * @param _amount array of amount of bond tokens to be transferred
    * @param _destinationChainID array of unique IDs that identify the destination Chain
    */
    event CrossChainTransferBatch(address _from, address[] _to, uint256[] _amount, uint64[] _destinationChainID);

    /**
    * @notice MUST be emitted when an account is approved
    * @param _owner bond token's owner
    * @param _spender the account to be allowed to spend bonds
    * @param _amount amount of bond tokens allowed by _owner to be spent by _spender.
    */
    event Approval(address _owner, address _spender, uint256 _amount);

    /**
    * @notice MUST be emitted when an account is approved cross-chain
    * @param _owner the bonds owner
    * @param _spender the account to be allowed to spend bonds
    * @param _amount amount of bond tokens allowed by _owner to be spent by _spender
    * @param _destinationChainID The unique ID that identifies the destination Chain
    */
    event CrossChainApproval(address _owner, address _spender, uint256 _amount, uint64 _destinationChainID);

    /**
    * @notice MUST be emitted when a batch of accounts are approved
    * @param _owner bond token's owner
    * @param _spender array of accounts to be allowed to spend bonds
    * @param _amount array of amount of bond tokens allowed by _owner to be spent by _spender.
    */
    event ApprovalBatch(address _owner, address[] _spender, uint256[] _amount);

    /**
    * @notice MUST be emitted when a batch of accounts are approved cross-chain
    * @param _owner bond token's owner
    * @param _spender array of accounts to be allowed to spend bonds
    * @param _amount array of amount of bond tokens allowed by _owner to be spent by _spender
    * @param _destinationChainID array of unique IDs that identify the destination Chain
    */
    event CrossChainApprovalBatch(address _owner, address[] _spender, uint256[] _amount, uint64[] _destinationChainID);

    /**
    * @notice MUST be emmitted when the `_owner` decreases allowance from `_sepnder` by quantity `_amount`
    * @param _owner the bonds owner
    * @param _spender the account that has been allowed to spend bonds
    * @param _amount amount of bond tokens to disapprove
    */
    event DecreaseApproval(address _owner, address _spender, uint256 _amount);

    /**
    * @notice MUST be emmitted when the `_owner` decreases allowance from `_sepnder` by quantity `_amount` cross-chain
    * @param _owner the bonds owner
    * @param _spender the account that has been allowed to spend bonds
    * @param _amount amount of bond tokens to disapprove
    * @param _destinationChainID The unique ID that identifies the destination Chain
    */
    event CrossChainDecreaseApproval(address _owner, address _spender, uint256 _amount, uint64 _destinationChainID);

    /**
    * @notice MUST be emmitted when  `_owner` decreases allowance from several sepnders by corresponding quantity in the array `_amount`
    * @param _owner the bonds owner
    * @param _spender array of accounts that had been allowed to spend bonds
    * @param _amount array of amount of bond tokens to disapprove
    */
    event DecreaseApprovalBatch(address _owner, address[] _spender, uint256[] _amount);

    /**
    * @notice MUST be emmitted when the `_owner` decreases allowance from several sepnders by corresponding quantity in `_amount` cross-chain
    * @param _owner the bonds owner
    * @param _spender array of accounts that have been allowed to spend bonds
    * @param _amount array of amount of bond tokens to disapprove
    * @param _destinationChainID array of unique IDs that identify the destination Chain
    */
    event CrossChainDecreaseApprovalBatch(address _owner, address _spender[], uint256 _amount[], uint64 _destinationChainID[]);
}
