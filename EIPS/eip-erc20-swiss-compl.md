---
eip: <to be assigned>
title: ERC-20-compatible Swiss Compliant Asset Token
author: Gianluca Perletti (@Perlets9), Alan Scarpellini (@alanscarpellini), Roberto Gorini (@robertogorini), Manuel Olivi (@manvel79)
discussions-to: Pull Request
status: Draft
type: Standards Track
category: ERC
created: 2020-09-08
requires: eip-20
---

## Simple Summary

An interface for asset tokens (or security tokens), compliant with Swiss Law and compatible with ERC-20.

## Abstract

This new standard is an ERC-20 compatible token with restrictions that comply with one or more one the following Swiss laws: Stock Exchange Act, the Banking Act, the Financial Market Infrastructure Act, the Act on Collective Investment Schemes and the Anti-Money Laundering Act. The Financial Services Act and the Financial Institutions Act must also be considered. The solution achieved meet also the European jurisdiction.

This new standard meets the new era of asset tokens (or security tokens). These new methods manage securities ownership during issuance and trading. The issuer is the only role that can manage a white-listing and the only one that is allowed to execute “freeze” or “revoke” functions.

## Motivation

In its ICO guidance dated February 16, 2018, FINMA (Swiss Financial Market Supervisory Authority) defines asset tokens as tokens representing assets and/or relative rights. It explicitly mentions that asset tokens are analogous to and can economically represent shares, bonds, or derivatives. The long list of relevant financial market laws mentioned above reveal that we need more methods than with Payment and Utility Token.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

The words "asset tokens" and "security tokens" can be considered synonymous.

Every ERC-toBeAssigned compliant contract must implement the ERCtoBeAssigned interface.

### ERCtoBeAssigned (Token Contract)

``` solidity
interface ERCtoBeAssigned {
  
  /// @dev This emits when funds are reassigned
  event FundsReassigned(address from, address to, uint256 amount);

  /// @dev This emits when funds are revoked
  event FundsRevoked(address from, uint256 amount);

  /// @dev This emits when an address is frozen
  event FundsFrozen(address target);

  /**
  * @dev Transfer tokens from a specified address to another one
  * this operation can be performmed only by an Issuer.
  * @param _from The address from which the tokens are withdrawn
  * @param _to The address that receives the tokens
  * @return true if the tokens are transferred
  */
  function reassign(address _from, address _to) external;

  /**
  * @dev Transfer tokens from a specified address to the Issuer who invokes the method
  * this operation can be performmed only by an Issuer.
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
  * this operation can be performmed only by an Issuer.
  * @param _operator address
  * @return true if the address was added to the frozenlist, false if the address was already in the frozenlist
  */
  function addAddressToFrozenlist(address _operator) external;

  /**
  * @dev remove an address from the frozenlist
  * this operation can be performmed only by an Issuer.
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
  * this operation can be performmed only by an Issuer.
  * @param _operator address
  * @return true if the address was added to the whitelist, false if the address was already in the whitelist
  */
  function addAddressToWhitelist(address _operator) external;

  /**
  * @dev remove an address from the whitelist
  * this operation can be performmed only by an Issuer.
  * @param _operator address
  * @return true if the address was removed from the whitelist,
  * false if the address wasn't in the whitelist in the first place
  */
  function removeAddressFromWhitelist(address _operator) external;

  /**
  * @dev add a new issuer address
  * this operation can be performmed only by the contract Owner.
  * @param _operator address
  * @return true if the address was not an issuer, false if the address was already an issuer
  */
  function addIssuer(address _operator) external;

  /**
  * @dev remove an address from issuers
  * this operation can be performmed only by the contract Owner.
  * @param _operator address
  * @return true if the address has been removed from issuers,
  * false if the address wasn't in the issuer list in the first place
  */
  function removeIssuer(address _operator) external;

  /**
  * @dev Allows the current issuer to transfer his role to a newIssuer.
  * this operation can be performmed only by an Issuer.
  * @param _newIssuer The address to transfer the issuer role to.
  */
  function transferIssuer(address _newIssuer) external;

}
```

The ERCtoBeAssigned extends ERC-20. Due to the indivisible nature of asset tokens, the decimals number MUST be zero.

### Whitelist and Frozenlist

The accomplishment of the Swiss Law requirements is achieved by the use of two distinct lists of address: the Whitelist and the Frozenlist.
Although these lists may look similar, they differ for the following reasons: the Whitelist members are the only ones who can receive tokens from other addresses. There is no restriction on the possibility that these addresses can transfer the tokens already in their ownership.
On the other hand, the addresses assigned to the Frozenlist have to be considered "frozen", so they cannot either receive tokens or send tokens to anyone.

### Issuers

A key role is played by the Issuer (if there are more than one, we refer to them as Issuers). This figure has the permission to manage Whitelists and Frozenlists, to revoke tokens and reassign them and to transfer the role to another address. Issuers are nominated by the Owner of the contract, who also is in charge of remove the role. By default, the Owner SHOULD NOT be an Issuer, but in some cases the Owner can manage both roles without restrictions.

### Revoke and Reassign

Revoke and Reassign methods allow Issuers to move tokens from addresses, even if they are in the Frozenlist. The Revoke method transfers the entire balance of the target address to the Issuer who invoked the method. The Reassign method transfers the entire balance of the target address to another address. These rights of these operations MUST be allowed only to Issuers.

## Rationale

There are currently no token standards that expressly facilitate conformity to securities law and related regulations. EIP-1404 (Simple Restricted Token Standard) it’s not enough to address FINMA requirements around re-issuing securities to Investors.
In Swiss law, an issuer must eventually enforce the restrictions of their token transfer with a “freeze” function. The token must be “revocable”, and we need to apply a white-list method for AML/KYC checks.

## Backwards Compatibility

This EIP does not introduce backward incompatibilities and is backward compatible with the older ERC-20 token standard.
This standard allows the implementation of ERC-20 functions transfer, transferFrom, approve and allowance alongside to make a token fully compatible with ERC-20.
The token MAY implement decimals() for backward compatibility with ERC-20. If implemented, it MUST always return 0.

## Implementations

A public Github repository will be added soon.

## References

### Standards

1. ERC-20 Token Standard. <https://eips.ethereum.org/EIPS/eip-20>

### Swiss Law

1. Federal Act on Combating Money Laundering and Terrorist Financing (Anti-Money Laundering Act, AMLA). <https://www.admin.ch/opc/en/classified-compilation/19970427/202002180000/955.0.pdf>
2. Federal Act on Collective Investment Schemes (Collective Investment Schemes Act, CISA). <https://www.admin.ch/opc/en/classified-compilation/20052154/201607010000/951.31.pdf>
3. FINMA publishes ICO guidelines. <https://www.finma.ch/en/news/2018/02/20180216-mm-ico-wegleitung>

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
