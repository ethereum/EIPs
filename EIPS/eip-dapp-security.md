---
title: dApp Security Policy Standard
description: Defines a document standard for defining the expected on-chain behavior of a dApp frontend.
author: Bernard Wagner (bernard-wagner)
status: Draft
discussions-to: https://ethereum-magicians.org/t/dapp-security-policy/21431
type: Meta
created: 2024-10-22
---

## Abstract

Introduce a standardized JSON document structure that wallets can interpret to determine whether transaction signing requests should be permitted or rejected. Policy documents should be publicly discoverable using a notary service so that a policy's authenticity can be assumed even when the origin of the transaction signing request may be compromised.

As an initial implementation, DNS-in-ENS can be used as the discovery mechanism as described in ENSIP-TBC.

## Motivation

Hackers often target dApp front-ends to coerce users into signing transactions that allow the hacker to transfer victims' funds. By introducing a security policy standard, wallet providers can implement safeguards to protect users against such attacks.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Policy Document

The document MUST be in JSON format and follow the structure defined below:

```json
{
  "version": "1.0.0",
  "report": "<https://mywebapp.xyz/report>",
  "rules": [
    {
      "description": "Limit USDC approvals to Uniswap Router",
      "inputs": [
        {
          "name": "_spender",
          "type": "address",
          "values": ["0xE592427A0AEce92De3Edee1F18E0157C05861564"]
        },
        {
          "name": "_value",
          "type": "uint256"
        }
      ],
      "name": "approve",
      "payable": false,
      "chainIds": [1],
      "targets": ["0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]
    }
  ],
  "metadata": {
    "commit": "70edc32"
  }
}

```

- **version**: REQUIRED. Version of the specification.
- **report**: OPTIONAL. URL to notify in case transactions are blocked. MUST include the raw unsigned 0x-hex-encoded transaction as the `tx` URL parameter in an HTTP GET request. e.g. `https://mywebapp.xyz/report?tx=0x...`
- **rules**: OPTIONAL. An array of rules for transaction validation. Extension of the ABI specification.
    - **name**: OPTIONAL. Name of the function. If omitted, it MUST be interrupted as the `fallback` function.
    - **description**: OPTIONAL. Description for front-end messages.
    - **inputs**: OPTIONAL. Extended function ABI that defines a list of permittable `values`. It MUST be ignored if no function `name` is specified.
        - **name:** OPTIONAL. User-readable name of the argument.
        - **type:** REQUIRED. ABI type of argument.
        - **values**: REQUIRED. List of valid values. It MUST be an encoded hex string of the correct byte length.
    - **payable**: OPTIONAL. Indicates whether the function is payable. MUST default to `false` if not specified.
    - **chainIds**: OPTIONAL. A List of chain IDs to which the rule applies. If not specified, it MUST default to any chain.
    - **targets**: OPTIONAL. Valid "to" addresses for the transaction. MUST default to any address if not specified.
- **metadata**: OPTIONAL. Any valid JSON to include in the document but not interpreted by Wallets. Typically, it will include a commit hash or change control of the policy document.

### Discovery

It is envisioned that the policy document may be discovered and obtained using different protocols. However, the discovery protocol MUST adhere to the following:

- Provide a high level of confidence that only the legitimate owner of a domain can associate a policy document to their domain.
- Be publicly accessible.
- Validate the integrity of the policy document.

## Rationale

The front ends of dApps are regularly targeted using supply-chain attacks or DNS hijacking, whether DNS cache poisoning or registrar compromise. When executed, these attacks inject malicious JavaScript that invokes transaction signing requests to drain users' wallets. In most scenarios, this behavior is not part of the expected behavior of the dApp from which the request originates. Therefore, if dApp developers can define the intended behavior of their dApp and have wallets obtain this policy out-of-band to enforce the intended behavior or warn users, several front-end compromise risks can be mitigated.

This EIP intends to be agnostic to the discovery protocol. However, DNS-in-ENS is a good first candidate, as it allows for importing DNSSEC-enabled domains into ENS. This process requires the submission of an on-chain transaction that includes the DNSSEC attestation for the domain. From there, the ENS controller can create a text record notarizing the location of the policy document.

Wallets, such as Metamask, can query ENS when receiving a transaction signing request to obtain the location of the policy and retrieve the document. The policy can then be applied to any signing request.

From a security perspective, this mitigates several supply-chain and DNS attack paths:

#### Malicious JavaScript embedded into the webpage

It invokes a transaction signing request from the webpage's context. The wallet uses its context to obtain the HTTP origin of the request and queries ENS for the domain using its own RPC endpoint. Since the policy retrieval and evaluation are performed outside the malicious JavaScript's execution context, it cannot request any action not permitted by the policy.

#### DNS cache-poisoning / BGP hijacking

The domain's IP address is changed to direct users to a malicious version of the dApp (the DNS resolver doesn't perform DNSSEC validation). As with a supply-chain compromise, the attackers have no control over the policy's evaluation.

If the attack extends to the location where the policy is hosted, the policy remains intact, as the discovery protocol MUST enforce an integrity check. In the case of ENSIP-TBC, the policy digest is included in the ENS text record for policy retrieval over HTTPS.

## Backwards Compatibility

N/A.

## Reference Implementation

A MetaMask Snap was developed to illustrate the implementation of the EIP. 

* https://dapp-security-demo.org/
* https://github.com/bernard-wagner/dapp-security-snap