import hashlib
import struct

from blake2s import IV, blake2s_compress


# 64-byte test message (must be exactly one block for fair comparison)
msg = b"hello world" * 5 + b"!!"  # 57 bytes
msg = msg.ljust(64, b"\x00")     # pad to full 64 bytes
msg_words = list(struct.unpack("<16I", msg))  # 16 32-bit words, little-endian

h = IV.copy()
h[0] ^= 0x01010020  # 0x20 = 32-byte digest

# Total bytes so far: 64
t0 = 64
t1 = 0
f0 = 0xFFFFFFFF  # last block flag
f1 = 0

# Run your custom blake2s_compress()
custom_state = blake2s_compress(
    h=h, message=msg_words, t0=t0, t1=t1, f0=f0, f1=f1)

# Convert final state to 32-byte digest (little-endian)
custom_digest = b''.join(struct.pack("<I", word) for word in custom_state)

# Run hashlib.blake2s
hashlib_digest = hashlib.blake2s(msg).digest()

# Print and compare
print("Custom  digest:", custom_digest.hex())
print("Hashlib digest:", hashlib_digest.hex())

assert custom_digest == hashlib_digest, "Digests do not match!"
print("✅ Digest match!")
