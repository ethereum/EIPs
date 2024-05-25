import io
from typing import Any, BinaryIO, Dict, List as PyList, Optional, Tuple, TypeVar, Type, Union as PyUnion, \
    get_args, get_origin
from textwrap import indent
from remerkleable.bitfields import Bitvector
from remerkleable.complex import ComplexView, Container, FieldOffset, \
    decode_offset, encode_offset
from remerkleable.core import View, ViewHook, OFFSET_BYTE_LENGTH
from remerkleable.tree import Gindex, NavigationError, Node, PairNode, \
    get_depth, subtree_fill_to_contents, zero_node, \
    RIGHT_GINDEX

N = TypeVar('N')
B = TypeVar('B', bound="ComplexView")
S = TypeVar('S', bound="ComplexView")


def all_fields(cls) -> Dict[str, Tuple[Type[View], bool]]:
    fields = {}
    for k, v in cls.__annotations__.items():
        fopt = get_origin(v) == PyUnion and type(None) in get_args(v)
        ftyp = get_args(v)[0] if fopt else v
        fields[k] = (ftyp, fopt)
    return fields


def field_val_repr(self, fkey: str, ftyp: Type[View], fopt: bool) -> str:
    field_start = '  ' + fkey + ': ' + (
        ('Optional[' if fopt else '') + ftyp.__name__ + (']' if fopt else '')
    ) + ' = '
    try:
        field_repr = getattr(self, fkey).__repr__()
        if '\n' in field_repr:  # if multiline, indent it, but starting from the value.
            i = field_repr.index('\n')
            field_repr = field_repr[:i+1] + indent(field_repr[i+1:], ' ' * len(field_start))
        return field_start + field_repr
    except NavigationError:
        return f"{field_start} *omitted*"


def repr(self) -> str:
    return f"{self.__class__.type_repr()}:\n" + '\n'.join(
        indent(field_val_repr(self, fkey, ftyp, fopt), '  ')
        for fkey, (ftyp, fopt) in self.__class__.fields().items())


class StableContainer(ComplexView):
    _field_indices: Dict[str, Tuple[int, Type[View], bool]]
    __slots__ = '_field_indices'

    def __new__(cls, backing: Optional[Node] = None, hook: Optional[ViewHook] = None, **kwargs):
        if backing is not None:
            if len(kwargs) != 0:
                raise Exception("cannot have both a backing and elements to init fields")
            return super().__new__(cls, backing=backing, hook=hook, **kwargs)

        for fkey, (ftyp, fopt) in cls.fields().items():
            if fkey not in kwargs:
                if not fopt:
                    raise AttributeError(f"Field '{fkey}' is required in {cls}")
                kwargs[fkey] = None

        input_nodes = []
        active_fields = Bitvector[cls.N]()
        for findex, (fkey, (ftyp, fopt)) in enumerate(cls.fields().items()):
            fnode: Node
            assert fkey in kwargs
            finput = kwargs.pop(fkey)
            if finput is None:
                fnode = zero_node(0)
                active_fields.set(findex, False)
            else:
                if isinstance(finput, View):
                    fnode = finput.get_backing()
                else:
                    fnode = ftyp.coerce_view(finput).get_backing()
                active_fields.set(findex, True)
            input_nodes.append(fnode)

        if len(kwargs) > 0:
            raise AttributeError(f'The field names [{"".join(kwargs.keys())}] are not defined in {cls}')

        backing = PairNode(
            left=subtree_fill_to_contents(input_nodes, get_depth(cls.N)),
            right=active_fields.get_backing())
        return super().__new__(cls, backing=backing, hook=hook, **kwargs)

    def __init_subclass__(cls, *args, **kwargs):
        super().__init_subclass__(*args, **kwargs)
        cls._field_indices = {
            fkey: (i, ftyp, fopt)
            for i, (fkey, (ftyp, fopt)) in enumerate(cls.fields().items())
        }

    def __class_getitem__(cls, n) -> Type["StableContainer"]:
        if n <= 0:
            raise Exception(f"invalid stablecontainer capacity: {n}")

        class StableContainerView(StableContainer):
            N = n

        StableContainerView.__name__ = StableContainerView.type_repr()
        return StableContainerView

    @classmethod
    def fields(cls) -> Dict[str, Tuple[Type[View], bool]]:
        return all_fields(cls)

    @classmethod
    def is_fixed_byte_length(cls) -> bool:
        return False

    @classmethod
    def min_byte_length(cls) -> int:
        total = Bitvector[cls.N].type_byte_length()
        for _, (ftyp, fopt) in cls.fields().items():
            if fopt:
                continue
            if not ftyp.is_fixed_byte_length():
                total += OFFSET_BYTE_LENGTH
            total += ftyp.min_byte_length()
        return total

    @classmethod
    def max_byte_length(cls) -> int:
        total = Bitvector[cls.N].type_byte_length()
        for _, (ftyp, _) in cls.fields().items():
            if not ftyp.is_fixed_byte_length():
                total += OFFSET_BYTE_LENGTH
            total += ftyp.max_byte_length()
        return total

    def active_fields(self) -> Bitvector:
        active_fields_node = super().get_backing().get_right()
        return Bitvector[self.__class__.N].view_from_backing(active_fields_node)

    def __getattribute__(self, item):
        if item == 'N':
            raise AttributeError(f"use .__class__.{item} to access {item}")
        return object.__getattribute__(self, item)

    def __getattr__(self, item):
        if item[0] == '_':
            return super().__getattribute__(item)
        else:
            try:
                (findex, ftyp, fopt) = self.__class__._field_indices[item]
            except KeyError:
                raise AttributeError(f"unknown attribute {item}")

            if not self.active_fields().get(findex):
                assert fopt
                return None

            data = super().get_backing().get_left()
            fnode = data.getter(2**get_depth(self.__class__.N) + findex)
            return ftyp.view_from_backing(fnode)

    def __setattr__(self, key, value):
        if key[0] == '_':
            super().__setattr__(key, value)
        else:
            try:
                (findex, ftyp, fopt) = self.__class__._field_indices[key]
            except KeyError:
                raise AttributeError(f"unknown attribute {key}")

            next_backing = self.get_backing()

            assert value is not None or fopt
            active_fields = self.active_fields()
            active_fields.set(findex, value is not None)
            next_backing = next_backing.rebind_right(active_fields.get_backing())

            if value is not None:
                if isinstance(value, ftyp):
                    fnode = value.get_backing()
                else:
                    fnode = ftyp.coerce_view(value).get_backing()
            else:
                fnode = zero_node(0)
            data = next_backing.get_left()
            next_data = data.setter(2**get_depth(self.__class__.N) + findex)(fnode)
            next_backing = next_backing.rebind_left(next_data)

            self.set_backing(next_backing)

    def __repr__(self):
        return repr(self)

    @classmethod
    def type_repr(cls) -> str:
        return f"StableContainer[{cls.N}]"

    @classmethod
    def deserialize(cls: Type[S], stream: BinaryIO, scope: int) -> S:
        num_prefix_bytes = Bitvector[cls.N].type_byte_length()
        if scope < num_prefix_bytes:
            raise ValueError("scope too small, cannot read StableContainer active fields")
        active_fields = Bitvector[cls.N].deserialize(stream, num_prefix_bytes)
        scope = scope - num_prefix_bytes

        max_findex = 0
        field_values: Dict[str, Optional[View]] = {}
        dyn_fields: PyList[FieldOffset] = []
        fixed_size = 0
        for findex, (fkey, (ftyp, _)) in enumerate(cls.fields().items()):
            max_findex = findex
            if not active_fields.get(findex):
                field_values[fkey] = None
                continue
            if ftyp.is_fixed_byte_length():
                fsize = ftyp.type_byte_length()
                field_values[fkey] = ftyp.deserialize(stream, fsize)
                fixed_size += fsize
            else:
                dyn_fields.append(FieldOffset(
                    key=fkey, typ=ftyp, offset=int(decode_offset(stream))))
                fixed_size += OFFSET_BYTE_LENGTH
        if len(dyn_fields) > 0:
            if dyn_fields[0].offset < fixed_size:
                raise Exception(f"first offset {dyn_fields[0].offset} is "
                                f"smaller than expected fixed size {fixed_size}")
            for i, (fkey, ftyp, foffset) in enumerate(dyn_fields):
                next_offset = dyn_fields[i + 1].offset if i + 1 < len(dyn_fields) else scope
                if foffset > next_offset:
                    raise Exception(f"offset {i} is invalid: {foffset} "
                                    f"larger than next offset {next_offset}")
                fsize = next_offset - foffset
                f_min_size, f_max_size = ftyp.min_byte_length(), ftyp.max_byte_length()
                if not (f_min_size <= fsize <= f_max_size):
                    raise Exception(f"offset {i} is invalid, size out of bounds: "
                                    f"{foffset}, next {next_offset}, implied size: {fsize}, "
                                    f"size bounds: [{f_min_size}, {f_max_size}]")
                field_values[fkey] = ftyp.deserialize(stream, fsize)
        for findex in range(max_findex + 1, cls.N):
            if active_fields.get(findex):
                raise Exception(f"unknown field index {findex}")
        return cls(**field_values)  # type: ignore

    def serialize(self, stream: BinaryIO) -> int:
        active_fields = self.active_fields()
        num_prefix_bytes = active_fields.serialize(stream)

        num_data_bytes = sum(
            ftyp.type_byte_length() if ftyp.is_fixed_byte_length() else OFFSET_BYTE_LENGTH
            for findex, (_, (ftyp, _)) in enumerate(self.__class__.fields().items())
            if active_fields.get(findex))

        temp_dyn_stream = io.BytesIO()
        data = super().get_backing().get_left()
        for findex, (_, (ftyp, _)) in enumerate(self.__class__.fields().items()):
            if not active_fields.get(findex):
                continue
            fnode = data.getter(2**get_depth(self.__class__.N) + findex)
            v = ftyp.view_from_backing(fnode)
            if ftyp.is_fixed_byte_length():
                v.serialize(stream)
            else:
                encode_offset(stream, num_data_bytes)
                num_data_bytes += v.serialize(temp_dyn_stream)  # type: ignore
        temp_dyn_stream.seek(0)
        stream.write(temp_dyn_stream.read(num_data_bytes))

        return num_prefix_bytes + num_data_bytes

    @classmethod
    def navigate_type(cls, key: Any) -> Type[View]:
        if key == '__active_fields__':
            return Bitvector[cls.N]
        (_, ftyp, fopt) = cls._field_indices[key]
        if fopt:
            return Optional[ftyp]
        return ftyp

    @classmethod
    def key_to_static_gindex(cls, key: Any) -> Gindex:
        if key == '__active_fields__':
            return RIGHT_GINDEX
        (findex, _, _) = cls._field_indices[key]
        return 2**get_depth(cls.N) * 2 + findex


class Profile(ComplexView):
    _o: int

    def __new__(cls, backing: Optional[Node] = None, hook: Optional[ViewHook] = None, **kwargs):
        if backing is not None:
            if len(kwargs) != 0:
                raise Exception("cannot have both a backing and elements to init fields")
            return super().__new__(cls, backing=backing, hook=hook, **kwargs)

        extra_kwargs = kwargs.copy()
        for fkey, (ftyp, fopt) in cls.fields().items():
            if fkey in extra_kwargs:
                extra_kwargs.pop(fkey)
            elif not fopt:
                raise AttributeError(f"Field '{fkey}' is required in {cls}")
            else:
                pass
        if len(extra_kwargs) > 0:
            raise AttributeError(f'The field names [{"".join(extra_kwargs.keys())}] are not defined in {cls}')

        value = cls.B(backing, hook, **kwargs)
        return cls(backing=value.get_backing())

    def __init_subclass__(cls, *args, **kwargs):
        super().__init_subclass__(*args, **kwargs)
        cls._o = 0
        for _, (_, fopt) in cls.fields().items():
            if fopt:
                cls._o += 1
        assert cls._o == 0 or issubclass(cls.B, StableContainer)

    def __class_getitem__(cls, b) -> Type["Profile"]:
        if not issubclass(b, StableContainer) and not issubclass(b, Container):
            raise Exception(f"invalid Profile base: {b}")

        class ProfileView(Profile):
            B = b

        ProfileView.__name__ = ProfileView.type_repr()
        return ProfileView

    @classmethod
    def fields(cls) -> Dict[str, Tuple[Type[View], bool]]:
        return all_fields(cls)

    @classmethod
    def is_fixed_byte_length(cls) -> bool:
        if cls._o > 0:
            return False
        for _, (ftyp, _) in cls.fields().items():
            if not ftyp.is_fixed_byte_length():
                return False
        return True

    @classmethod
    def type_byte_length(cls) -> int:
        if cls.is_fixed_byte_length():
            return cls.min_byte_length()
        else:
            raise Exception("dynamic length Profile does not have a fixed byte length")

    @classmethod
    def min_byte_length(cls) -> int:
        total = Bitvector[cls._o].type_byte_length() if cls._o > 0 else 0
        for _, (ftyp, fopt) in cls.fields().items():
            if fopt:
                continue
            if not ftyp.is_fixed_byte_length():
                total += OFFSET_BYTE_LENGTH
            total += ftyp.min_byte_length()
        return total

    @classmethod
    def max_byte_length(cls) -> int:
        total = Bitvector[cls._o].type_byte_length() if cls._o > 0 else 0
        for _, (ftyp, _) in cls.fields().items():
            if not ftyp.is_fixed_byte_length():
                total += OFFSET_BYTE_LENGTH
            total += ftyp.max_byte_length()
        return total

    def active_fields(self) -> Bitvector:
        assert issubclass(self.__class__.B, StableContainer)
        active_fields_node = super().get_backing().get_right()
        return Bitvector[self.__class__.B.N].view_from_backing(active_fields_node)

    def optional_fields(self) -> Bitvector:
        assert issubclass(self.__class__.B, StableContainer)
        assert self.__class__._o > 0
        active_fields = self.active_fields()
        optional_fields = Bitvector[self.__class__._o]()
        oindex = 0
        for fkey, (_, fopt) in self.__class__.fields().items():
            if fopt:
                (findex, _, _) = self.__class__.B._field_indices[fkey]
                optional_fields.set(oindex, active_fields.get(findex))
                oindex += 1
        return optional_fields

    def __getattribute__(self, item):
        if item == 'B':
            raise AttributeError(f"use .__class__.{item} to access {item}")
        return object.__getattribute__(self, item)

    def __getattr__(self, item):
        if item[0] == '_':
            return super().__getattribute__(item)
        else:
            try:
                (ftyp, fopt) = self.__class__.fields()[item]
            except KeyError:
                raise AttributeError(f"unknown attribute {item}")
            try:
                (findex, _, _) = self.__class__.B._field_indices[item]
            except KeyError:
                raise AttributeError(f"unknown attribute {item} in base")

            if not issubclass(self.__class__.B, StableContainer):
                return super().get(findex)

            if not self.active_fields().get(findex):
                assert fopt
                return None

            data = super().get_backing().get_left()
            fnode = data.getter(2**get_depth(self.__class__.B.N) + findex)
            return ftyp.view_from_backing(fnode)

    def __setattr__(self, key, value):
        if key[0] == '_':
            super().__setattr__(key, value)
        else:
            try:
                (ftyp, fopt) = self.__class__.fields()[key]
            except KeyError:
                raise AttributeError(f"unknown attribute {key}")
            try:
                (findex, _, _) = self.__class__.B._field_indices[key]
            except KeyError:
                raise AttributeError(f"unknown attribute {key} in base")

            if not issubclass(self.__class__.B, StableContainer):
                super().set(findex, value)
                return

            next_backing = self.get_backing()

            assert value is not None or fopt
            active_fields = self.active_fields()
            active_fields.set(findex, value is not None)
            next_backing = next_backing.rebind_right(active_fields.get_backing())

            if value is not None:
                if isinstance(value, ftyp):
                    fnode = value.get_backing()
                else:
                    fnode = ftyp.coerce_view(value).get_backing()
            else:
                fnode = zero_node(0)
            data = next_backing.get_left()
            next_data = data.setter(2**get_depth(self.__class__.B.N) + findex)(fnode)
            next_backing = next_backing.rebind_left(next_data)

            self.set_backing(next_backing)

    def __repr__(self):
        return repr(self)

    @classmethod
    def type_repr(cls) -> str:
        return f"Profile[{cls.B.__name__}]"

    @classmethod
    def deserialize(cls: Type[B], stream: BinaryIO, scope: int) -> B:
        if cls._o > 0:
            num_prefix_bytes = Bitvector[cls._o].type_byte_length()
            if scope < num_prefix_bytes:
                raise ValueError("scope too small, cannot read Profile optional fields")
            optional_fields = Bitvector[cls._o].deserialize(stream, num_prefix_bytes)
            scope = scope - num_prefix_bytes

        field_values: Dict[str, Optional[View]] = {}
        dyn_fields: PyList[FieldOffset] = []
        fixed_size = 0
        oindex = 0
        for fkey, (ftyp, fopt) in cls.fields().items():
            if fopt:
                have_field = optional_fields.get(oindex)
                oindex += 1
                if not have_field:
                    field_values[fkey] = None
                    continue
            if ftyp.is_fixed_byte_length():
                fsize = ftyp.type_byte_length()
                field_values[fkey] = ftyp.deserialize(stream, fsize)
                fixed_size += fsize
            else:
                dyn_fields.append(FieldOffset(
                    key=fkey, typ=ftyp, offset=int(decode_offset(stream))))
                fixed_size += OFFSET_BYTE_LENGTH
        assert oindex == cls._o
        if len(dyn_fields) > 0:
            if dyn_fields[0].offset < fixed_size:
                raise Exception(f"first offset {dyn_fields[0].offset} is "
                                f"smaller than expected fixed size {fixed_size}")
            for i, (fkey, ftyp, foffset) in enumerate(dyn_fields):
                next_offset = dyn_fields[i + 1].offset if i + 1 < len(dyn_fields) else scope
                if foffset > next_offset:
                    raise Exception(f"offset {i} is invalid: {foffset} "
                                    f"larger than next offset {next_offset}")
                fsize = next_offset - foffset
                f_min_size, f_max_size = ftyp.min_byte_length(), ftyp.max_byte_length()
                if not (f_min_size <= fsize <= f_max_size):
                    raise Exception(f"offset {i} is invalid, size out of bounds: "
                                    f"{foffset}, next {next_offset}, implied size: {fsize}, "
                                    f"size bounds: [{f_min_size}, {f_max_size}]")
                field_values[fkey] = ftyp.deserialize(stream, fsize)

        return cls(**field_values)  # type: ignore

    def serialize(self, stream: BinaryIO) -> int:
        if self.__class__._o > 0:
            optional_fields = self.optional_fields()
            num_prefix_bytes = optional_fields.serialize(stream)
        else:
            num_prefix_bytes = 0

        num_data_bytes = 0
        oindex = 0
        for _, (ftyp, fopt) in self.__class__.fields().items():
            if fopt:
                have_field = optional_fields.get(oindex)
                oindex += 1
                if not have_field:
                    continue
            if ftyp.is_fixed_byte_length():
                num_data_bytes += ftyp.type_byte_length()
            else:
                num_data_bytes += OFFSET_BYTE_LENGTH
        assert oindex == self.__class__._o

        temp_dyn_stream = io.BytesIO()
        if issubclass(self.__class__.B, StableContainer):
            data = super().get_backing().get_left()
            active_fields = self.active_fields()
            n = self.__class__.B.N
        else:
            data = super().get_backing()
            n = len(self.__class__.B.fields())
        for fkey, (ftyp, _) in self.__class__.fields().items():
            if issubclass(self.__class__.B, StableContainer):
                (findex, _, _) = self.__class__.B._field_indices[fkey]
                if not active_fields.get(findex):
                    continue
                fnode = data.getter(2**get_depth(n) + findex)
            else:
                findex = self.__class__.B._field_indices[fkey]
                fnode = data.getter(2**get_depth(n) + findex)
            v = ftyp.view_from_backing(fnode)
            if ftyp.is_fixed_byte_length():
                v.serialize(stream)
            else:
                encode_offset(stream, num_data_bytes)
                num_data_bytes += v.serialize(temp_dyn_stream)  # type: ignore
        temp_dyn_stream.seek(0)
        stream.write(temp_dyn_stream.read(num_data_bytes))

        return num_prefix_bytes + num_data_bytes

    @classmethod
    def navigate_type(cls, key: Any) -> Type[View]:
        if key == '__active_fields__':
            return Bitvector[cls.B.N]
        (ftyp, fopt) = cls.fields()[key]
        if fopt:
            return Optional[ftyp]
        return ftyp

    @classmethod
    def key_to_static_gindex(cls, key: Any) -> Gindex:
        if key == '__active_fields__':
            return RIGHT_GINDEX
        (_, _) = cls.fields()[key]
        if issubclass(cls.B, StableContainer):
            (findex, _, _) = cls.B._field_indices[key]
            return 2**get_depth(cls.B.N) * 2 + findex
        else:
            findex = cls.B._field_indices[key]
            n = len(cls.B.fields())
            return 2**get_depth(n) + findex


class OneOf(ComplexView):
    def __class_getitem__(cls, b) -> Type["OneOf"]:
        if not issubclass(b, StableContainer) and not issubclass(b, Container):
            raise Exception(f"invalid OneOf base: {b}")

        class OneOfView(OneOf, b):
            B = b

            @classmethod
            def fields(cls):
                return b.fields()

        OneOfView.__name__ = OneOfView.type_repr()
        return OneOfView

    def __repr__(self):
        return repr(self)

    @classmethod
    def type_repr(cls) -> str:
        return f"OneOf[{cls.B}]"

    @classmethod
    def decode_bytes(cls: Type[B], bytez: bytes, *args, **kwargs) -> B:
        stream = io.BytesIO()
        stream.write(bytez)
        stream.seek(0)
        return cls.deserialize(stream, len(bytez), *args, **kwargs)

    @classmethod
    def deserialize(cls: Type[B], stream: BinaryIO, scope: int, *args, **kwargs) -> B:
        value = cls.B.deserialize(stream, scope)
        v = cls.select_from_base(value, *args, **kwargs)
        if not issubclass(v.B, cls.B):
            raise Exception(f"unsupported select_from_base result: {v}")
        return v(backing=value.get_backing())
