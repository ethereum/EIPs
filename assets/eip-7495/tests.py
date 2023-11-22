from typing import Optional, Type
from remerkleable.basic import uint8, uint16
from remerkleable.bitfields import Bitvector
from remerkleable.complex import Container
from stable_container import OneOf, StableContainer, Variant

# Serialization and merkleization format
class Shape(StableContainer[4]):
    side: Optional[uint16]
    color: uint8
    radius: Optional[uint16]

# Valid variants
class Square(Variant[Shape]):
    side: uint16
    color: uint8

class Circle(Variant[Shape]):
    radius: uint16
    color: uint8

class AnyShape(OneOf[Shape]):
    @classmethod
    def select_variant(cls, value: Shape, circle_allowed = False) -> Type[Shape]:
        if value.radius is not None:
            assert circle_allowed
            return Circle
        if value.side is not None:
            return Square
        assert False

# Helper containers for merkleization testing
class ShapePayload(Container):
    side: uint16
    color: uint8
    radius: uint16
class ShapeRepr(Container):
    value: ShapePayload
    active_fields: Bitvector[4]

# Square tests
shape1 = Shape(side=0x42, color=1, radius=None)
square_bytes = bytes.fromhex("03420001")
square1 = Square(side=0x42, color=1)
square2 = Square(backing=shape1.get_backing())
square3 = Square(backing=square1.get_backing())
assert shape1 == square1 == square2 == square3
assert (
    shape1.encode_bytes() == square1.encode_bytes() ==
    square2.encode_bytes() == square3.encode_bytes() ==
    square_bytes
)
assert (
    Shape.decode_bytes(square_bytes) ==
    Square.decode_bytes(square_bytes) ==
    AnyShape.decode_bytes(square_bytes) ==
    AnyShape.decode_bytes(square_bytes, circle_allowed = True)
)
assert (
    shape1.hash_tree_root() == square1.hash_tree_root() ==
    square2.hash_tree_root() == square3.hash_tree_root() ==
    ShapeRepr(
        value=ShapePayload(side=0x42, color=1, radius=0),
        active_fields=Bitvector[4](True, True, False, False),
    ).hash_tree_root()
)
try:
    circle = Circle(side=0x42, color=1)
    assert False
except:
    pass
try:
    circle = Circle(backing=shape1.get_backing())
    assert False
except:
    pass
try:
    circle = Circle.decode_bytes(square_bytes)
    assert False
except:
    pass
shape1.side = 0x1337
square1.side = 0x1337
square2.side = 0x1337
square3.side = 0x1337
square_bytes = bytes.fromhex("03371301")
assert shape1 == square1 == square2 == square3
assert (
    shape1.encode_bytes() == square1.encode_bytes() ==
    square2.encode_bytes() == square3.encode_bytes() ==
    square_bytes
)
assert (
    Shape.decode_bytes(square_bytes) ==
    Square.decode_bytes(square_bytes) ==
    AnyShape.decode_bytes(square_bytes) ==
    AnyShape.decode_bytes(square_bytes, circle_allowed = True)
)
assert (
    shape1.hash_tree_root() == square1.hash_tree_root() ==
    square2.hash_tree_root() == square3.hash_tree_root() ==
    ShapeRepr(
        value=ShapePayload(side=0x1337, color=1, radius=0),
        active_fields=Bitvector[4](True, True, False, False),
    ).hash_tree_root()
)
try:
    square1.radius = 0x1337
    assert False
except:
    pass
try:
    square1.side = None
    assert False
except:
    pass

# Circle tests
shape2 = Shape(side=None, color=1, radius=0x42)
circle_bytes = bytes.fromhex("06014200")
circle1 = Circle(radius=0x42, color=1)
circle2 = Circle(backing=shape2.get_backing())
circle3 = Circle(backing=circle1.get_backing())
circle4 = shape1
circle4.side = None
circle4.radius = 0x42
assert shape2 == circle1 == circle2 == circle3 == circle4
assert (
    shape2.encode_bytes() == circle1.encode_bytes() ==
    circle2.encode_bytes() == circle3.encode_bytes() ==
    circle4.encode_bytes() ==
    circle_bytes
)
assert (
    Shape.decode_bytes(circle_bytes) ==
    Circle.decode_bytes(circle_bytes) ==
    AnyShape.decode_bytes(circle_bytes, circle_allowed = True)
)
assert (
    shape2.hash_tree_root() == circle1.hash_tree_root() ==
    circle2.hash_tree_root() == circle3.hash_tree_root() ==
    circle4.hash_tree_root() ==
    ShapeRepr(
        value=ShapePayload(side=0, color=1, radius=0x42),
        active_fields=Bitvector[4](False, True, True, False),
    ).hash_tree_root()
)
try:
    square = Square(radius=0x42, color=1)
    assert False
except:
    pass
try:
    square = Square(backing=shape2.get_backing())
    assert False
except:
    pass
try:
    square = Square.decode_bytes(circle_bytes)
    assert False
except:
    pass
try:
    circle = AnyShape.decode_bytes(circle_bytes, circle_allowed = False)
    assert False
except:
    pass

# Unsupported tests
shape3 = Shape(side=None, color=1, radius=None)
shape3_bytes = bytes.fromhex("0201")
assert shape3.encode_bytes() == shape3_bytes
assert Shape.decode_bytes(shape3_bytes) == shape3
try:
    shape = Square.decode_bytes(shape3_bytes)
    assert False
except:
    pass
try:
    shape = Circle.decode_bytes(shape3_bytes)
    assert False
except:
    pass
try:
    shape = AnyShape.decode_bytes(shape3_bytes)
    assert False
except:
    pass
shape4 = Shape(side=0x42, color=1, radius=0x42)
shape4_bytes = bytes.fromhex("074200014200")
assert shape4.encode_bytes() == shape4_bytes
assert Shape.decode_bytes(shape4_bytes) == shape4
try:
    shape = Square.decode_bytes(shape4_bytes)
    assert False
except:
    pass
try:
    shape = Circle.decode_bytes(shape4_bytes)
    assert False
except:
    pass
try:
    shape = AnyShape.decode_bytes(shape4_bytes)
    assert False
except:
    pass
try:
    shape = AnyShape.decode_bytes("00")
    assert False
except:
    pass
try:
    shape = Shape.decode_bytes("00")
    assert False
except:
    pass
