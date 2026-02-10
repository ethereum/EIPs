---
eip: 7923
title: Linear, Page-Based Memory Costing
description: Linearize Memory Costing and replace the current quadratic formula with a page-based cost model.
author: Charles Cooper (@charles-cooper), Qi Zhou (@qizhou)
discussions-to: https://ethereum-magicians.org/t/eip-linearize-memory-costing/23290
status: Draft
type: Standards Track
category: Core
created: 2025-03-27
---

## Abstract

This EIP replaces the quadratic memory model in the EVM with a linear, page-based costing model. Memory is virtually addressable. Page allocation is included in the cost model. After applying this EIP, memory limits are invariant to the state of the message call stack.

## Motivation

The EVM currently uses a quadratic pricing model for its memory. This was originally put in place to defend against DoS attacks. However, the memory model has several drawbacks.

1. It is anachronistic. Even at a gas limit of 30 million gas, users can only use 3MB of memory in a message call (and that burns all gas). Since the quadratic term for memory expansion starts kicking in at 724 bytes, users use much less memory in practice. To use even 64KB of memory -- the amount of memory available to a PC from the early 80's -- costs 14336 gas!
2. The quadratic model makes it difficult to reason about how much memory a transaction can allocate. It requires solving an optimization problem which involves computing how many message calls are available to recurse into based on the call stack limit (and, post [EIP-150](./eip-150.md), the 63/64ths rule), and then maximizing the memory used per message call.
3. The quadratic model makes it impossible for high-level smart contracts languages to get the benefits of virtual memory. Most modern programming languages maintain what is known as the "heap" and the "call stack". The heap is used to allocate objects which live past the lifetime of their current function frame, whereas the call stack is used to allocate objects which live in the current function frames. Importantly, the call stack starts at the top of memory and grows down, while the heap starts at the bottom of memory and grows up, thus the language implementation does not need to worry about the two regions of memory interfering with each other. This is a feature which is enabled by virtual, paged memory, which has been present in operating systems since the early 90's. However, smart contract languages like Vyper and Solidity are not able to implement this, leading to inefficiencies in their memory models.

This EIP proposes a linear costing model which more closely reflects the hardware of today, which is hierarchical ("hot" memory is much faster to access than "cold" memory), and virtually addressed (memory does not need to be allocated contiguously, but is rather served "on-demand" by the operating system).

First, some preliminaries. A page is 4096 bytes on most architectures. Given a memory address, its page is simple to compute by masking out the rightmost 12 bits.

There are two factors which contribute to "cold" memory (i.e. not-recently-used) being slower: CPU cache and TLB (Translation Lookaside Buffer) cache. The CPU cache is a least-recently-used memory cache, which is significantly faster than fetching all the way from RAM. The TLB is usually some hash table which maps virtual pages (used by the user) to physical pages in RAM. "Thrashing", or accessing a lot of different memory addresses, does two things: it pushes memory out of the hot cache and into cold memory, and it pushes pages out of the TLB cache. For this reason, it is worth limiting the amount of memory that is available to a transaction to memory which can be held in the hot set.

This EIP uses a virtual addressing scheme so that memory pages are not allocated until they are actually accessed.

Notably, the data structures used for costing memory do not need to be part of the memory implementation itself, which suggests an elegant implementation using the POSIX `mmap` syscall (or, its counterpart on Windows, `VirtualAlloc`).

The implementation can be approached in two ways. The first way is to implement the virtual addressing "manually". This is intended for systems without `mmap` or a virtual addressing capability. The implementation needs to maintain a map from `map[page_id -> char[4096]]`, where `page_id` is an integer, computed as `memory_address >> 12`. (On reads or writes which cross page boundaries, the implementation needs to load both pages and combine the result of the read or write across both pages).

The other implementation is easier, for systems with `mmap` or a similar facility. To hold the actual data of the memory, the implementation `mmap`s a `2**32` byte region of memory. Then, memory operations can be implemented simply as reads or writes against this buffer. (With an anonymous `mmap`, the operating system will not allocate the entire buffer up-front, rather, it will allocate pages "on demand", as they are touched). The `pages` map is still necessary, but it doesn't hold any data, it is just to track which pages have been allocated, for pricing purposes. In this implementation, there are two data structures: `memory char[2**32]` and `allocated_pages set[page_id]`. The `memory` data structure is only used for memory reads and writes. The `allocated_pages` is only used for gas costing.

## Specification

Consider the following constants:

```python
ALLOCATE_PAGE_COST = 100
PAGE_SIZE = 4096
MAXIMUM_MEMORY_SIZE = 64 * 1024 * 1024
```

The memory costing algorithm is changed as follows:

1. For each page touched by an instruction, charge `ALLOCATE_PAGE_COST` gas if it has not been touched before in this message call, except for page 0 which is free.
2. The base gas cost for all memory instructions, e.g. `MLOAD` and `MSTORE`, remains the same, at 3.
3. The linear and quadratic terms in the memory expansion cost are removed.

The behavior of `msize` remains the same. It returns the maximum byte touched by any memory instruction, rounded up by 32.

Memory addresses are restricted to 32-bits. If an address is larger than `2**32 - 1`, an exceptional halt should be raised.

A transaction-global memory limit is imposed. If the number of pages allocated in a transaction exceeds `MAXIMUM_MEMORY_SIZE // PAGE_SIZE` (i.e., 16384), an exceptional halt should be raised.

## Rationale

Benchmarks were performed on a 2019-era CPU, with the ability to `keccak256` around 256MB/s, giving it a gas-to-ns ratio of 20 ns per 1 gas (given that `keccak256` costs 6 gas per 32 bytes). The following benchmarks were performed:

- Time to allocate a fresh page: 1-2us
- Time to randomly read a byte from a 2MB range: 1.8ns
- Time to randomly read a byte from a 32MB range: 7ns
- Time to randomly read a byte from a 4GB range: 40ns
- Time to update a hashmap with 512 items: 8ns
- Time to update a hashmap with 8192 items: 9ns
- Time to update a hashmap with 5mm items: 108ns
- Time to execute the `mmap` syscall: 230ns

These suggest the following prices:

- 100 gas to allocate a page

Note that the cost to execute `mmap` (~11 gas) is already well-paid for by the base cost of the CALL series of instructions (100 gas). For the same reason, page 0 is free, since the CALL overhead already pays for the initial page allocation. This also improves backwards compatibility, since it keeps the cost for any access within the first page either the same as or lower than current pricing.

There is a desire among client implementations to be able to enforce global limits separately from the gas limit due to DoS reasons. For example, RPC providers may be designed to allow many concurrent `eth_call` computations with a much higher gas limit than on mainnet. Not implicitly tying the memory limit to the gas limit results in one less vector for misconfiguration. That is not to say that in the future, a clean formula cannot be created which allows the memory limit to scale with future hardware improvements (e.g., proportional to the sqrt of the gas limit), but to limit the scope of things that need to be reasoned about for this EIP, the hard limit is introduced.

The hard limit is specified as a transaction-global limit rather than a message-call limit. That is, a reasonable alternative could be to limit the number of pages that can be allocated in a given message call, e.g., to 2MB, but it doesn't significantly improve implementation complexity.

On keeping the semantics of `MSIZE` the same:
With users expected to use the full address space instead of growing it linearly, the rationale for keeping `MSIZE` semantics the same is to avoid breaking backwards compatibility with existing contracts which expect it to grow linearly. New contracts taking advantage of the new virtual addressing scheme should not rely on `MSIZE` for memory allocation.

A hard limit of `2**32` bytes was imposed on the addressing. This makes it simpler for modern 64-bit computers to allocate that much virtual address space, given that clients run on a diverse set of operating systems and architectures which have different virtual memory limits per process. This could be revisited in the future, for instance if gas limits or client memory sizes substantially increase.

## Backwards Compatibility

Addressed in Security Considerations section. No backwards compatibility is broken, although some contracts that previously ran out of gas may now successfully complete.

## Test Cases

## Reference Implementation

A ~60-line reference implementation is provided below. It is implemented as a patch against the `py-evm` codebase at commit ethereum/py-evm@fec63b8c4b9dad9fcb1022c48c863bdd584820c6. (This is a reference implementation, it does not, for example, contain fork choice rules).

```diff
diff --git a/eth/vm/computation.py b/eth/vm/computation.py
index bf34fbee..db85aee7 100644
--- a/eth/vm/computation.py
+++ b/eth/vm/computation.py
@@ -454,34 +454,40 @@ class BaseComputation(ComputationAPI, Configurable):
         validate_uint256(start_position, title="Memory start position")
         validate_uint256(size, title="Memory size")

-        before_size = ceil32(len(self._memory))
-        after_size = ceil32(start_position + size)
-
-        before_cost = memory_gas_cost(before_size)
-        after_cost = memory_gas_cost(after_size)
-
-        if self.logger.show_debug2:
-            self.logger.debug2(
-                f"MEMORY: size ({before_size} -> {after_size}) | "
-                f"cost ({before_cost} -> {after_cost})"
-            )
-
-        if size:
-            if before_cost < after_cost:
-                gas_fee = after_cost - before_cost
-                self._gas_meter.consume_gas(
-                    gas_fee,
-                    reason=" ".join(
-                        (
-                            "Expanding memory",
-                            str(before_size),
-                            "->",
-                            str(after_size),
-                        )
-                    ),
-                )
-
-            self._memory.extend(start_position, size)
+        if size == 0:
+            return
+
+        ALLOCATE_PAGE_COST = 100
+        LOWER_BITS = 12  # bits ignored for page calculations
+        PAGE_SIZE = 4096
+        assert 2**LOWER_BITS == PAGE_SIZE   # sanity check
+        MAXIMUM_MEMORY_SIZE = 64 * 1024 * 1024
+        TRANSACTION_MAX_PAGES = MAXIMUM_MEMORY_SIZE // PAGE_SIZE
+
+        end_position = start_position + size - 1
+
+        start_page = start_position >> LOWER_BITS
+        end_page = end_position >> LOWER_BITS
+
+        for page in range(start_page, end_page + 1):
+            if page not in self._memory.pages:
+                if self.transaction_context.num_pages >= TRANSACTION_MAX_PAGES:
+                    raise VMError("Out Of Memory")
+                self.transaction_context.num_pages += 1
+
+                reason = f"Allocating page {hex(page << LOWER_BITS)}"
+                self._gas_meter.consume_gas(ALLOCATE_PAGE_COST, reason)
+                self._memory.pages[page] = True

     def memory_write(self, start_position: int, size: int, value: bytes) -> None:
         return self._memory.write(start_position, size, value)
diff --git a/eth/vm/forks/frontier/computation.py b/eth/vm/forks/frontier/computation.py
index 51666ae0..443f82b5 100644
--- a/eth/vm/forks/frontier/computation.py
+++ b/eth/vm/forks/frontier/computation.py
@@ -29,6 +29,7 @@ from eth.exceptions import (
     InsufficientFunds,
     OutOfGas,
     StackDepthLimit,
+    VMError,
 )
 from eth.vm.computation import (
     BaseComputation,
@@ -87,12 +88,21 @@ class FrontierComputation(BaseComputation):

         state.touch_account(message.storage_address)

-        computation = cls.apply_computation(
-            state,
-            message,
-            transaction_context,
-            parent_computation=parent_computation,
-        )
+        # implement transaction-global memory limit
+        num_pages_anchor = transaction_context.num_pages
+        try:
+            computation = cls.apply_computation(
+                state,
+                message,
+                transaction_context,
+                parent_computation=parent_computation,
+            )
+        finally:
+            # "deallocate" all the pages allocated in the child computation
+
+            # sanity check an invariant:
+            allocated_pages = len(computation._memory.pages)
+            assert transaction_context.num_pages == num_pages_anchor + allocated pages
+            transaction_context.num_pages = num_pages_anchor

         if computation.is_error:
             state.revert(snapshot)
diff --git a/eth/vm/logic/memory.py b/eth/vm/logic/memory.py
index 806dbd8b..247b3c74 100644
--- a/eth/vm/logic/memory.py
+++ b/eth/vm/logic/memory.py
@@ -43,7 +43,7 @@ def mload(computation: ComputationAPI) -> None:


 def msize(computation: ComputationAPI) -> None:
-    computation.stack_push_int(len(computation._memory))
+    computation.stack_push_int(computation._memory.msize)


 def mcopy(computation: ComputationAPI) -> None:
diff --git a/eth/vm/memory.py b/eth/vm/memory.py
index 2ccfd090..9002b559 100644
--- a/eth/vm/memory.py
+++ b/eth/vm/memory.py
@@ -1,8 +1,11 @@
 import logging

+import mmap
+
 from eth._utils.numeric import (
     ceil32,
 )
+from eth.exceptions import VMError
 from eth.abc import (
     MemoryAPI,
 )
@@ -13,52 +16,48 @@ from eth.validation import (
     validate_uint256,
 )

 class Memory(MemoryAPI):
-    __slots__ = ["_bytes"]
+    __slots__ = ("pages", "msize")
     logger = logging.getLogger("eth.vm.memory.Memory")

     def __init__(self) -> None:
-        self._bytes = bytearray()
+        self.memview = mmap.mmap(-1, 2**32, flags=mmap.MAP_PRIVATE | mmap.MAP_ANONYMOUS)
+        self.pages = {0: True}  # page 0 is free (per spec)
+        self.msize = 0

     def extend(self, start_position: int, size: int) -> None:
         if size == 0:
             return

-        new_size = ceil32(start_position + size)
-        if new_size <= len(self):
+        if start_position + size > self.msize:
+            self.msize = ceil32(start_position + size)
+
+    def write(self, start_position: int, size: int, value: bytes) -> None:
+        if size == 0:
             return

-        size_to_extend = new_size - len(self)
-        try:
-            self._bytes.extend(bytearray(size_to_extend))
-        except BufferError:
-            # we can't extend the buffer (which might involve relocating it) if a
-            # memoryview (which stores a pointer into the buffer) has been created by
-            # read() and not released. Callers of read() will never try to write to the
-            # buffer so we're not missing anything by making a new buffer and forgetting
-            # about the old one. We're keeping too much memory around but this is still
-            # a net savings over having read() return a new bytes() object every time.
-            self._bytes = self._bytes + bytearray(size_to_extend)
-
-    def __len__(self) -> int:
-        return len(self._bytes)
+        if start_position + size >= 2**32:
+            raise VMError("Non 32-bit address")

-    def write(self, start_position: int, size: int, value: bytes) -> None:
-        if size:
-            validate_uint256(start_position)
-            validate_uint256(size)
-            validate_is_bytes(value)
-            validate_length(value, length=size)
-            validate_lte(start_position + size, maximum=len(self))
+        validate_uint256(start_position)
+        validate_uint256(size)
+        validate_is_bytes(value)
+        validate_length(value, length=size)
+
+        end_position = start_position + size

-            self._bytes[start_position : start_position + len(value)] = value
+        self.memview[start_position : end_position] = value

+    # unused
     def read(self, start_position: int, size: int) -> memoryview:
-        return memoryview(self._bytes)[start_position : start_position + size]
+        return memoryview(self.memview)[start_position : start_position + size]

     def read_bytes(self, start_position: int, size: int) -> bytes:
-        return bytes(self._bytes[start_position : start_position + size])
+        return bytes(self.memview[start_position : start_position + size])

     def copy(self, destination: int, source: int, length: int) -> None:
         if length == 0:
@@ -69,5 +68,5 @@ class Memory(MemoryAPI):
         validate_uint256(length)
         validate_lte(max(destination, source) + length, maximum=len(self))

-        buf = memoryview(self._bytes)
+        buf = memoryview(self.memview)
         buf[destination : destination + length] = buf[source : source + length]
diff --git a/eth/vm/transaction_context.py b/eth/vm/transaction_context.py
index 79b570e9..5943f897 100644
--- a/eth/vm/transaction_context.py
+++ b/eth/vm/transaction_context.py
@@ -36,6 +36,9 @@ class BaseTransactionContext(TransactionContextAPI):
         # post-cancun
         self._blob_versioned_hashes = blob_versioned_hashes or []

+        # eip-7923
+        self.num_pages = 0
+
     def get_next_log_counter(self) -> int:
         return next(self._log_counter)
```

## Security Considerations

There are two primary security considerations regarding this EIP.

One, does it break existing contracts? That is, do existing contracts depend on memory being restricted?

Outside of gas costing, existing contracts may simply execute to completion rather than running out of gas.

Two, does this enable memory-based DoS attacks against clients?

This requires a maximum-memory usage analysis. Based on a gas limit today of 30mm gas, recursively calling a contract that allocates 256KB of memory in each call stack can allocate 54MB of total memory, which is not substantially different than the 64MB limit proposed in this EIP. Note that the transaction-global memory limit proposed in this EIP provides a useful invariant, which is that future changes to call stack limits will not affect the total amount of memory that can be allocated in a given transaction.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
