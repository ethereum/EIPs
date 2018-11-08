---
eip: 1459
title: Node Discovery via DNS
author: Felix Lange <fjl@ethereum.org>, Péter Szilágyi <peter@ethereum.org>
type: Standards Track
category: Networking
status: Draft
created: 2018-09-26
requires: 778
discussions-to: https://github.com/ethereum/devp2p/issues/50
---

# Abstract

This document describes a scheme for authenticated, updateable Ethereum node lists
retrievable via DNS.

# Motivation

Many Ethereum clients contain hard-coded bootstrap node lists. Updating those
lists requires a software update. The current lists are small, giving the client
little choice of initial entry point into the Ethereum network. We would like to
maintain larger node lists containing hundreds of nodes, and update them
regularly.

The scheme described here is a replacement for client bootstrap node lists with
equivalent security and many additional benefits. DNS node lists may also be
useful to Ethereum peering providers because their customers can configure the
client to use the provider's list. Finally, the scheme serves as a fallback
option for nodes which can't join the node discovery DHT.

# Specification

### DNS Record Structure

Node lists are encoded as TXT records. The records form a merkle tree. The root
of the tree is a record with content:

    enrtree-root=v1 hash=<roothash> seq=<seqnum> sig=<signature>

`roothash` is the abbreviated root hash of the tree in base32 encoding. `seqnum`
is the tree's update sequence number, a decimal integer. `signature` is a
65-byte secp256k1 EC signature over the keccak256 hash of the record content,
encoded as URL-safe base64.

Further TXT records on subdomains map hashes to one of three entry types. The
subdomain name of any entry is the base32 encoding of the abbreviated keccak256
hash of its text content.

- `enrtree=<h₁>,<h₂>,...,<hₙ>` is an intermediate tree containing further hash
  subdomains.
- `enrtree-link=<key>@<fqdn>` is a leaf pointing to a different list located at
  another fully qualified domain name. The key is the expected signer of the
  remote list, a base32 encoded secp256k1 public key,
- `enr=<node-record>` is a leaf containing a node record [as defined in EIP-778][eip-778].
  The node record is encoded as a URL-safe base64 string.

No particular ordering or structure is defined for the tree. Whenever the tree
is updated, its sequence number should increase. The content of any TXT record
should be small enough to fit into the 512 byte limit imposed on UDP DNS
packets. This limits the number of hashes that can be placed into a `enrtree=`
entry.

Example in zone file format:

```text
; name                        ttl     class type  content
@                             60      IN    TXT   "enrtree-root=v1 hash=TO4Q75OQ2N7DX4EOOR7X66A6OM seq=3 sig=N-YY6UB9xD0hFx1Gmnt7v0RfSxch5tKyry2SRDoLx7B4GfPXagwLxQqyf7gAMvApFn_ORwZQekMWa_pXrcGCtwE="
TO4Q75OQ2N7DX4EOOR7X66A6OM    86900   IN    TXT   "enrtree=F4YWVKW4N6B2DDZWFS4XCUQBHY,JTNOVTCP6XZUMXDRANXA6SWXTM,JGUFMSAGI7KZYB3P7IZW4S5Y3A"
F4YWVKW4N6B2DDZWFS4XCUQBHY    86900   IN    TXT   "enr=-H24QI0fqW39CMBZjJvV-EJZKyBYIoqvh69kfkF4X8DsJuXOZC6emn53SrrZD8P4v9Wp7NxgDYwtEUs3zQkxesaGc6UBgmlkgnY0gmlwhMsAcQGJc2VjcDI1NmsxoQPKY0yuDUmstAHYpMa2_oxVtw0RW_QAdpzBQA8yWM0xOA=="
JTNOVTCP6XZUMXDRANXA6SWXTM    86900   IN    TXT   "enr=-H24QDquAsLj8mCMzJh8ka2BhVFg3n4V9efBJBiaXHcoL31vRJJef-lAseMhuQBEVpM_8Zrin0ReuUXJE7Fs8jy9FtwBgmlkgnY0gmlwhMYzZGOJc2VjcDI1NmsxoQLtfC0F55K2s1egRhrc6wWX5dOYjqla-OuKCELP92O3kA=="
JGUFMSAGI7KZYB3P7IZW4S5Y3A    86900   IN    TXT   "enrtree-link=AM5FCQLWIZX2QFPNJAP7VUERCCRNGRHWZG3YYHIUV7BVDQ5FDPRT2@morenodes.example.org"
```

### Referencing Trees by URL

When referencing a record tree, e.g. in source code, the preferred form is a
URL. References should use the scheme `enrtree://` and encode the DNS domain in
the hostname. The expected public key that signs the tree should be encoded in
33-byte compressed form as a base32 string in the username portion of the URL.

Example:

```text
enrtree://AP62DT7WOTEQZGQZOU474PP3KMEGVTTE7A7NPRXKX3DUD57TQHGIA@nodes.example.org
```

### Client Protocol

To find nodes at a given DNS name, say "mynodes.org":

1. Resolve the TXT record of the name and check whether it contains a valid
   "enrtree-root=v1" entry. Let's say the root hash contained in the entry is
   "CFZUWDU7JNQR4VTCZVOJZ5ROV4".
2. Optionally verify the signature on the root against a known public key and
   check whether the sequence number is larger than or equal to any previous
   number seen for that name.
3. Resolve the TXT record of the hash subdomain, e.g. "CFZUWDU7JNQR4VTCZVOJZ5ROV4.mynodes.org"
   and verify whether the content matches the hash.
4. The next step depends on the entry type found:
   - for `enrtree`: parse the list of hashes and continue resolving those (step 3).
   - for `enrtree-link`: continue traversal on the linked domain (step 1).
   - for `enr`: decode, verify the node record and import it to local node storage.

During traversal, the client should track hashes and domains which are already
resolved to avoid going into an infinite loop.

# Rationale

### Why DNS?

We have chosen DNS as the distribution medium because it is always available,
even under restrictive network conditions. The protocol provides low latency and
answers to DNS queries can be cached by intermediate resolvers. No custom server
software is needed. Node lists can be deployed to any DNS provider such as
CloudFlare DNS, dnsimple, Amazon Route 53 using their respective client
libraries.

### Why is this a merkle tree?

Being a merkle tree, any node list can be authenticated by a single signature on
the root. Hash subdomains protect the integrity of the list. At worst
intermediate resolvers can block access to the list or disallow updates to it,
but cannot corrupt its content. The sequence number prevents replacing the root
with an older version.

Synchronizing updates on the client side can be done incrementally, which
matters for large lists. Individual entries of the tree are small enough to fit
into a single UDP packet, ensuring compatibility with environments where only
basic UDP DNS is available. The tree format also works well with caching
resolvers: only the root of the tree needs a short TTL. Intermediate entries and
leaves can be cached for days.

### Why does `enrtree-link` exist?

Links between lists enable federation and web-of-trust functionality. The
operator of a large list can delegate maintenance to other list providers. If
two node lists link to each other, users can use either list and get nodes from
both.

# References

1. The base64 and base32 encodings used to represent binary data are defined in
   RFC 4648 (https://tools.ietf.org/html/rfc4648). No padding is used for base32.

[eip-778]: https://eips.ethereum.org/EIPS/eip-778

# Copyright

Copyright and related rights waived via CC0.
