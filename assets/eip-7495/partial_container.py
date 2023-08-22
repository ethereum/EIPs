from dataclasses import fields, is_dataclass
import io
from typing import BinaryIO, Dict, Optional, TypeVar, Type, Union as PyUnion, get_args, get_origin
from textwrap import indent
from remerkleable.bitfields import Bitvector
from remerkleable.complex import ComplexView, encode_offset
from remerkleable.core import View, ViewHook, OFFSET_BYTE_LENGTH
from remerkleable.tree import NavigationError, Node, PairNode, \
    get_depth, subtree_fill_to_contents, zero_node

T = TypeVar('T')
N = TypeVar('N')

PartialFields = Dict[str, tuple[Type[View], bool]]

class PartialContainer(ComplexView):
    _field_indices: Dict[str, tuple[int, Type[View], bool]]
    __slots__ = '_field_indices'

    def __new__(cls, backing: Optional[Node] = None, hook: Optional[ViewHook] = None, **kwargs):
        if backing is not None:
            if len(kwargs) != 0:
                raise Exception("cannot have both a backing and elements to init fields")
            return super().__new__(cls, backing=backing, hook=hook, **kwargs)

        for fkey, (ftyp, fopt) in cls.fields().items():
            if fkey not in kwargs:
                if not fopt:
                    raise AttributeError(f"Field '{fkey}' is required in {cls.T}")
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
            raise AttributeError(f'The field names [{"".join(kwargs.keys())}] are not defined in {cls.T}')

        backing = PairNode(
            left=subtree_fill_to_contents(input_nodes, get_depth(cls.N)),
            right=active_fields.get_backing())
        return super().__new__(cls, backing=backing, hook=hook, **kwargs)

    def __init_subclass__(cls, *args, **kwargs):
        super().__init_subclass__(*args, **kwargs)
        cls._field_indices = {
            fkey: (i, ftyp, fopt) for i, (fkey, (ftyp, fopt)) in enumerate(cls.fields().items())}
        if len(cls._field_indices) == 0:
            raise Exception(f"PartialContainer {cls.__name__} must have at least one field!")

    def __class_getitem__(cls, params) -> Type["PartialContainer"]:
        t, n = params

        if not is_dataclass(t):
            raise Exception(f"partialcontainer doesn't wrap `@dataclass`: {t}")
        if n <= 0:
            raise Exception(f"invalid partialcontainer capacity: {n}")

        class PartialContainerView(PartialContainer):
            T = t
            N = n

        PartialContainerView.__name__ = PartialContainerView.type_repr()
        return PartialContainerView

    @classmethod
    def fields(cls) -> PartialFields:
        ret = {}
        for field in fields(cls.T):
            fkey = field.name
            fopt = get_origin(field.type) == PyUnion and type(None) in get_args(field.type)
            ftyp = get_args(field.type)[0] if fopt else field.type
            ret[fkey] = (ftyp, fopt)
        return ret

    def active_fields(self) -> Bitvector:
        active_fields_node = super().get_backing().get_right()
        return Bitvector[self.__class__.N].view_from_backing(active_fields_node)

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

    def _get_field_val_repr(self, fkey: str, ftyp: Type[View], fopt: bool) -> str:
        field_start = '  ' + fkey + ': ' + (
            ('Optional[' if fopt else '') + ftyp.__name__ + (']' if fopt else '')
        ) + ' = '
        try:
            field_repr = repr(getattr(self, fkey))
            if '\n' in field_repr:  # if multiline, indent it, but starting from the value.
                i = field_repr.index('\n')
                field_repr = field_repr[:i+1] + indent(field_repr[i+1:], ' ' * len(field_start))
            return field_start + field_repr
        except NavigationError:
            return f"{field_start} *omitted from partial*"

    def __repr__(self):
        return f"{self.__class__.type_repr()}:\n" + '\n'.join(
            indent(self._get_field_val_repr(fkey, ftyp, fopt), '  ')
            for fkey, (ftyp, fopt) in self.__class__.fields().items())

    @classmethod
    def type_repr(cls) -> str:
        return f"PartialContainer[{cls.T.__name__}, {cls.N}]"

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
