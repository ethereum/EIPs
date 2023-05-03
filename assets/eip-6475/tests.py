from optional import Optional
from remerkleable.basic import boolean, uint8, uint16, uint32, uint64, uint128, uint256
from remerkleable.bitfields import Bitlist, Bitvector
from remerkleable.complex import Container, List, Vector
from remerkleable.union import Union

def do_test(value):
    v = value.get()
    if v is None:
        assert value.encode_bytes() == b''
        assert value.hash_tree_root() == List[value.__class__, 1]().hash_tree_root()
    else:
        assert value.encode_bytes() == bytes([0x01]) + v.encode_bytes()
        assert value.hash_tree_root() == List[value.__class__, 1](v).hash_tree_root()
    assert value.__class__.decode_bytes(value.encode_bytes()) == value

if __name__ == '__main__':
    do_test(Optional[uint8](None))
    do_test(Optional[uint8](8))

    do_test(Optional[uint16](None))
    do_test(Optional[uint16](16))

    do_test(Optional[uint32](None))
    do_test(Optional[uint32](32))

    do_test(Optional[uint64](None))
    do_test(Optional[uint64](64))

    do_test(Optional[uint128](None))
    do_test(Optional[uint128](128))

    do_test(Optional[uint256](None))
    do_test(Optional[uint256](256))

    do_test(Optional[boolean](None))
    do_test(Optional[boolean](True))

    do_test(Optional[Optional[uint64]](None))
    do_test(Optional[Optional[uint64]](Optional[uint64](None)))
    do_test(Optional[Optional[uint64]](Optional[uint64](64)))

    class Foo(Container):
        a: uint64
        b: Optional[uint32]
        c: Optional[uint16]

    do_test(Optional[Foo](None))
    do_test(Optional[Foo](Foo(a=64)))
    do_test(Optional[Foo](Foo(a=64, b=Optional[uint32](32))))
    do_test(Optional[Foo](Foo(a=64, b=Optional[uint32](32), c=Optional[uint16](16))))

    do_test(Optional[Vector[uint64, 1]](None))
    do_test(Optional[Vector[uint64, 1]](Vector[uint64, 1](64)))
    do_test(Optional[Vector[uint64, 5]](None))
    do_test(Optional[Vector[uint64, 5]](Vector[uint64, 5](64, 64, 64, 64, 64)))

    do_test(Optional[List[uint64, 1]](None))
    do_test(Optional[List[uint64, 1]](List[uint64, 1]()))
    do_test(Optional[List[uint64, 1]](List[uint64, 1](64)))
    do_test(Optional[List[uint64, 5]](List[uint64, 5](64, 64)))
    do_test(Optional[List[Optional[uint64], 9]](None))
    do_test(Optional[List[Optional[uint64], 9]](
        List[Optional[uint64], 9](Optional[uint64](None), Optional[uint64](64))))
    do_test(Optional[List[Foo, 1]](List[Foo, 1](Foo(a=64, b=Optional[uint32](32)))))
    do_test(Optional[List[Optional[Foo], 1]](
        List[Optional[Foo], 1](Optional[Foo](Foo(a=64, b=Optional[uint32](32), c=Optional[uint16](16))))))

    do_test(Optional[Bitvector[1]](None))
    do_test(Optional[Bitvector[1]](Bitvector[1](True)))
    do_test(Optional[Bitvector[9]](None))
    do_test(Optional[Bitvector[9]](Bitvector[9](True, True, True, True, False, True, True, True, True)))

    do_test(Optional[Bitlist[0]](None))
    do_test(Optional[Bitlist[0]](Bitlist[0]()))
    do_test(Optional[Bitlist[1]](None))
    do_test(Optional[Bitlist[1]](Bitlist[1](True)))
    do_test(Optional[Bitlist[9]](None))
    do_test(Optional[Bitlist[9]](Bitlist[9](True)))

    do_test(Optional[Union[None, uint64, uint32]](None))
    do_test(Optional[Union[None, uint64, uint32]](Union[None, uint64, uint32](selector=0)))
    do_test(Optional[Union[None, uint64, uint32]](Union[None, uint64, uint32](selector=1, value=64)))
    do_test(Optional[Union[None, uint64, uint32]](Union[None, uint64, uint32](selector=2, value=32)))
