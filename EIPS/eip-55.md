```
EIP: 55
Title: Mixed-case checksum address encoding
Author: Vitalik Buterin
Type: Standard Track
Category: ERC
Status: Accepted
Created: 2016-01-14
```

# Specification

Code:

``` python
from ethereum import utils

def checksum_encode(addr): # Takes a 20-byte binary address as input
    o = ''
    v = utils.big_endian_to_int(utils.sha3(addr.hex()))
    for i, c in enumerate(addr.hex()):
        if c in '0123456789':
            o += c
        else:
            o += c.upper() if (v & (2**(255 - 4*i))) else c.lower()
    return '0x'+o

def test(addrstr):
    assert(addrstr == checksum_encode2(bytes.fromhex(addrstr[2:])))

test('0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed')
test('0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359')
test('0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB')
test('0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb')

```

In English, convert the address to hex, but if the `i`th digit is a letter (ie. it's one of `abcdef`) print it in uppercase if the `4*i`th bit of the hash of the address is 1 otherwise print it in lowercase.

# Implementation

In javascript:

```js
const createKeccakHash = require('keccak')

function toChecksumAddress (address) {
  address = address.toLowerCase().replace('0x','');
  var hash = createKeccakHash('keccak256').update(address).digest('hex')
  var ret = '0x'

  for (var i = 0; i < address.length; i++) {
    if (parseInt(hash[i], 16) >= 8) {
      ret += address[i].toUpperCase()
    } else {
      ret += address[i]
    }
  }

  return ret
}
```

```
> toChecksumAddress('0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359')
'0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359'
```

Note that the input to the Keccak256 hash is the lowercase hexadecimal string (i.e. the hex address encoded as ASCII):

```
    var hash = createKeccakHash('keccak256').update(Buffer.from(address.toLowerCase(), 'ascii')).digest()
```

# Rationale

Benefits:
- Backwards compatible with many hex parsers that accept mixed case, allowing it to be easily introduced over time
- Keeps the length at 40 characters
- On average there will be 15 check bits per address, and the net probability that a randomly generated address if mistyped will accidentally pass a check is 0.0247%. This is a ~50x improvement over ICAP, but not as good as a 4-byte check code.

# References

1. EIP 55 issue and discussion https://github.com/ethereum/eips/issues/55
2. Python example by @Recmo https://github.com/ethereum/eips/issues/55#issuecomment-261521584
3. Ethereumjs-util implementation https://github.com/ethereumjs/ethereumjs-util/blob/75f529458bc7dc84f85fd0446d0fac92d991c262/index.js#L452-L466
