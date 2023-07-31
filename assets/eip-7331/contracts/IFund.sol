// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IFund {


    /**
    @dev Shares dividends with multiple addresses.
    @param _address An array of addresses to receive dividends.
    @param _dividend An array of corresponding dividend amounts.
    @param _from The address from which the dividends are sent.
    @param _key An array of keys indicating the type of dividends: 0 for Token, 1 for StableCoin, and any other value for Fiat.
    @param coin The index of the stablecoin to use.
    onlyAgent modifier ensures that only authorized agents can call this function.
    Requires that the length of _address, _dividend, and _key arrays are the same.
    Retrieves the address of the stablecoin at the specified index.
    Iterates over each address and shares the corresponding dividends.
    If the key is 0, mints the token dividends to the address.
    If the key is 1, transfers the stablecoin dividends from _from address to the recipient address.
    Calls the _addUserDividend() function to add the dividends to the recipient's record.
    Assumes that the token, factory, and _addUserDividend() function are already initialized.
    */
    function shareDividend(address[] calldata _address, uint256[] calldata _dividend, address _from, uint8[] calldata _key, uint8 coin) external;

    /**
    @dev Distributes funds and burns tokens for multiple investors.
    @param _investors An array of investor addresses.
    @param _amount An array of corresponding fund amounts to distribute.
    @param _tokens An array of corresponding token amounts to burn.
    @param _from The address from which the funds are sent.
    @param coin The index of the stablecoin to use.
    onlyAgent modifier ensures that only authorized agents can call this function.
    Requires that the length of _investors, _amount, and _tokens arrays are the same.
    Retrieves the address of the stablecoin at the specified index.
    Iterates over each investor and performs the distribution and token burning.
    Burns the specified amount of tokens from the investor's balance.
    Transfers the corresponding amount of funds from _from address to the investor's address.
    Assumes that the token, factory, and TransferHelper.safeTransferFrom() function are already initialized.
    */
    function distributeAndBurn(address[] calldata _investors, uint256[] calldata _amount, uint256[] calldata _tokens, address _from, uint8 coin) external;

    /**
    @dev Rescues any ERC20 tokens accidentally sent to the contract.
    @param _tokenAddr The address of the ERC20 token to be rescued.
    @param _to The address to which the rescued tokens will be transferred.
    @param _amount The amount of tokens to be rescued.
    onlyAgent modifier ensures that only authorized agents can call this function.
    Uses the SafeERC20Upgradeable library to safely transfer the specified amount of tokens to the specified address.
    Assumes that the _tokenAddr is a valid ERC20 token address.
    This function is callable externally.
    */
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint128 _amount) external;
}