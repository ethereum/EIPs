```  
---
eip: <to be assigned>
title: <Ethereum Token Action Protocol>
author: <Paul Bolhar <paul.bolhar@gmail.com>>
discussions-to: <URL>
status: Draft
type: <ERC>
category (*only required for Standard Track): <Interface | ERC>
created: <2019-04-13>
requires (*optional): <EIP20>
replaces (*optional): <>
---
```

# Simple Summary
Health alternative for crypto ecosystem. Transition from utility tokens to action tokens.
# Abstract
Not ready
# Motivation
Almost anything ethereum tokens is utility and you as investor do not have any rights on company profits,
it is profitable for business, but not profitable for us.
But if we could be possible to change it now, in cryptocurrency technologies age.
I see no reason for us to make the crowdsalers pay us a legitimate income.
# Specification

##### Consensus

1) At the first stage, we determine the owner of the token, and only the true owner, can create a contract wrapper TAP.
For this purpose, the contract is ConfrimOwnership.

2) Second, the owner receives all shares in the amount of totalsupply from EPC 20 token.

3) Third, the distribution of shares occurs at the will of the creator.

4) Fourth, the restriction on the transfer of rights, requires that the recipient on the account have more or equivalent balance in relation to the ERC20 balance. Those. the recipient must have an equivalent balance in order to prove that he, at least at the moment of receipt, is the real holder of the asset.

5) The fifth. The recalculation of the David takes place at a predetermined time limit, and when the legal balance is changed, the recalculation and accrual of the Devian occurs, under the conditions specified in the contract.

6) The sixth. The outputs are output through the withdraw pattern, the withdraw function.

##### TAP interface

    /**
     * @dev Return current rightholders balance, this balance show your real action balance
     * @param rightholder <address>
     */
    function rightsOf(address rightholder) external view returns (uint256);

    /**
     * @dev Transfer rights. Use when need to sell your active.
     * @param to 
     * @param amount 
     */
    function transferOfRights(address to, uint256 amount) external returns(bool);

    /**
     * @dev Allow another balance spend the current balance.
     * @param to 
     * @param amount 
     */
    function rightToTransfer(address from, address to, uint256 amount) external returns(bool);

    /**
     * @dev Using for transfer tokens with rights. 
     *      Economical function make double send if you need. 
     *      Do not use for transfer to exchanges.
     * @param to 
     * @param amount 
     */
    function transferWithRights(address to, uint256 amount) external returns(bool);

    /**
     * @dev Call to get your devidents. You need execute func.withdrawalRequest() before.
     */
    function getDividends() external returns (bool);

    /**
     * @dev Emits when rights transfer to new rightholder.
     * @param rightholder tx sender
     * @param newRightholder tx spender
     * @param amount tx value
     */
    event RightsTransfer(address indexed rightholder, address indexed newRightholder, uint256 indexed amount);

    /**
     * @dev Emits when rights transfer to new rightholder.
     * @param rightholder tx sender
     * @param newRightholder tx allowed address
     * @param amount tx value
     */
    event RightsApproval(address indexed rightholder, address indexed newRightholder, uint amount);

    /**
     * @dev Emits when calculating dividends and crediting to balance.
     * @param rightholder 
     * @param amount
     */
    event AccrualDividends(address indexed rightholder, uint amount);

# Rationale
Not ready
# Backwards Compatibility
Not ready
# Test Cases
Could be found here <https://github.com/pironmind/TokenActionProtocol/tree/master/test>
# Implementation
Could be found here <https://github.com/pironmind/TokenActionProtocol/tree/master/contracts>
# Copyright
Copyright by pironmind - link <https://github.com/pironmind> | paul.bolhar@gmail.com
