# cbench: the native cost of validation

A C port of the bounds-proving validator (`../magic_validator.py`),
kept for one purpose: measuring what validation costs natively.  The
reference validator's costs are bounded above by these — the demand
relaxation that dominates the worst case is the same.

    gcc -O2 -o validator validator.c
    python3 measure.py

measure.py first establishes correctness — the shared vectors and a
fuzz corpus against the Python — then times the benchmark shapes.
Measured on this project's hardware: 8-11 ns/byte on ordinary shapes,
541 ns/byte on the recursion pump, the worst shape found.  These are
the numbers behind `VALIDATION_BYTE_COST`.
