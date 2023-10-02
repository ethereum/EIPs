---
title: DNS over HTTPS for Contract Discovery and eTLD+1 Association
description: A simple standard leveraging TXT Records to discover and verify association of a smart contract with the owner of a DNS domain. 
author: Todd Chapman (@TtheBC01), Charlie Sibbach (charlie@cwsoftware.com), Sean Sing (@SeanSing)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-9-30
---

## Abstract

The introduction of [DNS over HTTPS](https://en.wikipedia.org/wiki/DNS_over_HTTPS) (DoH) in [RFC 8484](https://datatracker.ietf.org/doc/html/rfc8484) has enabled tamper-resistant client-side queries of DNS records directly from the browser context. This ERC describes a simple standard leveraging DoH to fetch TXT records which are used for discovering and verifying the association of a smart contract with a common DNS domain.

## Motivation

As mainstream businesses begin to adopt public blockchain and digital asset technologies more rapidly, there is a growing need for a discovery/search mechanism (compatible with conventional browser resources) of smart contracts associated with a known business domain as well as reasonable assurance that the smart contract does indeed belong to the business owner of the DNS domain. The relatively recent introduction and widespread support of DoH means it is possible to make direct queries of DNS records straight from the browser context and thus leverage a simple TXT record as a pointer to an on-chain smart contract. 

A TXT pointer coupled with an appropriate smart contract interface (described in this ERC) yields a simple, yet flexible and robust mechanism for the client-side detection and reasonably secure verification of on-chain data logic and digital assets associated with a the owner of a domain name. For example, a stablecoin issuer might leverage this standard to provide a method for an end user or web-based end user client to ensure that the asset their wallet is interacting with is indeed the contract issued or controlled by the owner or administrator of a well known DNS domain. 

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### How Smart Contracts are Discovered

The owner of a domain name MUST create a TXT record in their DNS settings that serves as a pointer to all relevant smart contracts they wish to associate with their domain. 

[TXT records](https://datatracker.ietf.org/doc/html/rfc1035#section-3.3.14) are not intended (nor permitted by most DNS servers) to store large amounts of data. Every DNS provider has their own vendor-specific character limits (see [Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ResourceRecordTypes.html#TXTformat-limits) and [Namecheap](https://www.namecheap.com/support/knowledgebase/article.aspx/10058/10/namecheap-dns-limits/#:~:text=For%20TXT%20records%2C%20the%20limit,dots%2C%20for%20example%2C%201.2.) for typical limits). However, an EVM-compatible address string is 42 characters, so most DNS providers will allow for dozens of contract addresses to be stored under a single record. 

The TXT record MUST adhere to the following schema:

- `HOST`: `chain_id`-`record_number`._domaincontracts
- `TTL`: auto
- `VALUE`: "<integer number of TXT records referencing smart contract addresses on this domain>""<address 1>""<address 2>"`...`

This `HOST` naming scheme is designed to mimic the [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail#Verification) naming convention. Additionally, this naming scheme makes it simple to programmatically ascertain if any smart contracts are associated with the domain on a given blockchain network. The value of `chain_id` is simply the integer associated with the target network (i.e. `1` for Ethereum mainnet or `42` for Polygon). The `record_number` acts as a page number to allow for multiple TXT records to be created if the quantity of referenced contracts cannot fit in a single record. Additionally, `record_number` is used in conjunction with the first integer given in the `VALUE` field which denotes the total number of relevant TXT records. So, a typical `HOST`  might be: `1-1._domainContracts`, `1-2._domainContracts`, etc.

A user can check the propagation of their TXT record from the command line via [`dig`](https://linux.die.net/man/1/dig):

```
dig -t txt 1-1._domaincontracts.example.com
```

or leverage DoH in the browser console with [`fetch`](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch):

```
await fetch("https://cloudflare-dns.com/dns-query?name=1-1._domaincontracts.example.com&type=TXT", {
  headers: {
    Accept: "application/dns-json"
  }
})
```

### Verifying Smart Contract Association Against a Domain Reference

Any smart contract MAY implement this ERC to provide a verification mechanism of smart contract addresses listed in a compatible TXT record.

A smart contract need only store one new member variable, `domains`, which is an array of all unique [eTLD+1](https://developer.mozilla.org/en-US/docs/Glossary/eTLD) domains associated with the contract. This member variable can be written to with the external functions `addDomain` and `removeDomain`.

```solidity
{
  public string[] domains; // a string list of eTLD+1 domains associated with this contract

  function addDomain(string memory domain) external; // an authenticated method to add an eTLD+1

  function removeDomain(string memory domain) external; // an authenticated method to remove an eTLD+1
}
```

The user client MUST verify that the eTLD+1 of the TXT record matches an entry in the `domains` list of the smart contract.

## Rationale

According to [Cloudflare](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/), the two most common use cases of TXT records today are email spam prevention (via [SPF](https://www.cloudflare.com/learning/dns/dns-records/dns-spf-record/), [DKIM](https://www.cloudflare.com/learning/dns/dns-records/dns-dkim-record/), and [DMARC](https://www.cloudflare.com/learning/dns/dns-records/dns-dmarc-record/) TXT records) and domain ownership verification. The use case considered here for on-chain smart contract discovery and verification is essentially analogous. Now that DoH is supported by most major DNS providers, it is easy to leverage TXT records directly in wallets, dApps, and other web applications without relying on a proprietary vendor API to provide DNS information and thus gain the same benefits afforded to email and domain verification with digital assets and on-chain logic. 

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

The implementation of `addDomain` and `removeDomain` is a trivial exercise, but candidate implementations are given here for completeness (note that these functions are unlikely to be called often, so gas optimizations are possible):

```solidity
function addDomain(
      string memory domain
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
      string[] memory domainsArr = domains;

      // check if domain already exists in the array
      for (uint256 i; i < domains.length; ) {
          if (
              keccak256(abi.encodePacked((domainsArr[i]))) ==
              keccak256(abi.encodePacked((domain)))
          ) {
              revert("Consent : Domain already added");
          }
          unchecked {
            ++i;
          }
      }
    domains.push(domain);
  }

function removeDomain(
    string memory domain
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    string[] memory domainsArr = domains;
    // A check that is incremented if a requested domain exists
    uint8 flag;
    for (uint256 i; i < domains.length; ) {
      if (
        keccak256(abi.encodePacked((domainsArr[i]))) ==
        keccak256(abi.encodePacked((domain)))
      ) {
          // replace the index to delete with the last element
          domains[i] = domains[domains.length - 1];
          // delete the last element of the array
          domains.pop();
          // update to flag to indicate a match was found
          flag++;
          break;
        }
        unchecked {
          ++i;
        }
    }
    require(flag > 0, "Consent : Domain is not in the list");
  }
```

**NOTE**: It is important that appropriate account authentication be applied to `addDomain` and `removeDomain` so that only authorized users may update the `domains` list.

## Security Considerations

Due to the reliance on traditional DNS systems, this ERC is susceptible to attacks on this technology, such as [domain hijacking](https://en.wikipedia.org/wiki/Domain_hijacking). Additionally, it is the responsibility of the smart contract author to ensure that `addDomain` and `removeDomain` are authenticated properly, otherwise an attacker could associate their smart contract with an undesirable domain. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
