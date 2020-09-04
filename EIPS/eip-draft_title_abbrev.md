---
eip: <to be assigned>
title: EthPM URI Specification
author: Nick Gheorghita (@njgheorghita), Piper Merriam (@pipermerriam), g. nicholas d'andrea (@gnidan), Benjamin Hauser (@iamdefinitelyahuman)
status: Draft
type: Standards Track
category: ERC
created: 2020-09-04
requires: EIP 2678
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
A custom [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) scheme to identify an [EthPM](https://docs.ethpm.com/) registry, package, release, or specific contract asset within a release.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
When interacting with the EthPM ecosystem, users and tooling can benefit from a URI scheme to identify EthPM assets. Being able to specify a package, registry, or release with a single string makes simplifies the steps required to install, publish, or distribute EthPM packages.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

`scheme://registry_address:chain_id/package_name@package_version/json_pointer`

#### `scheme`
- Required
- Must be one of `ethpm` or `erc2678`. If future versions of the EthPM packaging standard are designed and published via the ERC process, those ERCs will also be valid schemes.

#### `registry_address`
- Required
- This **should** be either an ENS name or a 0x-prefixed, checksummed address. ENS names are more suitable for cases where mutability of the underlying asset is acceptable and there is implicit trust in the owner of the name. 0x prefixed addresses are more preferable in higher security cases to avoid needing to trust the controller of the name.

#### `chain_id`
- Optional
- Integer representing the chain id on which the registry is located
- If omitted, defaults to `1` (mainnet).

#### `package_name`
- Optional
- String of the target package name

#### `package_version`
- Optional
- String of the target package version
- If the package version contains any [url unsafe characters](https://www.werockyourweb.com/url-escape-characters/), they **must** be safely escaped
- Since semver is not strictly enforced by the ethpm spec, if the `package_version` is omitted from a uri, tooling **should** avoid guessing in the face of any ambiguity and present the user with a choice from the available versions.

#### `json_pointer`
- Optional
- A path that identifies a specific asset within a package.
- This path **MUST** conform to the [JSON pointer](https://tools.ietf.org/html/rfc6901) spec and resolve to an available asset within the package.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Most interactions within the EthPM ecosystem benefit from a single-string representation of EthPM assets; from installing a package, to identifying a registry, to distributing a package. A single string that can faithfully represent any kind of EthPM asset, across the mainnet or testnets, reduces the mental overload for new users, minimizes configuration requirements for frameworks, and simplifies distribution of packages for package authors.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
A JSON file for testing various URIs can be found in the [`ethpm-spec`](https://github.com/ethpm/ethpm-spec) repository.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The EthPM URI scheme has been implemented in the following libraries...
- [Brownie](https://eth-brownie.readthedocs.io/en/stable/)
- [Truffle](https://www.trufflesuite.com/docs/truffle/overview)
- [EthPM CLI](https://ethpm-cli.readthedocs.io/en/latest/)

## Security Considerations
In most cases, an EthPM URI points to an immutable asset, giving full security that the target asset has not been modified. However, in the case where an EthPM URI uses an ENS name as its registry address, it is possible that the ENS name has been redirected to a new registry, in which case the guarantee of immutability no longer exists.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
