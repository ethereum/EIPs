---
eip: 5
title: Gas Usage for `RETURN` and `CALL*`
author: Christian Reitwiessner <c@ethdev.com>
status: Final
type: Standards Track
category: Core
created: 2015-11-22
---

### Abstract

This EIP makes it possible to call functions that return strings and other dynamically-sized arrays.
Currently, when another contract / function is called from inside the Ethereum Virtual Machine,
the size of the output has to be specified in advance. It is of course possible to give a larger
size, but gas also has to be paid for memory that is not written to, which makes returning
dynamically-sized data both costly and inflexible to the extent that it is actually unusable.

The solution proposed in this EIP is to charge gas only for memory that is actually written to at
the time the `CALL` returns.

### Specification

The gas and memory semantics for `CALL`, `CALLCODE` and `DELEGATECALL` (called later as `CALL*`)
are changed in the following way (`CREATE` does not write to memory and is thus unaffected):

Suppose the arguments to `CALL*` are `gas, address, value, input_start, input_size, output_start, output_size`,
then, at the beginning of the opcode, gas for growing memory is only charged for `input_start + input_size`, but not
for `output_start + output_size`.

If the called contract returns data of size `n`, the memory of the calling contract is grown to
`output_start + min(output_size, n)` (and the calling contract is charged gas for that) and the
output is written to the area `[output_start, output_start + min(n, output_size))`.

The calling contract can run out of gas both at the beginning of the opcode and at the end
of the opcode.

After the call, the `MSIZE` opcode should return the size the memory was actually grown to.

### Motivation

In general, it is good practice to reserve a certain memory area for the output of a call,
because letting a subroutine write to arbitrary areas in memory might be dangerous. On the
other hand, it is often hard to know the output size of a call prior to performing the call:
The data could be in the storage of another contract which is generally inaccessible and
determining its size would require another call to that contract.

Furthermore, charging gas for areas of memory that are not actually written to is unnecessary.

This proposal tries to solve both problems: A caller can choose to provide a gigantic area of
memory at the end of their memory area. The callee can "write" to it by returning and the
caller is only charged for the memory area that is actually written.

This makes it possible to return dynamic data like strings and dynamically-sized arrays
in a very flexible way. It is even possible to determine the size of the returned data:
If the caller uses `output_start = MSIZE` and `output_size = 2**256-1`, the area of
memory that was actually written to is `(output_start, MSIZE)` (here, `MSIZE` as evaluated
after the call). This is important because it allows "proxy" contracts
which call other contracts whose interface they do not know and just return their output,
i.e. they both forward the input and the output. For this, it is important that the caller
(1) does not need to know the size of the output in advance and (2) can determine the
size of the output after the call.


### Rationale

This way of dealing with the problem requires a minimal change to the Ethereum Virtual Machine.
Other means of achieving a similar goal would have changed the opcodes themselves or
the number of their arguments. Another possibility would have been to only change the
gas mechanics if `output_size` is equal to `2**256-1`. Since the main difficulty in the
implementation is that memory has to be enlarged at two points in the code around `CALL`,
this would not have been a simplification.

At an earlier stage, it was proposed to also add the size of the returned data on the stack,
but the `MSIZE` mechanism described above should be sufficient and is much better
backwards compatible.

Some comments are available at https://github.com/ethereum/EIPs/issues/8

### Backwards Compatibility

This proposal changes the semantics of contracts because contracts can access the gas counter
and the size of memory.

On the other hand, it is unlikely that existing contracts will suffer from this change due to
the following reasons:

Gas:

The VM will not charge more gas than before. Usually, contracts are written in a way such
that their semantics do not change if they use up less gas. If more gas were used, contracts
might go out-of-gas if they perform a tight estimation for gas needed by sub-calls. Here,
contracts might only return more gas to their callers.

Memory size:

The `MSIZE` opcode is typically used to allocate memory at a previously unused spot.
The change in semantics affects existing contracts in two ways:

1. Overlaps in allocated memory. By using `CALL`, a contract might have wanted to allocate
   a certain slice of memory, even if that is not written to by the called contract.
   Subsequent uses of `MSIZE` to allocate memory might overlap with this slice that is
   now smaller than before the change. It is though unlikely that such contracts exist.

2. Memory addresses change. Rather general, if memory is allocated using `MSIZE`, the
   addresses of objects in memory will be different after the change. Contract should
   all be written in a way, though, such that objects in memory are _relocatable_,
   i.e. their absolute position in memory and their relative position to other
   objects does not matter. This is of course not the case for arrays, but they
   are allocated in a single allocation and not with an intermediate `CALL`.


### Implementation

VM implementers should take care not to grow the memory until the end of the call and after a check that sufficient
gas is still available. Typical uses of the EIP include "reserving" `2**256-1` bytes of memory for the output.

Python implementation:

  old: http://vitalik.ca/files/old.py
  new: http://vitalik.ca/files/new.py
