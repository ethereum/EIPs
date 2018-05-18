---
eip: <to be assigned>
title: Opt-in web3 access
author: Paul Bouchon <mail@bitpshr.net>
discussions-to: https://ethereum-magicians.org/t/opt-in-web3-access/414
status: Draft
type: Standards Track
category: Interface
created: 2018-05-04
---

## Simple summary

This proposal describes a new way for environments to expose the web3 API that requires user approval.

## Abstract

MetaMask and most other tools that provide access to web3-enabled environments do so automatically and without user consent. This exposes users of such environments to fingerprinting attacks since untrusted websites can check for a `web3` object and reliably identify web3-enabled clients.

This proposal outlines a new dapp initialization strategy in which websites request access to the web3 API instead of relying on its preexistence in a given environment.

## Specification

### Typical dapp initialization

```
START dapp
IF web3 is defined
    CONTINUE dapp
IF web3 is undefined
    STOP dapp
```

### Proposed dapp initialization

```
START dapp
IF web3 is defined
    CONTINUE dapp
IF web3 is undefined
    REQUEST[1] web3 API
    IF user approves
        INJECT[2] web3 API
        NOTIFY[3] dapp
        CONTINUE dapp
    IF user rejects
        STOP dapp
```

**REQUEST[1]** This operation would be achieved by an implementation-level messaging API like `window.postMessage` and should pass a payload containing a `type` property with a value of “WEB3_API_REQUEST”.

**INJECT[2]** This operation would be achieved by any implementation-level API that can expose the web3 API to the user’s browser context, such as HTML script tag injection.

**NOTIFY[3]** This operation would be achieved by an implementation-level messaging API like `window.postMessage` and should pass a payload containing a `type` property with a value of “WEB3_API_SUCCESS” after successful web3 exposure or “WEB3_API_ERROR” after unsuccessful web3 exposure. In the case of an error, an optional `message` property can be included with additional information.

### Example implementation: `postMessage`

```js
if (typeof web3 !== 'undefined') {
    // web3 API defined, start dapp
} else {
    window.addEventListener('message', function (event) {
        if (!event.data || !event.data.type) { return; }
        if (event.data.type === 'WEB3_API_SUCCESS') {
            // web3 API defined, start dapp
        } else if (event.data.type === 'WEB3_API_ERROR') {
            // Something went wrong, stop dapp
        }
    });
    // request web3 API
    window.postMessage({ type: 'WEB3_API_REQUEST' });
}
```

## Rationale

An [open issue](https://github.com/MetaMask/metamask-extension/issues/714) against the [MetaMask](https://github.com/MetaMask/metamask-extension) extension has received community upvotes and Richard Burton of the [Balance](https://github.com/balance-io) team published a well-received [blog post](https://medium.com/@ricburton/metamask-walletconnect-js-b47857efb4f7) discussing these potential changes.

### Constraints

* Web3 SHOULD NOT be exposed to websites by default.
* Dapps SHOULD request web3 if it does not exist.
* Users SHOULD be able to approve or reject web3 access.
* Web3 SHOULD be exposed to websites after user consent.
* Dapps MUST continue to work in environments that continue to auto-expose web3.
* Environments MAY continue auto-exposing web3 if users can disable this behavior.

### Immediate value-add

* Users can reject web3 access on untrusted sites to prevent web3 fingerprinting.

### Long-term value-add

* Dapps could request specific account information based on user consent.
* Dapps could request specific user information based on user consent (uPort, DIDs).
* Dapps could request a specific network based on user consent.
* Dapps could request multiple instances of the above based on user consent.

## Backwards compatibility

This proposal impacts dapp authors and requires that they request access to the web3 API before using it. This proposal also impacts developers of web3-enabled environments or dapp browsers as these tools should no longer auto-expose the web3 API; instead, they should only do so if a website requests the API and if the user consents to its access. As mentioned in the [constraints](/#constraints) section above, environments may continue to auto-expose the web3 API as long as users have the ability to disable this behavior.

## Implementation

The MetaMask team is currently working an [MVP implementation](https://github.com/MetaMask/metamask-extension/issues/3930) of the strategy described above and expects to begin limited user testing soon.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).