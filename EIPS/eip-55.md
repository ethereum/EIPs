EDITOR NOTE: below is a copy of the EIP 55 https://github.com/ethereum/eips/issues/55#issue-126609688 raw text fetched on 2017-06-24.

Code:

``` python
def checksum_encode(addr): # Takes a 20-byte binary address as input
    o = ''
    v = utils.big_endian_to_int(utils.sha3(addr))
    for i, c in enumerate(addr.encode('hex')):
        if c in '0123456789':
            o += c
        else:
            o += c.upper() if (v & (2**(255 - i))) else c.lower()
    return '0x'+o
```

In English, convert the address to hex, but if the ith digit is a letter (ie. it's one of `abcdef`) print it in uppercase if the ith bit of the hash of the address (in binary form) is 1 otherwise print it in lowercase.

Benefits:
- Backwards compatible with many hex parsers that accept mixed case, allowing it to be easily introduced over time
- Keeps the length at 40 characters
- ~~The average address will have 60 check bits, and less than 1 in 1 million addresses will have less than 32 check bits; this is stronger performance than nearly all other check schemes. Note that the very tiny chance that a given address will have very few check bits is dwarfed by the chance in any scheme that a bad address will randomly pass a check~~

UPDATE: I was actually wrong in my math above. I forgot that the check bits are per-hex-character, not per-bit (facepalm). On average there will be 15 check bits per address, and the net probability that a randomly generated address if mistyped will accidentally pass a check is 0.0247%. This is a ~50x improvement over ICAP, but not as good as a 4-byte check code.

Examples:
- `0xCd2a3d9f938e13Cd947eC05ABC7fe734df8DD826` (the "cow" address)
- `0x9Ca0e998dF92c5351cEcbBb6Dba82Ac2266f7e0C`
- `0xcB16D0E54450Cdd2368476E762B09D147972b637`
