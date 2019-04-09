---
eip: <to be assigned>
title: Standard proxy storage slots
author: Santiago Palladino (@spalladino)
discussions-to: <URL>
status: Draft
type: Standards Track (Core, Networking, Interface, ERC)
category: ERC
created: 2019-04-08
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Standardise how proxies store the address of the logic contract they delegate to, and other proxy specific information.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Delegating **proxy contracts** are widely used for both upgradeability and gas savings. These proxies rely on a **logic contract** (also known as implementation contract or master copy) that is `delegatecall`ed into. This allows proxies to keep a persistent state (storage and balance) while the code is delegated to the logic contract. 

To avoid clashes in storage usage between the proxy and logic contract, the address of the logic contract is typically saved in a [specific storage slot](https://blog.zeppelinos.org/upgradeability-using-unstructured-storage/) guaranteed to be never allocated by a compiler. This EIP proposes a set of standard slots where proxy information is stored. This allows clients like block explorers to properly extract and show this information to end users, and logic contracts to optionally act upon it.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Delegating proxies are widely in use, as a means to both support upgradeability and reduce gas costs of deployments. Examples of these proxies are found in [ZeppelinOS](https://blog.zeppelinos.org/the-transparent-proxy-pattern/), [Terminal](https://medium.com/terminaldotco/escape-hatch-proxy-efb681de108d), [Gnosis](https://blog.gnosis.pm/solidity-delegateproxy-contracts-e09957d0f201), [AragonOS](https://github.com/aragon/aragonOS/blob/dev/contracts/common/DelegateProxy.sol), [Melonport](https://github.com/melonproject/melon-mail/blob/782aeff9418ac8cdd80875fd6c400bf96f3b03b3/solidity/contracts/DelegateProxy.sol), [Limechain](https://github.com/LimeChain/UpgradeableSolidityContract/blob/14bcabc338130fb2aba2ce8bd27b885305566fce/contracts/Upgradeability/Forwardable.sol), [WindingTree](https://github.com/windingtree/upgradeable-token-labs/blob/af3b66096091d8282d5c9c55c33365315d85f3e1/contracts/upgradable/DelegateProxy.sol), [Decentraland](https://github.com/decentraland/land/blob/5154046844f6f94a5074e82abe01381e6fd7c39d/contracts/upgradable/DelegateProxy.sol), and many others.

However, lacking a common interface for obtaining the logic address for a proxy makes it impossible to build common tools that act upon this information.

A classic example of this is a block explorer. Here, the end user wants to interact with the underlying logic contract and not the proxy itself. Having a common way to retrieve the logic contract address from a proxy would allow a block explorer, among other things, to show the ABI of the logic contract and not that of the proxy (see [this proxy](https://etherscan.io/token/0x00fdae9174357424a78afaad98da36fd66dd9e03#readContract) for an example).

Another example are logic contracts that explicitly act upon the fact that they are being proxied. This allows them to potentially trigger a code update as part of their logic, as is the case of [EIP1822](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1822.md). A common storage slot allows these use cases independently of the specific proxy implementation being used.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
The main requirement for the storage slots chosen is that they must never be picked by the compiler to store any contract state variable. Otherwise, a logic contract could inadvertently overwrite this information on the proxy when writing to a variable of its own.

[Solidity](https://solidity.readthedocs.io/en/v0.4.21/miscellaneous.html#layout-of-state-variables-in-storage) maps variables to storage based on the order in which they were declared, after the contract inheritance chain is linearized: the first variable is assigned the first slot, and so on. The exception are values in dynamic arrays and mappings, which are stored in the hash of the concatenation of the key and the storage slot. The Solidity development team has [confirmed](https://twitter.com/ethchris/status/1073692785176444928) that the storage layout is to be preserved among new versions.

As such, the proposed storage slots for proxy-specific information are the following. They are chosen after the ones used in ZeppelinOS, which have been already deployed to mainnet by several projects, and are guaranteed to not clash with state variables allocated by the compiler.

More slots for additional information can be added in subsequent EIPs as needed.

### Logic contract address

Storage slot `0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3`
(obtained as `keccak256('org.zeppelinos.proxy.implementation')`).

Holds the address of the logic contract that this proxy delegates to.

### Admin address

Storage slot `0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b`
(obtained as `keccak256('org.zeppelinos.proxy.admin')`).

Holds the address that is allowed to upgrade the logic contract address for this proxy (optional).

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

This EIP standardises the **storage slot** for the logic contract address, instead of a public method on the proxy contract as [EIP897](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md) does. The rationale for this is that proxies should never expose functions to end users that could potentially clash with those of the logic contract. 

Note that a clash may occur even among functions with different names, since that the ABI relies on just four bytes for the function selector. This can lead to unexpected errors, or even exploits, where a call to a proxied contract returns a different value than expected, since the proxy intercepts the call and answers with a value of its own. 

From [_Malicious backdoors in Ethereum proxies_](https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357) by Nomic Labs:

> Any function in the Proxy contract whose selector matches with one in the implementation contract will be called directly, completely skipping the implementation code.
> 
> Because the function selectors use a fixed amount of bytes, there will always be the possibility of a clash. This isn’t an issue for day to day development, given that the Solidity compiler will detect a selector clash within a contract, but this becomes exploitable when selectors are used for cross-contract interaction. Clashes can be abused to create a seemingly well-behaved contract that’s actually concealing a backdoor.

The fact that proxy public functions are potentially exploitable makes it necessary to standardise the logic contract address in a different way. This approach is also used as part of [EIP1822](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1822.md), which could become a specialization of this EIP.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This EIP is compatible with existing proxies deployed that rely on this pattern using these specific storage slots. Exactly 110 proxies that use this same slot were found on mainnet by January 2019 (thanks @kolinko!).

<details>
0xAACbadE46A99B162113C925452fDead63e1dc1F2
0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
0xB6E580bA48c6cAf974903C05C79409938Ac269fa
0x9fC6E486B6b1A1ff96aeF72Deaf0c2Ff46aa01c0
0xf0655f7AeDf09ef8CeB2232B037209CE0BFE6417
0x1489d01712FA4dCa39c24666Eb7bf33c194058DC
0xdc131d78C648560c1FDD46a0D81E3DFD2fDC5224
0x959e104E1a4dB6317fA58F8295F586e1A978c297
0x83433C0c4f726EA1e5f8D85BB63DAF852BCe9450
0x141bc20b41C92401a91D05F906bD18663bb8841B
0xe8536e99C9D30C6807BABD63Dc9fF8386b86aded
0xf324D70F328d1af931128fEd39cf61FaE7FD20E5
0x3FCCE645D31774f34bC0DF9E4257D3d680104937
0xcf55D22b0C6F4D783f8593741dEd453c804ea12F
0x9553983E11735bb8dcCB59eD92462F1C96948E0F
0x8b3fD36E3a1e8E18e8a8d416c07072Db512f7C30
0xe9a17561c6D9E37a156e3250583B3A06BD2727Ca
0x7B00aE36C7485B678Fe945c2DD9349Eb5Baf7b6B
0x9cCbae575b54DC4C80629FD5b71D03cEf0278902
0xC9d92014684558b35C4Aef0f0bC9D3098bC91F13
0xb698938b41AbE65f0Bb3c4cee428b4aDb2A5D5D9
0xF485712a8F14C81c331E7C1341704c3434DA65CD
0x8A3b14355692F60C5b97D8FBd4F571cCfe02D3A6
0x9db37d15FEFbF42DC390c3c81fee453465841038
0x038c8f9aBC21BF6575f49FcE9a1eD7a69301A49B
0x5E79b05c21fF95710062942045064AE15262323e
0x6aB36216C7fF05ca968101CA0501C9C1bA449787
0x1dbA1C36BD64db47D835622C3a5cA1fB0cdf864f
0x8DDd6aBf3a2CD497E03426BD254f66b3cC19ffFB
0x7900e8cEAe0f40741fCC2C1BBEAaF60604cAbB83
0x24Cad2Ef40685B35A13a60F93C80f1F681B52fE9
0x6De037ef9aD2725EB40118Bb1702EBb27e4Aeb24
0xfe5610a03Ed7872710F40778591740415F7E4D6d
0xBAfDD76f3e9AFa61394b04FD37f9BdD3206BdD24
0xE22e63605806006ca5dFeCa846Eb041d70f1D852
0xaCa419FbAB8AEFabA1EA067206D048eA4527Fe3f
0xb705fBB649c51aD3c615b6C806192802C1A8e2F4
0xF821b941c1d4eca346eb35ec92D366fE415e2186
0x00cfD77Fb89432037199857d827BEC887cede17A
0x366842DFcE170CA1cD4445a9a8c91c4a768FB797
0xb842722c8bb8510c20b3Dbbb934C9d4802650b8a
0x00fDAE9174357424A78aFAAd98da36Fd66dD9E03
0xE88778E100Cc2170cc28a6feE5533bB1c7778E71
0x6Fd49c2C3fbF84a89f5dd7B10dBAB6372F496819
0x2e3daacf773fd11a981933DbF729093233203bd5
0xFf488FD296c38a24CCcC60B43DD7254810dAb64e
0xb0A8aDBC7BD27a97742C7b64aC16e730ED5EF50a
0x0155A467908f2Cf36108Ae165b1028885CdD595C
0x6D5658158518C073E4805BB398Ad9233632057a2
0x99A68D46D23F9a4592d9e080f6e3d69552b3a2F9
0x2EcdC9A5c305435B9432727fcA6351C3aA0FBD0b
0xAf4Fdd31d4BC4D5987137A4A97396C44c3B219b7
0x98b5346b22cD55381fDb249d4F7DA7aD01C12118
0x2B3588bC1FBc553C0988FdDF076ffd662f9c7176
0xcee2Aa0e9F4BB8E0D7ac0D0Cb6739E4B72078cC6
0xA7E26d3455629a01d9136BF4F9a1644634934773
0x0a66f99F389783201eA4edDe3F49c45c1beb5F95
0x43e023f4A891F8e5e4198E760e86C254A93A840f
0x4AeF6dc7969d91D59d8A9891541abfDB4CB82A17
0x46Bfcf4811b7A60CD05520125D799A172cD025Ca
0xF6D950DBC0b3841a3B960F4321424E333e777FE6
0x7C99b4c381f81b22416C977f9FE4D72806a35De5
0x1Ace37F1d9048c8fEb856D39411e3fcd2f57125A
0xeF2C3bC801C29468870Da09B498ABdC010d05dA7
0xC7d911F198f57B32C089f725F8eF894D6FeCe9Da
0x5957f64d07d0039D7c3d977CB38D33F7DbdA4b89
0x01368366A2B256E14e967C9acfd87440aC1d9Cca
0x9ce894a11AdA19881aB560A5091A4cc3fF8f2d84
0x1F7A2Fb8B999E928c463fe9A4844833f5EFDA84A
0x92678E568FD6019f7c773EA8f6b3933a9fdD061b
0x6355d4F22368bD7b8F961392b94d75b707D19bf2
0x00319F722bd546182cB2c701cA254146D3F084fC
0xa032cd66751e74Fc2CEc2d3f530704758a9Aa792
0x84990D99d35F5a3e6487430381a8E6B9328743c2
0xE2f35dc1724E07494466FFC2B78C9cA973ceD5Cb
0x4eF94A2ACfF7011e995631c6865cc50a7d0C7f9F
0x6242574f033556E2F6CEaEF362190580B1c9A360
0x7c205273C3416Af9E226bECeb6b31A32bDaF6CFA
0x965602a405f78D095F5c36DE2165ae60693bC650
0x3aFfCCa64c2A6f4e3B6Bd9c64CD2C969EFd1ECBe
0x70cB9F639893761fc72E6EDd80Ec40EF0DD7231D
0xeE3CA8C8B5Ea3c2Aa293B0fD2E61B3638D953241
0x6cDB08d7A67C8C7381dEabCFdea885520B651a45
0x04Eab683391502DB39b952D89F4b99bb63E24B62
0x4E24ae34d4b781764148168ACA0D60162f4015B9
0xE88ddB5C07BF45a3944b8E2DAdaC58E82Cc05942
0x082dc075F8556ddd4E2A9f61fd6145B490aB1558
0xD2902371D10E2b2B511419A03e0f571bAEC3e7f7
0x8644b70D1E40E954D8397e79a210624Cbc22E1FE
0x21683397Aa53AAf7BaCA416C27f2c1e0e84bB493
0xfd61573e565462B8De96C3392Cc5634FB074e8Eb
0x1410d4eC3D276C0eBbf16ccBE88A4383aE734eD0
0xBE729D06DD2D7B2e953b40E234c62Bd5F0204a12
0x04f14fe9C7843A2c7e319EB1D666B9131C7E15b7
0x6ca1dAe56B80b65ceE201b541D282D803AE253Dd
0x5937512B02555967a01d78B0994F53168A985aC4
0x3401CAb9bEe49bCb76E13A8A09619e53D45C0AF0
0x8C461c8E8e5fD9aDb34601E75aD6Cb5B53db4544
0x04c1eD360ABf2852647CE2a1CBc800d1b664a9C9
0x1DC94d2470217D47A599771913dc0A0a9543bF2F
0x8C5Dde4217D416347596CE801fa9C7950CBf8B7f
0x4F1a2D9D1Cb092074d87b8D74771738564288927
0x954b890704693af242613edEf1B603825afcD708
0x6A8FB6e96FF8bc580b66591064855B4E29B22B02
0x63B049Db07157dE1aDea99E49CC1b5bF4FAa1B19
0x165F504306f0187D03DA44bAC40cDb3f8c53dcBe
0x7eAf7C8458204f71943A3E07F31f6B14E62F2bD8
0x8E870D67F660D95d5be530380D0eC0bd388289E1
0xA991aEAC42FFdEe21e86EA4f20148092722C73ff
0x86e8D8c86fD3685Be57B83DD23Ca91585f1A92F9
</details>

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Sample proxy implementations that follow this standard can be found in the [ZeppelinOS repository](https://github.com/zeppelinos/zos/blob/dc9e4ed/packages/lib/contracts/upgradeability/BaseUpgradeabilityProxy.sol).

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).