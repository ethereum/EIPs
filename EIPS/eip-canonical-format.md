---
eip: <to be assigned>
title: Canonically Referring to EIPs
author: <a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s), e.g. (use with the parentheses or triangular brackets): FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
discussions-to: <URL>
status: Draft
type: Meta
created: 2020-06-17
---

## Simple Summary
Recommend that EIPs be written as `EIP-X` where `X` is the EIP's assigned
number.

## Abstract
When referring to an EIP by it's number it should be written in the hyphenated
format `EIP-X` where `X` is the EIP's assigned number.

## Motivation
There is no consensus on how EIPs should be referred to. The [EIP
homepage](https://github.com/ethereum/EIPs/blob/0298105902a610f6031a205ec268b8705c0dae0a/index.html)
refers to EIPs using both the `EIP-X` and `EIPX` format.

## Specification
When an EIP is referred to via it's number `X`, it **SHOULD** be
written in the hyphenated form:

```
EIP-X
```

## Rationale

The hyphenated `EIP-X` format was chosen by analyzing the most popular format
in this repository. As of 2020/06/17, the following is true:

```console
$ grep "EIP-[0-9]+" * | wc -l
373

$ grep "EIP[0-9]+" * | wc -l
118

$ grep "EIP[0-9]+" index.html | wc -l
4

$ grep "EIP[0-9]+" EIPS/eip-1.md | wc -l
13
```

Anecdotally, the hyphenated format is also more popular in the community.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
