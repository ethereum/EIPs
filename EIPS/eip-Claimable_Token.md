---
eip: <to be assigned>
title: Claimable Token Standard
author: Wansheng Li huhulws@gmail.com
status: Draft
type: Standards Track
category: ERC
created: 2020-8-10
requires: 20
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This standard defines a token which can be claimed on Ethereum by verifying the payer's signature.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
In some scenarios, like metering internet service traffic or counting paid e-mail messages, small but frequent payments are needed. If we use ETH or token transfer to make those payments, the sum gas cost will be enormous, besides Ethereum probably won't hold high TPS.

This standard allows payer to establish micropayment channel with service provider. When using service, payer should sign messages that specify how much token is owned to the provider through micropayment channel. The provider collects and checks those messages to decide if the payer is honest with owned amount. If the provider thinks it gets insufficient token, it can stop providing service to this payer.

At anytime, the service provider can claim the right amount of token on Ethereum providing the last signed message it accepts.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
There are two motivations for this standard, one is to reduce Ethereum gas costs, the other is to link Ethereum to real-world payment problem: pay for usage.

Assume we are provider of a paid API and we want to charge the user every time he/she calls this API. Traditionally we let user sign agreement of small automatic payment and charges the user right after(or before) he/she uses the service. When the user encounter a payment problem, such as he/she thinks we charged too many times, he/she can contact with us and argue about the API call history.

But if we want to use Etherum as payment platform, there are two problems to be solved. One is we can't let user transfer token to us every time he uses service, the gas cost is too much and the payment is delayed for Ethereum has to confirm the transaction. The other problem is our service may be decentralized and it's hard for user to contract us. So, we provide this standard with those feature:

1. Any number of continuous payments can be claimed using just one transaction on Ethereum smart contract.
2. The user will get just enough service corresponding to the token he spent (no double spend problem).
3. The provider only accepts the signed payment messages as long as he/she thinks user can afford, and those messages are guaranteed to be successfully claimed and just be claimed once.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

```solidity
interface IStamp is IERC20{

    function iconUrl() external view returns (string memory);
    function issuer() external view returns (address);
    function transferIssuer(address newIssuer) external;
    function active(uint256 amount) external;
    function activeBalanceOf(address user) external view returns(uint256 balance, uint256 activedSum, uint256 epoch);
    function claim(address from, uint256 credit, uint256 epoch, bytes calldata signature) external;

    event Active(
        address indexed from,
        uint256 amount
    );

    event TransferIssuer(
        address indexed oldIssuer,
        address indexed newIssuer
    );

    event Claim(
        address indexed from,
        address indexed to,
        uint256 epoch,
        uint256 credit
    );
}
```

### Functions

#### iconUrl

Returns the image url of this token

#### issuer

Returns the issuer of this token. Only issuer can claim token and is the only beneficiary.

#### transferIssuer

Transfer issuer role by changing its address.

| Parameter | Description |
| ---------|-------------|
| newIssuer | The new issuer address |

#### active

User can make part of token balance 'active' as deposit to ensure micropayments. Token can only be claimed form active balance. This works likes 'increaseAllowance' in ERC20 with additional check on amount of active balance should be less equal than token balance.

| Parameter | Description |
| ---------|-------------|
| amount | amount to active |

#### activeBalanceOf

Returns balance, active balance and epoch of user account. The epoch is an increasing number which is added by one when account get claimed. Epoch is a part of sign data, verified by both user and provider, prevents double spend and double claim.

| Parameter | Description |
| ---------|-------------|
| user | user account address |

#### claim

Service provider (account of issuer) sends micropayment message data params to this function, and recover unsigned message. Then this function checks the message with it's signature (probably using  built-in function 'ecrecover'). If the signature is successfully verified, provider get corresponding token, and user active balance reduce the same ammount. Epoch increase by 1

| Parameter | Description |
| ---------|-------------|
| from | which user account to be claimed |
| credit | how many token should be claimed |
| epoch | current epoch number |
| signature| micropayment message signature signed by user|


### Events

#### Active

Event emits when user calls active function

| Parameter | Description |
| ---------|-------------|
| from | indexed msg.sender |
| amount | amount to be active|

#### TransferIssuer

Event emits when transferIssuer is called

| Parameter | Description |
| ---------|-------------|
| oldIssuer | old issuer/beneficiary |
| newIssuer | new issuer/beneficiary |

#### Claim

Event emits when claim is called

| Parameter | Description |
| ---------|-------------|
| from | user account to be claimed |
| to | msg.sender, the issuer |
| epoch | which epoch is based on |
| credit | how many token be claimed |

## Rationale
This standards provides a way for user and service provider to establish micropayment channel to make free and repaid payment messages off blockchain. Those payment messages are linked one by one, providing a trace of service consumption and keeps an increasing number of credit, which is how much the payer owned to the service provider.

The service provider can stop serving when payer no longer send new payment message or the payment message describes smaller credit than provider think it should be. In this case, the user can either change provider (assuming provider is dishonest) or accept the make up for the loss in next micropayment message.

The Service can claim token on Ethereum at later time using the data of the largest (probably the latest) signed micropayment message.

## Backwards Compatibility
This EIP is fully backwards compatible as its implementation extends the functionality of [ERC-20].

## Implementation
The GitHub repository [Bmail_Token](https://github.com/realbmail/Bmail_token) contains the work in progress implementation.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[ERC-20]: https://eips.ethereum.org/EIPS/eip-20
