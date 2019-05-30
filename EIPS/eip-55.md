---
eip: 55
title: Mixed-case checksum address encoding
author: Vitalik Buterin <vitalik.buterin@ethereum.org>, Alex Van de Sande <avsa@ethereum.org>
type: Standards Track
category: ERC
status: Final
created: 2016-01-14
---

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
    assert(addrstr == checksum_encode(bytes.fromhex(addrstr[2:])))

test('0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed')
test('0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359')
test('0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB')
test('0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb')

```

In English, convert the address to hex, but if the `i`th digit is a letter (ie. it's one of `abcdef`) print it in uppercase if the `4*i`th bit of the hash of the lowercase hexadecimal address is 1 otherwise print it in lowercase.

# Rationale

Benefits:
- Backwards compatible with many hex parsers that accept mixed case, allowing it to be easily introduced over time
- Keeps the length at 40 characters
- On average there will be 15 check bits per address, and the net probability that a randomly generated address if mistyped will accidentally pass a check is 0.0247%. This is a ~50x improvement over ICAP, but not as good as a 4-byte check code.

# Implementation

In javascript:

```js
const createKeccakHash = require('keccak')

function toChecksumAddress (address) {
  address = address.toLowerCase().replace('0x', '')
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

# Test Cases

```
# All caps
0x52908400098527886E0F7030069857D2E4169EE7
0x8617E340B3D01FA5F11F306F4090FD50E238070D
# All Lower
0xde709f2102306220921060314715629080e2fb77
0x27b1fdb04752bbc536007a920d24acb045561c26
# Normal
0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed
0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359
0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB
0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb
```

# Adoption

| Wallet                   | displays checksummed addresses | rejects invalid mixed-case | rejects too short | rejects too long |
|--------------------------|--------------------------------|----------------------------|-------------------|------------------|
| Etherwall 2.0.1          | Yes                            | Yes                        | Yes               | Yes              |
| Jaxx 1.2.17              | No                             | Yes                        | Yes               | Yes              |
| MetaMask 3.7.8           | Yes                            | Yes                        | Yes               | Yes              |
| Mist 0.8.10              | Yes                            | Yes                        | Yes               | Yes              |
| MyEtherWallet v3.9.4     | Yes                            | Yes                        | Yes               | Yes              |
| Parity 1.6.6-beta (UI)   | Yes                            | Yes                        | Yes               | Yes              |
| Jaxx Liberty 2.0.0       | Yes                            | Yes                        | Yes               | Yes              |
| Coinomi 1.10             | Yes                            | Yes                        | Yes               | Yes              |
| Trust Wallet             | Yes                            | Yes                        | Yes               | Yes              |

### Exchange support for mixed-case address checksums, as of 2017-05-27:

| Exchange     | displays checksummed deposit addresses | rejects invalid mixed-case | rejects too short | rejects too long |
|--------------|----------------------------------------|----------------------------|-------------------|------------------|
| Bitfinex     | No                                     | Yes                        | Yes               | Yes              |
| Coinbase     | Yes                                    | No                         | Yes               | Yes              |
| GDAX         | Yes                                    | Yes                        | Yes               | Yes              |
| Kraken       | No                                     | No                         | Yes               | Yes              |
| Poloniex     | No                                     | No                         | Yes               | Yes              |
| Shapeshift   | No                                     | No                         | Yes               | Yes              |

# References

1. EIP 55 issue and discussion https://github.com/ethereum/eips/issues/55
2. Python example by @Recmo https://github.com/ethereum/eips/issues/55#issuecomment-261521584
3. Python implementation in [`ethereum-utils`](https://github.com/pipermerriam/ethereum-utils#to_checksum_addressvalue---text)
4. Ethereumjs-util implementation https://github.com/ethereumjs/ethereumjs-util/blob/75f529458bc7dc84f85fd0446d0fac92d991c262/index.js#L452-L466
5. Swift implementation in [`EthereumKit`](https://github.com/yuzushioh/EthereumKit/blob/master/EthereumKit/Helper/EIP55.swift)
6. Kotlin implementation in [`KEthereum`](https://github.com/walleth/kethereum/tree/master/erc55)
