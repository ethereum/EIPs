POC-7 https://ethereum.etherpad.mozilla.org/14?
Latest changes:


---------------------------------------------------

Stateless contracts:
Additional opcode: 0xf4: CALLSTATELESS
Calls self, but grabbing the code from the TO argument instead of from one's own address
DONE PY,C++, go/Java

--------------------------------------------------------

0x3b EXTCODESIZE
0x3c EXTCODECOPY
like CODECOPY, CODESIZE but takes an additional parameter at beginning (top of stack) containing address from which to copy.
DONE C++, Go, Java,JS

--------------------------------------------------------

* zero-size memory reads/writes do not lead to a size increase for fee purposes

DONE PY,C++, go, Java,JS

--------------------------------------------------------

New opcodes:

0x80...8f: DUP1 ... DUP16
0x90...9f: SWAP1...SWAP16 (for LLVM cross-compilation)
0x14: ADDMOD
0x15: MULMOD (to make ecrecover easier)

0x51, 0x52 are INVALID.

DONE C++/GO/PY/Java,JS

--------------------------------------------------------

0xf3: POST (same as call, except 5 arguments in and 0 arguments out, and instead of immediately calling it adds the call to a postqueue, to be executed after everything else (including prior-created posts) within the scope of that transaction execution is executed)

Transaction finalisation:
- Create contract if transaction was contract-creation
- Keep executing earliest POST while postqueue isn't empty.
- Refund unused gas to caller (this includes gas unused from POSTs) & give fees to miner.
- Execute SUICIDEs.

DONE C++/GO/PY,JS

----------------------------------------------------

New GHOST protocol

 •	A block can contain as uncles headers which satisfy all of the following criteria:
 ◦	They are valid headers (not necessarily valid blocks)
 ◦	Their parent is a kth generation ancestor for k in {2, 3, 4, 5, 6, 7}
 ◦	They were not uncles of the kth generation ancestor for k in {1, 2, 3, 4, 5, 6}
 •	The uncle reward is increased to 15/16x the main block reward
 •	The nephew reward (ie. reward for including an uncle) is set to 1/32x the main block reward
 •	The target block time is 12s (ie. s/42/9/g in the diff adjustment algo)
 •	>= 5 -> increase
 •	<= 4 -> reduce

SUGGESTION: target block time 4s (eg. >= 3 increase <= 2 reduce) as a temporary stress test

DONE C++/PY/node.js, go/Java

----------------------------------------------------

for blocks, block.hash = sha3(rlp.encode(block.header))

for accounts which don't have code, the code is ""
and the codehash is "" (instead of sha3(()) as in PoC5)

for contract-creation transactions, address is empty rather than 000000000000000...

DONE C++/PY, go/Java/node.js

---------------------------------------------------

CALL, CREATE, CALLDATACOPY, etc should take memory indices as given, and not as mod 2^64 (this could just be implemented as a <=2^64 error check in the code, since using 2^64 memory will be prohibitively expensive)

DONE C++/PY, Go/Java

---------------------------------------------------

PoC-6 Networking (parallel downloads)

DONE C++, Go, node.js/Java

---------------------------------------------------

