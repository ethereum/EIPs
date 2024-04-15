from typing import Optional, Type
from remerkleable.basic import uint8, uint16
from remerkleable.bitfields import Bitvector
from remerkleable.complex import Container
from stable_container import OneOf, StableContainer, Variant

# Defines the common merkleization format and a portable serialization format across variants
class Shape(StableContainer[4]):
    side: Optional[uint16]
    color: uint8
    radius: Optional[uint16]

# Inherits merkleization format from `Shape`, but is serialized more compactly
class Square(Variant[Shape]):
    side: uint16
    color: uint8

# Inherits merkleization format from `Shape`, but is serialized more compactly
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
square_bytes_stable = bytes.fromhex("03420001")
square_bytes_variant = bytes.fromhex("420001")
square_root = ShapeRepr(
    value=ShapePayload(side=0x42, color=1, radius=0),
    active_fields=Bitvector[4](True, True, False, False),
).hash_tree_root()
shapes = [Shape(side=0x42, color=1, radius=None)]
squares = [Square(side=0x42, color=1)]
squares.extend(list(Square(backing=shape.get_backing()) for shape in shapes))
shapes.extend(list(Shape(backing=shape.get_backing()) for shape in shapes))
shapes.extend(list(Shape(backing=square.get_backing()) for square in squares))
squares.extend(list(Square(backing=square.get_backing()) for square in squares))
assert len(set(shapes)) == 1
assert len(set(squares)) == 1
assert all(shape.encode_bytes() == square_bytes_stable for shape in shapes)
assert all(square.encode_bytes() == square_bytes_variant for square in squares)
assert (
    Square(backing=Shape.decode_bytes(square_bytes_stable).get_backing()) ==
    Square.decode_bytes(square_bytes_variant) ==
    AnyShape.decode_bytes(square_bytes_stable) ==
    AnyShape.decode_bytes(square_bytes_stable, circle_allowed = True)
)
assert all(shape.hash_tree_root() == square_root for shape in shapes)
assert all(square.hash_tree_root() == square_root for square in squares)
try:
    circle = Circle(side=0x42, color=1)
    assert False
except:
    pass
for shape in shapes:
    try:
        circle = Circle(backing=shape.get_backing())
        assert False
    except:
        pass
for square in squares:
    try:
        circle = Circle(backing=square.get_backing())
        assert False
    except:
        pass
for shape in shapes:
    shape.side = 0x1337
for square in squares:
    square.side = 0x1337
square_bytes_stable = bytes.fromhex("03371301")
square_bytes_variant = bytes.fromhex("371301")
square_root = ShapeRepr(
    value=ShapePayload(side=0x1337, color=1, radius=0),
    active_fields=Bitvector[4](True, True, False, False),
).hash_tree_root()
assert len(set(shapes)) == 1
assert len(set(squares)) == 1
assert all(shape.encode_bytes() == square_bytes_stable for shape in shapes)
assert all(square.encode_bytes() == square_bytes_variant for square in squares)
assert (
    Square(backing=Shape.decode_bytes(square_bytes_stable).get_backing()) ==
    Square.decode_bytes(square_bytes_variant) ==
    AnyShape.decode_bytes(square_bytes_stable) ==
    AnyShape.decode_bytes(square_bytes_stable, circle_allowed = True)
)
assert all(shape.hash_tree_root() == square_root for shape in shapes)
assert all(square.hash_tree_root() == square_root for square in squares)
for square in squares:
    try:
        square.radius = 0x1337
        assert False
    except:
        pass
for square in squares:
    try:
        square.side = None
        assert False
    except:
        pass

# Circle tests
circle_bytes_stable = bytes.fromhex("06014200")
circle_bytes_variant = bytes.fromhex("420001")
circle_root = ShapeRepr(
    value=ShapePayload(side=0, color=1, radius=0x42),
    active_fields=Bitvector[4](False, True, True, False),
).hash_tree_root()
modified_shape = shapes[0]
modified_shape.side = None
modified_shape.radius = 0x42
shapes = [Shape(side=None, color=1, radius=0x42), modified_shape]
circles = [Circle(radius=0x42, color=1)]
circles.extend(list(Circle(backing=shape.get_backing()) for shape in shapes))
shapes.extend(list(Shape(backing=shape.get_backing()) for shape in shapes))
shapes.extend(list(Shape(backing=circle.get_backing()) for circle in circles))
circles.extend(list(Circle(backing=circle.get_backing()) for circle in circles))
assert len(set(shapes)) == 1
assert len(set(circles)) == 1
assert all(shape.encode_bytes() == circle_bytes_stable for shape in shapes)
assert all(circle.encode_bytes() == circle_bytes_variant for circle in circles)
assert (
    Circle(backing=Shape.decode_bytes(circle_bytes_stable).get_backing()) ==
    Circle.decode_bytes(circle_bytes_variant) ==
    AnyShape.decode_bytes(circle_bytes_stable, circle_allowed = True)
)
assert all(shape.hash_tree_root() == circle_root for shape in shapes)
assert all(circle.hash_tree_root() == circle_root for circle in circles)
try:
    square = Square(radius=0x42, color=1)
    assert False
except:
    pass
for shape in shapes:
    try:
        square = Square(backing=shape.get_backing())
        assert False
    except:
        pass
for circle in circles:
    try:
        square = Square(backing=circle.get_backing())
        assert False
    except:
        pass
try:
    circle = AnyShape.decode_bytes(circle_bytes_stable, circle_allowed = False)
    assert False
except:
    pass

# Unsupported tests
shape = Shape(side=None, color=1, radius=None)
shape_bytes = bytes.fromhex("0201")
assert shape.encode_bytes() == shape_bytes
assert Shape.decode_bytes(shape_bytes) == shape
try:
    shape = Square.decode_bytes(shape_bytes)
    assert False
except:
    pass
try:
    shape = Circle.decode_bytes(shape_bytes)
    assert False
except:
    pass
try:
    shape = AnyShape.decode_bytes(shape_bytes)
    assert False
except:
    pass
shape = Shape(side=0x42, color=1, radius=0x42)
shape_bytes = bytes.fromhex("074200014200")
assert shape.encode_bytes() == shape_bytes
assert Shape.decode_bytes(shape_bytes) == shape
try:
    shape = Square.decode_bytes(shape_bytes)
    assert False
except:
    pass
try:
    shape = Circle.decode_bytes(shape_bytes)
    assert False
except:
    pass
try:
    shape = AnyShape.decode_bytes(shape_bytes)
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
try:
    square = Square(radius=0x42, color=1)
    assert False
except:
    pass
try:
    circle = Circle(side=0x42, color=1)
    assert False
except:
    pass

# Surrounding container tests
class ShapeContainer(Container):
    shape: Shape
    square: Square
    circle: Circle

class ShapeContainerRepr(Container):
    shape: ShapeRepr
    square: ShapeRepr
    circle: ShapeRepr

container = ShapeContainer(
    shape=Shape(side=0x42, color=1, radius=0x42),
    square=Square(side=0x42, color=1),
    circle=Circle(radius=0x42, color=1),
)
container_bytes = bytes.fromhex("0a000000420001420001074200014200")
assert container.encode_bytes() == container_bytes
assert ShapeContainer.decode_bytes(container_bytes) == container
assert container.hash_tree_root() == ShapeContainerRepr(
    shape=ShapeRepr(
        value=ShapePayload(side=0x42, color=1, radius=0x42),
        active_fields=Bitvector[4](True, True, True, False),
    ),
    square=ShapeRepr(
        value=ShapePayload(side=0x42, color=1, radius=0),
        active_fields=Bitvector[4](True, True, False, False),
    ),
    circle=ShapeRepr(
        value=ShapePayload(side=0, color=1, radius=0x42),
        active_fields=Bitvector[4](False, True, True, False),
    ),
).hash_tree_root()
