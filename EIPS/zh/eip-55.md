---
eip: 55
title: 混合大小写校验和地址编码
author: Vitalik Buterin <vitalik.buterin@ethereum.org>, Alex Van de Sande <avsa@ethereum.org>
discussions-to: https://github.com/ethereum/eips/issues/55
type: Standards Track
category: ERC
status: Final
created: 2016-01-14
---

# 规范

代码:

``` python
import eth_utils


def checksum_encode(addr): # Takes a 20-byte binary address as input
    hex_addr = addr.hex()
    checksummed_buffer = ""

    # Treat the hex address as ascii/utf-8 for keccak256 hashing
    hashed_address = eth_utils.keccak(text=hex_addr).hex()

    # Iterate over each character in the hex address
    for nibble_index, character in enumerate(hex_addr):

        if character in "0123456789":
            # We can't upper-case the decimal digits
            checksummed_buffer += character
        elif character in "abcdef":
            # Check if the corresponding hex digit (nibble) in the hash is 8 or higher
            hashed_address_nibble = int(hashed_address[nibble_index], 16)
            if hashed_address_nibble > 7:
                checksummed_buffer += character.upper()
            else:
                checksummed_buffer += character
        else:
            raise eth_utils.ValidationError(
                f"Unrecognized hex character {character!r} at position {nibble_index}"
            )

    return "0x" + checksummed_buffer


def test(addr_str):
    addr_bytes = eth_utils.to_bytes(hexstr=addr_str)
    checksum_encoded = checksum_encode(addr_bytes)
    assert checksum_encoded == addr_str, f"{checksum_encoded} != expected {addr_str}"


test("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed")
test("0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")
test("0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB")
test("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb")

```

在英语中，将地址转换为十六进制，但如果第 `i` 位是一个字母 (比如它是 `abcde` 中的一个），如果小写十六进制地址的哈希值的第 `4*i` 位为 1 ，则用大写打印，否则用小写打印。

# 基本原理

好处:
- 向后兼容许多接受混合大小写的十六进制解析器，允许它随着时间的推移很容易引入
- 保持长度为 40 个字符
- 平均每个地址将有 15 个检查位，并且一个随机生成的地址如果键入错误将意外通过检查的净概率是 0.0247%。与 `ICAP` 相比，这是大约 50 倍的改进，但不如 4 字节的检查代码好。

# 实现

在 `javascript` 中:

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

注意，`Keccak256` 哈希的输入是小写的十六进制字符串(即编码为 `ASCII` 的十六进制地址):

```
    var hash = createKeccakHash('keccak256').update(Buffer.from(address.toLowerCase(), 'ascii')).digest()
```

# 测试用例

```
# 全部大写
0x52908400098527886E0F7030069857D2E4169EE7
0x8617E340B3D01FA5F11F306F4090FD50E238070D
# 全部小写
0xde709f2102306220921060314715629080e2fb77
0x27b1fdb04752bbc536007a920d24acb045561c26
# 正常
0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed
0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359
0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB
0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb
```
