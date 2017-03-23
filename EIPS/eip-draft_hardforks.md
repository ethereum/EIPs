## Preamble

    EIP: <to be assigned>
    Title: Formal process of hard forks
    Author: Alex Beregszaszi
    Type: Meta
    Status: Draft
    Created: 2017-03-23

## Simple Summary

To describe the formal process of preparing and activating hard forks.

## Abstract

To provide a process of coordination on hard forks.

## Motivation

Today discussions about hard forks happen at various forums and sometimes in ad-hoc ways.

## Specification

A Meta EIP should be created as a draft as a pull request as soon as a hard fork is planned. This EIP should contain:
- the desired codename of the hard fork,
- list of all the EIPs included in the hard fork and
- activation block number once decided.

The draft pull request shall be updated with summaries of the decisions around the hard fork. It should move in to `Accepted` state once the changes are frozen and in to the `Final` state once the hard fork has been activated.

The Yellow Paper should be kept updated with the hard fork changes. It could either refer to the fork codename or the EIP number of the fork.

## Rationale

A meta EIP for coordinating the hard fork should help in visibility and traceability of the scope of changes as well as provide a simple name and/or number for referring to the proposed fork.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
