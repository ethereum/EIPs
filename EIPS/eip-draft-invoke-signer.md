## Standardize OS Level Management of Signature Handling

    eip: <to be assigned>
    title: Invoke Signer
    author: Zac Mitton (@zmitton)
    discussions-to: https://github.com/ethereumclassic/ECIPs/issues/147
    status:  Draft
    type: STANDARDS TRACK
    category: Interface
    created: 2019-02-07

## Simple Summary
A standardized way for dapps to "pull up" the user's preferred wallet when completing any task requiring a signature. Any dapp should work with any wallet as long as they use the standard. This should even be true of different environments (i.e. browser, desktop, mobile...)

## Note
I will often use the term "Signer" to mean the same thing as "Wallet", because these programs can sign more than just transactions.

## Abstract
UX involved with handling ethereum signing is especially cumbersome. This is mostly due to the fact that dapps and wallets are used in many different *environments* (i.e. desktop, mobile, CLI, plugin, mobile-browsers desktop-browsers, and hardware). Attempts to improve this UX shortcoming have generally involved rigid user work-flows, or specific application combinations. I assert the problem is best solved at the operating system level using a widely standardized protocol like the one proposed below.

The following describes

1. A way for dapp developers to handle _any action requiring a signature_ (i.e. signing a tx or logging in). The spec defines *how the wallet is chosen and invoked by the user's Operating System*

2. A way for wallet applications to handle incoming requests for signature.

## Motivation
Users should be able to use any wallet of their choosing when interacting with a dapp. Having users download a specific wallet per-environment reduces security, inhibits adoption, and is terrible UX: The user has to "top-up", and not forget about each application-specific wallet. This sucks for the user because they have money all over the place and a laundry list of wallet program installations across devices.

The current architecture leads to staments like "Our dapp currently works on the chrome browser with metamask enabled. We plan to add support MyEtherWallet soon."

As the number of wallets and dapps grow, the combinations become n^2. This will inhibit small wallets from entering the market, but require users to download all major wallets.

## Current Scenario
#### Desktop Browser Dapps 
So far, the best solution has been to download wallet plugins like Metamask, that inject javascript (by being granted very scary permissions) onto every single page the user navigates to. The user often cannot use a hardware wallet _unless_ the dapp developer specifically integrates support for it - a huge security limitation.
     
#### Mobile Browser Dapps
If the user attempts to load the dapp on mobile, they are expected to use a specially made "web3 enabled" mobile browser (i.e. Brave, Toshi), to view the app so the dapp has available it's in-browser wallet for invocation. This is suboptimal architecture, and a waste of engineering resources. Browsers are extraordinarily complex programs, and building a decent one is an overwhelmingly monumental challenge (unless say, you're the inventor of Javascript). UX is much better when they can use their preferred browser. Besides - we should not be building web-browsers to solve the problem of wallets.

#### Native Dapps (the worst UX of all)
Currently, if a mobile app developer wants to integrate an ethereum feature in their app, they genreally build a wallet into the app itself (from scratch). The user ends up with loose change in siloed apps, and these wallets will have widely varying (and therefore pathetic) security standards.


## Desired Dapp Experience
Before defining the proposed spec, I'd like to outline the _ideal_ user experience, and work backwards to achieve it. After all, that's how this spec came about.

1) If a dapp is browser-based, the user can browse to it using ANY available browser on mobile OR desktop.

2) If the dapp is a native mobile or native desktop app, they simply download then open the application.

3) When the dapp requires a signature it should 
    
   - Automatically open the user's preferred mobile wallet when on mobile, or 
    
   - Automatically open the user's preferred desktop/hardware wallet when on desktop. 
4) The wallet should then display details of the signing request. 
5) The user can then tap or click "sign" and be sent back to the dapp.

## Rationale
This problem finally must be addressed at the _Operating System_ level, because it is the only way to flexibly hand off control flow to another app.

### Deep Links
_Deep linking_ is a method available from any application or webpage that provides the user's operating system with instructions to open a specific application (and can carry an arbitrary data string with it). They work in basically all environments: Android, iOS, MacOS, Windows, and Linux (possibly others).

Most of us have seen deep linking used when clicking on a Zoom or Spotify link. It usually invokes focus to a _specific_ application. In our case, we don't want to open a _specific_ (branded) application (i.e. Jaxx, Toshi, or Gnosis-Safe). Rather we tell the operating system to open the user's "_default signer_" (wallet).

### Implementations
#### IOS and OSX
Implementation of signer apps varies by OS. On IOS it can be done with NSUrl Protocol, which is like a link, but instead of a opening a specific app, you specify a name space (e.g. "invoke-signer") to which any app can register itself as a handler. 

All apps on the device registered as a handler will call a boolean function deciding whether or not the app should handle the incoming request (perhaps true if (and only if) the user has chosen this signer as default). The first app to return `true` from this function will be launched with access to data from the URL (the rpc data and/or more).

<!-- 
#### Windows
#### Linux
#### Android

exists on all 3 but I just haven't done enough research to describe the details yet
 -->

## Draft Specification
The name space should indicate fundamentally that its doing the _signing_. So `ethereum-signer` was my first though. However, nearly any cryptocurrency can benefit from this. For that reason simply `signer` would be better. Lastly this spec is about more than just a _referring_ to the signer app - it is about  specifically _invoking_ that app. Therefore I think *`invoke-signer`* is the most relevant namespace to use.

From there, the `path` could communicate the specific cryptocurrency, i.e. `ethereum` (together `invoke-signer://ethereum`...). The path can be used by the singer in its boolean function to determine whether it's capable of handling this particular signing request. Then we need a way to tell the signer exactly what to do:

From there we need to communicate exactly what the signer should do. Rather then re-inventing the wheel, we can just `uri_encode` the existing JSON RPC calls. For instance all signers would want to support the existing RPC methods `eth_sign` and `eth_signTypedData`.

In standard query format this would be:

```
invoke-signer://ethereum?rpc=%7B%22jsonrpc%22%3A%222.0%22%2C%22method%22%3A%22eth_sign%22%2C%22params%22%3A%5B%220xc45bc213664f565324ad302d187e0dc08ad7d1c57%22%5D%2C%22id%22%3A67%7D
```

Over time signers should become the secure and predictable place to view blockchain information, espesially data about to be signed. We can not really trust data being viewed on brower-based explorers or new dapp websites. More advanced RPC methods will be added over time to accomidate this. For instance, methods that pass `contractCode` and `compilerVerion`, will be able to verify the code and ABI *in the signer app*. But none of that needs to be defined right now, because the format accepts arbitrary future methods!

## Conclusion
#### New User Experience
Most users will have a favorite mobile signer and enjoy a consistent experience with every dapp. Some may still use a plugin like metamask when on desktop, and power users will use a hardware signer for ultra-high security as needed.

#### Developer Experience
It becomes much easier to add a single "ethereum feature" into any software application. The app dev does not need to worry about any of the details of building a wallet/signer. They just create a string to be signed, and invoke the user's signer with it. The user expectation is only that they have _a_ signer, as opposed to some specific signer.


## Test Cases
Testing should consist of making sure the deep linking works in all environments. So somone needs to make both mock signers and mock dapps for all concievable environment: ios/android/desktop(osx, windows, linux) for browsers/native apps.

The mock dapps only need only to test a single url to make sure the wallet can be invoked. The mock wallets only need to prove that they can indeed be invoked and that they  received the request data by printing the rpc method.

<!-- Leaving the rpc call embedded, allows developers to continue to use existing tools for formatting and decoding transactions and signatures. Using query string format for arbitrary variables will also allow experimentation with new features that can be ignored by non-supporting wallets. For instance, I'd like wallets to eventually be sent the `contractCode` and `compilerVerion` so they can verify the code and ABI. But I would not like to define any of that into the spec right now. Over time we can standardize certain variable names. -->

<!-- Supporting Links:

[ECIP 1037 -- Simple Non-Interactive URI Scheme](https://github.com/ethereumproject/ECIPs/pull/81)

[EIP 67 -- Standard URI scheme with metadata value and byte code](https://github.com/ethereum/EIPs/issues/67)

[EIP 681 -- Payment request URL specification](https://github.com/ethereum/EIPs/pull/681)

[EIP 831 -- Standard URL Format](https://github.com/ethereum/EIPs/pull/831)

[URI Schemes](https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml) -->
