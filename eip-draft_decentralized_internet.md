---
eip: 711
title: Ethereum decentralized base network service
author: Kirill Varlamov @ongrid <kirill@ongrid.pro>, Vsevolod Mikhalevsky <seva@ongrid.pro>
type: Informational
category: Networking
status: Draft
created: 2017-08-08
---

## Simple Summary
This 'umbrella' EIP describes the arguments against using current Internet as a transport for public blockchain applications, the potential vulnerabilities and risks of the current design and proposes the new principles for fast, autonomous, censorship-resistant base network. The proposal was written by network engineers with solid operations background at largest European service providers and practicing network architects.

## Abstract
The Ethereum [Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf) says "it is possible to use the internet to make a decentralized value-transfer system, shared across the world and virtually free to use". But Internet in its current state and IPv4 protocol in particular don't suit the needs of P2P applications - the current global network lacks connectivity, hugely technically and administratively centralized, totally controlled by governments and monopolies, vulnerable to censorship and intervention so shouldn't be considered as the only media for global distributed systems such as Ethereum, swarm, IPFS and other peer-to-peer applications of the future.

## Motivation

The Ethereum was designed to become the global platform for peer-to-peer decentralized value transfer, so we should rethink the base network service to make it faster and more decentralized and secure yet compatible with current Internet standards.

### Decentralized internet

#### Independence from authorities (IANA, RIRs, ICANN)

The Internet pioneers kept an open and decentralized design in mind developing its protocols suite, but the allocation of globally unique names and numbers (global IP address, autonomous system numbers, root zones in the Domain Name System) historically maintained in a centralized manner by nonprofit private American corporation [Internet Assigned Numbers Authority](https://www.iana.org)  (IANA). Now we have the new paradigm for globally unique resources fair distribution - open, verifiable, self-executing and self-enforcing Smart Contracts running in global public Virtual Machine. The [Ethereum Name Service](https://ens.domains) project proved such model for domain names. The IP (v6) global assignment registry could be maintained the similar, decentralized way.

#### Independence from ISPs

Individual internet users and organization such as hosting-, content-, CDN- and cloud-providers are typically connected to the global network through Internet Service Providers (ISPs). ISPs in most cases need to identify the entity before it can access Internet resources. Government-issued ID or another trusted authentication mechanism is typically used to prove the person. ISPs owning and maintaining the base infrastructure typically enforce some level of espionage and censorship (for law enforcement, business metrics or other reasons). Some of the well-known technical methods are:

* **Data interception** - raw packets could be copied on the fly at just any element of the ISP infrastructure: on dark fiber links by passive optical splitter, by the [SPAN/RSPAN/monitoring](https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960/software/release/12-2_40_se/configuration/guide/scg/swspan.pdf) features of the routers/switches on the path. Typically ['Lawful interception'](https://en.wikipedia.org/wiki/Lawful_interception) is done on per user/protocol/application basis by edge appliances: BRAS/BNG/PCEF/PE routers. Special management software makes these practices automated and simple. Within some jurisdictions ISPs must give the access to such systems to the government agencies under threat of license revocation. Now it's possible to sniff Ethereum node traffic and analyze the metadata, intensity, messages types, sniff raw swarm content and correlate it with specific actions on the chain to connect personal identities to addresses.

* **Session/stream/connection logging** is widely used on ISP infrastructure to record per-flow statistics about time, sources, destinations, protocols, ports (typically done with [Netflow](https://en.wikipedia.org/wiki/NetFlow)/[IPFIX](https://en.wikipedia.org/wiki/IP_Flow_Information_Export) protocols). If access technologies such as GTP, PPP, PPPoE, L2TP, PPTP used, each tunnel session is logged by [RADIUS](https://en.wikipedia.org/wiki/RADIUS) or [DIAMETER](https://en.wikipedia.org/wiki/RADIUS) AAA servers where time, floating (pool) IP address and user id get recorded. If ISP makes [Network Address Translation(NAT)](https://en.wikipedia.org/wiki/Network_address_translation) for subscribers, each translation is logged to correlate subscriber's internal address with external IP. This valuable personalized data is stored for years and often used for legal or illegal prosecution (e.g. to figure out the person who posted something on the internet or to confirm the fact of running some application or accessing some resource). For Ethereum it's possible to figure out the users running Ethereum and swarm nodes, mining apps (rigs), their personal data and physical location.

* **Traffic filtering/off-ramping** - just any switch or router is able to filter (drop or blackhole) the traffic by [Access Control List (ACL)](https://en.wikipedia.org/wiki/Access_control_list) or specific routing rules. Access-list based forwarding (ABF), [Policy-Based routing (PBR)](https://en.wikipedia.org/wiki/Policy-based_routing), BGP-FlowSpec are able to re-route specific application by its src-ip/dst-ip/protocol/src-port/dst-port (known as 5-tuple fields) with minimal effort. For Ethereum it's possible to either totally ban peers discovery protocol (node will never synchronize with the rest of the network as result), break IP connectivity with the most popular PoW mining pools with significant impact to the security of the ledger. It's possible to make short- or long-term high-scale network split for fraud/censorship reasons (known as a Segmentation attack). With off-ramping it's feasible to make more complex attacks, e.g. redirect discovery messages to the home-brewed nodes running wrong chain, redirect Proof-of-work mining applications to Strarum [MiM proxy](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) pointing to another pool/node that will give the unreasonable compute power gain in its favor (see [Sybil attack](https://en.wikipedia.org/wiki/Sybil_attack)). The entities maintaining big centralized networks as national Service Providers of the largest countries, [Internet exchange points](https://en.wikipedia.org/wiki/Internet_exchange_point) of the internet) are possible to implement massive Majority attack (50%+) this way.

* **HTTP(s) MiM proxy** - ISPs are technically able redirect HTTP traffic to the transparent HTTP proxy under its control. HTTP proxies can be specifically configured for blacklisting specific URIs, HTTP requests could be logged, HTTP data such as GET/POST content can be inspected and recorded. Currently most of the sites use HTTPs protocol based on public/private-key cryptography. It implements the additional layer of security, but the proxy server could be configured to forge the certificate and provide his own public key instead. The browser typically warns about the invalid certificate, but users tend to accept the wrong certificate to access the interesting resource so ISP's MiM can have the full access to all the data passing through it, analyze, log, manipulate, ban. Some countries implement more sophisticated way such a 'National browser' with modified PKI. This allows to inspect users' HTTPs traffic more smoothly. It's technically possible to ban blockchain- and cryptocurrency-related web resources such as exchanges, pools, blockchain explorers by URL pattern or keywords, or run rogue Ethereum site/repository hosting "malicious" node so the global consensus mechanism can be targeted this way.

* **Deep packet inspection** appliances and **Next-Gen firewalls** intelligently classify application traffic by different properties, metadata, keywords, context and classify the traffic with highest granularity. [DPI](https://en.wikipedia.org/wiki/Deep_packet_inspection) is perfect in filtering advanced dynamic protocols initially designed for firewalls traversal like Bittorent and Skype. With [NGFW](https://en.wikipedia.org/wiki/Next-Generation_Firewall) it's possible to finely ban specific actions for specific application while other communication stays intact, e.g. specific Facebook group or user profile can be categorized by the context and keywords and granularly filtered. Other applications can be treated this way if NGFW vendor release Protocol pack for it. Such packs are probably under research or development for Ethereum, IPFS and Swarm because of ongoing interest to take it under control to implement, say, transaction censorship on the network- (not EVM-) level. 

* **Malicious DNS** - ISPs typically maintain a set of application servers: for example NTP and DNS. For different reasons (such as caching, statistical or resource filtering) providers can specifically redirect the requests to their own servers. It's a common practice to intercept any DNS request (e.g. sent to independent DNS server such as well-known Google's 8.8.8.8) to the local DNS-server which is under ISP's control. Provider's DNS servers can be intentionally misconfigured as authoritative DNS server for censored domains and respond with incorrect address records for it ([rogue DNS-server](https://en.wikipedia.org/wiki/DNS_hijacking)). This leads to impossibility to reach the specific resource by its domain name. DNS hijacking could implement a simple phishing technique to redirect the request to the wrong site (say, to enforce downloading the malicious ethereum client instead of the original application, either clone from the wrong repository). With DNS hijack it's possible to redirect the Stratum applications configured to mine on well-known pool to the Stratum MiM proxy specified by the DNS administrator. Majority (50%+) attack is possible if significant subscriber base is under single administration.

* **Timejacking** - Exotic yet elegant split attack could be implemented by redirecting NTP time requests from the Ethereum-running host to the malicious NTP server advertising wrong time. As the result, the client clock starts drifting from reference time. Just a several seconds difference could result to node syncronization issues (state perfect for double-spend attacks). Notably, this method runs smoothly and non-traceable - no traffic interrupts, no peer resets. After the attack the redirection could be removed off the path so node connects proper NTP servers and smothly drifts toward correct UTC time and becomes syncronized back.

#### Independence from governments

At this stage it's difficult to predict will global decentralized value-transfer systems such as Ethereum be consentaneously supported by all the governments or not. Today several biggest contries consider  blockchain financials as 'illegal institutions', 'financial fraud' or 'speculation disrupting the economical and financial order'. Some governments have already voiced the position against the legalization of virtual currencies. 
Now the Ethereum's existence as a global platform is up to governments decisions until it's possible to ban, identify and prosecute persons and organizations running this technology. Technically this is done by ISPs, but in most countries telecommunications services are licensed or owned by governments so they are under strict regulation and tend to follow the rules. Special agencies, police, prosecutors, courts are able to make a wide range of administrative actions against the technology:

* Police can request ISP for **historical data** (session, connections, translations) by different criterias. For example police could request the list of 'UDP traffic initiators with udp.dport=30303 and ip.dst=[bootstrap nodes list] for period of time sorted in descending order'. ISP typically discloses all the data by such request including the copy of ID, address of the physical location, address of the registration and other significant details about the person. Agencies often have a direct access to such information systems or have a curator at the ISP staff who makes such requests treated smoothly.

* Special agencies can order **traffic mirroring** for specific pattern or user session. The 'Lawful interception' often implemented transparently for ISP with special management system so ISP operations staff can't see which traffic is under agencies supervision. Despite the feature name, such sniffing has nothing to do with the law, not backed up by court decision and agencies sometimes abuse their authorities.

* Specific IP address, domain, application, URI **can be blacklisted** (often without court decision, just by supervisory authority). Some countries have the special registries and management systems to automatically enforce blacklists on all the ISPs networks. Such technical measures are often accompanied  strict supervision regarding blacklists enforcement - special monitoring agents placed on ISP network to constantly monitor this. If blacklisted resource found reachable by any reason, regulator imposes significant fine on ISP up to license withdrawal.

* The entire country can be intentionally **disconnecting from the global network**. For example, during the 2011 Tahrir Square protests, the Egyptian government [cut off Egypt's connections](https://www.wired.com/2011/01/egypt-isp-shutdown/) to the rest of the internet. This was possible because Egypt's internet is hugely monopolized and links to the outside world are controlled by several large companies.  Such national-scale network split could potentially have a massive negative impact on the blockchain.
 
The target base network design should have independent 'backdoor' options to pass the messages between nodes. It is technically feasible to keep nodes connected despite of fiber cuts (using radios, satellites, private cable spans). Current model of the internet doesn't allow persons to organize and maintain peering relations, nobody is permitted to get IP prefix from Regional Internet Registry for personal use, nobody allowed to connect Internet exchange, nobody able to advertise his globally unique prefix to become an independent transit ISP. With proposed solution this will be possible by design.

### Optimizations for network performance

#### Current internet's traffic pattern

Current internet is built and optimized for client-server paradigm (for South-North or Up-Down traffic direction). If you watch video from Netflix or upload large file to Amazon Storage, the performance is really amazing. But if you try to establish direct connection with your neighbor (which is located at the same building as you and connected through the same ISP) you probably find it's impossible (no route to host or ICMP unreachable returned). The well-known design patterns of Access and Aggregation ISP networks tend to bring all the traffic up to the central service node. Then traffic authenticated and authorized, service policies enforced (bandwith, limits) and traffic pushed towards Cloud-/Content-/OTT-providers edge nodes. The share of West-East (Right-Left) connections in current internet is absolutely tiny, just a little amount of traffic destined to the individual hosts so ISPs don't consider it at all. The new approach guarantees better alignment for individual peering.

#### Barriers for direct peering

If you look at the peers list of your node you probaly find the most node addresses reported by bootnodes are unreachable in fact. The reason of this is the nontransitive relations between two nodes and the bootnode server. For example ClientA connects to the bootnode (ClientA IS available from the bootnode), then ClientB connects to the bootnode (ClientB IS available from the bootnode too). But it doesn't always mean ClientA and ClientB can reach each other - in IPv4 networks **direct p2p connectivity is rarely feasible**. The new design should implement higher degree of transparent connectivity.

##### Stateful packet filters and NAT44

Network devices such as consumer routers typically implement Network Address Translation (NAT) and stateful firewall as the default security measure for users behind it. They typically forward only the packets requested from the inside. If unsolicited packet comes from the internet, the stateful firewall (or NAT engine) doesn't pass it into the LAN so **the node has no chance to receive it**. To allow this traffic user should 'expose' specific ports to the outside (configure destination NAT rules for specific port). This need explicit router configuration and some networking skills. There is the protocol for automatic port exposition on node start (UPNP protocol theoretically allows this), but it rarely works and doesn't make sense if NAT444 in place.

##### NAT 444 (double NAT44)

Since IPv4 address space exhausted in 2011 a lot of ISPs were denied to allocate new large blocks of globally unique IP addresses. To satisfy the needs of growing subscriber base, a lot of providers implemented one more level of NAT. In addition to the first NAT on subscriber's gateway, providers assigned private addresses for the gateways and enforced the second NAT at the provider's edge routers (this is often called Carrier-Grade NAT). There is a different techniques of such address translation, some of them are primitive stateless and un-configurable packet header rewrite engines. As the result, the packet between the individual hosts should successfully traverse from 2 to 4 NATs in the usual case and **rarely able to reach target**. According to the author's observations running his own node as the typical user over NAT444, the best performance have the peers hosted at Cloud providers such Google cloud, Amazon and Azure virtual machines by the reasons mentioned above - they have the perfect connectivity. The trend to host the applications at major cloud providers is alarming - it leads to further **centralization of the global Ethereum infrastructure**.

## Specification

The solution for problems described above is not trivial and should be discussed within the community and described in specific EIPs each. We propose just an approximate, high-level list of points to start moving this direction:

* **IPv6-capable nodes** - in addition to existing node discovery over IPv4, the IPv6 stack should be implemented, IPv6 bootnodes should be deployed and added to the bootnodes list. IPv6 provides better end-to-end connectivity (no NAT), this address family has a good support over the routing and switching gear, has much larger address space so perfectly suits distributed applications;

* **Subprotocol for node discovery** - need to implemented peer discovery mechanism on the local link and some option to report its functional capabilities (router, probe or stub peer);

* **Routing protocol(s)** - router nodes need to exchange detaled network topology information with the neighboring routers. Keeping in mind the extended requirements for network visibility (for reliable measurement of the connections quality for reward/penalty), [Link-Stale routing protocol](https://en.wikipedia.org/wiki/Link-state_routing_protocol) such as [OSPFv3](https://tools.ietf.org/html/rfc5340) with [LSA extentions](https://tools.ietf.org/html/draft-ietf-ospf-ospfv3-lsa-extend-14) could be considered as the choice. Link state advertisements should propagate actual data about nodes, links with the associated characteristics (cost, bandwidth, delay, stability, loss, load and so on). For scalability reasons, the [Distance-Vector protocol](https://en.wikipedia.org/wiki/Distance-vector_routing_protocol) such as BGP could be implemented for global routing exchange.

* All the data (including both signalling and payload packets from kernel stack) should be **natively encrypted** with strong cryptography before get off the port. However we should avoid redundant overlay techniques (where encrypted tunnel encapsulated into other encrypted tunnel and so on) to keep the network performant and suitable for peer-to-peer patterns. The preferred way is to adapt the security model of IPv6 making use of [Cryptographically Generated Address (CGA)](https://www.ietf.org/rfc/rfc3972.txt), and [native security protocols](https://tools.ietf.org/html/rfc4301): AH (authentication header) and ESP (Encapsulating Security Payload).

* **Smart contract for Customer/Provider peering relations** - Each router node should be rewarded for passing transit traffic sourced from another node. These relations could be established by the smart contracts where parties agree the price and the service level similarly to the typical contract between ISP and it's customer. To make Ethereum unconditionally operational, all the internal signalling between neighboring nodes should be transmitted unconditionally.

* **Smart contract for IP address assignment and delegation** - node should be able to deposit some reasonable amount of Ether to 'rent' IP address prefix. The prefix can be assigned to the node or another smart contract for subordinate prefixes redistribution.

* **Mechanism for routing reward** - good routers (which actual service quality satisfies reported metrics) should take fair reward for it. Bad behaving actors should be penalized for poor quality of service (flapping channels, non-stable quality, packet loss, lower actual bandwith compared to reported). 

* **Timing distribution** - proper clock syncronization between nodes is mandatory for Ethereum ecosystem so the nodes need to implement native precision time distribution protocol, strong yet simple timing consensus algorithm.

* **Accurate end-to end service measurement** - special nodes should implement in-band service quality measurements to provide reliable information regarding routers behavior (actual loss, delay, traffic delivery rate) and the level of trust to measurements. This protocol should be natively mixed with the payload to be treated equally by the transit nodes and avoid cheating. Need to implement mathematical algorithm of failure link search in minimal iterations, consensus mechanism regarding the point of failure, procedure of the results feedback to enforce rewards/penalties. Such intensive packet processing is the resource-intensive operation so the service measurement node should be rewarded for its operation (and penalized for cheating). 

* **Link failure detection protocol** - routing node should be able to identify the problems on link (packet loss, unexpected jitter or delay) in terms of milliseconds similar to CFM/BFD in traditional networks. 

* **Network stack for endpoint operating systems** - OS should be able to keep local IPv6 routing table consistent to the path reported by the node and correctly route the packets for Ethereum destinations. DNS resolver should be able to resolve .eth domains through the node, other TLDs should be resolved by conventional DNS servers.

* **Reference routing node** - to proliferate routing incentives we should build reference router and probe implementing Ethereum-based control plane. The node should support existing routing protocols such as OSPF, IS-IS, BGP (existing solutions could be taken as the reference such as [Quagga](https://en.wikipedia.org/wiki/Quagga_(software))). Routing node should be able to route IPv6 packets between new-standard and traditional 'islands' and provide some kind of redistribution between them.

* **High-performance routing node** - Open standard for high-performance router platform should be designed for the most common hardware platforms. The forwarders can be built around [Software-Defined Networking](https://en.wikipedia.org/wiki/Software-defined_networking) principles. Cheap commertial off-the-shelf [OpenFlow](https://en.wikipedia.org/wiki/OpenFlow) switches could be used as the high-performance routing gear or custom protocols can be implemented with different dataplane vendor kits such as [Broadcom OFDPA](https://www.broadcom.com/products/ethernet-connectivity/software/of-dpa#specifications).. It's probably feasible to use  x86 platform with [Intel DPDK](http://dpdk.org) or other high-performance packet processor under the hood.

## Rationale

* This EIP is written upon the results of face-to-face discussion with Vitalik Buterin at Phys Tech Institute, Moscow which took place 30.08.2017. Vitalik agreed that such a proposal should be considered as EIP.

* The disadvantages of the current network stack were discussed in 'research' and 'p2p' gitter channels during the in july, 2017. 

## Backwards Compatibility

* This EIP is proposed keeping in mind strong backward compatibility with the current standards of the internet;

* The global routing of the internet is unaffected (the proposed design should operate in parallel for long);

* Changes to the enpoints operating systems network stack will affect just a minimal subset of its functionality: domain resolution of .eth TLD and numerous IPv6 prefixes treated special way;

* The name resolution of current TLDs domains should stay on conventional DNS system. .ETH TLD and its subdomains should be resolved by the Ethereum stack; 

* To avoid global name overlaps, the Foundation should justify some changes to base RFCs such as https://tools.ietf.org/html/rfc1591 to allow domain delegation to the Ethereum Smart Contract (the term 'designated manager' should be redefined to allow this);

* Current globally IANA-assigned IPv6 prefixes should be routed as usual. Ethereum-owned prefixes should be delegated and routed by the Ethereum stack;

* To achieve this, Ethereum Foundation should justify IANA to assign it a significant block of addresses to the 'root' smart contract. Probably RFC changes needed to define Smart Contract as IPv6-address management entity;

* Lots of the ideas and described principles do already exist in the networking world and need to be ported into the Ethereum stack.

## Implementation

Not implemented

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
