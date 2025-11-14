# import unittest
# from blake2s_prng import Blake2sPRNG
# from falcon import hash_to_point


# def print_rfc_hash_to_words(hex_str):
#     # Conversion to words for Cairo format
#     b = bytes.fromhex(hex_str)
#     words = []
#     for i in range(0, len(b), 4):
#         # Extract 4 bytes chunk
#         chunk = b[i:i+4]
#         # Interpret as little-endian uint32
#         word = int.from_bytes(chunk, 'little')
#         words.append(word)
#     print("[")
#     for word in words:
#         print('\t{},'.format(word))
#     print("],")


# class TestHashToPointBlake2s(unittest.TestCase):

#     def test_HashToPoint_Blake2s(self):
#         print()
#         salt = "12341234123412341234".encode()  # 40 bytes
#         message = "5678567856785678".encode()  # 32 bytes

#         h = Blake2sPRNG()
#         h.update(message)
#         h.update(salt)
#         h.flip()
#         print_rfc_hash_to_words(h.read(16).hex())
#         h = Blake2sPRNG()
#         h.update(message)
#         h.update(salt)
#         h.flip()
#         two_bytes = h.read(2)
#         elt = (two_bytes[0] << 8) + two_bytes[1]
#         while elt >= 61445:
#             two_bytes = h.read(2)
#             elt = (two_bytes[0] << 8) + two_bytes[1]

#         # res = hash_to_point(512, message, salt, xof=Blake2sPRNG)
#         # print()
#         # print(res[0:2])
#         # res = hash_to_point(512, salt, message, xof=Blake2sPRNG)
#         # print(res[0:2])
