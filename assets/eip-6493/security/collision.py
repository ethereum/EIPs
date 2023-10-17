from remerkleable.byte_arrays import ByteList, ByteVector
from remerkleable.complex import Container

class Signature(ByteVector[65]):
    pass

class FooTransaction(Container):
    x: ByteVector[73]

class FooSignedTransaction(Container):
    message: FooTransaction
    signature: Signature

class BarTransaction(Container):
    x: ByteList[65]

class BarSignedTransaction(Container):
    message: BarTransaction
    signature: Signature

FooSignedTransaction(
    message=FooTransaction(
        x=bytes.fromhex('45000000bf9f6e691dc8d90c41308b3155baf8095a3b10b4ddf8cac808cb755ba872e14b5ee6f49aa43f89715d24235bf49ffa6cd30179e44e360fc0458bc5b4f3458fc31404000000'),
    ),
    signature=bytes.fromhex('a70279ba3b0c56b04cbaeb805e5f36e9214427f2df26d906e0e05cd013cb25463dec281a060b3df5d240c1354113fbdbac70d2f1392002dbd0b7a4f991a0996001'),
).encode_bytes() == \
BarSignedTransaction(
    message=BarTransaction(
        x=bytes.fromhex('a70279ba3b0c56b04cbaeb805e5f36e9214427f2df26d906e0e05cd013cb25463dec281a060b3df5d240c1354113fbdbac70d2f1392002dbd0b7a4f991a0996001'),
    ),
    signature=bytes.fromhex('f3d2ea8ea566a9ce680fc638a00127f183f22c98eceb0d909b7c8660faca3a46648a9da6f40f515cb39d18dbf5f4526a052736832a8bb6234b27e9e536a531a400'),
).encode_bytes()
