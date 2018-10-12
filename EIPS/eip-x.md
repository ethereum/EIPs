---
eip: TBD
title: Digital Identity Aggregator
author: Anurag Angara <anurag.angara@gmail.com>, Andy Chorlian <andychorlian@gmail.com>, Shane Hampton <shanehampton1@gmail.com>, Noah Zinsmeister <noahwz@gmail.com>
discussions-to: https://github.com/ethereum/EIPs/issues/TBD
status: Draft
type: Standards Track
category: ERC
created: 2018-10-12
---

## Simple Summary
A protocol for aggregating digital identity information that's broadly interoperable with existing, proposed, and hypothetical future digital identity standards.

## Abstract
This EIP proposes an identity management and aggregation framework on the Ethereum blockchain. It allows entities to claim an identity via a singular `Identity Registry` smart contract, associate this identity with Ethereum addresses in a meaningful way, and use it to interface with smart contracts, enabling arbitrarily complex identity-related functionality.

## Motivation
Emerging identity standards and related frameworks proposed by the Ethereum community (including ERCs/EIPs [725](https://github.com/ethereum/EIPs/issues/725), [735](https://github.com/ethereum/EIPs/issues/735), [780](https://github.com/ethereum/EIPs/issues/780), [1056](https://github.com/ethereum/EIPs/issues/1056), etc.) define and instrumentalize individuals' digital identities in a variety of ways. As existing approaches mature, new standards emerge, and isolated, non-standard approaches to identity develop, managing multiple identities will become increasingly burdensome and involve unnecessary duplication of work.

The proliferation of on-chain identity solutions can be traced back to the fact that each has codified a notion of identity and linked it to specific aspects of Ethereum (claims protocols, per-user smart contracts, signature verification schemes, etc.). This proposal eschews that approach, instead introducing a protocol layer in between the Ethereum network and individual identity applications. This solves identity management and interoperability challenges by enabling any identity-driven application to leverage an un-opinionated identity management protocol.

## Definitions
- `Identity Registry`: A single smart contract which is the hub for all user `Identities`. The primary responsibility of the `Registry` is to enforce a global namespace for identities, which are individually denominated by `uint` Ethereum Identification Numbers (EINs).

- `Identity`: The core data structure that constitutes a user's identity. Identities are denominated by EINs which are unique but uninformative. Each `Resolver` added to an `Identity` makes the `Identity` more informative.

- `Associated Address`: An Ethereum address publicly associated with an `Identity`. In order for an address to become an `Associated Address` for an `Identity`, the `Identity` must produce:

  - a signed message from the candidate address indicating intent to associate itself with the `Identity`
  - a signed message from an existing `Associated Address` of the `Identity` indicating the same.

 `Identities` can remove an `Associated Address` by producing a signed message indicating intent to disassociate itself from the `Identity`. Signatures are stored in the `Registry` to prevent replay attacks.

- `Provider`: An Ethereum address (typically but not by definition a smart contract) authorized to add and remove `Associated Addresses`, `Providers`, and `Resolvers` from the `Identities` of users who have authorized the `Provider` to act on their behalf. `Providers` exist to facilitate end users adoption, and make it easy to manage identities.

- `Resolver`: A smart contract containing arbitrary information pertaining to users' `Identities`. A resolver may implement an identity standard, such as ERC 725, or may consist of a smart contract leveraging or declaring any identifying information about `Identities`. These could be simple attestation structures or more sophisticated financial dApps, social media dApps, etc.

- `Recovery Address`: An Ethereum address (either an account or smart contract) that can be used to recover lost identities as outlined in the [Recovery](#recovery) section.

- `Poison Pill`: In the event of irrecoverable control of an `Identity`, the `Poison Pill` offers a contingency measure to disable the `Identity`. It removes all `Associated Addresses` and `Providers` while preserving the `Identity` (and optionally, `Resolvers`). Evidence of the existence of the `Identity` persists, while control over the `Identity` is nullified.

## Specification
A digital identity in this proposal can be viewed as an omnibus account, containing more information about an identity than any individual identity application could. This omnibus identity is resolvable to an unlimited number of sub-identities called `Resolvers`. `Resolvers` recognize identities by any of their associated addresses. The protocol allows for an atomic entity, the `Identity`, to be resolvable to abstract data structures, the `Resolvers`.

The protocol revolves around claiming an `Identity` and managing `Associated Addresses` and `Resolvers`. Identities delegate much of this responsibility to one or more `Providers`. `Provider` smart contracts or addresses may add and remove `Resolvers` indiscriminately, and may only add and remove `Associated Addresses` or other `Providers` with the appropriate permissions.

### Identity Registry
The Identity Registry contains functionality for a user to establish their core identity and manage their `Providers`, `Associated Addresses`, and `Resolvers`. It is important to note that this registry fundamentally requires transactions for every aspect of building out a user's identity. Nonetheless, we recognize the importance of global accessibility to dApps and identity applications. Accordingly, we include the option for a delegated identity-building scheme that allows smart contracts called `Providers` to build out a user's identity through signatures without requiring users to pay gas costs.

Due to the fact that multiple addresses can be associated with a given identity (though not the reverse), `Identities` are denominated by EINs. This `uint` can be encoded in QR format or transformed into more user-intuitive formats, such as a `string`, in registries at the `Provider` or `Resolver` levels.

### Address Management
The address management function consists of trustlessly connecting multiple user-owned `Associated Addresses` to a user's `Identity`. It does not prescribe any special status to any given `Associated Address` address, rather leaving this specification to identity applications built on top of the protocol - for instance, `management`, `action`, `claim` and `encryption` keys denominated in the ERC 725 standard or `Identifiers`, and `delegates` as denominated in ERC 1056. This allows a user to access common identity data from multiple wallets while still:

- retaining flexibility to interact with contracts outside of their identity
- taking advantage of address-specific permissions established at the application layer of a user's identity.

Trustlessness in the address management function is achieved through a signature and verification scheme that requires two signatures - one from an address already within the registry and one from the address to be claimed. Importantly, the transaction need not come from the original user, which allows entities, governments, etc. to bear the overhead of creating a core identity. To prevent a compromised `Associated Address` from unilaterally removing other `Associated Addresses`, removal of an `Associated Address` also requires a signature from the address to be removed.


### Resolver Management
The resolver management function is similarly low-level. A resolver is any smart contract that encodes information which resolves to a user's core identity. We remain agnostic about the specific information that can be encoded in a resolver and the functionality that this enables.

The existence of resolvers is primarily what makes this ERC an identity *protocol* rather than an identity *application*. `Resolvers` resolve abstract data in smart contracts to an atomic entity, the `Identity`.

### Provider Management
While the protocol allows for users to directly call identity management functions, it also aims to be more robust and future-proof by allowing arbitrary smart contracts to perform identity management functions on a user's behalf. A provider set by an identity can perform address management and resolver management functions by passing the user's `Identity` in function calls. In order to prevent identities from adding an initial `Provider` that does not implement the functionality to add other `Providers`, identities may add `Providers` directly from the `Registry`.

### Recovery
The specification includes a `Recovery Address` to account for instances of lost user control over an `Associated Address`. Upon `Identity` creation, the public `Recovery Address` is passed as a parameter by a provider. Identity recovery functionality is triggered in three scenarios.

**Changing Recovery Key**: If a recovery key is lost, a provider can [initiateRecoveryAddressChange](#initiaterecoveryaddresschange) through a Provider. To prevent malicious behavior from someone who has gained control of an `Associated Address` or `Provider`, this triggers a 14 day challenge period during which the old `Recovery Address` may reject the change. If the `Recovery Address` does not reject the change within 14 days, the `Recovery Address` is changed. However, during the fourteen day period, the `Recovery Address` can dispute the change request by calling [triggerRecovery](triggerrecovery).

**Recovery**: Recovery occurs when a user recognizes that an `Associated Address` or the `Recovery Address` belonging to the user is lost or stolen. In this instance Identities call [triggerRecovery](triggerrecovery) from the `Recovery Address`. This removes all `Associated Addresses` and `Providers` from the corresponding `Identity` and replaces them with an address passed in the function call. The `Identity` and associated `Resolvers` maintain integrity. The user is now responsible for adding the appropriate un-compromised addresses back to their `Identity` in the `Registry`.

**Poison Pill**
The Recovery scheme offers considerable power to a `Recovery Address`; accordingly, `triggerPoisonPill` is a nuclear option to combat malicious control over an `Identity` when a `Recovery Address` is compromised. If a malicious actor compromises a user's `Recovery Address` and triggers recovery, any address removed in the `Recovery` process can `triggerPoisonPill` within 14 days to permanently disable the `Identity`. The user would then need to create a new `Identity`, and would be responsible for engaging in recovery schemes for any Identity Applications built in the application layer.

#### Alternative Recovery Considerations
In devising the Recovery process outlined in this specification, we considered many Recovery options. We ultimately selected the scheme that was most un-opinionated and modular to be consistent with the the `Associated Address`, `Provider`, and `Resolver` components within the specification. Still, we feel it important to highlight some of the other recovery options considered to provide deeper rationale as to why we arrived at the above scheme.

**High Level Concerns**
Fundamentally, a Recovery scheme needed to be resilient to a compromised address taking control of a user's `Identity`. A secondary concern was preventing a compromised address from maliciously destroying a user's identity due to off-chain utility, which is not an optimal scenario, but is strictly better than if they've gained control.  

**Nuclear Option**
This approach would allow any `Associated Address` to destroy an `Identity` whenever another `Associated Address` is compromised. While this may seem harsh, we held it in strong consideration due to the fact that this ERC is a protocol rather than an Identity *application*. Accordingly, once a user destroyed their compromised `Identity`, they would need to use whatever restoration mechanisms were available in each of their actual identities. We ultimately dismissed this approach for two main reasons.

- It is not robust for instances in which a user has only one `Associated Address`
- It would increase the frequency of recovery requests for applications of identity due to the multiple addresses any of which could be compromised.


**Unilateral Address Removal from a provider**
This would allow providers to remove an `Associated Address` without a signature from the `Associated Address`. To prevent a compromised address from setting a malicious provider to remove un-compromised addresses, this would require a waiting period between when a provider is set and when a provider is able to remove an `Associated Address`. This implementation would allow a provider to include arbitrarily sophisticated Recovery schemes - for instance, multi-sig requirements, centralized off-chain verification, user controlled master addresses, deferral to a jurisdictional contract, or more. We dismissed this approach because we felt it placed too high of a burden on `Providers`. If a `Provider` offered a sophisticated range of functionality to a user, but post-deployment a threat was found in the Recovery logic of the provider, provider-specific infrastructure would need to be rebuilt. We considered including a flag that allows a user to determine if a provider may or may not remove `Associated Addresses`; however, we ultimately concluded that breaking out removal of an `Associated Address` into a `Recovery Address` allows for equally sophisticated recovery logic while separating the functionality from providers and leaving less room for users to relinquish control to poorly implemented providers.

*Importantly, the recovery address can be a user-controlled wallet or another address such as a multisig wallet or a smart contract address. This allows for more sophisticated recovery structures that can be compliant with identity standards for recovery such as those laid out by DID.*

## Rationale
We find that at a protocol layer, identity should contain no claim or attestation structure and should rather simply lay a trustless framework upon which arbitrarily sophisticated claim and attestation structures may be based.

The main criticism of an identity layer comes from restrictiveness; we aim to limit requirements to be modular and future-proof without providing any special functionality for any component within the core registry. It simply allows users the option to interact on the blockchain using an arbitrarily robust identity rather than just an address.

## Implementation
[**The reference implementation for the ERC may be found in this public repository.**](https://github.com/hydrogen-dev/identity-erc)

#### identityExists

Returns a `bool` indicating whether or not an `Identity` denominated by the passed `ein` string exists.

```solidity
function identityExists(uint ein) public view returns (bool);
```

#### hasIdentity

Returns a `bool` indicating whether or not the passed `_address` is associated with an `Identity`.

```solidity
function hasIdentity(address _address) public view returns (bool);
```

#### getIdentity

Returns the `ein` associated with the passed `_address`. Throws if no such `ein` exists.

```solidity
function getEIN(address _address) public view returns (uint ein);
```

#### isProviderFor

Returns a `bool` indicating whether or not the passed `provider` is assigned to the passed `ein`.

```solidity
function isProviderFor(uint ein, address provider) public view returns (bool);
```

#### isResolverFor

Returns a `bool` indicating whether or not the passed `resolver` is assigned to the passed `ein`.

```solidity
function isResolverFor(uint ein, address resolver) public view returns (bool);
```

#### isAddressFor

Returns a `bool` indicating whether or not the passed `_address` is owned by the passed `ein`.

```solidity
function isAddressFor(uint ein, address _address) public view returns (bool);
```

#### getDetails

Returns three `address` arrays of `associatedAddresses`, `providers` and `resolvers`. All of these arrays represent the addresses associated with the passed `ein`.

```solidity
function getDetails(uint ein) public view returns (address[] associatedAddresses, address[] providers, address[] resolvers);
```

#### mintIdentity

Mints an `Identity` with the passed `ein` and `provider`.

```solidity
function mintIdentity(address recoveryAddress, address provider, address[] resolvers) public returns (uint ein);
```

#### mintIdentityDelegated

Preforms the same logic as `mintIdentity`, but can be called by a `provider`. This function requires a signature for the `associatedAddress` to confirm their consent.

```solidity
function mintIdentityDelegated(address recoveryAddress, address associatedAddress, address[] resolvers, uint8 v, bytes32 r, bytes32 s) public returns (uint ein);
```

#### addProviders

Adds an array of `providers` to the `Identity` of the `msg.sender`.

```solidity
function addProviders(address[] providers) public;
```

#### removeProviders

Removes an array of `providers` from the `Identity` of the `msg.sender`.

```solidity
function removeProviders(address[] providers) public;
```

Triggers event: [ProviderRemoved](#providerremoved)

#### removeProviders

Removes an array of `providers` from the `Identity` of the `ein` passed.

```solidity
function removeProviders(uint ein, address[] providers, address approvingAddress, uint8 v, bytes32 r, bytes32 s, uint salt) public;
```

Triggers event: [ProviderRemoved](#providerremoved)

#### addResolvers

Adds an array of `resolvers` to the passed `ein`. This must be called by a `provider`.

```solidity
function addResolvers(uint ein, address[] resolvers) public;
```

#### removeResolvers

Removes an array of `resolvers` from the passed `ein`. This must be called by a `provider`.

```solidity
function removeResolvers(uint ein, address[] resolvers) public;
```

#### addAddress

Adds the `addressToAdd` to the passed `ein`. Requires signatures from both the `addressToAdd` and the `approvingAddress`.

```solidity
function addAddress(uint ein, address approvingAddress, address addressToAdd, uint8[2] v, bytes32[2] r, bytes32[2] s, uint salt) public;
```

#### removeAddress

Removes an `addressToRemove` from the passed `ein`. Requires a signature from the `addressToRemove`.

```solidity
function removeAddress(uint ein, address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint salt) public;
```

Triggers event: [AddressRemoved](#addressremoved)

#### initiateRecoveryAddressChange

Initiates a change in the current `recoveryAddress` for a given `ein`.

```solidity
function initiateRecoveryAddressChange(uint ein, address newRecoveryAddress) public;
```

Triggers event: [RecoveryAddressChangeInitiated](#recoveryaddresschangeinitiated)

#### triggerRecovery

Initiates `ein` recovery from the current `recoveryAddress`.

```solidity
function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s) public;
```

Triggers event: [RecoveryTriggered](#recoverytriggered)

#### triggerPoisonPill

Initiates the `poison pill` on an `ein`. This will render the `Identity` unusable.

```solidity
function triggerPoisonPill(uint ein, address[] firstChunk, address[] lastChunk, bool clearResolvers) public;
```

Triggers event: [Poisoned](#poisoned)

### Events

#### IdentityMinted

MUST be triggered when an `Identity` is minted.

```solidity
event IdentityMinted(uint ein, address associatedAddress, address provider, bool delegated);
```

#### AddressAdded

MUST be triggered when an address is added to an `Identity`.

```solidity
event AddressAdded(uint indexed ein, address addedAddress, address approvingAddress, address provider);
```

#### AddressRemoved

MUST be triggered when an address is removed from an `Identity`.

```solidity
event AddressRemoved(uint indexed ein, address removedAddress, address provider);
```

#### ProviderAdded

MUST be triggered when a provider is added to an `Identity`.

```solidity
event ProviderAdded(uint indexed ein, address provider, bool delegated);
```

#### ProviderRemoved

MUST be triggered when a provider is removed.

```solidity
emit ProviderRemoved(uint indexed ein, address provider, bool delegated);
```

#### ResolverAdded

MUST be triggered when a resolver is added.

```solidity
event ResolverAdded(uint indexed ein, address resolvers, address provider);
```

#### ResolverRemoved

MUST be triggered when a resolver is removed.

```solidity
event ResolverRemoved(uint indexed ein, address resolvers, address provider);
```

#### RecoveryAddressChangeInitiated

MUST be triggered when a recovery address change is initiated.

```solidity
event RecoveryAddressChangeInitiated(uint indexed ein, address oldRecoveryAddress, address newRecoveryAddress);
```

#### RecoveryTriggered

MUST be triggered when recovery is initiated.

```solidity
event RecoveryTriggered(uint indexed ein, address recoveryAddress, address[] oldAssociatedAddress, address newAssociatedAddress);
```

#### Poisoned

MUST be triggered when an `Identity` is poisoned.

```solidity
event Poisoned(uint indexed ein, address poisoner, bool resolversCleared);
```


### Solidity Interface
```solidity
pragma solidity ^0.4.24;

contract ERCTBD {

  event IdentityMinted(uint ein, address associatedAddress, address provider, bool delegated);
  event AddressAdded(uint indexed ein, address addedAddress, address approvingAddress, address provider);
  event AddressRemoved(uint indexed ein, address removedAddress, address provider);
  event ProviderAdded(uint indexed ein, address provider, bool delegated);
  event ProviderRemoved(uint indexed ein, address provider, bool delegated);
  event ResolverAdded(uint indexed ein, address resolvers, address provider);
  event ResolverRemoved(uint indexed ein, address resolvers, address provider);
  event RecoveryAddressChangeInitiated(uint indexed ein, address oldRecoveryAddress, address newRecoveryAddress);
  event RecoveryTriggered(uint indexed ein, address recoveryAddress, address[] oldAssociatedAddress, address newAssociatedAddress);
  event Poisoned(uint indexed ein, address poisoner, bool resolversCleared);

  struct Identity {
    AddressSet.Set associatedAddresses;
    AddressSet.Set providers;
    AddressSet.Set resolvers;
  }

  function identityExists(uint ein) public view returns (bool);

  function hasIdentity(address _address) public view returns (bool);
  function getEIN(address _address) public view returns (uint ein);

  function isProviderFor(uint ein, address provider) public view returns (bool);
  function isResolverFor(uint ein, address resolver) public view returns (bool);
  function isAddressFor(uint ein, address _address) public view returns (bool);

  function getDetails(uint ein) public view returns (address[] associatedAddresses, address[] providers, address[] resolvers);

  function mintIdentity(address recoveryAddress, address provider, address[] resolvers) public returns (uint ein);
  function mintIdentityDelegated(address recoveryAddress, address associatedAddress, address[] resolvers, uint8 v, bytes32 r, bytes32 s) public returns (uint ein);

  function addProviders(address[] providers) public;
  function removeProviders(address[] providers) public;
  function removeProviders(uint ein, address[] providers, address approvingAddress, uint8 v, bytes32 r, bytes32 s, uint salt) public;

  function addResolvers(uint ein, address[] resolvers) public;
  function removeResolvers(uint ein, address[] resolvers) public;

  function addAddress(uint ein, address approvingAddress, address addressToAdd, uint8[2] v, bytes32[2] r, bytes32[2] s, uint salt) public;
  function removeAddress(uint ein, address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint salt) public;

  function initiateRecoveryAddressChange(uint ein, address newRecoveryAddress) public;
  function triggerRecovery(uint ein, address newAssociatedAddress, uint8 v, bytes32 r, bytes32 s) public;
  function triggerPoisonPill(uint ein, address[] firstChunk, address[] lastChunk, bool clearResolvers) public;
}
```
## Backwards Compatibility
`Identities` established under this standard consist of existing Ethereum addresses; accordingly, identity construction has no backwards compatibility issues. Deployed, non-upgradeable smart contracts that wish to become `Resolvers` to a user's `ein` will need to write wrapper contracts that resolve addresses to `Identities` with `getEIN`.

## Additional References

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
