---
title: Tokenized Reserve
description: Reservses with user auditing
author: Jimmy Debe (@jimstir)
discussions-to: 
status: Draft
type: Standards Track
category: EIP
created: 2023-06-30
requires: ERC4626, ERC20
---

## Abstract

A proposal for a tokenized reserve mechanism. The reserve allows an audit of on-chain actions of the owner. Using ERC4626, stakeholders can create shares to show support for actions in the reserve.

## Motivation

Tokenized reserves are an extension of tokenized vaults. The goal is to create a reserve similar to a real world reserve an entity has as a backup incase regular funds run low. In the real world, an entity will have certain criteria to access reserve funds. In a decentralized environment, an entity can incorporate stakeholders into their criteria. Hopefully this will help entities who participate in decentralized environments to be more transparent with stakeholders.

## Specification

### Definitions:

	- owner: The creator of the reserve.
	- user: Stakeholders of specific proposals
	- reserve: The tokenized reserve contract
	- proposal: Occurs when the owner wants a withdrawal from contract
 
### Constructor:
 
 	- name: ERC20 token name
  	- ticker: ERC20 ticker
   	- asset: ERC4626 underlying ERC20 address
	- rAuth: Primary authorized user
	- rOwner: Owner of the Reserve
 
### Interface

   ```solidity
interface TokenReserve{
// @dev proposals event
event proposals(
	address indexed token,
	uint256 indexed proposalNum,
	uint256 indexed amount,
	address recipient
 );
/// @dev owner deposit event
event depositR(
	address indexed token,
	uint256 indexed amount,
	uint256 indexed time,
	uint256 count
 );
/** @dev Owner accounting struct
* @param time Deposit time
* @param token Address of ERC20 token
* @param deposit Amount of owner deposit
*/
struct ownerAccount{
 	uint256 time;
 	address token;
 	uint256 deposit;
 }
/** @dev User accounting struct
* @param proposal Specific participating proposal number
* @param deposit Amount user deposited
* @param withdrew Amount of user withdrew
*/
 struct userAccount{
	uint256 proposal;
	uint256 deposit;
	uint256 withdrew;
 }
/** @dev Proposal accounting struct
* @param token Address of ERC20 token
* @param withdrew Amount withdrawn
* @param received Amount received
*/
 struct proposalAccount{
	address token;
	uint256 withdrew;
	uint256 received;
 }
/**
* @dev Make a deposit to proposal creating new shares
* - MUST be open proposal
* - MUST NOT be closed proposal
* NOTE: using the deposit() will cause shares to not be accounted for in a proposal
* @param assets amount being deposited
* @param receiver address of depositor
* @param proposal number associated proposal
*/
function proposalDeposit(uint256 assets, address receiver, uint256 proposal) external virtual returns (uint256);
/**
* @dev Make a deposit to proposal creating new shares
* - MUST account for proposalNumber
* - MUST have proposalNumber
* NOTE: using the mint() will cause shares to not be accounted for in a proposal
* @param shares amount being deposited
* @param receiver address of depositor
* @param proposal number associated proposal
*/
function proposalMint(uint256 shares, address receiver, uint256 proposal) external virtual returns(uint256);
/**
* @dev Burn shares, receive 1 to 1 value of assets
* - MUST have closed proposalNumber
* - MUST NOT be userWithdrew amount greater than userDeposit amount
*/
function proposalWithdraw(uint256 assets, address receiver, address owner, uint256 proposal)external virtual returns(uint256);
/**
* @dev Burn shares, receive 1 to 1 value of assets
* - MUST have open proposal number
* - MUST have user deposit greater than or equal to user withdrawal
* NOTE: using ERC 4626 redeem() will not account for proposalWithdrawal
*/
function proposalRedeem(uint256 shares, address receiver, address owner, uint256 proposal) external virtual returns(uint256);
/**
* @dev Issue new proposal
* - MUST create new proposal number
* - MUST account for amount withdrawn 
* @param token address of ERC20 token
* @param amount token amount being withdrawn
* @param receiver address of token recipient
*/
function proposalOpen(address token, uint256 amount, address receiver) external virtual returns (uint256);
/**
* @dev Close an opened proposal
 * - MUST account for amount received
 * - MUST proposal must be greater than current proposal
 * @param token address of ERC20 token
 * @param proposal number of desired proposal to close
 * @param amount number assets being received
 */
 function proposalClose(address token, uint256 proposal, uint256 amount) external virtual returns (bool);
/**
* @dev Optional accounting for tokens deposited by owner
 * - MUST be contract owner
 * NOTE: No shares are issued, funds can not be redeemed. Only withdrawn from proposalOpen
 * @param token address of ERC20 token
 * @param sender address of where tokens from
 * @param amount number of assets being deposited
 */
 function depositReserve(address token, address sender, uint256 amount) external virtual;

}
```				

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

The reserve is designed to be a basic implementation of the reserve interface. Other non specified conditions should be addressed on case by case instances. Reserves use ERC20 for shares and ERC4626 for creations of shares within proposals. All accounting measures are designed to enforce audit practices based on use case. 

## Backwards Compatibility

Tokenized reserves are made compatible with ERC20 and ERC4626.


## Reference Implementation

A reference implementation is located [here](https://github.com/jimstir/Reserve-Vault).

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
