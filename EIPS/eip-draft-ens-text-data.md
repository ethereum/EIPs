## Preamble

    EIP: <to be assigned>
    Title: Storage of text records in ENS 
    Author: Richard Moore <me@ricmoo.com>
    Type: Standard Track
    Category ERC
    Status: Draft
    Created: 2017-05-17


## Abstract
This EIP defines a resolver profile for ENS that permits the lookup of arbitrary key-value
text data. This allows ENS name holders to associate e-mail addresses, URLs and other
informational data with a ENS name.


## Motivation
There is often a desire for human-readable metadata to be associated with otherwise
machine-driven data; used for debugging, maintenance, reporting and general information.

In this EIP we define a simple resolver profile for ENS that permits ENS names to
associate arbitrary key-value text.


## Specification

### Resolver Profile
A new resolver interface is defined, consisting of the following method:

    function text(bytes32 node, string key) constant returns (string text);

The interface ID of this interface is 0x59d1d43c.

The `text` data may be any arbitrary UTF-8 string. If the key is not present, the empty string
should be returned.


### Initial Recommended Keys

Keys should always be made up of lowercase letters, numbers and the hyphen (-). Extended keys
or non-standard services should be prefixed with `x-`.

- **email** - an e-mail address
- **url** - a URL
- **x-twitter** - a twitter username (should it be prefixed with an @?)
- **x-github** - a GitHub username

A separate document may make more sense to track *standard* and *extended* keys.


## Rationale

### Application-specific vs general-purpose record types
Rather than define a large number of specific record types (each for generally human-readable
data) such as `url` and `email`, we follow an adapted model of DNS's `TXT` records, which allow
for a general keys and values, allowing future extension without adjusting the resolver, while
allowing applications to use custom keys for their own purposes.

## Backwards Compatibility
Not applicable.

## Test Cases
TBD

## Implementation
None yet.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
