---
eip: <to be assigned>
title: ERC20 for Swiss compliant
author: Gianluca Perletti (@Perlets9), Alan Scarpellini (@alanscarpellini), Roberto Gorini (@robertogorini), Manuel Olivi (@manvel79)
discussions-to: Pull Request
status: Draft
type: Standards Track
category: ERC
created: 2020-09-08
requires: eip-20
---

ERC20 for Swiss compliant

## Simple Summary
This new standard is an ERC-20 compatible token with restrictions that comply with one or more one the following Swiss laws: Stock Exchange Act, the Banking Act, the Financial Market Infrastructure Act, the Act on Collective Investment Schemes and the Anti-Money Laundering Act. The Financial Services Act and the Financial Institutions Act must also be considered. The solution achieved meet also the European jurisdiction. 

## Abstract
This new standard meets the new era of asset tokens (or security tokens). These new methods manage securities ownership during issuance and trading. The issuer is the only role that can manage a white-listing and the only one that is allowed to execute “freeze” or “revoke” functions.

## Motivation
In its ICO guidance dated February 16, 2018, FINMA (Swiss Financial Market Supervisory Authority) defines asset tokens as tokens representing assets and/or relative rights. It explicitly mentions that asset tokens are analogous to and can economically represent shares, bonds, or derivatives. The long list of relevant financial market laws mentioned above reveal that we need more methods than with Payment and Utility Token. 

## Rationale
There are currently no token standards that expressly facilitate conformity to securities law and related regulations. EIP-1404 (Simple Restricted Token Standard) it’s not enough to address FINMA requirements around re-issuing securities to Investors.
In Swiss law, an issuer must eventually enforce the restrictions of their token transfer with a “freeze” function. The token must be “revocable”, and we need to apply a white-list method for AML/KYC checks.

## Backwards Compatibility
This EIP does not introduce backward incompatibilities and is backward compatible with the older ERC20 token standard.
This standard allows the implementation of ERC20 functions transfer, transferFrom, approve and allowance alongside to make a token fully compatible with ERC20.
The token MAY implement decimals() for backward compatibility with ERC20. If implemented, it MUST always return 0.

## Implementation
``` js
  interface IERCX {
  
  /// @dev This emits when funds are reassigned
  event FundsReassigned(address _from, address _to, uint256 _amount);

  /// @dev This emits when funds are revoked
  event FundsRevoked(address _from, uint256 _amount);

  /// @dev This emits when an address is frozen
  event FundsFrozen(address _target);

  /**
  * @dev Transfer tokens from a specified address to another one
  * @param _from The address from which the tokens are withdrawn
  * @param _to The address that receives the tokens
  * @return true if the tokens are transferred
  */
  function reassign(address _from, address _to) external;

  /**
  * @dev Transfer tokens from a specified address to the contract owner (issuer)
  * @param _from The address from which the tokens are withdrawn
  * @return true if the tokens are transferred
  */
  function revoke(address _from) external;

  /**
  * @dev getter to determine if address is in frozenlist
  */
  function frozenlist(address _operator) external view returns (bool);

  /**
  * @dev add an address to the frozenlist
  * @param _operator address
  * @return true if the address was added to the frozenlist, false if the address was already in the frozenlist
  */
  function addAddressToFrozenlist(address _operator) external;

  /**
  * @dev remove an address from the frozenlist
  * @param _operator address
  * @return true if the address was removed from the frozenlist,
  * false if the address wasn't in the frozenlist in the first place
  */
  function removeAddressFromFrozenlist(address _operator) external;

  /**
  * @dev getter to determine if address is in whitelist
  */
  function whitelist(address _operator) external view returns (bool);

  /**
  * @dev add an address to the whitelist
  * @param _operator address
  * @return true if the address was added to the whitelist, false if the address was already in the whitelist
  */
  function addAddressToWhitelist(address _operator) external;

  /**
  * @dev remove an address from the whitelist
  * @param _operator address
  * @return true if the address was removed from the whitelist,
  * false if the address wasn't in the whitelist in the first place
  */
  function removeAddressFromWhitelist(address _operator) external;

  /**
  * @dev add a new issuer address
  * @param _operator address
  * @return true if the address was not an issuer, false if the address was already an issuer
  */
  function addIssuer(address _operator) external;

  /**
  * @dev remove an address from issuers
  * @param _operator address
  * @return true if the address has been removed from issuers,
  * false if the address wasn't in the issuer list in the first place
  */
  function removeIssuer(address _operator) external;

  /**
  * @dev Allows the current issuer to transfer his role to a newIssuer.
  * @param _newIssuer The address to transfer the issuer role to.
  */
  function transferIssuer(address _newIssuer) external;

}
```

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
