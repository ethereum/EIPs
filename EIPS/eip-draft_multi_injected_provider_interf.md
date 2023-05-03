---
eip: draft_multi_injected_provider_interf
title: Multi Injected Provider Interface (aka MIPI)
description: Using `window.evmproviders` instead of `window.ethereum`
author: Pedro Gomes (@pedrouid), Kosala Hemachandra (@kvhnuke), Richard Moore (@ricmoo), Gregory Markou (@GregTheGreek)
discussions-to: https://ethereum-magicians.org/t/eip-6963-multi-injected-provider-interface-aka-mipi/14076/2
status: Draft
type: Standards Track
category: Interface
created: 2023-05-01
requires: 1193
---

## Abstract

A Javascript interface injected by browser extensions installed by the user that enables user selection from multiple wallet providers using a window object labelled `window.evmproviders` instead of overwriting `window.ethereum` object.

## Motivation

Currently, wallet providers that offer browser extensions must inject their Ethereum providers (EIP-1193) into the same window object `window.ethereum` however this creates conflicts for users that may install more than one browser extension.

Browser extensions are loaded in the web page and do not have a predictable pattern resulting in a race condition where the user is not in control to choose which wallet provider must be selected for exposing Ehtereum interface under the `window.ethereum` object.

This results not only in a degraded user experience but also increases the barrier to entry for new browser extensions as users are forced to only install one browser extension at a time.

Some browser extensions attempt to counteract this problem by delaying their injection to overwrite the same `window.ethereum` object which creates an unfair competition for wallet providers and lack of interoperability.

In this proposal, we provide a solution that optimitizes for interoperability and enables fairer competition by lowering the barrier to entry for new wallet providers to improve the user experience on Ethereum.

This is achieved by replacing the current window object `window.ethereum` with a new window object `window.evmproviders` that enables multiple browser extensions to be exposed for user selection in the web page.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### Provider Info

Each wallet provider will be exposed with the following interface `ProviderInfo` that will be used to display to the user:

```typescript
/**
 * Represents the assets needed to display a wallet
 */
interface ProviderInfo {
  uuid: string;
  walletId: string;
  name: string;
  icon: string;
}
```

The values in the `ProviderInfo` MUST be used as follows:

- uuid - locally unique of the wallet provider (UUIDv4 compliant)
- walletId - globally unique identifier of the wallet provider (eg. `io.dopewallet.extension` or `awesomewallet`)
- name - human-readable name of the wallet provider (e.g. `DopeWalletExtension` or `AwesomeWallet`)
- icon - uri encoded image (RFC-3986 complaint)

### EVMProvider

The wallet provider will also expose their own EIP-1193 provider interface in parallel with the provider info provided above in the following interface `EVMProvider`

```typescript
interface EVMProvider {
  info: ProviderInfo;
  ethereum: EIP1193Provider;
}
```

The `EIP1193Provider` interface is documented at [EIP-1193](./eip-1193.md) and can be used to override the `window.ethereum` object once the user as explicitly selected it.

### window.evmproviders

A web app will be able to display multiple wallet providers that were injected by browser extensions by parsing the window object `window.evmproviders` which will include an array of wallet providers that follow the `EVMProvider` described above

```typescript
window.evmproviders = EVMProvider[]
```

Popular Ethereum libraries will be able to parse this object to display multiple injected providers easily with the name, icon and description from the `ProviderInfo` and then use the provided `EIP1193Provider` to continue operating for future calls to the blockchain.

### Event Listeners

Different wallet providers might inject their scripts at different timeframes plus there is no guarantees that the dapp library in the web page will be loaded after all injected scripts have populated the window object `window.evmProviders`

Therefore we will use `window.postMessage` and `window.addEventListener` to observe future changes to the window object that is tracking all providers.

Whenever a new wallet provider is added it should be tracked with the following event payload:

```typescript
interface EVMProviderAddedEvent {
  eventName: "evmProviderAdded";
  provider: EVMProvider;
}
```

A wallet provider will add their own EIP-1193 provider to the `window.evmProviders` and then emit a message as follows:

```typescript
window.postMessage(event as EVMProviderAddedEvent);
```

A dapp library will be able to observe these events by listening with `window.addEventListener` to the `message` event:

```typescript
window.addEventListener("message", (event: EVMProviderAddedEvent) => {});
```

## Rationale

Standardizing a `ProviderInfo` type allows determining the necessary information to populate a wallet selection popup. This is particularly useful for web3 onboarding libraries such as Web3Modal, RainbowKit, Web3Onboard, ConnectKit, etc.

The name `evmproviders` was chosen to include all EIP-1193 providers that support any EVM chain.

A locally unique identifier prevents from conflicts using the same globally unique identifier by using UUID v4.0

A globally unique identifier is used to for machine-readable detection of which wallet is being used and it can take different formats, for example:

```sh
# lowercase name
awesomewallet

# legacy JS variable
isCoolWallet

# reserved domain
io.dopewallet.app
```

A uri encoded image was chosen to enable flexibility for multiple protocols for fetching and rendering icons, for example:

```sh
# svg (data uri)
data:image/svg+xml,<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="32px" height="32px" viewBox="0 0 32 32"><circle fill="red" cx="16" cy="16" r="12"/></svg>
# png (data uri)
data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==
# jpg (ipfs uri)
ipfs://QmZ8ify1Z3pSpJjRANKsWLDqZrJjjZJ9e7o65LheQ2pFqb
# webp (http uri)
https://ethereum.org/static/f541df14fca86543040c113725b5bd1a/99bcf/metamask.webp
```

## Backwards Compatibility

This EIP doesn't require supplanting `window.ethereum`, so it doesn't directly break existing applications. However, the recommended behavior of eventually supplanting `window.ethereum` would break existing applications that rely on it.

## Reference Implementation

### Wallet Provider

Here is a reference implementation for an injected script by a wallet provider to support this new interface in parallel with the existing pattern.

```typescript
const info: ProviderInfo = {...}
const ethereum: EIP1193Provider = {...}

window.ethereum = ethereum

if (!window.evmproviders) {
  window.evmproviders = []
}

const provider = { info, ethereum }
window.evmproviders.push(provider)
window.postMessage({ eventName: "evmProviderAdded", provider})
```

### Dapp Library

Here is a reference implementation for a dapp library to display and track multiple wallet providers that are injected by browser extensions.

```typescript
let providers = [];

function onPageLoad() {
  if (window.evmProviders) {
    providers = window.evmProviders;
  }

  window.addEventListener("message", (event) => {
    if (
      typeof event.data !== "string" &&
      event.data.eventName === "evmProviderAdded"
    ) {
      providers.push(event.data.provider);
    }
  });
}
```

## Security Considerations

The security considerations of EIP-1193 apply to this EIP.

The use of SVG images introduces a cross-site scripting risk as they can include JavaScript code. Applications and libraries must render SVG images using the `<img>` tag to ensure no JS executions can happen.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
