### Title
      EIP: 7
      Title: DELEGATECALL
      Author: Vitalik Buterin <v@buterin.com>
      Status: Final
      Type: Homestead feature
      Created: 2015-11-15

### Overview

Add a new opcode, `DELEGATECALL` at `0xf4`, which is similar in idea to `CALLCODE`, except that it propagates the sender and value from the parent scope to the child scope, i.e. the call created has the same sender and value as the original call.

### Specification

`DELEGATECALL`: `0xf4`, takes 6 operands:
- `gas`: the amount of gas the code may use in order to execute;
- `to`: the destination address whose code is to be executed;
- `in_offset`: the offset into memory of the input;
- `in_size`: the size of the input in bytes;
- `out_offset`: the offset into memory of the output;
- `out_size`: the size of the scratch pad for the output.

#### Notes on gas
- The basic stipend is not given; `gas` is the total amount the callee receives.
- Like `CALLCODE`, account creation never happens, so the upfront gas cost is always `schedule.callGas` + `gas`.
- Unused gas is refunded as normal.

#### Notes on sender
- `CALLER` and `VALUE` behave exactly in the callee's environment as they do in the caller's environment.

#### Other notes
- The depth limit of 1024 is still preserved as normal.

### Rationale

Propagating the sender and value from the parent scope to the child scope makes it much easier for a contract to store another address as a mutable source of code and ''pass through'' calls to it, as the child code would execute in essentially the same environment (except for reduced gas and increased callstack depth) as the parent.

Use case 1: split code to get around 3m gas barrier

```python
~calldatacopy(0, 0, ~calldatasize())
if ~calldataload(0) < 2**253:
    ~delegate_call(msg.gas - 10000, $ADDR1, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
elif ~calldataload(0) < 2**253 * 2:
    ~delegate_call(msg.gas - 10000, $ADDR2, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
...
```

Use case 2: mutable address for storing the code of a contract:

```python
if ~calldataload(0) / 2**224 == 0x12345678 and self.owner == msg.sender:
    self.delegate = ~calldataload(4)
else:
    ~delegate_call(msg.gas - 10000, self.delegate, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
```
The child functions called by these methods can now freely reference `msg.sender` and `msg.value`.

### Possible arguments against

* You can replicate this functionality by just sticking the sender into the first twenty bytes of the call data. However, this would mean that code would need to be specially compiled for delegated contracts, and would not be usable in delegated and raw contexts at the same time.
