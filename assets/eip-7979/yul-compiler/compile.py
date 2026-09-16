"""A Yul-subset compiler with two backends: EIP-7979 and legacy EVM.

The point is a demonstration: Yul already has functions, so a
compiler emits them onto CALLSUB / CALLDEST / RETURNSUB nearly
one-to-one, and the output validates under the EIP's reference
validator.  The legacy backend emits the same programs the way
compilers must today — return addresses synthesized on the data
stack, dynamic jumps to return — for a like-for-like comparison of
code size and gas (see test_translator.py).

The subset: function definitions with zero or one return value,
`let`, assignment, `if`, `for` with `break` and `continue`, `leave`,
calls, and a working set of builtins.  Literals are decimal or hex.
No switch, no multi-value returns, no optimizer: the code generator
is a straightforward stack scheduler, the same for both backends —
they differ only in how calls and returns are emitted.

Calling conventions.  7979: caller pushes arguments left to right
and executes CALLSUB; the callee's RETURNSUB leaves the return value
where the arguments were.  Legacy: the caller pushes a return label
below the arguments and jumps; the callee jumps back through it.

Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
"""
import re

CALLSUB, CALLDEST, RETURNSUB = 0xB0, 0xB1, 0xB2
JUMP, JUMPI, JUMPDEST = 0x56, 0x57, 0x5B
PUSH0, POP, ISZERO = 0x5F, 0x50, 0x15
DUP1, SWAP1 = 0x80, 0x90

# name -> (opcode, args, has_result).  Arguments are evaluated right
# to left, so the first argument lands on top, as the EVM pops it.
BUILTINS = {
    "add": (0x01, 2, 1), "mul": (0x02, 2, 1), "sub": (0x03, 2, 1),
    "div": (0x04, 2, 1), "sdiv": (0x05, 2, 1), "mod": (0x06, 2, 1),
    "smod": (0x07, 2, 1), "exp": (0x0A, 2, 1),
    "lt": (0x10, 2, 1), "gt": (0x11, 2, 1), "slt": (0x12, 2, 1),
    "sgt": (0x13, 2, 1), "eq": (0x14, 2, 1), "iszero": (0x15, 1, 1),
    "and": (0x16, 2, 1), "or": (0x17, 2, 1), "xor": (0x18, 2, 1),
    "not": (0x19, 1, 1), "byte": (0x1A, 2, 1),
    "shl": (0x1B, 2, 1), "shr": (0x1C, 2, 1), "sar": (0x1D, 2, 1),
    "calldataload": (0x35, 1, 1), "calldatasize": (0x36, 0, 1),
    "pop": (0x50, 1, 0), "mload": (0x51, 1, 1), "mstore": (0x52, 2, 0),
    "mstore8": (0x53, 2, 0),
    "stop": (0x00, 0, 0), "return": (0xF3, 2, 0), "revert": (0xFD, 2, 0),
}
TERMINATORS = {"stop", "return", "revert"}


# ----------------------------------------------------------------------
# Tokenizer and recursive-descent parser.  The AST is nested tuples.
# ----------------------------------------------------------------------

TOKEN = re.compile(r"""
    \s+ | //[^\n]*                          # skip
  | (?P<num>0x[0-9a-fA-F]+|\d+)
  | (?P<id>[A-Za-z_$][A-Za-z0-9_$.]*)
  | (?P<sym>:=|->|[{}(),])
""", re.X)


def tokenize(src):
    tokens, pos = [], 0
    while pos < len(src):
        m = TOKEN.match(src, pos)
        if not m:
            raise SyntaxError(f"bad character at {pos}: {src[pos:pos+20]!r}")
        pos = m.end()
        for kind in ("num", "id", "sym"):
            if m.group(kind):
                tokens.append((kind, m.group(kind)))
    tokens.append(("eof", ""))
    return tokens


class Parser:
    def __init__(self, src):
        self.toks = tokenize(src)
        self.i = 0

    def peek(self):
        return self.toks[self.i]

    def next(self):
        t = self.toks[self.i]
        self.i += 1
        return t

    def expect(self, text):
        kind, val = self.next()
        if val != text:
            raise SyntaxError(f"expected {text!r}, got {val!r}")

    def parse(self):
        self.expect("{")
        return self.block_body()

    def block_body(self):          # after '{', through matching '}'
        stmts = []
        while self.peek()[1] != "}":
            stmts.append(self.statement())
        self.next()
        return stmts

    def statement(self):
        kind, val = self.peek()
        if val == "{":
            self.next()
            return ("block", self.block_body())
        if val == "function":
            return self.function()
        if val == "let":
            self.next()
            _, name = self.next()
            if self.peek()[1] == ",":
                raise SyntaxError("multi-value let is outside the subset")
            self.expect(":=")
            return ("let", name, self.expression())
        if val == "if":
            self.next()
            cond = self.expression()
            self.expect("{")
            return ("if", cond, self.block_body())
        if val == "for":
            self.next()
            self.expect("{")
            init = self.block_body()
            cond = self.expression()
            self.expect("{")
            post = self.block_body()
            self.expect("{")
            body = self.block_body()
            return ("for", init, cond, post, body)
        if val in ("leave", "break", "continue"):
            self.next()
            return (val,)
        if val == "switch":
            raise SyntaxError("switch is outside the subset")
        if kind == "id" and self.toks[self.i + 1][1] == ":=":
            self.next()
            self.next()
            return ("assign", val, self.expression())
        return ("expr", self.expression())

    def function(self):
        self.expect("function")
        _, name = self.next()
        self.expect("(")
        params = []
        while self.peek()[1] != ")":
            params.append(self.next()[1])
            if self.peek()[1] == ",":
                self.next()
        self.next()
        rets = []
        if self.peek()[1] == "->":
            self.next()
            rets.append(self.next()[1])
            if self.peek()[1] == ",":
                raise SyntaxError("multi-value returns are outside the subset")
        self.expect("{")
        return ("func", name, params, rets, self.block_body())

    def expression(self):
        kind, val = self.next()
        if kind == "num":
            return ("num", int(val, 0))
        if kind != "id":
            raise SyntaxError(f"expected expression, got {val!r}")
        if self.peek()[1] != "(":
            return ("var", val)
        self.next()
        args = []
        while self.peek()[1] != ")":
            args.append(self.expression())
            if self.peek()[1] == ",":
                self.next()
        self.next()
        return ("call", val, args)


# ----------------------------------------------------------------------
# Code generation.  A symbolic stack of names tracks where every
# local lives; reads are DUPs, writes are SWAP-POPs.  Both backends
# share it and differ only in calls and returns.
# ----------------------------------------------------------------------

class Compiler:
    def __init__(self, mode="7979"):
        assert mode in ("7979", "legacy")
        self.mode = mode
        self.out = []                 # ints, ('PUSHLBL', l), ('LABEL', l)
        self.stack = []               # bottom -> top; None is a temporary
        self.funcs = {}               # name -> ('func', ...)
        self.labels = 0

    def label(self, hint):
        self.labels += 1
        return f"{hint}_{self.labels}"

    def emit(self, *ops):
        self.out.extend(ops)

    def push_num(self, v):
        if v == 0:
            self.emit(PUSH0)
        else:
            data = v.to_bytes((v.bit_length() + 7) // 8, "big")
            self.emit(0x5F + len(data), *data)
        self.stack.append(None)

    def dup_of(self, name):
        try:
            depth = len(self.stack) - 1 - max(
                i for i, n in enumerate(self.stack) if n == name)
        except ValueError:
            raise SyntaxError(f"undefined variable {name!r}") from None
        if depth > 15:
            raise SyntaxError(f"{name!r} is {depth} deep: outside the subset")
        self.emit(DUP1 + depth)
        self.stack.append(None)

    def store_to(self, name):        # value on top -> named slot
        depth = len(self.stack) - 1 - max(
            i for i, n in enumerate(self.stack) if n == name)
        if depth > 16:
            raise SyntaxError(f"{name!r} is {depth} deep: outside the subset")
        if depth > 0:
            self.emit(SWAP1 + depth - 1, POP)
        self.stack.pop()

    def pop_to(self, height):        # discard down to a stack height
        while len(self.stack) > height:
            self.emit(POP)
            self.stack.pop()

    # -- expressions ----------------------------------------------------

    def expr(self, e):
        kind = e[0]
        if kind == "num":
            self.push_num(e[1])
        elif kind == "var":
            self.dup_of(e[1])
        elif kind == "call" and e[1] in BUILTINS:
            op, nargs, result = BUILTINS[e[1]]
            if len(e[2]) != nargs:
                raise SyntaxError(f"{e[1]} takes {nargs} arguments")
            for a in reversed(e[2]):
                self.expr(a)
            self.emit(op)
            del self.stack[len(self.stack) - nargs:]
            if result:
                self.stack.append(None)
        elif kind == "call":
            self.user_call(e[1], e[2])
        else:
            raise SyntaxError(f"bad expression {e!r}")

    def user_call(self, name, args):
        if name not in self.funcs:
            raise SyntaxError(f"undefined function {name!r}")
        _, _, params, rets, _ = self.funcs[name]
        if len(args) != len(params):
            raise SyntaxError(f"{name} takes {len(params)} arguments")
        if self.mode == "legacy":
            rtn = self.label("rtn")
            self.out.append(("PUSHLBL", rtn))
            self.stack.append(None)              # the return address
        for a in args:                           # left to right: first deepest
            self.expr(a)
        self.out.append(("PUSHLBL", f"fn_{name}"))
        if self.mode == "7979":
            self.emit(CALLSUB)
        else:
            self.emit(JUMP)
            self.out.append(("LABEL", rtn))
            self.emit(JUMPDEST)
        del self.stack[len(self.stack) - len(args) - (self.mode == "legacy"):]
        if rets:
            self.stack.append(None)

    # -- statements -----------------------------------------------------

    def block(self, stmts, fn):
        height = len(self.stack)
        for s in stmts:
            self.statement(s, fn)
        self.pop_to(height)

    def statement(self, s, fn):
        kind = s[0]
        if kind == "block":
            self.block(s[1], fn)
        elif kind == "let":
            self.expr(s[2])
            self.stack[-1] = s[1]
        elif kind == "assign":
            self.expr(s[2])
            self.store_to(s[1])
        elif kind == "expr":
            before = len(self.stack)
            self.expr(s[1])
            if len(self.stack) > before:         # unused result
                self.emit(POP)
                self.stack.pop()
        elif kind == "if":
            end = self.label("endif")
            self.expr(s[1])
            self.emit(ISZERO)
            self.out.append(("PUSHLBL", end))
            self.emit(JUMPI)
            self.stack.pop()
            self.block(s[2], fn)
            self.out.append(("LABEL", end))
            self.emit(JUMPDEST)
        elif kind == "for":
            self.for_loop(s, fn)
        elif kind == "leave":
            self.epilogue(fn, len(self.stack))
        elif kind in ("break", "continue"):
            if fn.get("loop") is None:
                raise SyntaxError(f"{kind} outside a loop")
            target, height = fn["loop"][kind == "continue"], fn["loop"][2]
            for _ in range(len(self.stack) - height):
                self.emit(POP)                   # model kept: path leaves
            self.out.append(("PUSHLBL", target))
            self.emit(JUMP)
        else:
            raise SyntaxError(f"bad statement {s!r}")

    def for_loop(self, s, fn):
        _, init, cond, post, body = s
        height = len(self.stack)
        for st in init:
            self.statement(st, fn)
        lcond, lpost, lend = self.label("cond"), self.label("post"), self.label("endfor")
        outer = fn.get("loop")
        fn["loop"] = (lend, lpost, len(self.stack))
        self.out.append(("LABEL", lcond))
        self.emit(JUMPDEST)
        self.expr(cond)
        self.emit(ISZERO)
        self.out.append(("PUSHLBL", lend))
        self.emit(JUMPI)
        self.stack.pop()
        self.block(body, fn)
        self.out.append(("LABEL", lpost))
        self.emit(JUMPDEST)
        for st in post:
            self.statement(st, fn)
        self.out.append(("PUSHLBL", lcond))
        self.emit(JUMP)
        self.out.append(("LABEL", lend))
        self.emit(JUMPDEST)
        fn["loop"] = outer
        self.pop_to(height)

    # -- functions ------------------------------------------------------

    def epilogue(self, fn, height):
        """Leave only the return value, then return.  The emitted POPs
        and SWAPs work on copies of the model so that other paths
        (this may be a mid-function leave) still see their stack."""
        stack = self.stack[:]
        nargs, ret = fn["nargs"], fn["ret"]
        extra = ("legacy" == self.mode)          # the return address slot
        for _ in range(height - nargs - extra - bool(ret)):
            self.emit(POP)                       # locals above the return var
            stack.pop()
        if ret:
            if nargs:
                self.emit(SWAP1 + nargs - 1)     # return value into arg1's slot
            for _ in range(nargs):
                self.emit(POP)
        else:
            for _ in range(nargs):
                self.emit(POP)
        if self.mode == "7979":
            self.emit(RETURNSUB)
        else:                                    # the address is now adjacent
            if ret:
                self.emit(SWAP1)
            self.emit(JUMP)

    def function(self, f):
        _, name, params, rets, body = f
        self.out.append(("LABEL", f"fn_{name}"))
        self.emit(CALLDEST if self.mode == "7979" else JUMPDEST)
        self.stack = (["#ret"] if self.mode == "legacy" else []) + list(params)
        fn = {"nargs": len(params), "ret": rets[0] if rets else None, "loop": None}
        if rets:
            self.push_num(0)                     # return variables start at 0
            self.stack[-1] = rets[0]
        for s in body:
            self.statement(s, fn)
        self.epilogue(fn, len(self.stack))

    # -- program --------------------------------------------------------

    def program(self, stmts):
        funcs = [s for s in stmts if s[0] == "func"]
        main = [s for s in stmts if s[0] != "func"]
        self.funcs = {f[1]: f for f in funcs}
        fn = {"nargs": 0, "ret": None, "loop": None}
        for s in main:
            self.statement(s, fn)
        last = main[-1] if main else None
        if not (last and last[0] == "expr" and last[1][0] == "call"
                and last[1][1] in TERMINATORS):
            self.emit(0x00)                      # STOP
        for f in funcs:
            self.function(f)
        return self.assemble()

    def assemble(self):
        """Two passes: place labels with 2-byte pushes, then patch."""
        where, pc = {}, 0
        for item in self.out:
            if isinstance(item, tuple) and item[0] == "LABEL":
                where[item[1]] = pc
            elif isinstance(item, tuple):
                pc += 3                          # PUSH2 hi lo
            else:
                pc += 1
        code = bytearray()
        for item in self.out:
            if isinstance(item, tuple) and item[0] == "LABEL":
                continue
            if isinstance(item, tuple):
                dest = where[item[1]]
                code += bytes([0x61, dest >> 8, dest & 0xFF])
            else:
                code.append(item)
        return bytes(code)


def compile_yul(src, mode="7979"):
    """Compile a Yul-subset source text to EVM bytecode."""
    return Compiler(mode).program(Parser(src).parse())
