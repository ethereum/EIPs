---
title: Partial Gas Sponsorship Interface
description: Defining an interface that dApps can use to sponsor a portion of the gas fees required for user operations
author: Lyu Min (@rockmin216), Wu Jinzhou (@wujinzhou), Elwin Chua (@jingkang0822), Lucas Lim (@limyeechern)
discussions-to: https://ethereum-magicians.org/t/igassponsor-partial-gas-sponsorship-interface/21145
status: Draft
type: Standards Track
category: Interface
created: 2024-09-19 
requires: 4337
---

## Abstract
This proposal defines the necessary interface that decentralized applications (dApps) must implement to sponsor a portion of the required gas for user operations utilizing a Paymaster that supports this standard. The proposal also provides a suggested code implementation that Paymasters can include in their current implementation to support dApp sponsorship. Partial sponsorship between more than one dApps may also be achieved through this proposal.

## Motivation
This proposal introduces a standard that enables dApps to sponsor a portion of these transaction fees on behalf of users. Currently, TokenPaymasters allow users to pay gas fees using ERC-20 tokens instead of blockchain's native token. However, this approach does not equate to TokenPaymasters directly sponsoring the transaction fees, as users still bear the cost when the ERC-20 token is transferred to TokenPaymaster. 

Similarly, with a Free-Gas Paymaster, the cost of the entire UserOperation is borne by the Paymaster, and therefore may not be willing to sponsor some transaction. With this proposal, dApps can sponsor a portion of the transaction fees and therefore, by reducing the cost of interacting with dApps, this standard incentivizes increased user activity and attracts more users to the dApp.

From the user's perspective, this reduction in transaction costs encourages greater participation in the blockchain ecosystem, as interacting with dApps becomes more affordable. Additionally, with IGasSponsor, partial sponsorship can be achieved when a UserOperation involves multiple dApps that implement IGasSponsor within a single transaction, further enhancing the user experience.

## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Contract Interface
This interface is designed to be implemented by dApps that want to manage their gas funds internally and allow Paymasters to claim gas costs in a standardised way.

``` solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IGasSponsor {
    function authoriseGas(bytes calldata data) external;
    
    function sponsorGas(uint256 amount) external;
}
```
Interface: IGasSponsor
- Purpose: To be implemented by dApps to manage gas funds internally.
- Function: `sponsorGas`
  - Role: Allows the Paymaster to claim gas funds from the dApp's contract.
  - Parameters: 
    - `uint256 amount`: The amount of gas to be sponsored.
  - Visibility: External
  - Usage: This function is called by the Paymaster during the post-operation (`postOp`) stage to claim the gas spent on the corresponding User Operation.
- Function: `AuthoriseGas`
  - Role: Allows the Paymaster to invoke this function in the dApp's contract during validation phase as an alternative pathway to approve the amount of gas willing to be sponsored. This function can be used when additional sponsors are not part of the execution phase but still wish to sponsor the transaction.
  - Parameters: 
    - `bytes calldata data`: Additional data that can be passed to the dApp to help the dApp determine the amount of gas it is willing to sponsor.
  - Visibility: External
  - Usage: This function is called by the Paymaster during the validatePaymasterUserOp stage to set the gas that the dApp is willing to sponsor for the User Operation.

### DApp Example
```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./interfaces/IGasSponsor.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Dapp is IGasSponsor {

    constructor(....) {
        ....
    }

    function swap(....) public {
        
        ....
        
        bytes32 userAccount = bytes32(bytes20(msg.sender));
        assembly {
            tstore(userAccount, 1000000000000000)
        }
    }
    
    function authoriseGas(
        bytes calldata data
    ) external override {
        try {
            // Any custom logic to decode the data
            (
                address someAddress,
                bytes memory someData,
                bytes memory someOtherData
            ) = abi.decode(data, (address, bytes, bytes));
            
            if (...) {
                assembly {
                    tstore(msg.sender, 1000000000000000)
                }
            }
        } catch {
            // Handle the case where data doesn't conform to the expected format
            // Leave blank to not authorise any amount
        }    
    }

    function sponsorGas(
        uint256 amount
    ) external override {
        uint256 allowance;
        assembly {
            allowance := tload(msg.sender)
            tstore(msg.sender, 0) // Reset the value to zero to prevent attacks
        }
        payable(msg.sender).transfer(Math.min(allowance, amount));
    }
}
```

### TokenPaymaster Example
The following is an example with TokenPaymaster. The highlighted portion SHOULD be included in the postOp regardless of the type of Paymaster.

```solidity
function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {

        (
            uint48 validUntil,
            uint48 validAfter,
            bytes calldata signature
            bytes calldata sponsors
        ) = parsePaymasterAndData(userOp.paymasterAndData);
        
        ...
                 
        // Iterate over the sponsors to collect gas
        for (uint256 i = 0; i < sponsors.length; i += 20) {
            address gasSponsor = address(bytes20(sponsors[i:i + 20]));

            try IGasSponsor(gasSponsor).authoriseGas(userOp.paymasterAndData) {
                emit GasAuthorised(gasSponsor);
            } catch (bytes memory reason) {
                // Log the error reason
                emit GasAuthorisedError(gasSponsor, reason);
            }
        }
        
        ...     
        // Set the first 20 bytes of context to the sender address     
        address sender = userOp.sender;     
        assembly {         
            mstore(add(context, 0x20), sender) // Store sender at the beginning of the context (first 20 bytes)     
        }
        
        // Copy sponsors into context starting at byte 20     
        for (uint256 i = 0; i < sponsors.length; i++) {
            context[20 + i] = sponsors[i];     
        }
    }


function _postOp(
    PostOpMode mode, 
    bytes calldata context, 
    uint256 actualGasCost, 
    uint256 actualUserOpFeePerGas
    ) internal override {
    
    unchecked {
        uint256 priceMarkup = tokenPaymasterConfig.priceMarkup;
        (
            uint256 preCharge,
            address userOpSender
            bytes memory ... //TODO
        ) = abi.decode(context, (uint256, address));
        uint256 _cachedPrice = updateCachedPrice(false);
        // note: as price is in native-asset-per-token and we want more tokens increasing it means dividing it by markup
        uint256 cachedPriceWithMarkup = _cachedPrice * PRICE_DENOMINATOR / priceMarkup;
        
        uint256 gasCollected;
        address sender = address(bytes20(context[:20]));
        bytes calldata sponsors = context[72:];
         // Iterate over the sponsors to collect gas
        for (uint256 i = 0; i < sponsors.length; i += 20) {
            address gasSponsor = address(bytes20(sponsors[i:i + 20]));
            uint256 balanceBeforeClaim = address(this).balance;

            try IGasSponsor(gasSponsor).sponsorGas(type(uint256).max) {
                uint256 balanceAfterClaim = address(this).balance;
                uint256 gasClaimed = balanceAfterClaim - balanceBeforeClaim;
                gasCollected += gasClaimed;

                emit GasClaimed(gasSponsor, gasClaimed);
            } catch (bytes memory reason) {
                // Log the error reason
                emit GasClaimedError(gasSponsor, reason);
            }
        }
        
        // Refund tokens based on actual gas cost
        uint256 actualChargeNative = actualGasCost - gasCollected + tokenPaymasterConfig.refundPostopCost * actualUserOpFeePerGas;
        
        uint256 actualTokenNeeded = weiToToken(actualChargeNative, cachedPriceWithMarkup);
        if (preCharge > actualTokenNeeded) {
            // If the initially provided token amount is greater than the actual amount needed, refund the difference
            SafeERC20.safeTransfer(
                token,
                userOpSender,
                preCharge - actualTokenNeeded
            );
        } else if (preCharge < actualTokenNeeded) {
            // Attempt to cover Paymaster's gas expenses by withdrawing the 'overdraft' from the client
            // If the transfer reverts also revert the 'postOp' to remove the incentive to cheat
            SafeERC20.safeTransferFrom(
                token,
                userOpSender,
                address(this),
                actualTokenNeeded - preCharge
            );
        }

        emit UserOperationSponsored(userOpSender, actualTokenNeeded, actualGasCost, cachedPriceWithMarkup);
        refillEntryPointDeposit(_cachedPrice);
    }
}
```
![alt text](image.png)

## Rationale
This design allows the dApp to have full control over the maximum amount of gas it wishes to sponsor. By leveraging the transient storage opcode (`tstore`), the dApp can determine and set the amount of gas it will sponsor for a given user operation.

### Paymaster behavior
During `validatePaymasterUserOp`, the Paymaster will iterate through the list of sponsors and call the authoriseGas function implemented by the dApp. The main purpose of this is for dApps that are not involved in the execution phase to also be able to set in the transient storage a specified amount they wish to sponsor.

During the `postOp` phase, the Paymaster can iterate through the list of sponsors and call the `sponsorGas` function implemented by the dApp. The dApp then retrieves the sponsored amount from transient storage and transfers it to the Paymaster.

In the above TokenPaymaster example, when the TokenPaymaster refunds the excess token after calculating `actualChargeNative`, it may deduct the `gasCollected` amount that was collected from the sponsors. Therefore, it will refund a greater amount to the user, essentially allowing the dApp to sponsor the transaction.

### DApp behavior
The dApp has the flexibility to decide when and how much to sponsor for the transaction. This can be done by implementing more complex logic in the code to store the amount using `tstore`.

When the `authoriseGas` function is invoked, the dApp can choose to store the amount they wish to sponsor using `tstore`. If the dApp wishes to only determine the amount to sponsor during execution phase, the dApp can choose to omit the logic in this function.

When the `sponsorGas` function is invoked, the dApp can transfer either the maximum amount it wishes to sponsor or the amount that the Paymaster requested, whichever is lower. 

### Transient Storage
Since all of this occurs within a single atomic transaction, the transient storage memory is not cleared until the transaction is completed, eliminating the need to re-validate `msg.sender` during `postOp`. If a specified amount is stored in transient storage but not transferred out, the storage will be cleared at the end of the transaction, ensuring that the dApp will not sponsor that particular amount.

### Fallback
#### Insufficient dApp funds
If the dApp has insufficient funds, the try catch block will fail, and therefore the dApp will not be able to sponsor a portion of the transaction. However, this does not affect transaction execution as the paymaster would have committed to pay for the transaction. 

## Backwards Compatibility
### Existing paymaster upgrades
Existing Paymaster contracts can be modified to support this form of gas collection from dApps. Dapps should also implement allowance setting and sponsorGas function within their existing contract.



## Reference Implementation
TBD

## Security Considerations
### SponsorGas
The security risk in exposing `sponsorGas` function is minimal but not zero, because it relies on transient storage to determine the amount sent to `msg.sender`. Even if a malicious actor attempts to invoke the `sponsorGas` function, the amount transferred from the dApp to `msg.sender` will be zero, as the `tload` operation will return zero if the corresponding key was not set earlier in the same atomic transaction. Since the dApp has full control over the amount stored using `tstore`, it can effectively protect itself from attacks, provided the logic for storing the amount is correctly implemented.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).