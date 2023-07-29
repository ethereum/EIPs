---
title: Tokenized Reserve
description: Proposed method to replicate a 
author: Jimmy Debe (@jimstir)
discussions-to: <URL>
status: Draft
type: <Standards Track, Meta, or Informational>
category: 
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
requires: ERC4626, ERC20
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

A proposal for a tokenized reserve mechanism. The reservse is allows an audit of on-chain actions of the owner of the reserve. Using ERC4626, stakeholders can create shares to show support for actions in the reserve.
<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

## Motivation

Tokenized reserves are an extension of tokenized vaults. The goal is to create a reserve similar to a reserve an entity creates in the real world as a backup when regualr funds run low. In the real world, an entity will have certain cretria to access reserve funds. In a decentraiized envirnoment, an entity can incorporate stakeholders into the cretria. Hopefully this will help enities that participate in decentrailzed envirnoments to traspanet for every stakeholder. 

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

### Definitions:
	- owner: The creator of the reserve.
	- user: Stakeholders of specific proposals
	- reserve: The tokenized reserve contract
	- proposal: Occurs when the owner wants a withdrawal from contract
``` solidity
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
    	* @dev Get the reserve owner
    	* 
    	*/
    	function whosOwner() external view returns (address);
	/**
    	* @dev Get the reserve primary authorized user
    	*/
    	function whosAuth() external view returns (address);
	/** @dev Check current total of opened proposals
    	* @return uint256
    	*/ 
    	function proposalCheck() external view returns (uint256);
	/**
    	* @dev Authorized users of the reserve
    	*/
    	function getAuth(address user) external view returns (bool);
	/** 
    	* @dev Get number of deposits made to reserve by the owner
    	* - MUST BE deposits made by calling depositReserve function
    	*/
    	function accountCheck() external view returns (uint256);
	/** 
    	* @dev Get time of a deposit made to reserve by the owner
    	* @param count Number matching deposit
    	* @return block.timestamp format
    	*/
    	function depositTime(uint256 count) external view returns (uint256);
	/** 
    	* @dev Get amount deposited to reserve by the owner 
    	* @param count Number of deposit
    	* @return uint256 number of any asset that were deposited
    	*/
    	function ownerDeposit(uint256 count) external view returns(uint256);
	/**
    	* @dev Token type deposited to contract by the owner
	* @param count Number of deposit
    	* - MUST be an address of ERC20 token
    	*/
    	function tokenDeposit(uint256 count) external view returns(address);
	/**
    	* @dev Amount deposited for share of proposal by the user
    	* - MUST be an ERC20 address
    	* @param user address of user
    	* @param proposal number of the proposal the user deposited
    	*/
    	function userDeposit(address user, uint256 proposal) external view returns(uint256);
	/**
    	* @dev Amount withdrawn from given proposal by the user
    	* @param user address of user
    	* @param proposal number of the proposal the user withdrew
    	*/
    	function userWithdrew(address user, uint256 proposal) external view returns(uint256);
	/**
    	* @dev The total number of proposals joined by the user
    	* @param user address of user
    	*/
    	function userNumOfProposal(address user) external view returns(uint256);
	/**
    	* @dev The proposal number from the specific proposal joined by the user
    	* @param user address of user
    	* @param proposal the number the user was apart of
    	* MUST NOT be zero
    	*/
    	function userProposal(address user, uint256 proposal) external view returns(uint256);
	/**
    	* @dev Token used for given proposal
    	* - MUST be ERC20 address
    	* @param proposal number for requested token
    	* @return token address
    	*/
    	function proposalToken(uint256 proposal) external view returns(address);
	/**
    	* @dev Amount withdrawn for given proposal
    	*/
    	function proposalWithdrew(uint256 proposal) external view returns(uint256);
	/**
    	* @dev Amount received for given proposal
    	** change neme
    	*/
    	function proposalDeposit(uint256 proposal) external view returns(uint256);
	/**
    	* @dev Total shares issued for a given proposal
    	* NOTE: Number does not change after proposal closed and shares are redeemed
    	*/
    	function totalShares(uint256 proposal) external view returns(uint256);
	/**
    	* @dev Check if proposal is closed
    	* @return true if closed
    	*/
    	function closedProposal(uint256 proposal) external view returns(bool);
	/**
    	* @dev Add a new authorized user
    	* MUST BE primary authorized user not owner if agent = true
    	*/
    	function addAuth(address num) external virtual returns();
	/**
	* @dev Make a deposit to proposal creating new shares
	* - MUST be open proposal
	* - MUST NOT be closed proposal
	* NOTE: using the deposit() will cause shares to not be accounted for in a proposal
	* @param assets amount being deposited
	* @param receiver address of depositor
	* @param proposal number assciated proposal
	*/
	function proposalDeposit(uint256 assets, address receiver, uint256 proposal) external virtual returns (uint256);
	/**
	* @dev Make a deposit to proposal creating new shares
	* - MUST account for proposalNumber
	* - MUST have proposalNumber
	* NOTE: using the mint() will cause shares to not be accounted for in a proposal
	* @param shares amount being deposited
	* @param receiver address of depositor
	* @param proposal number asscoiated proposal
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
	* @param receiver address of token recipent
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
 


<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
