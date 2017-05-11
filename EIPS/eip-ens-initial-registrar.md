**Some of the parameters and mechanisms in this document are outdated with respect to the version deployed on the main net. Until this notice is removed or updated, please refer to [ReadTheDocs](http://docs.ens.domains/en/latest/userguide.html?highlight=auction#registering-a-name-with-the-auction-registrar) or natspec comments in the [deployed code](https://github.com/ethereum/ens/blob/mainnet/contracts/HashRegistrarSimplified.sol).**

```
EIP: Draft
Title: Initial ENS Hash Registrar
Author: J. Maurelian and Nick Johnson
Status: Draft
Type: Informational
Created: 2016-10-25
```
## Contents
- Abstract
- Motivations
- Specification
  - Initial restrictions
  - Name format for hash registration
  - Auctioning names
  - Deeds
  - Deployment and Upgrade process
  - Registrar Interface
- Rationale
  - Not committing to a permanent registrar at the outset
  - Valid names >= 7 characters
  - Restricting TLD to `.eth`
  - Holding ether as collateral
- Prior work

<!-- /MarkdownTOC -->
## Abstract

This ERC describes the implementation of a registrar contract to govern the allocation of names in the Ethereum Name Service (ENS). For background, refer to [EIP 137](https://github.com/ethereum/EIPs/issues/137).

> Registrars are responsible for allocating domain names to users of the system, and are the only entities capable of updating the ENS; the owner of a node in the ENS registry is its registrar. Registrars may be contracts or externally owned accounts, though it is expected that the root and top-level registrars, at a minimum, will be implemented as contracts.
>
> \- EIP 137

A well designed and governed registrar is essential to the success of the ENS described in EIP 137, but is described separately in this document as it is external to the core ENS protocol.

In order to maximize utility and adoption of a new namespace, the registrar should mitigate speculation and "name squatting", however the best approach for mitigation is unclear. Thus an "initial" registrar is proposed, which implements a simple approach to name allocation. During the initial period, the available namespace will be significantly restricted to the `.eth` top level domain, and subdomain shorter than 7 characters in length disallowed. This specification largely describes @alexvandesande's [hash registrar implementation](https://github.com/Arachnid/ens/blob/master/HashRegistrarSimplified.sol) in order to facilitate discussion. His [design mockups](https://projects.invisionapp.com/share/FE93G2K3Y#/screens/200024092) are also very helpful for understanding the flow

This Initial Registrar contract will be replaced with a permanent registrar contract. The Permanent Registrar will increase the available namespace, and incorporate lessons learned from the performance of the Initial Registrar. This upgrade is expected to take place within approximately 2 years of initial deployment.
## Motivations

The following factors should be considered in order to optimize for adoption of the ENS, and good governance of the Initial Registrar's namespace.

**Upgradability:** The Initial Registrar should be safely upgradeable, so that knowledge gained during its deployment can be used to replace it with an improved and permanent registrar.

**Effective allocation:** Newly released namespaces often create a land grab situation, resulting in many potentially valuable names being purchased but unused, with the hope of re-selling at a profit. This reduces the availability of the most useful names, in turn decreasing the utility of the name service to end users.

Achieving an effective allocation may or may not require human intervention for dispute resolution and other forms of curation. The Initial Registrar should not aim to create to most effective possible allocation, but instead limit the cost of misallocation in the long term.

**Security:** The registrar will hold a balance of ether without an explicit limit. It must be designed securely.

**Simplicity:** The ENS specification itself emphasizes a separation of concerns, allowing the most essential element, the registry to be as simple as possible. The interim registrar in turn should be as simple as possible while still meeting its other design goals.

**Adoption:** Successful standards become more successful due to network effects. The registrar should consider what strategies will encourage the adoption of the ENS in general, and the namespace it controls in particular.
## Specification
### Initial restrictions

The Initial Registrar is expected to be in service for approximately two years, prior to upgrading. This should be sufficient time to learn, observe, and design an updated system.

During the initial two year period, the available name space will be restricted to the `.eth` TLD.

This restriction is not implemented by the registrar, but rather by the owner of the ENS root node who should not assign any nodes other than `.eth` to the Initial Registrar. The ENS's root node should be controlled by multiple parties using a multisig contract.

The Initial Registrar will also prohibit registration of names shorter than the `minNameLength` parameter. The value of `minNameLength` will be 7 initially. This value will be reducible by a call from owner of the ENS's root node.
### Name format for hash registration

Names submitted to the initial registrar must be hashed using Ethereum's sha3 function. Note that the hashes submitted to the registrar are the hash of the subdomain label being registered, not the namehash as defined in EIP 137.

For example, in order to register `abcdefg.eth`, one should submit `sha3('abcdefg')`, not `sha3('abcdefg', sha3('eth', 0))`.
### Auctioning names

The registrar will allocate the available names through a Vickrey auction:

> A Vickrey auction is a type of sealed-bid auction. Bidders submit written bids without knowing the bid of the other people in the auction. The highest bidder wins but the price paid is the second-highest bid. This type of auction... gives bidders an incentive to bid their true value.
>
> \- [Vickrey Auction, Wikipedia](https://en.wikipedia.org/wiki/Vickrey_auction)

The timeline of the auction will be implemented as follows:
1. The hash of the desired name is submitted to the Initial Registrar, and bidding is opened on the hash.
2. The auction will last 5 days, except for auctions started during the first 3 weeks after deployment of the Initial Registrar, which will last until the end of the 4th week.
3. Bidders submit a payment of ether, along with sealed bids as a hash of `sha3(bytes32 hash, address owner, uint value, bytes32 salt)`. The transaction can obfuscate the true bid value by sending a greater amount of ether.
4. All bids must be received before the start of the final 48 hours of the auction, which is the reveal period. During this time, bidders must submit the true parameters of their sealed bid. As bids are revealed, ether payments are returned according to the schedule of "refund ratios" outlined in the table below.
5. After the 48 hour reveal period has finished, the Initial Registrar's `finalizeAuction` function can be called, which then calls the ENS's `setSubnodeOwner` function, recording the winning bidder's address as the owner of the hash of the name.

### Deeds

The Initial Registrar contract does not hold a balance itself. All ether sent to the Registrar will be held in separate deed contracts. Deeds are initially associated with a bidder and their sealed bid. After an auction is completed and a hash is registered, the deed for the winning bid is held in exchange for ownership of the hash.

After 1 year of registration, the owner of a hash may choose to relinquish ownership and have the value of the deed returned to them. A deed for an owned hash may also be transferred to another account by its owner.

Deeds for non-winning bid can be closed by various methods, at which time any ether held will either be returned to the bidder, burnt, or sent to someone else as a reward for actions which help the registrar.

The following table outlines what portion of the balance held in a deed contract will be returned upon closure, and to whom. The remaining balance will be burnt.

| Reason for Deed closure | Refund Recipient | Refund Percentage |
| --- | --- | --- |
| A valid non-winning bid is unsealed. | Bidder | 99.9% |
| An invalid bid is unsealed. | Bidder | 1% |
| A sealed bid is cancelled. <sup>1</sup> | Canceler | 0.5% |
| An registered hash is reported as invalid. <sup>2</sup> | Reporter | 10% |
##### Notes:
1. Bids which remain sealed for at least 12 weeks may be cancelled by anyone to collect a small reward.
2. Since names are hashed before auctioning and registration, the Initial Registrar is unable to enforce character length restrictions independently. A reward is therefore provided for reporting invalid names.
### Deployment and Upgrade process

The Initial Registrar requires the ENS's address as a contructor, and should be deployed after the ENS. The multisig account owning the root node in the ENS should then set the Initial Registrar's address as owner of the `eth` node.

The Initial Registrar is expected to be replaced by a Permanent Registrar approximately 2 years after deployment. The following process should be used for the upgrade:
1. The Permanent Registrar contract will be deployed.
2. The multisig account owning the root node in the ENS will assign ownership of the `.eth` node to the Permanent Registrar.
3. Owners of hashes in the Initial Registrar will be responsible for registering their deeds to the Permanent Registrar. A couple options are considered here:
   1. Require owners to transfer their ownership prior to a cutoff date in order to maintain ownership and/or continue name resolution services.
   2. Have the Permanent Registrar query the Initial Registrar for ownership if it is lacking an entry.

### Planned deactivation

In order to limit dependence on the Initial Registrar, new auctions will stop after 4 years, and all ether held in deeds after 8 years will become unreachable.

### Registrar Interface

`function startAuction(bytes32 _hash);`
- Starts an auction for an available hash. If the hash is already allocated, or there is an ongoing auction,  `startAuction` will throw.

`function startAuctions(bytes32[] _hashes);`
- Starts multiple auctions on an array of hashes. This enables someone to open up an auction for a number of dummy hashes when they are only really interested in bidding for one. This will increase the cost for an attacker to simply bid blindly on all new auctions. Dummy auctions that are open but not bid on are closed after a week.

`function shaBid(bytes32 hash, address owner, uint value, bytes32 salt) constant returns (bytes32 sealedBid);`
- Takes the parameters of a bid, and returns the sealedBid hash value required to participate in the bidding for an auction. This obfuscates the parameters in order to mimic the mechanics of placing a bid in an envelope.

`function newBid(bytes32 sealedBid);`
- Bids are sent by sending a message to the main contract with a sealedBid hash and an amount of ether. The hash contains information about the bid, including the bidded name hash, the bid value, and a random salt. Bids are not tied to any one auction until they are revealed. The value of the bid itself can be masqueraded by sending more than the value of your actual bid. This is followed by a 48h reveal period. Bids revealed after this period will be burned and the ether unrecoverable. Since this is an auction, it is expected that most public hashes, like known domains and common dictionary  words, will have multiple bidders pushing the price up.

`function unsealBid(bytes32 _hash, address _owner, uint _value, bytes32 _salt);`
- Once the bidding period is completed, there is a reveal period during with the properties of a bid are submitted to reveal them. The registrar hashes these properties using the `shaBid()` function above to verify that they match a pre-existing sealed bid. If the unsealedBid is the new best bid, the old best bid is returned to its bidder.

`function cancelBid(bytes32 seal);`
- Cancels an unrevealed bid, forfeiting <!-- X% of--> the funds.

`function finalizeAuction(bytes32 _hash);`

After the registration date has passed, this function can be called to finalize the auction, which then calls the ENS function `setSubnodeOwner()`  updating the ENS record to set the winning bidder as owner of the node.

`function transfer(bytes32 _hash, address newOwner);`
- Update the owner of the ENS node corresponding to the submitted hash to a new owner. This function must be callable only by the current owner.

`function releaseDeed(bytes32 _hash);`
- After some time, the owner can release the property and get their ether back.

`function invalidateName(string unhashedName);`
- Since registration is done on the hash of a name, the registrar itself cannot validate names. This function can be used to report a name which is 6 characters long or less. If it has been registered, the submitter will earn 10% of the deed value. We are purposefully handicapping the simplified registrar as a way to force it into being restructured in a few years.

`function transferRegistrars(bytes32 _hash) onlyOwner(_hash);`
- Used during the upgrade process to a permanent registrar. If this registrar is no longer the owner of the its root node in the ENS, this function will transfers the deed to the current owner, which should be a new registrar. This function throws if this registrar still owns its root node.
## Rationale
### Starting with a temporary registrar

Anticipating and designing for all the potential issues of name allocation names is unlikely to succeed. This approach chooses not to be concerned with getting it perfect, but allows us to observe and learn with training wheels on, and implement improvements before expanding the available namespace to shorter names or another TLD.
### Valid names >= 7 characters

Preserving the shortest, and often most valuable, domain names for the upgraded registrar provides the opportunity to implement processes for dispute resolution (assuming they are found to be necessary).
### Restricting TLD to `.eth`

Choosing a single TLD helps to maximize network effects by focusing on one namespace.

A three letter TLD is a pattern made familiar by it's common usage in internet domain names. This familiarity significantly increases the potential of the ENS to be integrated into pre-existing DNS systems, and reserved as a [special-use domain name](http://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml#special-use-domain).  A recent precedent for this is the [reservation of the `.onion` domain](https://tools.ietf.org/html/rfc7686).
### Holding ether as collateral

This approach is simpler than the familiar model of requiring owners to make recurring payments to retain ownership of a domain name. It also makes the initial registrar a revenue neutral service, and creates a new business model on Ethereum, by enabling owners to rent names as a service.
## Prior work

This document borrows heavily from several sources:
- [EIP 137](https://github.com/ethereum/EIPs/issues/137) outlines the initial implementation of the Registry Contract (ENS.sol) and associated Resolver contracts.
- [ERC 26](https://github.com/ethereum/EIPs/issues/26) was the first ERC to propose a name service at the contract layer
- @alexvandesande's current implementation of the [HashRegistrar](https://github.com/Arachnid/ens/blob/master/HashRegistrarSimplified.sol)
### Edits:
- 2016-10-26 Added link Alex's design in abstract
- 2016-11-01 change 'Planned deactivation' to h3'
- 2017-03-13 Update timelines for bidding and reveal periods
