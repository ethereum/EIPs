from typing import Optional
from remerkleable.basic import uint8, uint16, uint32, uint64
from remerkleable.bitfields import Bitvector
from remerkleable.complex import Container, List
from stable_container import Profile, StableContainer
import pytest

class Shape(StableContainer[4]):
    side: Optional[uint16]
    color: Optional[uint8]
    radius: Optional[uint16]

class Square(Profile[Shape]):
    side: uint16
    color: uint8

class Circle(Profile[Shape]):
    color: uint8
    radius: uint16

class ShapePair(Container):
    shape_1: Shape
    shape_2: Shape

class SquarePair(Container):
    shape_1: Square
    shape_2: Square

class CirclePair(Container):
    shape_1: Circle
    shape_2: Circle

# Helper containers for merkleization testing
class ShapePayload(Container):
    side: uint16
    color: uint8
    radius: uint16

class ShapeRepr(Container):
    value: ShapePayload
    active_fields: Bitvector[4]

class ShapePairRepr(Container):
    shape_1: ShapeRepr
    shape_2: ShapeRepr

# Square tests
square_bytes_stable = bytes.fromhex("03420001")
square_bytes_profile = bytes.fromhex("420001")
square_root = ShapeRepr(
    value=ShapePayload(side=0x42, color=1, radius=0),
    active_fields=Bitvector[4](True, True, False, False),
).hash_tree_root()
shapes = [Shape(side=0x42, color=1, radius=None)]
squares = [Square(side=0x42, color=1)]
squares.extend(list(Square.from_base(shape) for shape in shapes))
shapes.extend(list(Shape(
    side=shape.side, radius=shape.radius, color=shape.color
) for shape in shapes))
shapes.extend(list(square.to_base(Shape) for square in squares))
squares.extend(list(Square(side=square.side, color=square.color) for square in squares))
assert len(set(shapes)) == 1
assert len(set(squares)) == 1
assert all(shape.encode_bytes() == square_bytes_stable for shape in shapes)
assert all(square.encode_bytes() == square_bytes_profile for square in squares)
assert (
    Square.from_base(Shape.decode_bytes(square_bytes_stable)) ==
    Square.decode_bytes(square_bytes_profile)
)
assert all(shape.hash_tree_root() == square_root for shape in shapes)
assert all(square.hash_tree_root() == square_root for square in squares)
with pytest.raises(Exception):
    circle = Circle(side=0x42, color=1)
for shape in shapes:
    with pytest.raises(Exception):
        circle = Circle.from_base(shape)
for square in squares:
    with pytest.raises(Exception):
        circle = Circle.from_base(square.to_base(Shape))
for shape in shapes:
    shape.side = 0x1337
for square in squares:
    square.side = 0x1337
square_bytes_stable = bytes.fromhex("03371301")
square_bytes_profile = bytes.fromhex("371301")
square_root = ShapeRepr(
    value=ShapePayload(side=0x1337, color=1, radius=0),
    active_fields=Bitvector[4](True, True, False, False),
).hash_tree_root()
assert len(set(shapes)) == 1
assert len(set(squares)) == 1
assert all(shape.encode_bytes() == square_bytes_stable for shape in shapes)
assert all(square.encode_bytes() == square_bytes_profile for square in squares)
assert (
    Square.from_base(Shape.decode_bytes(square_bytes_stable)) ==
    Square.decode_bytes(square_bytes_profile)
)
assert all(shape.hash_tree_root() == square_root for shape in shapes)
assert all(square.hash_tree_root() == square_root for square in squares)
for square in squares:
    with pytest.raises(Exception):
        square.radius = 0x1337
for square in squares:
    with pytest.raises(Exception):
        square.side = None

# Circle tests
circle_bytes_stable = bytes.fromhex("06014200")
circle_bytes_profile = bytes.fromhex("014200")
circle_root = ShapeRepr(
    value=ShapePayload(side=0, color=1, radius=0x42),
    active_fields=Bitvector[4](False, True, True, False),
).hash_tree_root()
modified_shape = shapes[0]
modified_shape.side = None
modified_shape.radius = 0x42
shapes = [Shape(side=None, color=1, radius=0x42), modified_shape]
circles = [Circle(radius=0x42, color=1)]
circles.extend(list(Circle.from_base(shape) for shape in shapes))
shapes.extend(list(Shape(
    side=shape.side, radius=shape.radius, color=shape.color
) for shape in shapes))
shapes.extend(list(circle.to_base(Shape) for circle in circles))
circles.extend(list(Circle(radius=circle.radius, color=circle.color) for circle in circles))
assert len(set(shapes)) == 1
assert len(set(circles)) == 1
assert all(shape.encode_bytes() == circle_bytes_stable for shape in shapes)
assert all(circle.encode_bytes() == circle_bytes_profile for circle in circles)
assert (
    Circle.from_base(Shape.decode_bytes(circle_bytes_stable)) ==
    Circle.decode_bytes(circle_bytes_profile)
)
assert all(shape.hash_tree_root() == circle_root for shape in shapes)
assert all(circle.hash_tree_root() == circle_root for circle in circles)
with pytest.raises(Exception):
    square = Square(radius=0x42, color=1)
for shape in shapes:
    with pytest.raises(Exception):
        square = Square.from_base(shape)
for circle in circles:
    with pytest.raises(Exception):
        square = Square.from_base(circle.to_base(Shape))

# SquarePair tests
square_pair_bytes_stable = bytes.fromhex("080000000c0000000342000103690001")
square_pair_bytes_profile = bytes.fromhex("420001690001")
square_pair_root = ShapePairRepr(
    shape_1=ShapeRepr(
        value=ShapePayload(side=0x42, color=1, radius=0),
        active_fields=Bitvector[4](True, True, False, False),
    ),
    shape_2=ShapeRepr(
        value=ShapePayload(side=0x69, color=1, radius=0),
        active_fields=Bitvector[4](True, True, False, False),
    )
).hash_tree_root()
shape_pairs = [ShapePair(
    shape_1=Shape(side=0x42, color=1, radius=None),
    shape_2=Shape(side=0x69, color=1, radius=None),
)]
square_pairs = [SquarePair(
    shape_1=Square(side=0x42, color=1),
    shape_2=Square(side=0x69, color=1),
)]
square_pairs.extend(list(SquarePair.from_base(pair) for pair in shape_pairs))
shape_pairs.extend(list(ShapePair(
    shape_1=pair.shape_1, shape_2=pair.shape_2) for pair in shape_pairs))
shape_pairs.extend(list(pair.to_base(ShapePair) for pair in square_pairs))
square_pairs.extend(list(SquarePair(
    shape_1=pair.shape_1, shape_2=pair.shape_2) for pair in square_pairs))
assert len(set(shape_pairs)) == 1
assert len(set(square_pairs)) == 1
assert all(pair.encode_bytes() == square_pair_bytes_stable for pair in shape_pairs)
assert all(pair.encode_bytes() == square_pair_bytes_profile for pair in square_pairs)
assert (
    SquarePair.from_base(ShapePair.decode_bytes(square_pair_bytes_stable)) ==
    SquarePair.decode_bytes(square_pair_bytes_profile)
)
assert all(pair.hash_tree_root() == square_pair_root for pair in shape_pairs)
assert all(pair.hash_tree_root() == square_pair_root for pair in square_pairs)

# CirclePair tests
circle_pair_bytes_stable = bytes.fromhex("080000000c0000000601420006016900")
circle_pair_bytes_profile = bytes.fromhex("014200016900")
circle_pair_root = ShapePairRepr(
    shape_1=ShapeRepr(
        value=ShapePayload(side=0, color=1, radius=0x42),
        active_fields=Bitvector[4](False, True, True, False),
    ),
    shape_2=ShapeRepr(
        value=ShapePayload(side=0, color=1, radius=0x69),
        active_fields=Bitvector[4](False, True, True, False),
    )
).hash_tree_root()
shape_pairs = [ShapePair(
    shape_1=Shape(side=None, color=1, radius=0x42),
    shape_2=Shape(side=None, color=1, radius=0x69),
)]
circle_pairs = [CirclePair(
    shape_1=Circle(radius=0x42, color=1),
    shape_2=Circle(radius=0x69, color=1),
)]
circle_pairs.extend(list(CirclePair.from_base(pair) for pair in shape_pairs))
shape_pairs.extend(list(ShapePair(
    shape_1=pair.shape_1, shape_2=pair.shape_2) for pair in shape_pairs))
shape_pairs.extend(list(pair.to_base(ShapePair) for pair in circle_pairs))
circle_pairs.extend(list(CirclePair(
    shape_1=pair.shape_1, shape_2=pair.shape_2) for pair in circle_pairs))
assert len(set(shape_pairs)) == 1
assert len(set(circle_pairs)) == 1
assert all(pair.encode_bytes() == circle_pair_bytes_stable for pair in shape_pairs)
assert all(pair.encode_bytes() == circle_pair_bytes_profile for pair in circle_pairs)
assert (
    CirclePair.from_base(ShapePair.decode_bytes(circle_pair_bytes_stable)) ==
    CirclePair.decode_bytes(circle_pair_bytes_profile)
)
assert all(pair.hash_tree_root() == circle_pair_root for pair in shape_pairs)
assert all(pair.hash_tree_root() == circle_pair_root for pair in circle_pairs)

# Unsupported tests
shape = Shape(side=None, color=1, radius=None)
shape_bytes = bytes.fromhex("0201")
assert shape.encode_bytes() == shape_bytes
assert Shape.decode_bytes(shape_bytes) == shape
with pytest.raises(Exception):
    shape = Square.decode_bytes(shape_bytes)
with pytest.raises(Exception):
    shape = Circle.decode_bytes(shape_bytes)
shape = Shape(side=0x42, color=1, radius=0x42)
shape_bytes = bytes.fromhex("074200014200")
assert shape.encode_bytes() == shape_bytes
assert Shape.decode_bytes(shape_bytes) == shape
with pytest.raises(Exception):
    shape = Square.decode_bytes(shape_bytes)
with pytest.raises(Exception):
    shape = Circle.decode_bytes(shape_bytes)
with pytest.raises(Exception):
    shape = Shape.decode_bytes("00")
with pytest.raises(Exception):
    square = Square(radius=0x42, color=1)
with pytest.raises(Exception):
    circle = Circle(side=0x42, color=1)
with pytest.raises(Exception):
    square = Square.from_base(Circle(radius=0x42, color=1).to_base(Shape))

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
container_bytes = bytes.fromhex("0a000000420001014200074200014200")
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

# Nested surrounding container tests
shapes = List[Circle, 5](Circle(radius=0x42, color=1))
assert List[Circle, 5].from_base(shapes.to_base(List[Shape, 5])) == shapes
with pytest.raises(Exception):
    shapes = List[Square, 5].from_base(shapes.to_base(List[Shape, 5]))

shapes = Vector[Circle, 1](Circle(radius=0x42, color=1))
assert Vector[Circle, 1].from_base(shapes.to_base(Vector[Shape, 1])) == shapes
with pytest.raises(Exception):
    shapes = Vector[Square, 1].from_base(shapes.to_base(Vector[Shape, 1]))

class ShapeContainer(Container):
    shape: Shape

class SquareContainer(Container):
    shape: Square

class CircleContainer(Container):
    shape: Circle

shape = CircleContainer(shape=Circle(radius=0x42, color=1))
assert CircleContainer.from_base(shape.to_base(ShapeContainer)) == shape
with pytest.raises(Exception):
    shape = SquareContainer.from_base(shape.to_base(ShapeContainer))

class ShapeStableContainer(StableContainer[1]):
    shape: Optional[Shape]

class SquareStableContainer(StableContainer[1]):
    shape: Optional[Square]

class CircleStableContainer(StableContainer[1]):
    shape: Optional[Circle]

shape = CircleStableContainer(shape=Circle(radius=0x42, color=1))
assert CircleStableContainer.from_base(shape.to_base(ShapeStableContainer)) == shape
with pytest.raises(Exception):
    shape = SquareStableContainer.from_base(shape.to_base(ShapeStableContainer))

class NestedShapeContainer(Container):
    item: ShapeContainer

class NestedSquareContainer(Container):
    item: SquareContainer

class NestedCircleContainer(Container):
    item: CircleContainer

shape = NestedCircleContainer(item=CircleContainer(shape=Circle(radius=0x42, color=1)))
assert NestedCircleContainer.from_base(shape.to_base(NestedShapeContainer)) == shape
with pytest.raises(Exception):
    shape = NestedSquareContainer.from_base(shape.to_base(NestedShapeContainer))

# basic container
class Shape1(StableContainer[4]):
    side: Optional[uint16]
    color: Optional[uint8]
    radius: Optional[uint16]

# basic container with different depth
class Shape2(StableContainer[8]):
    side: Optional[uint16]
    color: Optional[uint8]
    radius: Optional[uint16]

# basic container with variable fields
class Shape3(StableContainer[8]):
    side: Optional[uint16]
    colors: Optional[List[uint8, 4]]
    radius: Optional[uint16]

stable_container_tests = [
    {
        'value': Shape1(side=0x42, color=1, radius=0x42),
        'serialized': '074200014200',
        'hash_tree_root': '37b28eab19bc3e246e55d2e2b2027479454c27ee006d92d4847c84893a162e6d'
    },
    {
        'value': Shape1(side=0x42, color=1, radius=None),
        'serialized': '03420001',
        'hash_tree_root': 'bfdb6fda9d02805e640c0f5767b8d1bb9ff4211498a5e2d7c0f36e1b88ce57ff'
    },
    {
        'value': Shape1(side=None, color=1, radius=None),
        'serialized': '0201',
        'hash_tree_root': '522edd7309c0041b8eb6a218d756af558e9cf4c816441ec7e6eef42dfa47bb98'
    },
    {
        'value': Shape1(side=None, color=1, radius=0x42),
        'serialized': '06014200',
        'hash_tree_root': 'f66d2c38c8d2afbd409e86c529dff728e9a4208215ca20ee44e49c3d11e145d8'
    },
    {
        'value': Shape2(side=0x42, color=1, radius=0x42),
        'serialized': '074200014200',
        'hash_tree_root': '0792fb509377ee2ff3b953dd9a88eee11ac7566a8df41c6c67a85bc0b53efa4e'
    },
    {
        'value': Shape2(side=0x42, color=1, radius=None),
        'serialized': '03420001',
        'hash_tree_root': 'ddc7acd38ae9d6d6788c14bd7635aeb1d7694768d7e00e1795bb6d328ec14f28'
    },
    {
        'value': Shape2(side=None, color=1, radius=None),
        'serialized': '0201',
        'hash_tree_root': '9893ecf9b68030ff23c667a5f2e4a76538a8e2ab48fd060a524888a66fb938c9'
    },
    {
        'value': Shape2(side=None, color=1, radius=0x42),
        'serialized': '06014200',
        'hash_tree_root': 'e823471310312d52aa1135d971a3ed72ba041ade3ec5b5077c17a39d73ab17c5'
    },
    {
        'value': Shape3(side=0x42, colors=[1, 2], radius=0x42),
        'serialized': '0742000800000042000102',
        'hash_tree_root': '1093b0f1d88b1b2b458196fa860e0df7a7dc1837fe804b95d664279635cb302f'
    },
    {
        'value': Shape3(side=0x42, colors=None, radius=None),
        'serialized': '014200',
        'hash_tree_root': '28df3f1c3eebd92504401b155c5cfe2f01c0604889e46ed3d22a3091dde1371f'
    },
    {
        'value': Shape3(side=None, colors=[1, 2], radius=None),
        'serialized': '02040000000102',
        'hash_tree_root': '659638368467b2c052ca698fcb65902e9b42ce8e94e1f794dd5296ceac2dec3e'
    },
    {
        'value': Shape3(side=None, colors=None, radius=0x42),
        'serialized': '044200',
        'hash_tree_root': 'd585dd0561c718bf4c29e4c1bd7d4efd4a5fe3c45942a7f778acb78fd0b2a4d2'
    },
    {
        'value': Shape3(side=None, colors=[1, 2], radius=0x42),
        'serialized': '060600000042000102',
        'hash_tree_root': '00fc0cecc200a415a07372d5d5b8bc7ce49f52504ed3da0336f80a26d811c7bf'
    }
]

for test in stable_container_tests:
    assert test['value'].encode_bytes().hex() == test['serialized']
    assert test['value'].hash_tree_root().hex() == test['hash_tree_root']

class StableFields(StableContainer[8]):
    foo: Optional[uint32]
    bar: Optional[uint64]
    quix: Optional[uint64]
    more: Optional[uint32]

class FooFields(Profile[StableFields]):
    foo: uint32
    more: Optional[uint32]

class BarFields(Profile[StableFields]):
    bar: uint64
    quix: uint64
    more: Optional[uint32]

assert issubclass((StableFields / '__active_fields__').navigate_type(), Bitvector)
assert (StableFields / '__active_fields__').navigate_type().vector_length() == 8
assert (StableFields / '__active_fields__').gindex() == 0b11
assert (StableFields / 'foo').navigate_type() == Optional[uint32]
assert (StableFields / 'foo').gindex() == 0b10000
assert (StableFields / 'bar').navigate_type() == Optional[uint64]
assert (StableFields / 'bar').gindex() == 0b10001
assert (StableFields / 'quix').navigate_type() == Optional[uint64]
assert (StableFields / 'quix').gindex() == 0b10010
assert (StableFields / 'more').navigate_type() == Optional[uint32]
assert (StableFields / 'more').gindex() == 0b10011

assert issubclass((FooFields / '__active_fields__').navigate_type(), Bitvector)
assert (FooFields / '__active_fields__').navigate_type().vector_length() == 8
assert (FooFields / '__active_fields__').gindex() == 0b11
assert (FooFields / 'foo').navigate_type() == uint32
assert (FooFields / 'foo').gindex() == 0b10000
assert (FooFields / 'more').navigate_type() == Optional[uint32]
assert (FooFields / 'more').gindex() == 0b10011
try:
    (FooFields / 'bar').navigate_type()
    assert False
except KeyError:
    pass

assert issubclass((BarFields / '__active_fields__').navigate_type(), Bitvector)
assert (BarFields / '__active_fields__').navigate_type().vector_length() == 8
assert (BarFields / '__active_fields__').gindex() == 0b11
assert (BarFields / 'bar').navigate_type() == uint64
assert (BarFields / 'bar').gindex() == 0b10001
assert (BarFields / 'more').navigate_type() == Optional[uint32]
assert (BarFields / 'more').gindex() == 0b10011
try:
    (BarFields / 'foo').navigate_type()
    assert False
except KeyError:
    pass
