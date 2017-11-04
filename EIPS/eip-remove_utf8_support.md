## Preamble

EIP: -

Title: Remove UTF-8 support from contract strings

Author: Andreas Olofsson (androlo1980@gmail.com)

Type: Standard Track

Category: ERC

Status: Draft

Created: 2017-10-16

## Simple Summary

This proposal is to remove UTF-8 support from contracts, and instead use a simpler and more generic string format.

## Abstract

Strings used in contracts are currently assumed to be UTF-8 encoded. There are no enforcement mechanisms, however, which means that a `string` is essentially the same as a `bytes`. An alternative to this is to define stings to be a more general form of `bytes`, which can be done by changing the the format of the header. The strings proposed here would allow user-defined alphabets with `O(1)` index access and length computation. Additionally, runtime validation of any given string would be done using a very simple compare function.

## Motivation

UTF-8 is not a good string format for contracts, for several reasons:

1. It uses variable length characters, which means you have to index the strings before using them, or iterate over parts of the string when you want to get the length, or get a character by index.
2. It has a non-trivial string validation scheme (http://www.unicode.org/versions/Unicode10.0.0/UnicodeStandard-10.0.pdf, Table 3-7, p 126, Well-Formed UTF-8 Byte Sequences).
3. Strings that aren't written in plain English require more bytes, which means they incur a higher gas cost.

These problems has lead to a marked lack of support for string processing and (runtime) validation in contract code.

The performance issues of UTF-8 is the worst part, but runtime validation is a problem as well. Most contracts are called from dedicated APIs, or web-based client UIs (such as parity), which means that validation is most likely being done at some point, but contracts can also be transacted to directly which means that no guarantees can be made unless the validation is done in contract code.

The author has been working with strings in Solidity and LLL, and has written a lot of code, tests, and benchmarks related to the processing of UTF-8 and ASCII strings. An example of a library used for UTF-8 validation in Solidity can be found here: https://github.com/ethereum/solidity-examples/blob/master/docs/strings/Strings.md. Working with string processing is what motivated this EIP.

## Specification

In the Ethereum ABI specification, a `string` is a "dynamically sized unicode string assumed to be UTF-8 encoded". Strings are currently encoded in the same way as `bytes`, with the same 32 byte header. The header contains the "length" of the string, which is the number of bytes that the string occupies.

The new string header would instead have three parts: *length*, *range*, and *reserved*.

| Section              | position (little endian)  |  size  | total size |
|----------------------|---------------------------|--------|------------|
| length (bytes)       | 0                         | 8      | 8          |
| range                | 8                         | 8      | 16         |
| reserved             | 16                        | 16     | 32         |

##### length

The length is the length of the data in bytes (same as it is now).

##### range

The range is an unsigned 8 byte integer, which is to be interpreted as the upper bound for character values. The lower bound is always `0`.

A range of `0` means that the standard byte encoding is used, so it is the same as setting it to `255`. This is to make `string` compatible with `bytes`.

Validating a string is done by checking that none of its characters has a value that is outside of the range.

Note that non power-of-two character-widths are not ideal, because they lead to inefficient use of storage (a single value could have its bytes spread out over more then one storage slot).

##### reserved

Reserved space can be used to store additional information. Using it is optional, but it can not be assumed to be empty.

#### Using the reserved section

The reserved section could be used to make more advanced strings possible.

| Section              | position (little endian)  |  size  | total size |
|----------------------|---------------------------|--------|------------|
| length (bytes)       | 0                         | 8      | 8          |
| range                | 8                         | 8      | 16         |
| format               | 16                        | 8      | 24         |
| reserved             | 24                        | 7      | 31         |
| extra bytes          | 31                        | 1      | 32         |

##### format

The format is an identifier, and would usually indicate that the string has a particular format. This format could for example be backed by a *character mapping*, but that is not a requirement (see the character mappings section for more information).

The zero key (i.e. `key == 0`) would be reserved for the standard byte encoding (range `0`).

##### extra bytes (optional)

The extra bytes field is optional, but can (and should) be used to avoid having to recompute the character width every time it is needed. The value held in this field must be one less then the (smallest) amount of bytes that is required to hold a character. Putting it in the last byte means it can be accessed using a single bit-shift operation (no masking is needed), which means that index access and length computation becomes slightly more efficient.

The reason for using extra bytes and not the character width itself is to stay compatible with the standard byte encoding.

### Character mappings and keys

A character mapping can be seen as a *locale* where the alphabet of the string is defined. The alphabet must be an array in which every index is mapped to a (unique) value from some set of integer values (UTF-8 code-points for example).

An example alphabet would be: `[0, 'a', 'b', 'c', 'd', 'e', 'f', 'g']`. This contains 8 UTF-8 characters indexed from 0 to 7. A string created from this alphabet would require 8 bits per character, so the range for this alphabet is `7`.

If the format identifier is `1`, and the length of a string is `10`, the relevant fields would be:

- length: **10**
- key: **1**
- range: **7**
- extraBytes: **0**

This is the header: `0x000000000000000000000000000000010000000000000007000000000000000a`

If the string is `"bababababa"`, the full encoding would be:

`0x000000000000000000000000000000010000000000000007000000000000000a0201020102010201020100000000000000000000000000000000000000000000`

When alphabets are created in this way, a simple range check is enough to do validation inside contracts, provided that all the characters in the alphabet are valid members of the target set (in this case UTF-8), and assuming that the alphabet contains no doubles.

#### standard formats

##### ASCII

ASCII could have format id `0` (standard byte encoding).

Standard ASCII would be the same as the default byte encoding but with the range set to `127`. The ISO/IEC 8859-1 extended ASCII table could be used as the default encoding for the full `255` range.

Besides allowing for `O(1)` index access and length computation, this would also be more storage efficient for many (latin-based) languages, as the standard extended ASCII tables only uses one byte per extended character (`ñ, é, å, ö, etc.)` whereas UTF-8 uses two.

##### Integer arrays

A range of standard format IDs could be reserved for (tightly packed) unsigned integer arrays. In thoe mappings, each index would be implicitly mapped to its own value. This would give arrays of every unsigned integer type (`uintN[]`) a well-defined string representation, although it should be noted that these representations would be possible with only the basic (length + range) header as well.

A range of formats could be reserved for (tightly packed) signed integer encodings as well. It could be working just like unsigned integer arrays using the standard two's complement representations.

Similar formats could be created for other types of arrays as well.

## Rationale

Changing the string header enables encoding schemes that would make runtime processing and validation of strings a lot easier. Index access and length computations would all be `O(1)` operations, which is necessary for efficient string processing. Also, in order to validate these strings, the contract only has to create `uint`s from sequences of bytes and do *less than or equal* comparisons.

Additionally, some languages that would normally require multiple bytes per characters could be used in a more efficient way by defining an alphabet made up only of characters from that language. The bytes per character would only depend on the total number of characters in the alphabet.

## Backwards compatibility

This is backwards compatible except in the cases where strings have a length of `2**64` or more. Languages would have to modify the code that deals with the length of a string (Solidity does not have that yet). They would also have to go over the system they use for processing string literals.
