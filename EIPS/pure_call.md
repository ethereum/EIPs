### Parameters

* BASE_GAS_COST: 80
* CODE_BYTES_PER_GAS: 15

### Specification

At `0xf5`, add an opcode `PURE_CALL` that takes seven arguments from the stack: GAS, CODESTART, CODELENGTH, DATASTART, DATALENGTH, OUTPUTSTART, OUTPUTLENGTH.

Let:

* `gas_cost = BASE_GAS_COST + floor(CODELENGTH / CODE_BYTES_PER_GAS)`.
* `input_gas` be the remaining gas in the current context, minus gas costs for expanding memory to cover the three memory slices given above.

Fail if `input_gas < gas_cost` or if `CODELENGTH > 24000`; otherwise execute a call with code equal to the memory slice `CODESTART...CODESTART + CODELENGTH - 1`, input data equal to the memory slice `DATASTART...DATASTART + DATALENGTH - 1`, gas equal to `min(GAS, (input_gas - gas_cost) - floor((input_gas - gas_cost) / 64))` and value 0. The inner context may NOT read state, write state or make any sub-calls except to non-state-changing precompiles; any attempt to do so throws an exception. If execution succeeds, fill the memory slice `OUTPUTSTART...OUTPUTSTART + OUTPUTLENGTH - 1` with the return data with similar rules to how this is handled in CALL, CALLCODE and DELEGATECALL, and push 1 onto the stack. If execution fails, push 0 onto the stack.

### Rationale

This is useful for:

* Adding functional programming features for higher-level languages
* Generally allowing for forms of computation that are safer and can be efficiently optimized/memoized due to their state-independence
* Processing validation code for Casper validators in the future
