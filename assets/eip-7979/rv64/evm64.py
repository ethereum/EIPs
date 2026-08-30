"""EVM64 as pure opcode addition: no modes, no prefixes.

The 64-bit twin of an arithmetic or comparison opcode x in
0x01..0x1C is 0xC0+x, operating modulo 2^64; CALLDATALOAD64=0xE0,
MLOAD64=0xE1, MSTORE64=0xE2 move words whose values fit 64 bits.
Stack items remain 256-bit words.  All opcode numbers are
placeholders for measurement.

Because the twins are ordinary opcodes, EIP-8337 validation covers
them for free: they are table entries under the fork rule — a fork
that adds instructions defines validation over its full instruction
set.  Nothing else changes.

compile_yul64() compiles the yul7979 subset with 64-bit opcodes by
remapping the compiler's output stream before assembly; the stack
scheduling, calling conventions, and both backends (7979 and legacy)
are untouched.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "yul7979"))

from compile import Compiler, Parser                # noqa: E402

TWIN = {x: 0xC0 + x for x in (0x01, 0x02, 0x03, 0x04, 0x06, 0x10, 0x11,
                              0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                              0x19, 0x1B, 0x1C)}
TWIN[0x35] = 0xE0                                   # CALLDATALOAD64
TWIN[0x51] = 0xE1                                   # MLOAD64
TWIN[0x52] = 0xE2                                   # MSTORE64


class Compiler64(Compiler):
    def assemble(self):
        out, i, src = [], 0, self.out
        while i < len(src):
            item = src[i]
            i += 1
            if isinstance(item, tuple):             # LABEL / PUSHLBL
                out.append(item)
                continue
            out.append(TWIN.get(item, item))
            if 0x5F < item <= 0x7F:                 # skip PUSH data
                n = item - 0x5F
                out.extend(src[i:i + n])
                i += n
        self.out = out
        return super().assemble()


def compile_yul64(src, mode="7979"):
    """Compile a Yul-subset source text to EVM64 bytecode."""
    return Compiler64(mode).program(Parser(src).parse())
