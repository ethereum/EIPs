<pre>
  EIP: draft
  Title: Ethereum Domain Name Service - Specification
  Author: Nick Johnson <arachnid@notdot.net>
  Status: Draft
  Type: Informational
  Created: 2016-04-04
</pre>

Abstract
========
This draft EIP describes the details of the Ethereum Name Service, a proposed protocol and ABI definition that provides flexible resolution of short, human-readable names to service and resource identifiers. This permits users and developers to refer to human-readable and easy to remember names, and permits those names to be updated as necessary when the underlying resource (contract, content-addressed data, etc) changes. 

The goal of domain names is to provide stable, human-readable identifiers that can be used to specify network resources. In this way, users can enter a memorable string, such as 'vitalik.wallet' or 'www.mysite.swarm', and be directed to the appropriate resource. The mapping between names and resources may change over time, so a user may change wallets, a website may change hosts, or a swarm document may be updated to a new version, without the domain name changing. Further, a domain need not specify a single resource; different record types allow the same domain to reference different resources. For instance, a browser may resolve 'mysite.swarm' to the IP address of its server by fetching its A (address) record, while a mail client may resolve the same address to a mail server by fetching its MX (mail exchanger) record.

Motivation
==========
Existing [specifications](https://github.com/ethereum/wiki/wiki/Registrar-ABI) and [implementations](https://ethereum.gitbooks.io/frontier-guide/content/registrar_services.html) for name resolution in Ethereum provide basic functionality, but suffer several shortcomings that will significantly limit their long-term usefulness:

 - A single global namespace for all names with a single 'centralised' resolver.
 - Limited or no support for delegation and sub-names/sub-domains.
 - Only one record type, and no support for associating multiple copies of a record with a domain.
 - Due to a single global implementation, no support for multiple different name allocation systems.
 - Conflation of responsibilities: Name resolution, registration, and whois information.

Use-cases that these features would permit include:

 - Support for subnames/sub-domains - eg, live.mysite.tld and forum.mysite.tld.
 - Multiple services under a single name, such as a DApp hosted in Swarm, a Whisper address, and a mail server.
 - Support for DNS record types, allowing blockchain hosting of 'legacy' names. This would permit an Ethereum client such as Mist to resolve the address of a traditional website, or the mail server for an email address, from a blockchain name.
 - DNS gateways, exposing ENS domains via the Domain Name Service, providing easier means for legacy clients to resolve and connect to blockchain services.
 - Programmatic name definition and resolution - for example, providing a service that resolves &lt;content hash>.swarm.tld to a swarm node that can return the content.
 
The first two use-cases, in particular, can be observed everywhere on the present-day internet under DNS, and we believe them to be fundamental features of a name service that will continue to be useful as the Ethereum platform develops and matures.

We propose to draw lessons from the design of the [DNS](https://www.ietf.org/rfc/rfc1035.txt) system, which has been providing name resolution to the internet for over 30 years. Many features apply well to Etherum and can be adapted; others are inapplicable or unwanted and should be discarded.

The normative parts of this document does not specify an implementation of the proposed system; its purpose is to document a protocol that different resolver implementations can adhere to in order to facilitate consistent name resolution. An appendix provides sample implementations of resolver contracts and libraries, which should be treated as illustrative examples only.

Likewise, this document does not attempt to specify how domains should be registered or updated, or how systems can find the owner responsible for a given domain. Registration is the responsibility of registrars, and is a governance matter that will necessarily vary between top-level domains. We propose a design for the governance of the top level resolver in a separate document (TBD).

Updating of domain records can also be handled separately from resolution. Some systems, such as swarm, may require a well defined interface for updating domains, in which event we anticipate the development of a standard for this. Finally, finding the responsible parties of a domain is the task of a whois system, which can be specified separately, even if resolvers typically implement both protocols.

Specification
=============
Overview
--------
The ENS, or Ethereum Name Service, proposed here, borrows where appropriate from the Domain Name System used to resolve domain names on the internet. This is done both because their requirements are similar, and thus we can take advantage of lessons learned from 30 years of accumulated experience serving as the Internet's name resolution system, and because it permits easier interoperability between the two systems.

Although this document aims to be as self contained as possible, in the interest of avoiding duplication, we make references to features of the DNS specification. [RFC1035](https://www.ietf.org/rfc/rfc1035.txt), which provides the basic definition of the domain name system, may prove useful reading alongside this document.

ENS is hierarchial, with more general parts on the left, and more specific parts on the right. In the domain 'www.example.com', 'com' is the top-level domain, while 'www' specifies a sub-domain. Unlike DNS, names are relative; each resolver is passed one label to resolve, and it performs a lookup and returns its record for that label. This means that rather than forming a tree, the set of deployed names may form a graph; nodes can link to each other at any depth in the hierarchy. The resolution process is described in detail below.

Although we expect most users to converge on a common root-level resolver, the system permits the existence of 'alternate roots', which provide their own set of top-level domains, which may potentially overlap with those exposed by other root resolvers. Due to the relative nature of name resolution in ENS, users may point to a "local resolver"; a name that resolves internally as "mysite.corp" may be exposed to external users as "mysite.corp.company.com".

Resolvers exist as contracts in the Ethereum blockchain; this allows contracts to perform name resolution, in addition to allowing use by DApps. We expect both to use ENS for resolving names to contracts and to content hashes.

Name Syntax
-----------
ENS names must conform to the following syntax:

<pre>&lt;domain> ::= &lt;label> | &lt;domain> "." &lt;label>
&lt;label> ::= &lt;letter> [ [ &lt;ldh-str> ] &lt;let-dig> ]
&lt;ldh-str> ::= &lt;let-dig-hyp> | &lt;let-dig-hyp> &lt;ldh-str>
&lt;let-dig-hyp> ::= &lt;let-dig> | "-"
&lt;let-dig> ::= &lt;letter> | &lt;digit>
&lt;letter> ::= any one of the 52 alphabetic characters A through Z in
upper case and a through z in lower case
&lt;digit> ::= any one of the ten digits 0 through 9
</pre>

In short, names consist of a series of dot-separated labels. Each label must start with a letter, and end with a letter or a digit. Intermediate letters may be letters, digits, or hyphens.

Note that while upper and lower case letters are allowed in names, no significance is attached to case. Two names with different case but identical spelling should be treated as identical.

Labels and domains may be of any length, but for compatibility with legacy DNS, it is recommended that labels be restricted to no more than 64 characters each, and complete ENS names to no more than 255 characters.

Names are restricted to ASCII on the basis that the existing punycode and nameprep systems exist to allow browsers and other tools to support unicode domain names. Although it is tempting to fully support UTF-8 directly in the system, this would require resolvers to implement generalized unicode case folding, which imposes an undue burden on contracts, which have to limit their gas consumption for callers.

ENS Structure
-------------
The ENS hierarchy is conceptually structured as a tree. Each node in the tree represents a part of a name. A tree node may have child nodes, representing subdomains, and resource records (RRs), containing mapping information from names to other resources.

A (simple) example tree might look something like this:
 - (root node)
   - "swarm"
     - "mysite"
       - RR: "CHASH" => "0x12345678"
     - "othersite"
       - RR: "CHASH" => "0x23456789"
       - "subdomain"
         - RR: "CHASH" => "0x34567890"
   - "eth
     - "bob"
       - RR: "HA" => "0x45678901"
       - RR: "HA" => "0x56789012"
       - RR: "CHASH" => "0x67890123"

Each node is uniquely identified by a Node ID and a resolver address. Node IDs are allocated arbitrarily by resolvers, and make it possible to resolve many different parts of the ENS hierarchy using a single resolver instance. Any of the above nodes may be hosted by separate resolvers; resolvers host "glue records" that allow clients to follow the links from one resolver to another when resolving a name.

Since any node can point to any other node, the ENS hierarchy is in fact a graph rather than a tree; it can even be cyclic, though in practical cases will generally not be. The structure of ENS makes it easy for organisations to define their own name (sub-)hierarchies, delegating parts of the namespace as they see fit.

Resolution Process
------------------
Before being passed to resolvers, ENS names are preprocessed. The name is divided into labels, starting with the rightmost one, and each label is first folded to lower-case, then hashed with SHA3-256. So, the domain "subdomain.othersite.swarm", after processing, becomes the sequence of labels [sha3("swarm"), sha3("othersite"), sha3("subdomain")].

Name resolution is performed iteratively. The client first performs `findResolver` query on the root resolver, passing it the hash of the rightmost label. The root resolver looks up its internal node for the last domain component, sha3("swarm") in this example. If the record, which consists of a (node ID, resolver address) tuple exists, it returns it, and the client repeats the process for the resolver specified in that record with the next part of the domain. If at any point the record does not exist, an immediate response of NXDOMAIN (No such domain) is returned.

Once this procedure has been executed for all domain components, the final resolver is sent a `resolve` query for the requested record type.

Resolvers are specified with a 160 bit address, specifying the address of the Ethereum contract acting as the resolver, and a 96 bit node ID. Node IDs are local to each resolver, and allow resolvers to host multiple independent subtrees. By convention, a root resolver's main tree has node ID of 0, but this is not mandatory.

RR Definitions
--------------
### Format
A Resource Record is the base unit of storage and retrieval in the ENS. Each resource record consists of:
 - NAME - the name to which this record pertains.
 - TYPE - one of the RR type codes, specifying the type of resource being addressed.
 - TTL - the duration, in seconds, that the record may be cached.
 - RDATA - the data associated with this record, whose format depends on TYPE and (potentially) CLASS.

### TYPE values
TYPE fields specify the nature of the record. ENS uses the same definitions of types as DNS, a registry of which can be seen [here](http://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml#dns-parameters-4).

Until standardized TYPE values are assigned, the following temporary TYPEs are employed for new record types:
 - CHASH - Provides the content-hash of a document, retrievable using a content-addressed storage system.
 - HA - Provides the hash-based address of an entity, such as a blockchain account address.

Unlike DNS, which uses type IDs from a 16 bit range to identify record types, ENS encodes types directly as ASCII strings in a bytes32 argument. Strings are left-aligned and padded with 0 bytes.

### QTYPE values
QTYPE fields appear in the question part of a query.  QTYPES are a superset of TYPEs, hence all TYPEs are valid QTYPEs. EIP defines the same set of QTYPEs as DNS.

New RRs
-------
### CHASH RDATA format
<pre>+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
/                                               /
/                   Hash value                  /
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+</pre>

Where:
 - Hash value - the binary value of a hash function applied to the content being referenced.

A CHASH record serves as a means to identify a document by its hash, permitting lookup in hash-named datastores such as Swarm.

### HA RDATA format
<pre>+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
/                                               /
/                   Hash value                  /
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+</pre>

Where:
 - Hash value - the binary value of the hash-based address.

A HA record specifies a hash-based address, such as an Ethereum wallet address.

API
---
### findResolver
This method requests that the resolver return the address and Node ID of the resolver responsible for the specified label.

An ENS resolver must implement an API conforming to the following signature, under the standard [Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI):

<pre>function findResolver(bytes12 node, bytes32 label) returns (uint16 rcode, uint32 ttl, bytes12 rnode, address raddress);</pre>

Where:
 - node - The 96-bit node ID from which to begin the query. By convention, root resolvers start their main tree at node 0.
 - label - The sha3 hash of a domain label, as described in "Resolution Process".
 - rcode - Response code, as defined in DNS.
 - ttl - Duration in seconds that this record may be cached.
 - rnode - The Node ID of the resolver.
 - raddress - The address of the resolver.

`ttl` specifies the maximum amount of time a record may be cached for. This is used only by local resolvers and DNS gateways. Contracts that need to resolve names may choose to ignore caching and fetch the record afresh each time the need it, if they expect to handle name resolutions infrequently compared to the expected TTL.

### resolve
This method requests that the resolver return a name record of the specified record type.

An ENS resolver must implement an API conforming to the following signature, under the standard [Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI):

<pre>function resolve(bytes12 node, bytes16 qtype, uint16 index) returns (uint16 rcode, bytes16 rtype, uint32 ttl, uint16 len, bytes32 data);</pre>

Where:
 - node - The 96-bit node ID from which to begin the query. By convention, root resolvers start their main tree at node 0.
 - qtype - The query type, a left-aligned zero-padded byte string, as specified by DNS and amended with the CHASH and RA types.
 - index - Specifies the index into the array of results to return. Specifying an index that is out of bounds will result in a 0-length response.
 - rcode - Response code, as defined in DNS.
 - rtype - The DNS TYPE of the returned record.
 - ttl - Duration in seconds that this record may be cached.
 - len - Length of the returned result, see below.
 - data - Result data.

`qtype` specifies the query type of the query. Unlike DNS, which uses numerical query types, ENS uses the name of the type, such as 'A', 'CHASH', etc. Query types are encoded as ASCII and left aligned (stored in the most significant bits of the 32 byte field).

`ttl` specifies the maximum amount of time a record may be cached for. This is used only by local resolvers and DNS gateways. Contracts that need to resolve names may choose to ignore caching and fetch the record afresh each time the need it, if they expect to handle name resolutions infrequently compared to the expected TTL.

`index` permits iteration over multiple records. If a request is made with an index that is out of bounds, a response with a `len` of 0 is returned. Resolvers may return records in an arbitrary order, but the order MUST be consistent within a single block.

If `len` is 32 or less, the complete record is returned in `data`. If `len` is greater than 32, the result is too large to fit in a bytes32, and `data` instead contains a unique identifier. To fetch the complete record, call `getExtended` (described below) with the identifier. Values with `len` less than 32 are left-aligned (most significant bytes; higher array indexes when treated as an array in Solidity). Since numeric values such as addresses are right-aligned in Solidity, these should be treated as having a length of 32 bytes, regardless of the original data length.

### getExtended
When a record exceeds 32 bytes in length, an alternative mechanism is provided for fetching the result data, as described above in the description of `resolve`.

If a resolver can ever return a result of length greater than 32 bytes, it MUST implement getExtended. Resolvers that limit their record size, or only implement record types of fixed length no longer than 32 bytes, need not provide this function.

<pre>function getExtended(bytes32 id) returns (bytes data);</pre>

Where:
 - id - The unique record identifier returned by a previous call to `resolve`.
 - data - The full contents of the requested extended record.

If the id provided does not exist in the database, the resolver returns an empty byte string.

Rationale
=========
Gas costs
---------
Ethereum contracts operate under a very constrained VM, with substantial costs for allocating memory and copying data. This drove a number of tradeoffs designed to retain as much flexibility as possible, while eliminating overhead that would be unnecessary in common name resolution situations:
 - `resolve` returns fixed-length records, with a separate API for fetching longer records. This avoids the need to dynamically allocate large buffers, when most common results (to A, CHASH, HA, etc records) will fit in a small fixed-length buffer.
 - Name components are preparsed and hashed. This allows name parsing to be done once in common cases, at contract instantiation time, avoiding the high overhead of string manipulation in the EVM, and also permitting names of arbitrary length without the overhead of variable length types.
 - DNS's distinction between 'answer records', 'authority records' and 'additional records' has been eliminated, in favor of returning a single record with each call, of whichever type is appropriate, to eliminate unnecessary overhead and repeated calls.

Complexity reduction
--------------------
Most contracts and DApps have fairly straightforward needs for name resolution. However, past experience with DNS has shown that adding new functionality once widely deployed is difficult to impossible; the immutability of contracts in Ethereum may serve to make this even harder. Thus, we seek to find an acceptable tradeoff, with enough flexibility to allow more sophisticated uses and to provide for future expandability, while not unduly complicating simple use-cases.

Several features are designed with this in mind. The `getExtended` function call is required only if a resolver may return records greater than 32 bytes in length. Since common record types, such as account/contract addresses and content hashes fit within this size, common resolver implementations may choose to simply not support longer records, reducing implementation complexity. Likewise, local resolvers that do not need to provide the facility to retrieve longer records may choose not to implement this functionality, returning an error if a record is too long.

Finally, we expect local resolver implementations to mask complexity from the user. Common interfaces will include simple "lookup" functions that parse names into lists of hashes, and potentially cache records internally. Root resolvers may additionally decide to offer simple interfaces compatible with current practice.

Elimination of DNS CLASS
------------------------
In addition to TYPE, DNS also defines CLASS, which specifies the type of network the record is for. In practice, this is almost universally 'IN' (Internet). Since we expect this to always be the case for Ethereum-based resolvers, we have omitted CLASS from the nameservice definition. Gateways to the DNS system should assume this value is always 'IN'.

Caching
-------
Because all resolvers exist as contracts in the blockchain, and all parts of the blockchain state are equally 'close' to each other and to the user, there is little point in supporting recursive lookup by resolvers and local caching for latency reasons. For this reason, and for others outlined above in 'Gas costs', ENS does not support recursive lookups. A `ttl` field is provided because limited caching is still useful in some cases: a contract that is called frequently and always needs to resolve a name may choose to cache it in local storage to reduce the overhead of calling the resolver contracts, and DApps and gateways existing outside the blockchain may find it useful to cache results locally.

Implementation
==============
Authoritative Resolver
----------------------
This contract implements a minimal authoritative resolver. The contract 'Resolver' implements the name resolution functionality, while 'OwnedRegistrar' adds functionality allowing the owner to set HA and CHASH records, following the ABI defined for existing global resolvers. It will happily act as authoritative resolver for any domain that's added to it, though naturally those domains will not resolve unless the relevant glue records are present in higher level resolvers.

A more complete implementation of a leaf authoritative resolver would add support for unsupported features (long records, CNAME) and provide a more sophisticated API for managing the resolver's database, including setting TTLs, multiple records, and other types than HA and CHASH.

```
/**
 * Basic authoritative resolver implementation.
 * 
 * This resolver supports basic functionality required to conform to the
 * ENS specification, but no advanced features. Not supported:
 *  - Data payloads of over 32 bytes (and thus, the getExtended() call).
 */
contract Resolver {
    bytes32 constant TYPE_STAR = "*";
    
    // Response codes.
    uint16 constant RCODE_OK = 0;
    uint16 constant RCODE_FORMAT_ERR = 1;
    uint16 constant RCODE_SRVFAIL = 2;
    uint16 constant RCODE_NXDOMAIN = 3;
    uint16 constant RCODE_NOT_IMPLEMENTED = 4;
    uint16 constant RCODE_REFUSED = 5;
    
    struct RR {
        bytes16 rtype;
        uint32 ttl;
        uint16 len;
        bytes32 data;
    }
    
    struct ResolverAddress {
        bytes12 nodeId;
        address addr;
        uint32 ttl;
    }
    
    struct Node {
        bool exists;
        mapping (bytes32=>ResolverAddress) subnodes;
        RR[] records;
    }

    mapping (bytes12=>Node) nodes;

    function findResolver(bytes12 nodeId, bytes32 label)
        returns (uint16 rcode, uint32 ttl, bytes12 rnode, address raddress)
    {
        var subnode = nodes[nodeId].subnodes[label];
        if (subnode.addr == address(0)) {
            rcode = RCODE_NXDOMAIN;
            return;
        }
        
        ttl = subnode.ttl;
        rnode = subnode.nodeId;
        raddress = subnode.addr;
    }

    function resolve(bytes12 nodeId, bytes32 qtype, uint16 index)
        returns (uint16 rcode, bytes16 rtype, uint32 ttl, uint16 len,
                 bytes32 data)
    {
        var node = nodes[nodeId];
        if (!node.exists) {
            rcode = RCODE_NXDOMAIN;
            return;
        }

        for(uint i = 0; i < node.records.length; i++) {
            var record = node.records[i];
            if (qtype == TYPE_STAR || qtype == record.rtype) {
                if (index > 0) {
                    index--;
                    continue;
                }
                
                rtype = record.rtype;
                ttl = record.ttl;
                len = record.len;
                data = record.data;
                return;
            }
        }
        
        // Returns with rcode=RCODE_OK and len=0, indicates record not found.
        return;
    }
}

/**
 * Authoritative resolver that allows its owner to insert and update records.
 */
contract OwnedRegistrar is Resolver {
    address _owner;
    uint96 nextNodeId = 0;
    
    modifier owner_only { if (msg.sender != _owner) throw; _ }
    
    function OwnedRegistrar() {
        _owner = msg.sender;
    }
    
    function setOwner(address owner) owner_only {
        _owner = owner;
    }

    /**
     * @dev Allocates a new node and returns its ID.
     * @return nodeId The ID of the newly created (empty) node.
     */
    function createNode() owner_only returns (bytes12 nodeId) {
        nodeId = bytes12(nextNodeId++);
        nodes[nodeId].exists = true;
    }
    
    /**
     * @dev Sets a subnode record on the specified node.
     * @param nodeId The ID of the node to set a subnode on.
     * @param label The label to set the subnode for.
     * @param subnodeId The Node ID of the subnode to set.
     * @param addr The address of the resolver for this subnode.
     * @return An RCODE indicating the status of the operation.
     */
    function setSubnode(bytes12 nodeId, bytes32 label, bytes12 subnodeId,
                        address addr, uint32 ttl)
        owner_only returns (uint16 rcode)
    {
        var node = nodes[nodeId];
        if (!node.exists)
            return RCODE_NXDOMAIN;
        
        node.subnodes[label].nodeId = subnodeId;
        node.subnodes[label].addr = addr;
        node.subnodes[label].ttl = ttl;
        return RCODE_OK;
    }
    
    /**
     * @dev Convenience function to create and return a subnode. Equivalent to
     *      calling `createNode` followed by `setSubnode`.
     * @param nodeId The ID of the node to create a subnode on.
     * @param label The label to set the subnode for.
     * @return An RCODE indicating the status of the operation, and the ID of
     *         the newly created subnode.
     */
    function createSubnode(bytes12 nodeId, bytes32 label, uint32 ttl)
        owner_only returns (uint16 rcode, bytes12 subnodeId)
    {
        subnodeId = createNode();
        rcode = setSubnode(nodeId, label, subnodeId, address(this), ttl);
    }
    
    /**
     * @dev Appends a new resource record to the specified node.
     * @param nodeId The ID of the node to append an RR to.
     * @param rtype The RR type.
     * @param ttl The TTL of the provided RR.
     * @param len The length of the provided RR.
     * @param data The data to append.
     * @return RCODE_OK on success, or RCODE_NXDOMAIN if the node does not exist.
     */
    function appendRR(bytes12 nodeId, bytes16 rtype, uint32 ttl, uint16 len,
                      bytes32 data)
        owner_only returns (uint16 rcode)
    {
        var node = nodes[nodeId];
        if (!node.exists)
            return RCODE_NXDOMAIN;
        
        node.records.length += 1;
        var record = node.records[node.records.length - 1];
        record.rtype = rtype;
        record.ttl = ttl;
        record.len = len;
        record.data = data;
        
        return RCODE_OK;
    }
    
    /**
     * @dev Deletes the specified resource record. Ordering of remaining records
     *      is not guaranteed to be preserved unless deleting the last record.
     * @param nodeId The ID of the node to delete an RR from.
     * @param idx The index of the RR to delete.
     * @return RCODE_OK on success, RCODE_NXDOMAIN if the node does not exist,
     *         RCODE_REFUSED if the index is out of bounds.
     */
    function deleteRR(bytes12 nodeId, uint16 idx)
        owner_only returns (uint16 rcode)
    {
        var node = nodes[nodeId];
        if (!node.exists)
            return RCODE_NXDOMAIN;
        
        if (idx >= node.records.length)
            return RCODE_REFUSED;
        
        if (idx != node.records.length - 1) {
            node.records[idx] = node.records[node.records.length - 1];
        }
        node.records.length--;
        
        return RCODE_OK;
    }
}
```

Local Resolver Library
----------------------
This library code implements a basic local resolver. It supports CNAME resolution, but not extended records or caching.

```
import 'github.com/arachnid/solidity-stringutils/StringUtils.sol';

contract Resolver {
    function findResolver(bytes12 nodeId, bytes32 label)
        returns (uint16 rcode, uint32 ttl, bytes12 rnode, address raddress);
    function resolve(bytes12 nodeId, bytes32 qtype, uint16 index)
        returns (uint16 rcode, bytes16 rtype, uint32 ttl, uint16 len,
                 bytes32 data);
}

contract LocalResolver is StringUtils {
    // Response codes.
    uint8 constant RCODE_OK = 0;
    uint8 constant RCODE_NXDOMAIN = 3;

    Resolver private root;

    function LocalResolver(address _root) {
        root = Resolver(_root);
    }
    
    function findResolver(string name)
        returns (uint16 rcode, Resolver resolver, bytes12 nodeId)
    {
        resolver = root;
        var lastIdx = int(bytes(name).length - 1);
        while (lastIdx > 0) {
            var idx = strrstr(name, ".", uint(lastIdx)) + 1;
            var label = sha3_substring(name, uint(idx), uint(lastIdx - idx) + 1);
            uint32 ttl;
            address addr;
            (rcode, ttl, nodeId, addr) = resolver.findResolver(nodeId, label);
            if (rcode != RCODE_OK)
                return;
            resolver = Resolver(addr);
            lastIdx = idx - 2;
        }
    }

    function resolveOne(string name, bytes16 qtype)
        returns (uint16 rcode, bytes16 rtype, uint16 len, bytes32 data)
    {
        Resolver resolver;
        bytes12 nodeId;
        (rcode, resolver, nodeId) = findResolver(name);
        
        uint32 ttl;
        (rcode, rtype, ttl, len, data) = resolver.resolve(nodeId, qtype, 0);
    }
    
    /**
     * Implements the legacy registrar addr() function.
     */
    function addr(string name) returns (address) {
        var (rcode, rtype, len, data) = resolveOne(name, "HA");
        return address(data);
    }

    /**
     * Implements the legacy registrar content() function.
     */
    function content(string name) returns (address) {
        var (rcode, rtype, len, data) = resolveOne(name, "CHASH");
        return address(data);
    }
}
```
