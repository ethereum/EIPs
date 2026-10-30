"""Tests for the validator and the interpreter, and the EIP's tables.

The validation vectors are headerless, like EIP-8337's, and run with
STACK_LIMIT reduced to 16; the first five are EIP-7979's runtime test
cases, which must still validate under the extended validator.  The
execution cases are legacy code -- the instructions behave the same
in validated code -- and every one that is meant to run is validated
as well.  `python3 test_tables.py --execution` and `--validation`
print the EIP's Test Cases, generated from these same programs.

Opcodes: CALLDEST=0xBB, CALLSUB=0xBC, CALLSUBV=0xBD, JUMPV=0xBE,
RETURNSUB=0xBF.
"""
import sys

import machine
import validator

OPS = {"STOP": 0x00, "ADD": 0x01, "POP": 0x50, "JUMP": 0x56, "JUMPI": 0x57,
       "JUMPDEST": 0x5B, "PUSH0": 0x5F, "CALLDEST": 0xBB, "CALLSUB": 0xBC,
       "CALLSUBV": 0xBD, "JUMPV": 0xBE, "RETURNSUB": 0xBF, "RETURN": 0xF3,
       "MSTORE": 0x52, "CALLDATALOAD": 0x35, "DUP1": 0x80, "SWAP1": 0x90}


def asm(text):
    """Assemble `text`: instructions separated by `;`, labels as
    `name:`, `PUSH1 x` with a number or a label, and `TABLE l1 l2 ...`
    laying down a table -- a count byte and the labels' positions, two
    bytes each -- as data."""
    items = [s.strip() for s in text.split(";") if s.strip()]
    labels, pc = {}, 0
    for item in items:                       # first pass: positions
        if item.endswith(":"):
            labels[item[:-1]] = pc
            continue
        word = item.split()
        pc += (2 if word[0] == "PUSH1" else
               1 + 2 * (len(word) - 1) if word[0] == "TABLE" else 1)
    out = bytearray()
    for item in items:                       # second pass: bytes
        if item.endswith(":"):
            continue
        word = item.split()
        if word[0] == "PUSH1":
            v = labels[word[1]] if word[1] in labels else int(word[1], 0)
            out += bytes([0x60, v])
        elif word[0] == "TABLE":
            out += bytes([len(word) - 2])
            for lab in word[1:]:
                out += labels.get(lab, 0).to_bytes(2, "big")
        else:
            out += bytes([OPS[word[0]]])
    return bytes(out)


# --- validation vectors: (name, program, valid?) -------------------------

VALIDATION = [
    # EIP-7979's runtime test cases, as EIP-8337 validates them
    ("simple routine (EIP-7979)", "PUSH1 f; CALLSUB; STOP; f:; CALLDEST; RETURNSUB", True),
    ("two levels of subroutines (EIP-7979)",
     "PUSH1 f; CALLSUB; STOP; f:; CALLDEST; PUSH1 g; CALLSUB; RETURNSUB; g:; CALLDEST; RETURNSUB", True),
    ("destination outside code (EIP-7979)", "PUSH1 255; CALLSUB; STOP; CALLDEST; RETURNSUB", False),
    ("bare RETURNSUB (EIP-7979)", "RETURNSUB", False),
    ("subroutine at end of code (EIP-7979)",
     "PUSH1 m; JUMP; f:; CALLDEST; RETURNSUB; m:; JUMPDEST; PUSH1 f; CALLSUB", True),

    # JUMPV
    ("JUMPV to two JUMPDESTs",
     "PUSH1 0; PUSH1 t; JUMPV; a:; JUMPDEST; STOP; b:; JUMPDEST; STOP; t:; TABLE a b", True),
    ("JUMPV to a CALLDEST",
     "PUSH1 0; PUSH1 t; JUMPV; a:; JUMPDEST; STOP; f:; CALLDEST; STOP; t:; TABLE a f", True),
    ("JUMPV, arms agree",
     "PUSH1 0; PUSH1 t; JUMPV; a:; JUMPDEST; PUSH1 1; PUSH1 j; JUMP; b:; JUMPDEST; PUSH1 2; j:; JUMPDEST; POP; STOP; t:; TABLE a b", True),
    ("JUMPV, arms disagree",
     "PUSH1 0; PUSH1 t; JUMPV; a:; JUMPDEST; PUSH1 1; PUSH1 j; JUMP; b:; JUMPDEST; j:; JUMPDEST; STOP; t:; TABLE a b", False),
    ("JUMPV not preceded by PUSH",
     "PUSH1 0; PUSH1 t; CALLDATALOAD; JUMPV; a:; JUMPDEST; STOP; t:; TABLE a", False),
    ("JUMPV to a non-label", "PUSH1 0; PUSH1 t; JUMPV; a:; STOP; t:; TABLE a", False),
    ("JUMPV into PUSH data", "PUSH1 0; PUSH1 t; JUMPV; PUSH1 0x5B; x:; STOP; t:; TABLE x", "pushdata"),
    ("JUMPV into its own table", "PUSH1 0; PUSH1 t; JUMPV; STOP; t:; TABLE t", False),
    ("JUMPV destination outside code", "PUSH1 0; PUSH1 t; JUMPV; STOP; t:; TABLE s", "far"),
    ("JUMPV table outside code", "PUSH1 0; PUSH1 255; JUMPV; STOP", False),
    ("JUMPV table truncated", "PUSH1 0; PUSH1 t; JUMPV; a:; JUMPDEST; STOP; t:; TABLE a", "truncate"),
    ("JUMPV with one item on the stack", "PUSH1 t; JUMPV; a:; JUMPDEST; STOP; t:; TABLE a", False),
    ("JUMPV does not fall through", "PUSH1 0; PUSH1 t; JUMPV; ADD; a:; JUMPDEST; STOP; t:; TABLE a", True),

    # CALLSUBV
    ("CALLSUBV to two subroutines",
     "PUSH1 0; PUSH1 t; CALLSUBV; POP; STOP; f:; CALLDEST; PUSH1 1; RETURNSUB; g:; CALLDEST; PUSH1 2; RETURNSUB; t:; TABLE f g", True),
    ("CALLSUBV, nets differ",
     "PUSH1 0; PUSH1 t; CALLSUBV; POP; STOP; f:; CALLDEST; PUSH1 1; RETURNSUB; g:; CALLDEST; RETURNSUB; t:; TABLE f g", False),
    ("CALLSUBV to a JUMPDEST", "PUSH1 0; PUSH1 t; CALLSUBV; STOP; f:; JUMPDEST; RETURNSUB; t:; TABLE f", False),
    ("CALLSUBV, one destination not a CALLDEST",
     "PUSH1 0; PUSH1 t; CALLSUBV; STOP; f:; CALLDEST; RETURNSUB; g:; JUMPDEST; RETURNSUB; t:; TABLE f g", False),
    ("CALLSUBV not preceded by PUSH",
     "PUSH1 0; PUSH1 t; CALLDATALOAD; CALLSUBV; STOP; f:; CALLDEST; RETURNSUB; t:; TABLE f", False),
    ("CALLSUBV subroutine consumes a caller item",
     "PUSH1 7; PUSH1 0; PUSH1 t; CALLSUBV; STOP; f:; CALLDEST; POP; RETURNSUB; t:; TABLE f", True),
    ("CALLSUBV subroutine underflows",
     "PUSH1 0; PUSH1 t; CALLSUBV; STOP; f:; CALLDEST; POP; RETURNSUB; t:; TABLE f", False),
    ("CALLSUBV recursion",
     "PUSH1 0; PUSH1 t; CALLSUBV; STOP; f:; CALLDEST; PUSH1 0; PUSH1 u; CALLSUBV; RETURNSUB; t:; TABLE f; u:; TABLE f", True),
    ("two instructions name one table",
     "PUSH1 0; PUSH1 t; JUMPV; a:; JUMPDEST; PUSH1 1; PUSH1 t; JUMPV; b:; JUMPDEST; STOP; t:; TABLE a b", False),
    ("CALLSUBV, 256 destinations", "many", True),
]


def program(name, text):
    """The bytecode of a validation vector, with its deliberate damage."""
    if text == "many":                       # the largest table: 256 calls of f
        f = 2 + 2 + 1 + 1                    # PUSH1 0, PUSH1 t, CALLSUBV, STOP
        t = f + 2                            # CALLDEST, RETURNSUB
        return (bytes([0x60, 0, 0x60, t, 0xBD, 0x00, 0xBB, 0xBF, 0xFF])
                + f.to_bytes(2, "big") * 256)
    code = asm(text)
    if text.endswith("TABLE s"):             # destination outside code
        return code[:-2] + (0xFF).to_bytes(2, "big")
    if name.endswith("truncated"):           # count says two, table has one
        return code[:-3] + b"\x01" + code[-2:]
    return code


# --- execution cases: (name, program) ------------------------------------

EXECUTION = [
    ("JUMPV: case 1 of three",
     "PUSH1 1; PUSH1 t; JUMPV; a:; JUMPDEST; PUSH1 0xAA; STOP; b:; JUMPDEST; PUSH1 0xBB; STOP; c:; JUMPDEST; PUSH1 0xCC; STOP; t:; TABLE a b c"),
    ("JUMPV: a case beyond the count takes the last entry",
     "PUSH1 7; PUSH1 t; JUMPV; a:; JUMPDEST; PUSH1 0xAA; STOP; b:; JUMPDEST; PUSH1 0xBB; STOP; c:; JUMPDEST; PUSH1 0xCC; STOP; t:; TABLE a b c"),
    ("CALLSUBV: case 0 of two, returning to the instruction after the CALLSUBV",
     "PUSH1 0; PUSH1 t; CALLSUBV; STOP; f:; CALLDEST; PUSH1 1; RETURNSUB; g:; CALLDEST; PUSH1 2; RETURNSUB; t:; TABLE f g"),
    ("JUMPV: the entry is not a JUMPDEST",
     "PUSH1 0; PUSH1 t; JUMPV; a:; STOP; t:; TABLE a"),
    ("JUMPV: the table lies outside the code",
     "PUSH1 0; PUSH1 255; JUMPV; STOP"),
]


def run_validation():
    failures = 0
    for name, text, want in VALIDATION:
        code = program(name, text)
        if want in ("pushdata", "far", "truncate"):
            want = False
        got = validator.validate(code, stack_limit=16)
        ok = got == want
        failures += not ok
        print(f"{'PASS' if ok else 'FAIL'}  {name:44s} 0x{code.hex().upper():<44s} valid={want}")
    return failures


def run_execution():
    failures = 0
    for name, text in EXECUTION:
        code = asm(text)
        status, out, gas, trace = machine.execute(code)
        halts = status not in ("stop", "return", "revert")
        valid = validator.validate(code)
        ok = valid != halts                  # what halts does not validate
        failures += not ok
        print(f"{'PASS' if ok else 'FAIL'}  {name}: {status}, gas {gas}, valid={valid}")
    return failures


def tables(which):
    """The EIP's Test Cases, generated: `execution` or `validation`."""
    if which == "execution":
        for name, text in EXECUTION:
            code = asm(text)
            status, out, gas, trace = machine.execute(code)
            print(f"#### {name}\n")
            print(f"Bytecode: `0x{code.hex().upper()}`\n")
            print(machine.markdown(trace))
            print()
            if status in ("stop", "return", "revert"):
                print(f"Consumed gas: `{gas}`\n")
            else:
                pc, op = trace[-1][0], trace[-1][1]
                print(f"Error: at PC={pc}, {op}: {status}\n")
    else:
        print("| Test | Bytecode | Valid |")
        print("|------|----------|-------|")
        for name, text, want in VALIDATION[5:]:
            code = program(name, text)
            shown = (f"`0x{code.hex().upper()}`" if len(code) <= 44
                     else "256 calls of one subroutine, in `test_tables.py`")
            print(f"| {name} | {shown} | {'yes' if want is True else 'no'} |")


if __name__ == "__main__":
    if "--execution" in sys.argv or "--validation" in sys.argv:
        tables("execution" if "--execution" in sys.argv else "validation")
    else:
        bad = run_validation() + run_execution()
        print("\nall passed" if not bad else f"\n{bad} failures")
        raise SystemExit(1 if bad else 0)
