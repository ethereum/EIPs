---
eip: 2871
title: Exclusive Claimable Token
author: Zhenyu Sun (@Ungigdu)
discussions-to: https://github.com/ethereum/EIPs/issues/3132
status: Draft
type: Standards Track
category: ERC
created: 2020-8-10
requires: 20
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This standard defines a token which can be claimed only by token issuer with payer's signature.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

When monitoring network traffic, counting paid e-mail messages or buy merchandise in general store, small but frequent payments are needed. We can't directly transfer tokens on chain to make payment because the sum gas cost is big and it takes time for blockchain to reach a consensus. 

This standard allows service provider to establish micropayment channels with many users by creating claimable token. A user gets claimable token and can make part of balance "active" as deposit to this channel. When using service, user should sign messages off chain to service provider and provider checks if user is honest with accumulating amount in message and checks if this amount is less than active balance. If check passed, provider continue to serve user, otherwise reject. 

At anytime, the service provider can claim the right amount of token on chain providing the last signed message it accepts and this claim function can only be called by issuer to avoid double spending.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
There are two motivations for this standard, one is to reduce gas costs, the other is to link Ethereum to real-world payment problem: pay for usage.

This token standard is useful in basically two types of businesses: 1. Real-world merchant (whose identity is known by user) can use this token as recharge card; 2. Online service provider (whose identity may not be known by user or is hard to reach) can use this token to build an automatic micropayment channel. In both cases, the token is the representation of provider's service/products, and should only be claimed by provider's "issuer" account.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

```solidity
interface IStamp is IERC20{

    function iconUrl() external view returns (string memory);
    function issuer() external view returns (address);
    function claim(address from, uint256 credit, uint256 epoch, bytes calldata signature) external;
    function transferIssuer(address newIssuer) external;
    function active(uint256 amount) external;
    function deactive(address to, uint256 amount) external;
    function activeBalanceOf(address user) external view returns(uint256 balance, uint256 activedSum, uint256 epoch);

    event Active(
        address indexed from,
        uint256 amount
    );

    event Deactive(
        address indexed to,
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

Returns the image url of this token or descriptive resources

#### issuer

Returns the issuer of this token. Only issuer can claim token so there is no generally double spending problems.

#### transferIssuer

Transfer issuer role by changing its address.

| Parameter | Description |
| ---------|-------------|
| newIssuer | The new issuer address |

#### active

User can make part of token balance 'active' as deposit to ensure micropayments. Token can only be claimed from active balance. This works likes 'increaseAllowance', except the active amount is removed from user's balance.

| Parameter | Description |
| ---------|-------------|
| amount | amount to active |

#### deactive

This function should have different implementation based on business model. For real-world businesses, such as recharge card of general store or membership card of fitness center, deactive should be called by merchant, act as refund function to return active balance to user's balance; for online businesses, user may found it hard to contact with service provider, so the deactive is called by user itself, with limitations such as epoch number didn't change for some period of time. Also gets token in active balance back.

| Parameter | Description |
| ---------|-------------|
| to | the account to perform deactive on |
| amount | amount to active |

#### activeBalanceOf

Returns balance, active balance and epoch of user account. The epoch is an increasing number which is added by one when account get claimed or deactive. Epoch is a part of sign data, verified by both user and provider, prevents double spend and double claim.

| Parameter | Description |
| ---------|-------------|
| user | user account address |

#### claim

Service provider (account of issuer) recovers unsigned message, then checks the message with it's signature (probably using built-in function 'ecrecover'). If the signature is successfully verified, provider get "credit" amount token from user's active balance and epoch is increased by 1. It is worth mentioning that the provider may not need to get token back because this token is basically created by this provider and holds no value to itself. In that case, the claim function can release some other more valuable token to provider. 

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

#### Deactive

| Parameter | Description |
| ---------|-------------|
| to | indexed account to deactive on |
| amount | amount to deactive|

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

The provider can stop serving when payer no longer send new valid payment message or the credit is bigger than active balance. The user can stop signing new message if provider is not available or is cheating. The provider can claim token on chain at any time using the message contains the largest credit number.

Let's explain the usage of exclusive claimable token by two cases.

### 1. Token as recharge card of general store

Like ordinary recharge card, the user pays with money/cryptocurrency to store in advance for a recharge card (with bonus or discount). Then user "activate recharge card" by calling active function. When checking out, the user just sign a message with updated credit (old credit + consumption this time) to store server. Server then verify this message and check the credit off chain. Then the shopping process goes on and on with out any blockchain involved. Until the user want to fund money. The shopping service should first make claim call to remove all credit from active balance, then call deactive function to return remaining token to user. Finally the user should transfer all token back to store to get money back, which is not a part of this discussion. The advantages are as follows:

- Token as card point can transfer between users freely
- The functions are built in token contract so the interacts with blockchain can be minimal for both parties
- The modification work from ordinary card system to token as card system is much less

### 2. Token as counter of online service

Assume we have a distributed VPN service which user pays by token. Unlike general store case, users and servers do not know each other and don't trust each other.  So there is two ways to implement claimable token based on the value of this token. If this token is widely accepted and holds value, token itself will serve as currency to buy service; if this token is just created on demand and is nothing more than number, this token will serve as a contract which user can deposit other token to. When using VPN service, the user active some token, and establish a counter channel with VPN service miner. For each x MB network traffic, the user signs a message to service miner, miner checks credit and user's active balance (this check can be done by pool rather than single miner) and decides to serve or not. This checking/serving process is in parallel. Because user can't trust VPN server, the deactive function must be called by user. To make sure user can't just use service and deactive balance back before server claims, some checks are needed, for example, user can only deactive token when epoch is not increased in a month. So, the server should claim at least monthly. The advantages are as follows:

- Token is equal to service, and can be transferred
- Token can act as stock of other valuable token
- Token consumes only when server servers, no trust needed
- Interaction with blockchain is minimal

## Backwards Compatibility
This EIP is fully backwards compatible as its implementation extends the functionality of [ERC-20].

## Implementation
The GitHub repository [Bmail_Token](https://github.com/realbmail/Bmail_token) contains the work in progress implementation.

## Security Considerations
There are many options to implement this token, leaving room for bugs and malicious codes. It's better to introduce factory contracts to create boilerplate claimable token.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).