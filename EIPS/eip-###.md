---
eip: 5503
title: Refundable Token Standard
author: <admin@startfund.io>
status: Draft
type: Standards Track
category: ERC
created: 2022-08-16
---

## Abstract
The value of a token can be the total sum of the linked currency’s value. For example, in the Token issuing process, the issuer can receive money from buyers( or investors) and transfer issuing token to buyers. . If the offering process is completed, there is no issue. But buyers can change their plan, or the offering is failed(or be canceled) cause of misfitting the compliance rules or other rules. There is no way guarantee to pay back (refund) to the buyer in the on-chain network.
We have suggested this process make possible in on-chain network with a payable currency like token(ex: USDT)

## Motivation
A standard interface allows the payable token contract to interact with ERC-2000 interface within smart contracts.

Any payable token contract call ERC-2000 interface to exchange with issuing token based on constraint built in ERC-2000 smart contract to validate transactions.

Note: Refund is only available in certain conditions(ex: period, oracle value, etc) based on implementations.

## Requirements
Exchanging tokens requires having an escrow like the standard way in the on-chain network.

The following stand interfaces should be provided on ERC-2000 interface.
  - MUST support querying texted-based compliance for transactions. ex: period, max number of buyers, minimum and maximum tokens to hold, refund period, etc.
  - exchange(or purchase) with success or failed return code.
  - refund(or cancel the transaction) with a success or failed return code.
  - withdraw when the escrow process has been a success.



## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

There are 3 contracts for the escrow process: `Buyer Contract`, `Seller Contract` and `Escrow Contract`.
 - Buyer Contract: Buyers will pay to an escrow account to exchange with `Seller Token`.
 - Seller Contract: The seller will pay to the escrow account to exchange with `Buyer Token`.
 - Escrow Contract: Will be created by the seller. Agent to co-operate between buyers and sellers based on constraint rules. Instead of a simple address mapped balance variable in ERC20 tokens, this balance should have (Seller, Buyer).

**Every ERC-5503 compliant contract must implement the `ERC5503` interfaces**

```solidity
pragma solidity ^0.4.20;


interface ERC5503 {

    /// @notice escrow balance of owner
    /// @dev assigned to the zero address are considered invalid, and this
    ///   function throws for queries about the zero address.
    ///   in case of escrow contract,
    ///       recommend return buyer's token balance.
    ///       used for backward compatibility with ERC20 standard.
    /// @param
    ///   - _owner: An address for whom to query the balance
    /// @return amount of current escrow account balance. can be seller's token or buyer's token
    function balanceOf(address account) public view returns (uint256);


    /// @notice escrow balance of owner
    /// @dev assigned to the zero address are considered invalid, and this
    ///   function throws for queries about the zero address.
    /// @param
    ///   - _owner: An address for whom to query the balance
    /// @return amount of current escrow account balance. First is buyer token , and seconds is seller token
    function escrowBalanceOf(address account) public view returns (uint256, uint256);


    /// @notice simple query to return simple description of compliance.
    /// @dev must implemented in Escrow-Contract and optional for other contracts.
    function escrowComplianceDescription() external view returns (string);

    /// simple query to return string based on error code. if code is zero, return can be 'success'
    /// @dev must implemented in Escrow-Contract and optional for other contracts.
    function escrowErrorCodeDescription(uint32 _code) external view returns (string);


    /// @notice deposit fund(token) into escrow account.
    /// @dev
    ///   - seller/buyer contract should call escrow contract's function before _transfer.
    ///   - escrow contract should update (Seller, Buyer) balance.
    ///   - seller can call this function to fund initial supply.
    /// @param
    ///   - to:
    ///     In case of buyer/seller contract, must be escrow contract address.
    ///     In case of escrow contract, must be user address who is triggered this transaction.
    ///   - _valuePayed: payable token amount
    /// @return reason code. 0 is success, otherwise is failure code.
    function escrowFund(address to, uint256 amount) public returns (uint32);


    /// @notice refund from escrow account.
    /// @dev
    ///   - seller/buyer contract should call escrow contract's function before _transfer.
    ///   - escrow contract should update (Seller, Buyer) balance.
    ///   - seller should not call this function.
    /// @param
    ///   - to:
    ///     In case of buyer/seller contract, must be escrow contract address.
    ///     In case of escrow contract, must be user address who is triggered this transaction.
    ///   - _valuePayed: payable token amount
    /// @return reason code. 0 is success, otherwise is failure code.
    function escrowRefund(address to, uint256 amount) public returns (uint32);

    /// @notice withdraw token from escrow account.
    /// @dev
    ///   - must implemented in Escrow-Contract and optional for other contracts.
    ///   - buyer is only available when escrow is success, otherwise should call escrowRefund.
    ///   - in case of escrow failed, seller can refund seller-token.
    ///   - if escrow is success, seller and buyer can get exchanged token on their own wallet.
    /// @return reason code. 0 is success, otherwise is failure code.
    function escrowWithdraw() public returns (uint32);

}


```

## Rationale
The standard proposes interfaces on top of the ERC-20 standard.
Each function should include constraint check logic.
In escrow-contract, should implemented internal constraint logic such as period, maximum investors, etc.
The buyer-contract and seller-contract should not have constraint rules.

Let's discuss the following functions.

1. **constructor**

An escrow contract will define success/failure conditions. It means constraint rules might not be changed forever (might be changed after being created for the market exchange rate.), so it guarantees escrow policy.

2. **escrowFund**

This function should run differently for buyers and sellers.

[Seller]
- The seller calls this function to be escrow-ready. Seller's token ownership(balance) will be transferred to escrow-contract and the escrow balance will be (Seller: amount, Buyer: 0).
- The seller can call this function multiple times depending on implementation, but preferred just one time.

[Buyer]
- When escrow is running (not successful or failed), the buyer can call this function to deposit funds into the escrow account.
- The escrow balance will be (Seller: amount x exchange-rate, Buyer: amount). The Buyer: the amount will be used for the refund process.
- Once it is a success, the seller's escrow balance will be (Seller: -= amount x exchange-rate, Buyer: += amount).

3. **escrowRefund**

This function should be invoked by buyers only.
The buyer can call this function in the running state only. In the state of failure or success, could not be a success.
The escrow balances of seller and buyer will be updated reverse way of `escrowFund`


4. **escrowWithdraw**

Buyers and sellers can withdraw tokens from the escrow account to their own account.
The following processes are recommended.
- Buyer can withdraw in escrow-success state only. Ownership of seller tokens can be transferred to the buyer from escrow-contract. In an escrow-failed state, the buyer should call `escrowRefund` function.
- When the seller calls this function in the escrow-success state, remained seller token will be transferred to the seller, and earned buyer's token will be also transferred from escrow-account.
- In the case of escrow-failed, the seller only gets a refund seller token.

## Backwards Compatibility
By design ERC-5503 is fully backward compatible with ERC-20.

## Test Cases
1. [Seller/Buyer Token example](../assets/eip-5503/ERC20Mockup.sol).
2. [Escrow contract example](../assets/eip-5503/EscrowContractAccount.sol).
3. [Unit test example with truffle](../assets/eip-5503/truffule-test.js).

The above 3 files demonstrate following conditions to exchange seller / buyer tokens.
 - exchange rate is 1:1
 - If number of buyer reached 2, escrow process will be terminated(success).

## Security Considerations
Since the external contract(Escrow Contract) will control seller or buyer rights, flaws within the escrow contract directly lead to the standard’s unexpected behavior.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
