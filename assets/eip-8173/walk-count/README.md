# One walk versus K-to-the-K: the two conventions, counted

A sound analyzer is downstream, and doesn't know which compiler, if
any, generated the code.  This experiment gives such an analyzer the
same program written two ways — today's `jump` convention, and
`CALLSUB`/`CALLDEST`/`RETURNSUB` — and counts the walks it must make.

## The walker's knowledge rule

Minimal and uncontestable:

* it knows a jump's destination only when the immediately preceding
  instruction pushed it — adjacency, not dataflow, not compiler idioms;
* it maintains the machine's *return stack* itself: only `CALLSUB` and
  `RETURNSUB` touch it, so a walk's own history determines it exactly;
* any other destination is data — the walker forks to every `JUMPDEST`.

A walk ends at `STOP` or the end of code.  A walk that visits the same
instruction more than `cap` times is abandoned.  The true execution of
the K-call program visits SQUARE K times, so `cap = K` is the least
sound bound: smaller loses the true path, larger only grows the tree.

## The program family

K calls to a shared SQUARE routine.  With today's convention (shown at
K = 2):

    push RTN_1 ; push 2 ; push SQUARE ; jump   <- dest pushed adjacent: certain
    RTN_1: jumpdest
    push RTN_2 ; push 3 ; push SQUARE ; jump   <- certain
    RTN_2: jumpdest
    stop
    SQUARE: jumpdest ; dup1 ; mul ; swap1 ; jump   <- dest is data: fork to
                                                      EVERY jumpdest

With the three opcodes:

    push 2 ; push SQUARE ; callsub    <- dest pushed adjacent: certain
    push 3 ; push SQUARE ; callsub    <- certain
    stop
    SQUARE: calldest ; dup1 ; mul ; returnsub  <- dest = the walker's own
                                                  return stack: certain

Both versions execute correctly and compute the same squares —
checked in `run7979.py`, a byte-identical copy of EIP-7979's
reference interpreter, beside the walker.

## The counts

| K | jumpdests | walks, `jump` | walks, `callsub` | gas, `jump` | gas, `callsub` |
|--:|----------:|--------------:|-----------------:|------------:|---------------:|
| 1 | 2 |          2 | 1 |  38 |  28 |
| 2 | 3 |          7 | 1 |  76 |  56 |
| 3 | 4 |         40 | 1 | 114 |  84 |
| 4 | 5 |        341 | 1 | 152 | 112 |
| 5 | 6 |      3,906 | 1 | 190 | 140 |
| 6 | 7 |     55,987 | 1 | 228 | 168 |

The `jump` column obeys a closed form, confirmed against the
enumeration at every row:

    walks(K) = 1 + K + K² + … + K^K

which grows like K^K — faster than any exponential.  Twenty shared
calls is on the order of 10²⁶ walks.  The `callsub` column is 1 at
every K, because both of its transfers are certain: the call's
destination by adjacency, and the return's because the return stack is
machine state the walker reconstructs from its own path.  The same
programs cost 26% less gas besides.

## The conclusion in two sentences

The `jump` convention stores the program's discipline — where returns
go — in data, where a sound walker cannot see it, and charges the
walker K^K walks to guess it back.  The call and return opcodes store
the same discipline in the machine, where the walker can compute it,
and one walk suffices.

## The one-bit exhibit

Give the two-call program one boolean input: if the bit is set, the
second call is skipped.  Now the truth is drawable — exactly two
traces — and all three objects can be compared on one program:

| object | size |
|---|---:|
| the truth (all actual flows) | 2 traces |
| the callsub walker's tree | **2 walks** |
| the jump walker's tree | **13 walks** |

The callsub tree *is* the truth: calls are certain by the adjacent
push, returns by the walker's own return stack, and the one fork left
is the honest one — the input bit, which no static tool can know.
The jump tree holds the same two real walks plus eleven ghosts, every
one born at a return jump whose destination is data.  Runtime, from
the reference interpreter: bit set, 58 gas versus 48; bit clear, 96
versus 76.

Real calldata is 256-bit words, not one bit — the truth for a real
contract is beyond enumeration, which is why tools walk possibilities
instead of inputs, and why the only escape is making the possibilities
certain.

`build_bit_jump()` and `build_bit_callsub()` in walker.py generate the
programs; running it prints the route listing that names all thirteen
walks — `>` marks a transfer the walker knows, `?` one it guesses.

## Reproduce

    python3 walker.py
