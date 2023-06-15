---
eip:
title: Interface naming conventions
description: Language-agnostic canonicalisation of interface naming conventions
author: Pascal Caversaccio (@pcaversaccio)
discussions-to: https://ethereum-magicians.org/t/interface-naming-conventions/14692
status: Draft
type: Meta
category: Interface
created: 2023-06-15
---

## Abstract

This specification defines a standardised way of naming interface functions, event or custom error definitions, or anything else included in an interface definition that is used as an identifier by compilers in some form.

## Motivation

The vast majority of interface definitions today are based on Solidity-based naming conventions such as `camelCase` for function names or `PascalCase` for events and custom errors. This has been an opinionated decision that is not compatible with other languages such as Vyper or Cairo that use a `snek_case` convention. Unfortunately, this approach leads to inconsistent naming within such codebases, where functions, events, or custom errors that must adhere to interface definitions are written in `camelCase`, while all other functions, events, or custom errors use a `snek_case` approach. This EIP attempts to standardise the naming convention on which the `keccak256`-based signatures of functions, events, custom errors, and other identifiers are calculated. The implementation of the naming convention can be implemented directly by the compilers, allowing each language to maintain its naming convention scheme generically.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

1. Every single word of an interface function, event or custom error definition, or anything else contained in an interface definition and used as an identifier, MUST be capitalised and concatenated with an underscore `_` before conversion. Examples:

- `transferFrom` -> `TRANSFER_FROM`
- `balanceOf` -> `BALANCE_OF`
- `safeBatchTransferFrom` -> `SAFE_BATCH_TRANSFER_FROM`

2. Using the standardised name, all non-alphanumeric characters excluding the underscore `_` MUST be removed from the name. Examples:

- `$TRANSFER_FROM` -> `TRANSFER_FROM`
- `BA{L}ANCE_OF` -> `BALANCE_OF`
- `SAFE_BA\TCH_TRAN!SFER_FROM` -> `SAFE_BATCH_TRANSFER_FROM`

3. The alphanumeric name string is `keccak256` hashed and converted to an integer type accordingly. Examples:

- `TRANSFER_FROM` -> `int(keccak(text="TRANSFER_FROM").hex(), 16) = 94395173975023775779662060048629656272561824698643396274474837925292473410016`
- `BALANCE_OF` -> `int(keccak(text="BALANCE_OF").hex(), 16) = 80708256028020625538388752345478945032378179923394270514785770355663480356011`
- `SAFE_BATCH_TRANSFER_FROM` -> `int(keccak(text="SAFE_BATCH_TRANSFER_FROM").hex(), 16) = 255983261274881569444563352188479556572877507257597428201081558335645686969`

4. The following naming conventions MUST be supported:

- `camelCase`
- `flatcase`
- `MACRO_CASE`
- `PascalCase`
- `snake_case`
  > `kebab-case` and `COBOL-CASE` are not supported due to general language compatibility reasons.

5. Eventually, the naming convention is selected based on the following algorithm, where `hashed` MUST be the result of _step 3_ and `non_alphanumeric_name` MUST be the result of _step 2_:

```python
MAX_UINT256 = 2**256 - 1  # Maximum value that a `keccak256` hash can reach.
INTERVAL = MAX_UINT256 / 5  # We support 5 different naming conventions.

if hashed > (MAX_UINT256 - INTERVAL):
    return camelcase(non_alphanumeric_name)
elif hashed > (MAX_UINT256 - 2 * INTERVAL):
    return flatcase(non_alphanumeric_name)
elif hashed > (MAX_UINT256 - 3 * INTERVAL):
    return macrocase(non_alphanumeric_name)
elif hashed > (MAX_UINT256 - 4 * INTERVAL):
    return pascalcase(non_alphanumeric_name)
else:
    return snakecase(non_alphanumeric_name)
```

Theoretically, it is possible that ERCs are proposed that are optimised for a particular naming convention based on this approach with forged names. The EIP editors MUST ensure that the names are reasonable enough to justify such reverse engineering of the implied naming convention.

## Rationale

Based on the above specification, we can achieve two goals:

- Each language can continue to use its naming convention consistently, while compilers can implement the conversion beneath the surface.
- The most common naming conventions are supported, covering Solidity, Vyper, Huff, Fe, or Cairo, making it future-proof.

## Backwards Compatibility

This EIP introduces a canonical naming scheme that is generally not backward compatible with the mostly Solidity-based naming conventions adopted by most ERCs.

## Test Cases

```python
assert to_checksum_name("SAFE_BATCH_TRANSFER_FROM") == "safe_batch_transfer_from"
assert to_checksum_name("BALANCE_OF") == "balanceof"
assert to_checksum_name("TRANSFER_FROM") == "transferFrom"
assert to_checksum_name("GET_APPROVED") == "GetApproved"
assert to_checksum_name("$I_HA$TE_PHP_R'{'}0!_!") == "I_HATE_PHP_R0"
```

## Reference Implementation

```python
from re import sub
from eth_utils import keccak
from caseconverter import camelcase, flatcase, macrocase, pascalcase, snakecase

"""
Biased Assumption: Every single word of an interface function, event or custom error definition,
or anything else contained in an interface definition and used as an identifier, is capitalised
and concatenated with an underscore before running `to_checksum_name`.

Examples: `TRANSFER_FROM`, `BALANCE_OF`, `$I_HATE_PHP`.

Common naming conventions:
    - camelCase
    - kebab-case (not supported due to general language compatibility reasons)
    - COBOL-CASE (not supported due to general language compatibility reasons)
    - flatcase
    - MACRO_CASE
    - PascalCase
    - snake_case
"""


MAX_UINT256 = 2**256 - 1  # Maximum value that a `keccak256` hash can reach.
INTERVAL = MAX_UINT256 / 5  # We support 5 different naming conventions.


def to_checksum_name(function_name):
    assert isinstance(function_name, str), "Input argument must be a string."
    assert function_name.isupper(), "String must be uppercase."

    # Remove all non-alphanumeric characters excluding underscore.
    # The expression `[\W]` is equal to `[^a-zA-Z0-9_]`, i.e. it
    # matches any character which is not a word character. For further
    # details, see: https://docs.python.org/3.11/library/re.html#regular-expression-syntax.
    non_alphanumeric_name = sub(r"[\W]", "", function_name)

    # `keccak256` hash and convert into an integer type. Note that in Python 3,
    # the `int` type has no maximum limit. You can handle values as
    # large as the available memory allows. For further details, see:
    # https://docs.python.org/3/whatsnew/3.0.html#integers.
    hashed = int(keccak(text=non_alphanumeric_name).hex(), 16)

    # Check the hash value and return the converted name.
    if hashed > (MAX_UINT256 - INTERVAL):
        return camelcase(non_alphanumeric_name)
    elif hashed > (MAX_UINT256 - 2 * INTERVAL):
        return flatcase(non_alphanumeric_name)
    elif hashed > (MAX_UINT256 - 3 * INTERVAL):
        return macrocase(non_alphanumeric_name)
    elif hashed > (MAX_UINT256 - 4 * INTERVAL):
        return pascalcase(non_alphanumeric_name)
    else:
        return snakecase(non_alphanumeric_name)
```

## Security Considerations

Compilers must ensure that the `keccak256`-based signatures of functions, events, custom errors, and any other identifiers that will be used in some form in the future are based on the canonical naming scheme.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
