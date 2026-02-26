---
eip: 3156
title: Flash Loans
author: Alberto Cuesta Cañada (@alcueca), Fiona Kobayashi (@fifikobayashi), fubuloubu (@fubuloubu), Austin Williams (@onewayfunction)
discussions-to: https://ethereum-magicians.org/t/erc-3156-flash-loans-review-discussion/5077
status: Final
type: Standards Track
category: ERC
created: 2020-11-15
---

## Simple Summary

This ERC provides standard interfaces and processes for single-asset flash loans.

## Abstract

A flash loan is a smart contract transaction in which a lender smart contract lends assets to a borrower smart contract with the condition that the assets are returned, plus an optional fee, before the end of the transaction. This ERC specifies interfaces for lenders to accept flash loan requests, and for borrowers to take temporary control of the transaction within the lender execution. The process for the safe execution of flash loans is also specified.

## Motivation

Flash loans allow smart contracts to lend an amount of tokens without a requirement for collateral, with the condition that they must be returned within the same transaction.

Early adopters of the flash loan pattern have produced different interfaces and different use patterns. The diversification is expected to intensify, and with it the technical debt required to integrate with diverse flash lending patterns.

Some of the high level differences in the approaches across the protocols include:
- Repayment approaches at the end of the transaction, where some pull the principal plus the fee from the loan receiver, and others where the loan receiver needs to manually return the principal and the fee to the lender.
- Some lenders offer the ability to repay the loan using a token that is different to what was originally borrowed, which can reduce the overall complexity of the flash transaction and gas fees.
- Some lenders offer a single entry point into the protocol regardless of whether you're buying, selling, depositing or chaining them together as a flash loan, whereas other protocols offer discrete entry points.
- Some lenders allow to flash mint any amount of their native token without charging a fee, effectively allowing flash loans bounded by computational constraints instead of asset ownership constraints.

## Specification

A flash lending feature integrates two smart contracts using a callback pattern. These are called the LENDER and the RECEIVER in this EIP.

### Lender Specification

A `lender` MUST implement the IERC3156FlashLender interface.
```
pragma solidity ^0.7.0 || ^0.8.0;
import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}
```

The `maxFlashLoan` function MUST return the maximum loan possible for `token`. If a `token` is not currently supported `maxFlashLoan` MUST return 0, instead of reverting.

The `flashFee` function MUST return the fee charged for a loan of `amount` `token`. If the token is not supported `flashFee` MUST revert.

The `flashLoan` function MUST include a callback to the `onFlashLoan` function in a `IERC3156FlashBorrower` contract.

```
function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
) external returns (bool) {
  ...
  require(
      receiver.onFlashLoan(msg.sender, token, amount, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan"),
      "IERC3156: Callback failed"
  );
  ...
}
```

The `flashLoan` function MUST transfer `amount` of `token` to `receiver` before the callback to the receiver.

The `flashLoan` function MUST include `msg.sender` as the `initiator` to `onFlashLoan`.

The `flashLoan` function MUST NOT modify the `token`, `amount` and `data` parameter received, and MUST pass them on to `onFlashLoan`.

The `flashLoan` function MUST include a `fee` argument to `onFlashLoan` with the fee to pay for the loan on top of the principal, ensuring that `fee == flashFee(token, amount)`.

The `lender` MUST verify that the `onFlashLoan` callback returns the keccak256 hash of "ERC3156FlashBorrower.onFlashLoan".

After the callback, the `flashLoan` function MUST take the `amount + fee` `token` from the `receiver`, or revert if this is not successful.

If successful, `flashLoan` MUST return `true`.

### Receiver Specification

A `receiver` of flash loans MUST implement the IERC3156FlashBorrower interface:

```
pragma solidity ^0.7.0 || ^0.8.0;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}
```

For the transaction to not revert, `receiver` MUST approve `amount + fee` of `token` to be taken by `msg.sender` before the end of `onFlashLoan`.

If successful, `onFlashLoan` MUST return the keccak256 hash of "ERC3156FlashBorrower.onFlashLoan".

## Rationale

The interfaces described in this ERC have been chosen as to cover the known flash lending use cases, while allowing for safe and gas efficient implementations.

`flashFee` reverts on unsupported tokens, because returning a numerical value would be incorrect.

`flashLoan` has been chosen as a function name as descriptive enough, unlikely to clash with other functions in the lender, and including both the use cases in which the tokens lent are held or minted by the lender.

`receiver` is taken as a parameter to allow flexibility on the implementation of separate loan initiators and receivers.

Existing flash lenders all provide flash loans of several token types from the same contract. Providing a `token` parameter in both the `flashLoan` and `onFlashLoan` functions matches closely the observed functionality.

A `bytes calldata data` parameter is included for the caller to pass arbitrary information to the `receiver`, without impacting the utility of the `flashLoan` standard.

`onFlashLoan` has been chosen as a function name as descriptive enough, unlikely to clash with other functions in the `receiver`, and following the `onAction` naming pattern used as well in EIP-667.

A `initiator` will often be required in the `onFlashLoan` function, which the lender knows as `msg.sender`. An alternative implementation which would embed the `initiator` in the `data` parameter by the caller would require an additional mechanism for the receiver to verify its accuracy, and is not advisable.

The `amount` will be required in the `onFlashLoan` function, which the lender took as a parameter. An alternative implementation which would embed the `amount` in the `data` parameter by the caller would require an additional mechanism for the receiver to verify its accuracy, and is not advisable.

A `fee` will often be calculated in the `flashLoan` function, which the `receiver` must be aware of for repayment. Passing the `fee` as a parameter instead of appended to `data` is simple and effective.

The `amount + fee` are pulled from the `receiver` to allow the `lender` to implement other features that depend on using `transferFrom`, without having to lock them for the duration of a flash loan. An alternative implementation where the repayment is transferred to the `lender` is also possible, but would need all other features in the lender to be also based in using `transfer` instead of `transferFrom`. Given the lower complexity and prevalence of a "pull" architecture over a "push" architecture, "pull" was chosen.

## Backwards Compatibility

No backwards compatibility issues identified.

## Implementation

### Flash Borrower Reference Implementation

```
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";


contract FlashBorrower is IERC3156FlashBorrower {
    enum Action {NORMAL, OTHER}

    IERC3156FlashLender lender;

    constructor (
        IERC3156FlashLender lender_
    ) {
        lender = lender_;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns(bytes32) {
        require(
            msg.sender == address(lender),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: Untrusted loan initiator"
        );
        (Action action) = abi.decode(data, (Action));
        if (action == Action.NORMAL) {
            // do one thing
        } else if (action == Action.OTHER) {
            // do another
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @dev Initiate a flash loan
    function flashBorrow(
        address token,
        uint256 amount
    ) public {
        bytes memory data = abi.encode(Action.NORMAL);
        uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
        lender.flashLoan(this, token, amount, data);
    }
}
```

### Flash Mint Reference Implementation

```
pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";


/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash minting.
 */
contract FlashMinter is ERC20, IERC3156FlashLender {

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public fee; //  1 == 0.01 %.

    /**
     * @param fee_ The percentage of the loan `amount` that needs to be repaid, in addition to `amount`.
     */
    constructor (
        string memory name,
        string memory symbol,
        uint256 fee_
    ) ERC20(name, symbol) {
        fee = fee_;
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        return type(uint256).max - totalSupply();
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency. Must match the address of this contract.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view override returns (uint256) {
        require(
            token == address(this),
            "FlashMinter: Unsupported currency"
        );
        return _flashFee(token, amount);
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must match the address of this contract.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool){
        require(
            token == address(this),
            "FlashMinter: Unsupported currency"
        );
        uint256 fee = _flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            "FlashMinter: Callback failed"
        );
        uint256 _allowance = allowance(address(receiver), address(this));
        require(
            _allowance >= (amount + fee),
            "FlashMinter: Repay not approved"
        );
        _approve(address(receiver), address(this), _allowance - (amount + fee));
        _burn(address(receiver), amount + fee);
        return true;
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        return amount * fee / 10000;
    }
}
```

### Flash Loan Reference Implementation

```
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";


/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash lending.
 */
contract FlashLender is IERC3156FlashLender {

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    mapping(address => bool) public supportedTokens;
    uint256 public fee; //  1 == 0.01 %.


    /**
     * @param supportedTokens_ Token contracts supported for flash lending.
     * @param fee_ The percentage of the loan `amount` that needs to be repaid, in addition to `amount`.
     */
    constructor(
        address[] memory supportedTokens_,
        uint256 fee_
    ) {
        for (uint256 i = 0; i < supportedTokens_.length; i++) {
            supportedTokens[supportedTokens_[i]] = true;
        }
        fee = fee_;
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns(bool) {
        require(
            supportedTokens[token],
            "FlashLender: Unsupported currency"
        );
        uint256 fee = _flashFee(token, amount);
        require(
            IERC20(token).transfer(address(receiver), amount),
            "FlashLender: Transfer failed"
        );
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            "FlashLender: Callback failed"
        );
        require(
            IERC20(token).transferFrom(address(receiver), address(this), amount + fee),
            "FlashLender: Repay failed"
        );
        return true;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view override returns (uint256) {
        require(
            supportedTokens[token],
            "FlashLender: Unsupported currency"
        );
        return _flashFee(token, amount);
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        return amount * fee / 10000;
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        return supportedTokens[token] ? IERC20(token).balanceOf(address(this)) : 0;
    }
}

```

## Security Considerations


### Verification of callback arguments

The arguments of `onFlashLoan` are expected to reflect the conditions of the flash loan, but cannot be trusted unconditionally. They can be divided in two groups, that require different checks before they can be trusted to be genuine.

0. No arguments can be assumed to be genuine without some kind of verification. `initiator`, `token` and `amount` refer to a past transaction that might not have happened if the caller of `onFlashLoan` decides to lie. `fee` might be false or calculated incorrectly. `data` might have been manipulated by the caller.
1. To trust that the value of `initiator`, `token`, `amount` and `fee` are genuine a reasonable pattern is to verify that the `onFlashLoan` caller is in a whitelist of verified flash lenders. Since often the caller of `flashLoan` will also be receiving the `onFlashLoan` callback this will be trivial. In all other cases flash lenders will need to be approved if the arguments in `onFlashLoan` are to be trusted.
2. To trust that the value of `data` is genuine, in addition to the check in point 1, it is recommended to verify that the `initiator` belongs to a group of trusted addresses. Trusting the `lender` and the `initiator` is enough to trust that the contents of `data` are genuine.

### Flash lending security considerations

#### Automatic approvals
The safest approach is to implement an approval for `amount+fee` before the `flashLoan` is executed.    

Any `receiver` that keeps an approval for a given `lender` needs to include in `onFlashLoan` a mechanism to verify that the initiator is trusted.

Any `receiver` that includes in `onFlashLoan` the approval for the `lender` to take the `amount + fee` needs to be combined with a mechanism to verify that the initiator is trusted.

If an unsuspecting contract with a non-reverting fallback function, or an EOA, would approve a `lender` implementing ERC3156, and not immediately use the approval, and if the `lender` would not verify the return value of `onFlashLoan`, then the unsuspecting contract or EOA could be drained of funds up to their allowance or balance limit. This would be executed by an `initiator` calling `flashLoan` on the victim. The flash loan would be executed and repaid, plus any fees, which would be accumulated by the `lender`. For this reason, it is important that the `lender` implements the specification in full and reverts if `onFlashLoan` doesn't return the keccak256 hash for "ERC3156FlashBorrower.onFlashLoan".

### Flash minting external security considerations

The typical quantum of tokens involved in flash mint transactions will give rise to new innovative attack vectors.

#### Example 1 - interest rate attack
If there exists a lending protocol that offers stable interests rates, but it does not have floor/ceiling rate limits and it does not rebalance the fixed rate based on flash-induced liquidity changes, then it could be susceptible to the following scenario:

FreeLoanAttack.sol
1. Flash mint 1 quintillion STAB
2. Deposit the 1 quintillion STAB + $1.5 million worth of ETH collateral
3. The quantum of your total deposit now pushes the stable interest rate down to 0.00001% stable interest rate
4. Borrow 1 million STAB on 0.00001% stable interest rate based on the 1.5M ETH collateral
5. Withdraw and burn the 1 quint STAB to close the original flash mint
6. You now have a 1 million STAB loan that is practically interest free for perpetuity ($0.10 / year in interest)

The key takeaway being the obvious need to implement a flat floor/ceiling rate limit and to rebalance the rate based on short term liquidity changes.

#### Example 2 - arithmetic overflow and underflow
If the flash mint provider does not place any limits on the amount of flash mintable tokens in a transaction, then anyone can flash mint 2^256-1 amount of tokens. 

The protocols on the receiving end of the flash mints will need to ensure their contracts can handle this, either by using a compiler that embeds overflow protection in the smart contract bytecode, or by setting explicit checks.

### Flash minting internal security considerations
    
The coupling of flash minting with business specific features in the same platform can easily lead to unintended consequences.

#### Example - Treasury draining
Assume a smart contract that flash lends its native token. The same smart contract borrows from a third party when users burn the native token. This pattern would be used to aggregate in the smart contract the collateralized debt of several users into a single account in the third party. The flash mint could be used to cause the lender to borrow to its limit, and then pushing interest rates in the underlying lender, liquidate the flash lender:
1. Flash mint from `lender` a very large amount of FOO.
2. Redeem FOO for BAR, causing `lender` to borrow from `underwriter` all the way to its borrowing limit.
3. Trigger a debt rate increase in `underwriter`, making `lender` undercollateralized.
4. Liquidate the `lender` for profit.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
