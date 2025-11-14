from Crypto.Hash import SHAKE256 as PyCryptoDomeShake
from shake import SHAKE
import os
import unittest
from random import randint


class TestShake(unittest.TestCase):

    def test_vs_pycryptodome(self):
        for _ in range(10):
            output_size = randint(1, 100)
            message = os.urandom(123)

            # Using PyCryptoDome
            shake = PyCryptoDomeShake.new()
            shake.update(message)
            output_1 = shake.read(output_size)

            # Using our implementation
            s = SHAKE.new()
            s.update(message)
            s.flip()
            output_2 = s.read(output_size)

            # Assert that it matches
            self.assertEqual(output_1, output_2)

    def test_for_renaud(self):
        from binascii import unhexlify as unhx
        # from coruus test vectors
        message = "B32D95B0B9AAD2A8816DE6D06D1F86008505BD8C14124F6E9A163B5A2ADE55F835D0EC3880EF50700D3B25E42CC0AF050CCD1BE5E555B23087E04D7BF9813622780C7313A1954F8740B6EE2D3F71F768DD417F520482BD3A08D4F222B4EE9DBD015447B33507DD50F3AB4247C5DE9A8ABD62A8DECEA01E3B87C8B927F5B08BEB37674C6F8E380C04"
        expected = "cc2eaa04eef8479cdae8566eb8ffa1100a407995bf999ae97ede526681dc3490616f28442d20da92124ce081588b81491aedf65caaf0d27e82a4b0e1d1cab23833328f1b8da430c8a08766a86370fa848a79b5998db3cffd057b96e1e2ee0ef229eca133c15548f9839902043730e44bc52c39fadc1ddeead95f9939f220ca300661540df7edd9af378a5d4a19b2b93e6c78f49c353343a0b5f119132b5312d004831d01769a316d2f51bf64ccb20a21c2cf7ac8fb6f6e90706126bdae0611dd13962e8b53d6eae26c7b0d2551daf6248e9d65817382b04d23392d108e4d3443de5adc7273c721a8f8320ecfe8177ac067ca8a50169a6e73000ebcdc1e4ee6339fc867c3d7aeab84146398d7bade121d1989fa457335564e975770a3a00259ca08706108261aa2d34de00f8cac7d45d35e5aa63ea69e1d1a2f7dab3900d51e0bc65348a25554007039a52c3c309980d17cad20f1156310a39cd393760cfe58f6f8ade42131288280a35e1db8708183b91cfaf5827e96b0f774c45093b417aff9dd6417e59964a01bd2a612ffcfba18a0f193db297b9a6cc1d270d97aae8f8a3a6b26695ab66431c202e139d63dd3a24778676cefe3e21b02ec4e8f5cfd66587a12b44078fcd39eee44bbef4a949a63c0dfd58cf2fb2cd5f002e2b0219266cfc031817486de70b4285a8a70f3d38a61d3155d99aaf4c25390d73645ab3e8d80f0"
        # using our shake implementation
        shake = SHAKE.new(data='')
        shake.update(unhx(message.lower()))
        shake.flip()
        self.assertEqual(shake.read(1088).hex()[0:1024], expected)

    def test_read_twice(self):
        from binascii import unhexlify as unhx
        # from coruus test vectors
        message = b"Hello my friend"
        # two reads
        shake = SHAKE.new(data='')
        shake.update(message)
        shake.flip()
        shake.read(2)
        out1 = shake.read(2)
        # one read
        shake = SHAKE.new(data='')
        shake.update(message)
        shake.flip()
        out2 = shake.read(4)
        self.assertEqual(out1, out2[2:4])

    def test_debug_h2p(self):
        from binascii import unhexlify as unhx
        salt = "77231395f6147293b68ceab7a9e0c58d864e8efde4e1b9a46cbe854713672f5caaae314ed9083dab"
        msg = "4d79206e616d652069732052656e617564"
        res = "ba50d4292b44271cadce6b8292cb0a4c885cff02317a4682b57be831fe8e9cea314a22913070dcf1317b4d34e8504d616015690c03c08e2614828dc27b382fd3f985bf8860d8577a0a5de93a66c53c65aec37d593b24a452e1b37203768228ed280f230473933486f793e94927783aa929c6bf3a056c59d6c2d971a0ac57e7d77167acc582ffec3c"
        shake = SHAKE.new(data='')
        shake.update(unhx(salt.lower()))
        shake.update(unhx(msg.lower()))
        shake.flip()
        self.assertEqual(shake.read(136).hex(), res)

    def test_absorb_twice(self):
        from binascii import unhexlify as unhx
        in1 = "abcd"
        in2 = "ef01"
        # absorb twice
        shake = SHAKE.new(data='')
        shake.update(unhx(in1))
        shake.update(unhx(in2))
        shake.flip()
        out1 = shake.read(32)
        # absorb both in one time
        shake2 = SHAKE.new(data='')
        shake2.update(unhx(in1) + unhx(in2))
        shake2.flip()
        out2 = shake2.read(32)
        self.assertEqual(out1, out2)

    def test_large_absorb(self):
        from binascii import unhexlify as unhx
        in1 = unhx("8b806e2aa93ea5ddc4dcd2b1a60234c75712006ea457526528f02ca66933297965735da00717a4776b415e8cbf6a1c6c06cd1409005d3d6a38b345207532989c")
        in2 = unhx("870458e57594cf92ade1aaad1474502aa81e6569529ba7855a1a7005e8595c464ed2c2514a12a8e0793c04718dde184a4285a0c668641ec010cd067624573855b27cc94712059839e808002a176c461a7d4f62561ab265497a745b6208d675699d831c5c8995162778e5296c89b7559d93488db4240b29504b526592a0395cd6a451e18d40c0ad0221381f292968aa1ce0c6298cf6551b7742d42a7e4fc07499657dc0505c0dc69d94e029dee29869b74a80a3a5c350a94d52a0075276d4c251694aad9554850a69549d08098746a105738892e594e170ade5711d0d383adb593267636c4c580c02113489d384c6981659280c64448951e92d29f88957097a5690165b4714c21071da061cc077920dd348e96a9ecd937a95f6009e724d62b938a7973cd0740e6567845ff21c105a405d12649e2539ebd9781e2840d8271de750624b977ca8444a05d6648326759228ad88730e8c12616944100a254a567105e0b87d992658e239211d5610c5e0ad4634a423f239d1ff40e0da4da959228c33909407acd56324668851d8453108395aa7370592d71543f33c937252d5531107b4150f810e03840c425420e7b70697674c1af0111310052b15a655432d690a8012a881da4928d6b35acdd44542a15ec293590844912bd921a01092e6380156315d1f277040b204de3879e1a1a1e0f74953b369d70a125b0a149f96940023619eca301ce834d763606a2340d6f44c1d8361477911def678d4aa90c33388612571eb496ed49700e6743604b714a3f4881e114d45093c4d597e1a68315fd6600223980eb83800534644e380eb737855e6611174184a868c90b562629925d952888213a5d3b945a5a26821371da0993e9d667c075580535659a84635634a640577a50b4968518a3414206d64c679179808ca666612f08c09794da6491ca7b985047792d773a6dd7344db0788c3397e5749a2cdc15554082c03440e2315919ac8694f9475dc836c11169062225acc997d20d46910e96dc18748d7627216ea3015368d25552ae032525141a51cd4589ae871e4a73cc5d070cc33720050ad117939999249")
        # absorb twice
        shake = SHAKE.new(data='')
        shake.update(in1)
        shake.update(in2)
        shake.flip()
        out1 = shake.read(32)
        # absorb both in one time
        shake2 = SHAKE.new(data='')
        shake2.update(in1 + in2)
        shake2.flip()
        out2 = shake2.read(32)
        self.assertEqual(out1, out2)
